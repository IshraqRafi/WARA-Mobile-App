import 'dart:async';
import 'package:flutter/foundation.dart';
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
  /// Error from the conversations stream (null when healthy).
  final Object? error;
  /// Per-room message stream errors.
  final Map<String, Object> roomErrors;

  const ChatState({
    this.error,
    this.roomErrors = const {},
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
    Object? error,
    bool clearError = false,
    Map<String, Object>? roomErrors,
  }) {
    return ChatState(
      error: clearError ? null : (error ?? this.error),
      roomErrors: roomErrors ?? this.roomErrors,
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
  StreamSubscription<List<ChatConversation>>? _demoConvosSubscription;
  final Map<String, StreamSubscription<List<ChatMessage>>> _msgSubscriptions = {};

  ChatNotifier(this._firestoreService, this._currentUser) : super(const ChatState()) {
    _init();
  }

  void _init() {
    final agencyId = _currentUser?.agencyId?.isNotEmpty == true
        ? _currentUser!.agencyId!
        : 'agency_demo_wara';

    // Seed the agency room with a welcome message only if it is empty.
    _firestoreService.seedInitialAgencyChatIfEmpty(
      agencyId: agencyId,
      agencyName: _currentUser?.agencyName ?? 'Wara Media Group',
      managerName: _currentUser?.role == UserRole.manager
          ? (_currentUser?.name.isNotEmpty == true ? _currentUser!.name : 'Ishraq Rafi')
          : 'Ishraq Rafi',
    );

    _subscribeConversations(agencyId);
  }

  /// Re-open the conversation streams (used by the Retry button).
  void retry() {
    final agencyId = _currentUser?.agencyId?.isNotEmpty == true
        ? _currentUser!.agencyId!
        : 'agency_demo_wara';
    state = state.copyWith(clearError: true);
    _subscribeConversations(agencyId);
  }

  void _subscribeConversations(String agencyId) {
    _convosSubscription?.cancel();
    _demoConvosSubscription?.cancel();
    // Stream real-time conversations for this agency
    _convosSubscription = _firestoreService.streamAgencyConversations(agencyId).listen(
      (convos) {
        final currentMap = {for (final c in state.conversations) c.id: c};
        for (final c in convos) {
          currentMap[c.id] = c;
        }
        final list = currentMap.values.toList()
          ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        state = state.copyWith(conversations: list, clearError: true);
      },
      onError: (Object err) {
        debugPrint('Conversations stream error: $err');
        state = state.copyWith(error: err);
      },
    );

    // Also stream demo workspace conversations to ensure cross-workspace direct messages sync
    if (agencyId != 'agency_demo_wara') {
      _demoConvosSubscription = _firestoreService.streamAgencyConversations('agency_demo_wara').listen(
        (demoConvos) {
          final currentMap = {for (final c in state.conversations) c.id: c};
          for (final c in demoConvos) {
            currentMap[c.id] = c;
          }
          final list = currentMap.values.toList()
            ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          state = state.copyWith(conversations: list);
        },
        onError: (Object err) {
          // Secondary demo workspace feed; log only, the main feed drives the UI.
          debugPrint('Demo conversations stream error: $err');
        },
      );
    }
  }

  @override
  void dispose() {
    _convosSubscription?.cancel();
    _demoConvosSubscription?.cancel();
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
    final agencyId = _currentUser?.agencyId?.isNotEmpty == true
        ? _currentUser!.agencyId!
        : 'agency_demo_wara';

    // Cancel existing subscription for this room if any
    _msgSubscriptions[conversationId]?.cancel();

    _msgSubscriptions[conversationId] = _firestoreService
        .streamConversationMessages(agencyId, conversationId)
        .listen(
      (messages) {
        final updatedMap = Map<String, List<ChatMessage>>.from(state.messagesMap);
        updatedMap[conversationId] = messages;
        final errors = Map<String, Object>.from(state.roomErrors)..remove(conversationId);
        state = state.copyWith(messagesMap: updatedMap, roomErrors: errors);
      },
      onError: (Object err) {
        debugPrint('Messages stream error ($conversationId): $err');
        final errors = Map<String, Object>.from(state.roomErrors)..[conversationId] = err;
        state = state.copyWith(roomErrors: errors);
      },
    );
  }

  /// Send a message with optimistic local update followed by Firestore persistence.
  /// Returns false if the message could not be saved (it is removed locally).
  Future<bool> sendMessage({
    required String conversationId,
    required String text,
    String? attachmentUrl,
    String? attachmentType,
    String? recipientId,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && (attachmentUrl == null || attachmentUrl.isEmpty)) {
      return false;
    }

    final user = _currentUser;
    if (user == null) return false;
    final agencyId = user.agencyId?.isNotEmpty == true ? user.agencyId! : 'agency_demo_wara';

    final now = DateTime.now();
    final messageId = 'msg_${now.millisecondsSinceEpoch}_${user.id.length > 4 ? user.id.substring(0, 4) : user.id}';

    final newMessage = ChatMessage(
      id: messageId,
      conversationId: conversationId,
      agencyId: agencyId,
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
        agencyId: agencyId,
        conversationId: conversationId,
        message: newMessage,
        recipientId: recipientId,
      );
      return true;
    } catch (err) {
      debugPrint('sendMessage failed: $err');
      // Revert the optimistic message so the UI doesn't show an unsent message as sent.
      final reverted = Map<String, List<ChatMessage>>.from(state.messagesMap);
      reverted[conversationId] =
          (reverted[conversationId] ?? []).where((m) => m.id != messageId).toList();
      state = state.copyWith(messagesMap: reverted);
      return false;
    }
  }

  /// Mark a conversation as read by the current user
  Future<void> markAsRead(String conversationId) async {
    final user = _currentUser;
    if (user == null) return;
    final agencyId = user.agencyId?.isNotEmpty == true ? user.agencyId! : 'agency_demo_wara';

    // Optimistic local update
    final updatedConvos = state.conversations.map((c) {
      if (c.id == conversationId) {
        final currentReadBy = List<String>.from(c.readBy);
        if (!currentReadBy.contains(user.id)) {
          currentReadBy.add(user.id);
        }
        return c.copyWith(readBy: currentReadBy);
      }
      return c;
    }).toList();
    state = state.copyWith(conversations: updatedConvos);

    await _firestoreService.markConversationAsRead(agencyId, conversationId, user.id);
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
