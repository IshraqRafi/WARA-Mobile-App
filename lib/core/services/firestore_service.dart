import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../../features/chat/domain/chat_models.dart';
import '../../features/notifications/domain/notification_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      _db.collection('projects');

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _agenciesRef =>
      _db.collection('agencies');

  /// Generate a memorable, human-friendly agency join key (e.g. WARA-4829, APEX-9281)
  static String generateJoinKey(String agencyName) {
    final clean = agencyName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final prefix = clean.length >= 4 ? clean.substring(0, 4) : clean.padRight(4, 'X');
    final randSuffix = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();
    return '$prefix-$randSuffix';
  }

  /// Create a new Agency in Firestore
  Future<AgencyModel> createAgency({
    required String name,
    required String managerUid,
    required String managerName,
  }) async {
    final suffix = managerUid.length > 5 ? managerUid.substring(0, 5) : managerUid;
    final agencyId = 'agency_${DateTime.now().millisecondsSinceEpoch}_$suffix';
    final joinKey = generateJoinKey(name);
    final agency = AgencyModel(
      id: agencyId,
      name: name.trim().isNotEmpty ? name.trim() : 'My Agency',
      managerUid: managerUid,
      managerName: managerName,
      joinKey: joinKey,
      createdAt: DateTime.now(),
    );

    await _agenciesRef.doc(agencyId).set(agency.toMap());
    return agency;
  }

  /// Verify and lookup an agency by its Join Key
  Future<AgencyModel?> validateAndGetAgencyByKey(String joinKey) async {
    final cleanKey = joinKey.trim().toUpperCase();
    if (cleanKey.isEmpty) return null;

    try {
      final query = await _agenciesRef
          .where('joinKey', isEqualTo: cleanKey)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return AgencyModel.fromMap(doc.id, doc.data());
      }
    } catch (_) {}
    return null;
  }

  /// Retrieve an agency by its ID
  Future<AgencyModel?> getAgencyById(String agencyId) async {
    try {
      final doc = await _agenciesRef.doc(agencyId).get();
      if (doc.exists && doc.data() != null) {
        return AgencyModel.fromMap(doc.id, doc.data()!);
      }
    } catch (_) {}
    return null;
  }

  /// Live stream of an agency document
  Stream<AgencyModel?> streamAgency(String agencyId) {
    return _agenciesRef.doc(agencyId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AgencyModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }

  /// Regenerate a join key for an existing agency
  Future<String> regenerateAgencyKey(String agencyId, String agencyName) async {
    final newKey = generateJoinKey(agencyName);
    await _agenciesRef.doc(agencyId).set({
      'joinKey': newKey,
      'keyUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return newKey;
  }

  /// Real-time stream of projects, optionally scoped by agencyId
  Stream<List<ProjectItem>> streamProjects({String? agencyId}) {
    Query<Map<String, dynamic>> query = _projectsRef;
    if (agencyId != null && agencyId.isNotEmpty) {
      query = query.where('agencyId', isEqualTo: agencyId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProjectItem.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Real-time stream of registered editors, optionally scoped by agencyId, sorted by rating/rank
  Stream<List<Map<String, dynamic>>> streamEditors({String? agencyId}) {
    return _usersRef.where('role', isEqualTo: 'editor').snapshots().map((snapshot) {
      final list = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['uid'] = doc.id;

        // If agencyId is provided, match this agency, unassigned users, or demo agency
        final docAgencyId = data['agencyId'] as String?;
        if (agencyId != null && agencyId.isNotEmpty) {
          final isMatch = docAgencyId == agencyId ||
              docAgencyId == null ||
              docAgencyId.isEmpty ||
              docAgencyId == 'agency_demo_wara';
          if (!isMatch) continue;
        }

        // Fallback name if missing or blank (e.g. use email prefix from real Google sign-in)
        final email = data['email'] as String? ?? '';
        final name = (data['name'] as String? ?? '').trim();
        if (name.isEmpty && email.isNotEmpty) {
          data['name'] = email.split('@').first;
        } else if (name.isEmpty) {
          data['name'] = 'Creative Editor';
        }

        // Default stats if not yet recorded
        if (data['rating'] == null) {
          data['rating'] = 5.0;
        }
        if (data['ratingCount'] == null) {
          data['ratingCount'] = 1;
        }
        if (data['completedProjects'] == null) {
          data['completedProjects'] = 0;
        }

        list.add(data);
      }

      // Sort in descending order of rating and completed projects
      list.sort((a, b) {
        final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        final cmp = rB.compareTo(rA);
        if (cmp != 0) return cmp;
        final pA = (a['completedProjects'] as num?)?.toInt() ?? 0;
        final pB = (b['completedProjects'] as num?)?.toInt() ?? 0;
        return pB.compareTo(pA);
      });

      return list;
    });
  }

  /// Reset all projects in Firestore and populate with the 6 fresh unassigned projects
  Future<void> resetAndSeedFreshProjects() async {
    try {
      final snapshot = await _projectsRef.get();
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      for (final project in kInitialProjectsData) {
        final docRef = _projectsRef.doc(project.id);
        batch.set(docRef, project.toMap());
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Automatically seeds initial projects if the Firestore collection is empty
  Future<void> seedInitialProjectsIfEmpty() async {
    try {
      final snapshot = await _projectsRef.limit(1).get();
      if (snapshot.docs.isEmpty) {
        await resetAndSeedFreshProjects();
      }
    } catch (e) {
      // In case of offline or rules error, log silently
    }
  }

  /// Create a new project in Firestore
  Future<void> createProject(ProjectItem item) async {
    await _projectsRef.doc(item.id).set(item.toMap());
  }

  /// Delete a project from Cloud Firestore
  Future<void> deleteProject(String projectId) async {
    await _projectsRef.doc(projectId).delete();
  }

  /// Update an open project's variables
  Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    await _projectsRef.doc(projectId).update(data);
  }

  /// Claim a project offer
  Future<void> claimProject(String projectId, String editorId, String editorName) async {
    await _projectsRef.doc(projectId).update({
      'claimedByEditorId': editorId,
      'claimedByEditorName': editorName,
      'claimedAt': DateTime.now().toIso8601String(),
      'status': ProjectStatus.claimed.name,
    });
  }

  /// Return a project offer to the marketplace pool
  Future<void> returnProject(String projectId, int newHoursLeft, String newDeadlineStr) async {
    await _projectsRef.doc(projectId).update({
      'claimedByEditorId': null,
      'claimedByEditorName': null,
      'claimedAt': null,
      'status': ProjectStatus.open.name,
      'deadlineHoursLeft': newHoursLeft,
      'deadlineStr': newDeadlineStr,
      'submissionLink': null,
      'submissionNote': null,
      'submittedAt': null,
      'isOverdue': false,
    });
  }

  /// Re-list an overdue project with updated payout
  Future<void> relistOverdueProject(String projectId, double newPayout) async {
    await _projectsRef.doc(projectId).update({
      'claimedByEditorId': null,
      'claimedByEditorName': null,
      'claimedAt': null,
      'status': ProjectStatus.open.name,
      'editorPayout': newPayout,
      'deadlineHoursLeft': 24,
      'deadlineStr': 'Urgent • 24 Hours Left',
      'submissionLink': null,
      'submissionNote': null,
      'submittedAt': null,
      'isOverdue': false,
    });
  }

  /// Submit deliverable link and notes
  Future<void> submitWork(String projectId, String link, String note, String submittedAt) async {
    await _projectsRef.doc(projectId).update({
      'status': ProjectStatus.submitted.name,
      'submissionLink': link,
      'submissionNote': note,
      'submittedAt': submittedAt,
    });
  }

  /// Approve project deliverable
  Future<void> approveProject(String projectId) async {
    await _projectsRef.doc(projectId).update({
      'status': ProjectStatus.approved.name,
    });
  }

  /// Request revision from editor
  Future<void> requestRevision(String projectId, String feedback) async {
    await _projectsRef.doc(projectId).update({
      'status': ProjectStatus.claimed.name,
      'submissionNote': 'Revision Request: $feedback',
    });
  }

  /// Assign project directly to an editor
  Future<void> assignProject(String projectId, String editorId, String editorName) async {
    await _projectsRef.doc(projectId).update({
      'claimedByEditorId': editorId,
      'claimedByEditorName': editorName,
      'claimedAt': DateTime.now().toIso8601String(),
      'status': ProjectStatus.claimed.name,
    });
  }

  /// User profile persistence in Firestore
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String name,
    required UserRole role,
    required List<String> skills,
    required int hoursPerWeek,
    required List<String> activeDays,
    bool isProfileComplete = false,
    String? specialization,
    String? portfolioLink,
    String? agencyId,
    String? agencyName,
    String? agencyJoinKey,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'name': name,
      'role': role.name,
      'skills': skills,
      'hoursPerWeek': hoursPerWeek,
      'activeDays': activeDays,
      'isProfileComplete': isProfileComplete,
      'specialization': specialization,
      'portfolioLink': portfolioLink,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (agencyId != null) data['agencyId'] = agencyId;
    if (agencyName != null) data['agencyName'] = agencyName;
    if (agencyJoinKey != null) data['agencyJoinKey'] = agencyJoinKey;

    await _usersRef.doc(uid).set(data, SetOptions(merge: true));
  }

  /// Complete full onboarding profile for an editor
  Future<void> completeEditorProfile({
    required String uid,
    required String name,
    required String specialization,
    required List<String> skills,
    required int hoursPerWeek,
    required List<String> activeDays,
    required String portfolioLink,
    String? photoUrl,
    String? agencyId,
    String? agencyName,
    String? agencyJoinKey,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'specialization': specialization,
      'skills': skills,
      'hoursPerWeek': hoursPerWeek,
      'activeDays': activeDays,
      'portfolioLink': portfolioLink,
      'isProfileComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      data['photoUrl'] = photoUrl.trim();
    }
    if (agencyId != null) data['agencyId'] = agencyId;
    if (agencyName != null) data['agencyName'] = agencyName;
    if (agencyJoinKey != null) data['agencyJoinKey'] = agencyJoinKey;

    await _usersRef.doc(uid).set(data, SetOptions(merge: true));
  }

  /// Update user profile data in Firestore
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final updateData = Map<String, dynamic>.from(data);
    updateData['updatedAt'] = FieldValue.serverTimestamp();
    await _usersRef.doc(uid).set(updateData, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get().timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw Exception('Firestore timeout'),
      );
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  // ── Messenger & Conversations ──────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _conversationsRef(String agencyId) =>
      _agenciesRef.doc(agencyId).collection('conversations');

  CollectionReference<Map<String, dynamic>> _messagesRef(String agencyId, String conversationId) =>
      _agenciesRef.doc(agencyId).collection('conversations').doc(conversationId).collection('messages');

  /// Real-time stream of conversations in an agency ordered by most recent message
  Stream<List<ChatConversation>> streamAgencyConversations(String agencyId) {
    return _conversationsRef(agencyId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatConversation.fromMap(doc.id, doc.data())).toList();
    });
  }

  /// Real-time stream of messages in a conversation ordered chronologically
  Stream<List<ChatMessage>> streamConversationMessages(String agencyId, String conversationId) {
    return _messagesRef(agencyId, conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromMap(doc.id, doc.data())).toList();
    });
  }

  /// Ensure a conversation document exists in Firestore
  Future<void> createOrGetConversation(String agencyId, ChatConversation conversation) async {
    final docRef = _conversationsRef(agencyId).doc(conversation.id);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set(conversation.toMap());
    }
  }

  /// Send a message and atomically update the parent conversation's last message metadata
  Future<void> sendChatMessage({
    required String agencyId,
    required String conversationId,
    required ChatMessage message,
  }) async {
    final batch = _db.batch();
    final msgDocRef = _messagesRef(agencyId, conversationId).doc(message.id);
    batch.set(msgDocRef, message.toMap());

    final convoDocRef = _conversationsRef(agencyId).doc(conversationId);
    batch.set(convoDocRef, {
      'lastMessage': message.text,
      'lastSenderName': message.senderName,
      'lastMessageTime': Timestamp.fromDate(message.createdAt),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Auto-seed the agency general room with initial welcome messages if empty
  Future<void> seedInitialAgencyChatIfEmpty({
    required String agencyId,
    required String agencyName,
    required String managerName,
  }) async {
    try {
      final convoDocRef = _conversationsRef(agencyId).doc('agency_general');
      final convoDoc = await convoDocRef.get();
      if (!convoDoc.exists) {
        final now = DateTime.now();
        final generalConvo = ChatConversation(
          id: 'agency_general',
          agencyId: agencyId,
          type: ConversationType.channel,
          title: '# agency-room',
          description: 'Official Agency Workspace & Production Channel for $agencyName',
          participantIds: [],
          participantNames: {},
          participantPhotos: {},
          lastMessage: 'Welcome to $agencyName team channel! Post updates, drop assets, or ask questions here.',
          lastSenderName: managerName.isNotEmpty ? managerName : 'Director',
          lastMessageTime: now,
        );
        await convoDocRef.set(generalConvo.toMap());

        // First message in # general
        final welcomeMsg = ChatMessage(
          id: 'msg_welcome_1',
          conversationId: 'agency_general',
          agencyId: agencyId,
          senderId: 'manager_director',
          senderName: managerName.isNotEmpty ? managerName : 'Director',
          senderRole: 'manager',
          text: '👋 Welcome to $agencyName! All project notifications, urgent cuts, and asset drive links will be shared here. Feel free to discuss ideas or ask any questions.',
          createdAt: now,
        );
        await _messagesRef(agencyId, 'agency_general').doc(welcomeMsg.id).set(welcomeMsg.toMap());
      }
    } catch (_) {}
  }

  /// Reset the agency room in messenger and seed a pre-welcoming message from the owner/director
  Future<void> resetAgencyRoom({
    required String agencyId,
    required String agencyName,
    required String managerName,
    required String managerId,
    String? managerPhotoUrl,
  }) async {
    try {
      final now = DateTime.now();

      // Clear any stale messages in agency_general
      final msgsSnap = await _messagesRef(agencyId, 'agency_general').get();
      final batch = _db.batch();
      for (final doc in msgsSnap.docs) {
        batch.delete(doc.reference);
      }

      // Update agency_general conversation document
      final convoDocRef = _conversationsRef(agencyId).doc('agency_general');
      final generalConvo = ChatConversation(
        id: 'agency_general',
        agencyId: agencyId,
        type: ConversationType.channel,
        title: '# agency-room',
        description: 'Official Agency Workspace & Production Channel for $agencyName',
        participantIds: [],
        participantNames: {},
        participantPhotos: {},
        lastMessage: '👋 Welcome to $agencyName team channel! Post updates, drop assets, or ask questions here.',
        lastSenderName: managerName.isNotEmpty ? managerName : 'Agency Director',
        lastMessageTime: now,
      );
      batch.set(convoDocRef, generalConvo.toMap(), SetOptions(merge: true));

      // Post pristine welcome message from the owner's account
      final welcomeMsg = ChatMessage(
        id: 'msg_welcome_${now.millisecondsSinceEpoch}',
        conversationId: 'agency_general',
        agencyId: agencyId,
        senderId: managerId,
        senderName: managerName.isNotEmpty ? managerName : 'Agency Director',
        senderPhotoUrl: managerPhotoUrl,
        senderRole: 'manager',
        text: '👋 Welcome to $agencyName! All project notifications, urgent cuts, and asset drive links will be shared here. Feel free to discuss ideas or ask any questions.',
        createdAt: now,
      );
      final msgDocRef = _messagesRef(agencyId, 'agency_general').doc(welcomeMsg.id);
      batch.set(msgDocRef, welcomeMsg.toMap());

      await batch.commit();
    } catch (_) {}
  }

  /// Rate an editor, calculate cumulative rating, and send in-app notification
  Future<void> rateEditor({
    required String agencyId,
    required String editorId,
    required double rating,
    String? projectId,
    String? feedback,
    required String managerName,
  }) async {
    try {
      final docRef = _usersRef.doc(editorId);
      final doc = await docRef.get();
      double currentTotal = 0.0;
      int currentCount = 0;
      int currentCompleted = 0;

      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        final rawRating = (d['rating'] as num?)?.toDouble();
        final rawCount = (d['ratingCount'] as num?)?.toInt();
        final rawTotal = (d['totalStars'] as num?)?.toDouble();
        currentCompleted = (d['completedProjects'] as num?)?.toInt() ?? 0;

        if (rawTotal != null && rawCount != null && rawCount > 0) {
          currentTotal = rawTotal;
          currentCount = rawCount;
        } else if (rawRating != null) {
          currentTotal = rawRating;
          currentCount = 1;
        }
      }

      final newCount = currentCount + 1;
      final newTotal = currentTotal + rating;
      final newRating = double.parse((newTotal / newCount).toStringAsFixed(1));
      final newCompleted = projectId != null ? (currentCompleted + 1) : currentCompleted;

      await docRef.set({
        'rating': newRating,
        'ratingCount': newCount,
        'totalStars': newTotal,
        'completedProjects': newCompleted,
        'lastRatedAt': FieldValue.serverTimestamp(),
        if (feedback != null && feedback.isNotEmpty) 'latestFeedback': feedback,
      }, SetOptions(merge: true));

      // Dispatch real-time notification to the editor
      await sendNotification(
        agencyId: agencyId,
        notification: AppNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          agencyId: agencyId,
          userId: editorId,
          title: '⭐ New Rating Received (${rating.toStringAsFixed(1)} Stars)',
          body: feedback != null && feedback.isNotEmpty
              ? '$managerName rated your work: "$feedback"'
              : '$managerName gave you a ${rating.toStringAsFixed(1)}-star rating! Keep up the great work.',
          type: NotificationType.ratingReceived,
          relatedId: projectId,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {}
  }

  // ── In-App Real-Time Notification Center ───────────────────────────────

  CollectionReference<Map<String, dynamic>> _notificationsRef(String agencyId) =>
      _agenciesRef.doc(agencyId).collection('notifications');

  /// Real-time stream of notifications for an agency, filtered for broadcast or specific user
  Stream<List<AppNotification>> streamNotifications({required String agencyId, String? userId}) {
    return _notificationsRef(agencyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
          .where((n) => n.userId == null || n.userId == userId)
          .toList();
    });
  }

  /// Dispatch an in-app notification
  Future<void> sendNotification({
    required String agencyId,
    required AppNotification notification,
  }) async {
    try {
      await _notificationsRef(agencyId).doc(notification.id).set(notification.toMap());
    } catch (_) {}
  }

  /// Mark a single notification as read
  Future<void> markNotificationAsRead(String agencyId, String notificationId) async {
    try {
      await _notificationsRef(agencyId).doc(notificationId).update({'isRead': true});
    } catch (_) {}
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String agencyId, String? userId) async {
    try {
      final snap = await _notificationsRef(agencyId).where('isRead', isEqualTo: false).get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        final dUserId = doc.data()['userId'] as String?;
        if (dUserId == null || dUserId == userId) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (_) {}
  }
}
