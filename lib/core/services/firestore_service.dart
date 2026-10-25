import '../../features/payments/domain/payout.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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

  /// Generate a memorable, human-friendly agency join key (e.g. STUD-7K4M2Q)
  static String generateJoinKey(String agencyName) {
    final clean = agencyName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final prefix = clean.length >= 4 ? clean.substring(0, 4) : clean.padRight(4, 'X');
    // Unambiguous alphabet (no 0/O, 1/I) and a secure RNG so keys can't be guessed.
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final suffix = List.generate(6, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
    return '$prefix-$suffix';
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

    final batch = _db.batch();
    batch.set(_agenciesRef.doc(agencyId), agency.toMap());
    batch.set(_joinKeysRef.doc(joinKey), _joinKeyData(agencyId, agency.name));
    await batch.commit();
    return agency;
  }

  /// joinKeys/{KEY} -> {agencyId, agencyName}. Editors resolve a key with a
  /// single get (no listing), so agency docs stay private to their members.
  CollectionReference<Map<String, dynamic>> get _joinKeysRef => _db.collection('joinKeys');

  Map<String, dynamic> _joinKeyData(String agencyId, String agencyName) => {
        'agencyId': agencyId,
        'agencyName': agencyName,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Agencies created before joinKeys/ existed have no lookup doc; the
  /// manager's app creates it. Best effort, errors ignored.
  Future<void> ensureJoinKeyIndex(String agencyId, String joinKey, String agencyName) async {
    if (joinKey.isEmpty) return;
    try {
      final doc = await _joinKeysRef.doc(joinKey).get();
      if (!doc.exists) await _joinKeysRef.doc(joinKey).set(_joinKeyData(agencyId, agencyName));
    } catch (_) {}
  }

  /// Rename the agency (manager only).
  Future<void> renameAgency(String agencyId, String oldKey, String name) async {
    final batch = _db.batch();
    batch.update(_agenciesRef.doc(agencyId), {'name': name});
    if (oldKey.isNotEmpty) batch.set(_joinKeysRef.doc(oldKey), {'agencyName': name}, SetOptions(merge: true));
    await batch.commit();
  }

  /// Resolve a join key to its agency via joinKeys/{KEY}.
  Future<AgencyModel?> validateAndGetAgencyByKey(String joinKey) async {
    final cleanKey = joinKey.trim().toUpperCase();
    if (cleanKey.isEmpty || cleanKey.contains('/')) return null;

    try {
      final doc = await _joinKeysRef.doc(cleanKey).get();
      final data = doc.data();
      if (doc.exists && data != null && (data['agencyId'] as String? ?? '').isNotEmpty) {
        return AgencyModel(
          id: data['agencyId'] as String,
          name: data['agencyName'] as String? ?? 'Agency',
          managerUid: '',
          managerName: '',
          joinKey: cleanKey,
          createdAt: DateTime.now(),
        );
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

  /// Regenerate a join key for an existing agency
  /// The old key stops working at once: the rules only accept the key
  /// currently on the agency doc.
  Future<String> regenerateAgencyKey(String agencyId, String agencyName, {String? oldKey}) async {
    final newKey = generateJoinKey(agencyName);
    final batch = _db.batch();
    batch.update(_agenciesRef.doc(agencyId), {
      'joinKey': newKey,
      'keyUpdatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_joinKeysRef.doc(newKey), _joinKeyData(agencyId, agencyName));
    if (oldKey != null && oldKey.isNotEmpty && oldKey != newKey) batch.delete(_joinKeysRef.doc(oldKey));
    await batch.commit();
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

  /// Normalises a user document for display. Missing names fall back to the
  /// email prefix; stats start at zero until real ratings exist.
  Map<String, dynamic> _memberFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data());
    data['uid'] = doc.id;
    data['id'] = data['id'] ?? doc.id;
    final email = (data['email'] as String? ?? '').trim();
    final name = (data['name'] as String? ?? '').trim();
    if (name.isEmpty) data['name'] = email.isNotEmpty ? email.split('@').first : 'Unnamed member';
    data['rating'] = (data['rating'] as num?)?.toDouble() ?? 0.0;
    data['ratingCount'] = (data['ratingCount'] as num?)?.toInt() ?? 0;
    data['completedProjects'] = (data['completedProjects'] as num?)?.toInt() ?? 0;
    return data;
  }

  /// Live copy of one user's own doc (rating, availability…).
  Stream<Map<String, dynamic>> streamUserDoc(String uid) =>
      _usersRef.doc(uid).snapshots().map((d) => d.data() ?? const {});

  /// Real-time stream of the editors in [agencyId], ranked by rating then
  /// completed projects. Without an agency there is nobody to show.
  Stream<List<Map<String, dynamic>>> streamEditors({String? agencyId}) {
    if (agencyId == null || agencyId.isEmpty) return Stream.value(const []);
    return _usersRef
        .where('agencyId', isEqualTo: agencyId)
        .where('role', isEqualTo: 'editor')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(_memberFromDoc).toList();
      list.sort((a, b) {
        final cmp = (b['rating'] as double).compareTo(a['rating'] as double);
        if (cmp != 0) return cmp;
        return (b['completedProjects'] as int).compareTo(a['completedProjects'] as int);
      });
      return list;
    });
  }

  /// Real-time stream of everyone (managers and editors) in [agencyId].
  Stream<List<Map<String, dynamic>>> streamAgencyTeamMembers({String? agencyId}) {
    if (agencyId == null || agencyId.isEmpty) return Stream.value(const []);
    return _usersRef
        .where('agencyId', isEqualTo: agencyId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_memberFromDoc).toList());
  }

  /// Create a new project in Firestore
  /// Two writes, not one batch: the project lands even when the finance
  /// write is refused (e.g. server rules without `private/finance`).
  /// Throws if the project write fails; returns false if only the price failed.
  Future<bool> createProject(ProjectItem item, {double? clientPrice, String? updatedBy}) =>
      createProjectWrites(
        writeProject: () => _projectsRef.doc(item.id).set(item.toMap()),
        writeFinance: clientPrice != null && clientPrice > 0
            ? () => _financeRef(item.id).set(_financeData(clientPrice, updatedBy))
            : null,
      );

  /// Soft delete: managers only (enforced by rules). Never removes data.
  Future<void> setProjectArchived(String projectId, bool archived) =>
      _projectsRef.doc(projectId).update({'archived': archived, 'archivedAt': FieldValue.serverTimestamp()});

  /// Delete a project (and its manager-only finance doc) from Cloud Firestore
  Future<void> deleteProject(String projectId) async {
    final batch = _db.batch();
    batch.delete(_financeRef(projectId));
    batch.delete(_projectsRef.doc(projectId));
    await batch.commit();
  }

  // ── Manager-only finance (projects/{id}/private/finance) ──────────────

  DocumentReference<Map<String, dynamic>> _financeRef(String projectId) =>
      _projectsRef.doc(projectId).collection('private').doc('finance');

  Map<String, dynamic> _financeData(double clientPrice, String? updatedBy) => {
        'clientPrice': clientPrice,
        'currency': 'BDT',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
      };

  /// Live client price for one project. Emits null when the doc is missing.
  Stream<ProjectFinance?> streamProjectFinance(String projectId) => _financeRef(projectId)
      .snapshots()
      .map((d) => d.exists && d.data() != null ? ProjectFinance.fromMap(d.data()!) : null);

  /// Saves the client price. Also drops a legacy `clientBudget` field from
  /// the editor-readable project doc, if one is still there.
  Future<void> setProjectFinance(String projectId, double clientPrice, {String? updatedBy, bool dropLegacy = false}) async {
    final batch = _db.batch();
    batch.set(_financeRef(projectId), _financeData(clientPrice, updatedBy));
    if (dropLegacy) batch.update(_projectsRef.doc(projectId), {'clientBudget': FieldValue.delete()});
    await batch.commit();
  }

  /// Update an open project's variables
  Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    await _projectsRef.doc(projectId).update(data);
  }

  /// Claim a project offer
  /// Claims in a transaction; throws [AlreadyTakenException] when another
  /// editor got there first (or the offer is no longer open).
  Future<void> claimProject(String projectId, String editorId, String editorName) async {
    final ref = _projectsRef.doc(projectId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final d = snap.data();
      final holder = d?['claimedByEditorId'] as String?;
      if (d == null || d['status'] != ProjectStatus.open.name || (holder != null && holder.isNotEmpty)) {
        throw const AlreadyTakenException();
      }
      tx.update(ref, {
        'claimedByEditorId': editorId,
        'claimedByEditorName': editorName,
        'claimedAt': DateTime.now().toIso8601String(),
        'status': ProjectStatus.claimed.name,
      });
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
      'deadlineAt': DateTime.now().add(Duration(hours: newHoursLeft)).toIso8601String(),
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
      'deadlineAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      'deadlineStr': 'Urgent • 24 Hours Left',
      'submissionLink': null,
      'submissionNote': null,
      'submittedAt': null,
      'isOverdue': false,
    });
  }

  /// Submit deliverable link and notes
  Future<void> submitWork(String projectId, String link, String note, String submittedAt,
      {required int version, bool late = false}) async {
    await _projectsRef.doc(projectId).update({
      'status': ProjectStatus.submitted.name,
      'submissionLink': link,
      'submissionNote': note,
      'submittedAt': submittedAt,
      'submissionVersion': version,
      'submittedLate': late,
    });
  }

  /// Approve project deliverable
  Future<void> approveProject(String projectId) async {
    await _projectsRef.doc(projectId).update({
      'status': ProjectStatus.approved.name,
      'approvedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Request revision from editor
  Future<void> requestRevision(String projectId, String feedback) async {
    await _projectsRef.doc(projectId).update({
      'status': ProjectStatus.claimed.name,
      'submissionNote': 'Revision Request: $feedback',
      'revisionNotes': feedback,
      'revisionChecks': <int>[],
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
    String? photoUrl,
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
    if (photoUrl != null && photoUrl.trim().isNotEmpty) data['photoUrl'] = photoUrl.trim();

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

  /// The caller's profile, or null only when the doc truly does not exist.
  /// Read, permission and timeout errors are thrown so callers never mistake
  /// a failed read for "no profile / no agency".
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get().timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw Exception('Firestore timeout'),
    );
    return doc.exists ? doc.data() : null;
  }

  // ── Messenger & Conversations ──────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _conversationsRef(String agencyId) =>
      _agenciesRef.doc(agencyId).collection('conversations');

  CollectionReference<Map<String, dynamic>> _messagesRef(String agencyId, String conversationId) =>
      _agenciesRef.doc(agencyId).collection('conversations').doc(conversationId).collection('messages');

  /// Real-time stream of the conversations [userId] can see in [agencyId]:
  /// the agency channels plus the direct messages they take part in.
  /// Sorted on the client so no composite index is needed.
  Stream<List<ChatConversation>> streamAgencyConversations(String agencyId, String userId) {
    final channels = _conversationsRef(agencyId).where('type', isEqualTo: 'channel');
    final directs = _conversationsRef(agencyId).where('participantIds', arrayContains: userId);

    late final StreamController<List<ChatConversation>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subA;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subB;
    List<ChatConversation>? latestA;
    List<ChatConversation>? latestB;

    List<ChatConversation> toList(QuerySnapshot<Map<String, dynamic>> s) =>
        s.docs.map((doc) => ChatConversation.fromMap(doc.id, doc.data())).toList();

    void emit() {
      final a = latestA;
      final b = latestB;
      if (a == null || b == null) return;
      final byId = <String, ChatConversation>{for (final c in [...a, ...b]) c.id: c};
      final merged = byId.values.toList()
        ..sort((x, y) => y.lastMessageTime.compareTo(x.lastMessageTime));
      controller.add(merged);
    }

    controller = StreamController<List<ChatConversation>>(
      onListen: () {
        subA = channels.snapshots().listen((s) {
          latestA = toList(s);
          emit();
        }, onError: controller.addError);
        subB = directs.snapshots().listen((s) {
          latestB = toList(s);
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return controller.stream;
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

  /// Send a message, update conversation metadata, and dispatch in-app notification to the recipient
  Future<void> sendChatMessage({
    required String agencyId,
    required String conversationId,
    required ChatMessage message,
    String? recipientId,
  }) async {
    final batch = _db.batch();
    final msgDocRef = _messagesRef(agencyId, conversationId).doc(message.id);
    batch.set(msgDocRef, message.toMap());

    final convoDocRef = _conversationsRef(agencyId).doc(conversationId);
    final isDirect = conversationId.startsWith('dm_');
    batch.set(convoDocRef, {
      'agencyId': agencyId,
      'type': isDirect ? 'direct' : 'channel',
      if (!isDirect) 'title': '# agency-room',
      'lastMessage': message.text,
      'lastSenderName': message.senderName,
      'lastMessageTime': Timestamp.fromDate(message.createdAt),
      'lastSenderId': message.senderId,
      'readBy': [message.senderId],
    }, SetOptions(merge: true));

    await batch.commit();

    // In-app notification: DM -> the other participant; an editor's post in
    // the agency room -> the manager. The rules decide who may notify whom,
    // so no client-side role gate (a failed manager lookup used to drop it).
    String? to = recipientId;
    if ((to == null || to.isEmpty) && isDirect) {
      to = conversationId
          .replaceFirst('dm_', '')
          .split('_')
          .where((p) => p.isNotEmpty && p != message.senderId)
          .firstOrNull;
    }
    if ((to == null || to.isEmpty) && !isDirect && message.senderRole != 'manager') {
      to = await managerUidOf(agencyId);
    }
    if (to != null && to.isNotEmpty) {
      await notifyUser(
        to,
        AppNotification.draft(
          type: NotificationType.message,
          title: 'Message from ${message.senderName}',
          body: message.text.isNotEmpty ? message.text : 'Sent an attachment',
          fromUid: message.senderId,
          chatId: conversationId,
        ),
      );
    }
  }

  /// Mark a conversation as read by a specific user
  Future<void> markConversationAsRead(String agencyId, String conversationId, String userId) async {
    try {
      await _conversationsRef(agencyId).doc(conversationId).set({
        'readBy': FieldValue.arrayUnion([userId]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Rate an editor directly, update their rating instance in database, and send in-app notification
  Future<void> rateEditor({
    required String agencyId,
    required String editorId,
    required double rating,
    String? projectId,
    String? feedback,
    required String managerName,
  }) async {
    try {
      DocumentReference<Map<String, dynamic>> docRef = _usersRef.doc(editorId);
      var doc = await docRef.get();
      if (!doc.exists) {
        final q = await _usersRef.where('id', isEqualTo: editorId).limit(1).get();
        if (q.docs.isNotEmpty) {
          docRef = q.docs.first.reference;
          doc = q.docs.first;
        }
      }

      int currentCount = 0;
      int currentCompleted = 0;

      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        final rawCount = (d['ratingCount'] as num?)?.toInt();
        currentCompleted = (d['completedProjects'] as num?)?.toInt() ?? 0;
        if (rawCount != null && rawCount > 0) {
          currentCount = rawCount;
        }
      }

      // Instance rating: Manager's rating directly updates the profile rating in database
      final newRating = double.parse(rating.toStringAsFixed(1));
      final newCount = currentCount + 1;
      final newCompleted = projectId != null ? (currentCompleted + 1) : currentCompleted;

      await docRef.set({
        'rating': newRating,
        'ratingCount': newCount,
        'totalStars': newRating,
        'completedProjects': newCompleted,
        'lastRatedAt': FieldValue.serverTimestamp(),
        if (feedback != null && feedback.isNotEmpty) 'latestFeedback': feedback,
      }, SetOptions(merge: true));

    } catch (_) {}
  }

  // ── In-app notifications: users/{uid}/notifications ─────────────────
  // Written by the sender's client (Spark plan, no Cloud Functions).

  CollectionReference<Map<String, dynamic>> _inbox(String uid) =>
      _usersRef.doc(uid).collection('notifications');

  final Map<String, String> _managerUids = {};

  /// The agency's manager uid (cached), or null.
  CollectionReference<Map<String, dynamic>> _payouts(String agencyId) => _agenciesRef.doc(agencyId).collection('payouts');

  /// Writes one test-mode receipt per project (doc id = project id).
  Future<void> recordPayouts(String agencyId, List<PayoutRecord> records, String paidBy) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final r in records) {
      batch.set(_payouts(agencyId).doc(r.projectId), r.draft(paidBy));
    }
    await batch.commit();
  }

  /// All agency receipts (manager) or only [editorId]'s (editor).
  Stream<List<PayoutRecord>> streamPayouts(String agencyId, {String? editorId}) {
    Query<Map<String, dynamic>> q = _payouts(agencyId);
    if (editorId != null) q = q.where('editorId', isEqualTo: editorId);
    return q.snapshots().map((s) => [for (final d in s.docs) PayoutRecord.fromMap(d.id, d.data())]);
  }

  Future<String?> managerUidOf(String agencyId) async {
    final hit = _managerUids[agencyId];
    if (hit != null) return hit;
    try {
      final d = await _agenciesRef.doc(agencyId).get();
      final uid = d.data()?['managerUid'] as String?;
      if (uid != null && uid.isNotEmpty) _managerUids[agencyId] = uid;
      return uid;
    } catch (_) {
      return null;
    }
  }

  /// Best effort: a failed notification never fails the action behind it.
  Future<void> notifyUser(String toUid, Map<String, dynamic> draft) async {
    if (toUid.isEmpty || toUid == draft['fromUid']) return;
    try {
      await _inbox(toUid).add(draft);
    } catch (e) {
      debugPrint('notifyUser(${draft['type']} -> $toUid) failed: $e');
    }
  }

  /// A log entry in my own inbox (e.g. the manager's payout receipt).
  Future<void> logToSelf(String uid, Map<String, dynamic> draft) async {
    if (uid.isEmpty || uid != draft['fromUid']) return;
    try {
      await _inbox(uid).add(draft);
    } catch (e) {
      debugPrint('logToSelf(${draft['type']}) failed: $e');
    }
  }

  Stream<List<AppNotification>> streamMyNotifications(String uid) => _inbox(uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => [for (final d in s.docs) AppNotification.fromMap(d.id, d.data())]);

  Future<void> markNotificationRead(String uid, String id) async {
    try {
      await _inbox(uid).doc(id).update({'read': true});
    } catch (_) {}
  }

  /// Deletes the user's own notices, 400 per batch.
  Future<void> deleteNotifications(String uid, List<String> ids) async {
    try {
      for (var i = 0; i < ids.length; i += 400) {
        final b = _db.batch();
        for (final id in ids.skip(i).take(400)) {
          b.delete(_inbox(uid).doc(id));
        }
        await b.commit();
      }
    } catch (e) {
      debugPrint('deleteNotifications failed: $e');
    }
  }

  /// Retention without Cloud Functions: deletes read notices older than
  /// [before]. Single-field range (no composite index); read filtered here.
  Future<int> purgeReadNotificationsBefore(String uid, DateTime before) async {
    final snap = await _inbox(uid)
        .where('createdAt', isLessThan: Timestamp.fromDate(before))
        .limit(400)
        .get();
    final ids = [for (final d in snap.docs) if (d.data()['read'] == true) d.id];
    await deleteNotifications(uid, ids);
    return ids.length;
  }

  Future<void> markNotificationsRead(String uid, List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final b = _db.batch();
      for (final id in ids) {
        b.update(_inbox(uid).doc(id), {'read': true});
      }
      await b.commit();
    } catch (_) {}
  }
}

/// The offer was claimed by someone else (or closed) before this claim.
class AlreadyTakenException implements Exception {
  const AlreadyTakenException();
  @override
  String toString() => 'Already taken';
}

/// Project first, then the optional price. Throws on project failure;
/// returns false when only the price write failed.
Future<bool> createProjectWrites({
  required Future<void> Function() writeProject,
  Future<void> Function()? writeFinance,
}) async {
  await writeProject();
  if (writeFinance == null) return true;
  try {
    await writeFinance();
    return true;
  } catch (e) {
    debugPrint('createProject: finance write failed: $e');
    return false;
  }
}
