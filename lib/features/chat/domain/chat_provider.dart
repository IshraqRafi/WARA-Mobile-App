import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/domain/auth_provider.dart';
import '../../projects/domain/project_provider.dart';
import 'chat_models.dart';

enum ChatFilter { all, channel, direct }

class ChatState {
  final List<ChatConversation> conversations;
  final Map<String, List<ChatMessage>> messagesMap;
  final bool isLoading;
  final String searchQuery;
  final ChatFilter activeFilter;

  const ChatState({
    this.conversations = const [],
    this.messagesMap = const {},
    this.isLoading = false,
    this.searchQuery = '',
    this.activeFilter = ChatFilter.all,
  });

  List<ChatConversation> get filteredConversations {
    return conversations.where((c) {
      if (activeFilter == ChatFilter.channel && c.type != ConversationType.channel) {
        return false;
      }
      if (activeFilter == ChatFilter.direct && c.type != ConversationType.direct) {
        return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchesTitle = c.title.toLowerCase().contains(q);
        final matchesLastMsg = c.lastMessage.toLowerCase().contains(q);
        final matchesParticipant = c.participantNames.values.any((n) => n.toLowerCase().contains(q));
        if (!matchesTitle && !matchesLastMsg && !matchesParticipant) return false;
      }
      return true;
    }).toList();
  }

  ChatState copyWith({
    List<ChatConversation>? conversations,
    Map<String, List<ChatMessage>>? messagesMap,
    bool? isLoading,
    String? searchQuery,
    ChatFilter? activeFilter,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messagesMap: messagesMap ?? this.messagesMap,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final FirestoreService _firestoreService;
  final UserSession? _currentUser;
  StreamSubscription<List<ChatConversation>>? _convosSubscription;
  final Map<String, StreamSubscription<List<ChatMessage>>> _msgSubscriptions = {};

  ChatNotifier(this._firestoreService, this._currentUser) : super(const ChatState()) {
    _init();
  }

  void _init() {
    final agencyId = _currentUser?.agencyId;
    if (agencyId == null || agencyId.isEmpty) return;

    // Reset agency general chat with owner welcome message
    _firestoreService.resetAgencyRoom(
      agencyId: agencyId,
      agencyName: _currentUser?.agencyName ?? 'Wara Media Group',
      managerName: _currentUser?.role == UserRole.manager
          ? (_currentUser?.name.isNotEmpty == true ? _currentUser!.name : 'Ishraq Rafi')
          : 'Ishraq Rafi',
      managerId: _currentUser?.role == UserRole.manager
          ? (_currentUser?.id ?? 'manager_1')
          : 'manager_1',
      managerPhotoUrl: _currentUser?.role == UserRole.manager ? _currentUser?.photoUrl : null,
    );

    // Stream real-time conversations for this agency
    _convosSubscription = _firestoreService.streamAgencyConversations(agencyId).listen(
      (convos) {
        state = state.copyWith(conversations: convos);
      },
      onError: (_) {
        // Fallback or offline
      },
    );
  }

  @override
  void dispose() {
    _convosSubscription?.cancel();
    for (final sub in _msgSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  void setFilter(ChatFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Subscribe to real-time messages for a specific conversation room
  void subscribeToConversationMessages(String conversationId) {
    final agencyId = _currentUser?.agencyId;
    if (agencyId == null || agencyId.isEmpty) return;

    // Cancel existing subscription for this room if any
    _msgSubscriptions[conversationId]?.cancel();

    _msgSubscriptions[conversationId] = _firestoreService
        .streamConversationMessages(agencyId, conversationId)
        .listen((messages) {
      final updatedMap = Map<String, List<ChatMessage>>.from(state.messagesMap);
      updatedMap[conversationId] = messages;
      state = state.copyWith(messagesMap: updatedMap);
    });
  }

  /// Send a message with optimistic local update followed by Firestore persistence
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && (attachmentUrl == null || attachmentUrl.isEmpty)) {
      return;
    }

    final user = _currentUser;
    if (user == null || user.agencyId == null) return;

    final now = DateTime.now();
    final messageId = 'msg_${now.millisecondsSinceEpoch}_${user.id.length > 4 ? user.id.substring(0, 4) : user.id}';

    final newMessage = ChatMessage(
      id: messageId,
      conversationId: conversationId,
      agencyId: user.agencyId!,
      senderId: user.id,
      senderName: user.name.isNotEmpty ? user.name : (user.role.name == 'manager' ? 'Agency Lead' : 'Editor'),
      senderPhotoUrl: user.photoUrl,
      senderRole: user.role.name,
      text: cleanText,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      createdAt: now,
    );

    // 1. Optimistic local update
    final currentList = state.messagesMap[conversationId] ?? [];
    final updatedMap = Map<String, List<ChatMessage>>.from(state.messagesMap);
    updatedMap[conversationId] = [...currentList, newMessage];
    state = state.copyWith(messagesMap: updatedMap);

    // 2. Cloud Firestore write
    try {
      await _firestoreService.sendChatMessage(
        agencyId: user.agencyId!,
        conversationId: conversationId,
        message: newMessage,
      );
    } catch (_) {
      // Revert or show offline state if needed
    }
  }

  /// Get or create a deterministic 1-on-1 Direct Message conversation between current user and another team member
  Future<ChatConversation> getOrCreateDirectConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
  }) async {
    final user = _currentUser;
    final agencyId = user?.agencyId ?? 'agency_demo_wara';

    // Deterministic DM ID sorted by UID
    final uids = [user?.id ?? 'user_me', otherUserId]..sort();
    final convoId = 'dm_${uids.join('_')}';

    // Check if conversation already exists in active state
    for (final c in state.conversations) {
      if (c.id == convoId) return c;
    }

    final newConvo = ChatConversation(
      id: convoId,
      agencyId: agencyId,
      type: ConversationType.direct,
      title: otherUserName,
      participantIds: [user?.id ?? 'user_me', otherUserId],
      participantNames: {
        user?.id ?? 'user_me': user?.name ?? 'Me',
        otherUserId: otherUserName,
      },
      participantPhotos: Map<String, String?>.fromEntries([
        if (user?.photoUrl != null) MapEntry(user!.id, user.photoUrl),
        if (otherUserPhoto != null) MapEntry(otherUserId, otherUserPhoto),
      ]),
      lastMessage: '',
      lastSenderName: '',
      lastMessageTime: DateTime.now(),
    );

    await _firestoreService.createOrGetConversation(agencyId, newConvo);
    return newConvo;
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final user = ref.watch(authProvider).user;
  return ChatNotifier(firestore, user);
});
