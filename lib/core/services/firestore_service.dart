import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      _db.collection('projects');

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  /// Real-time stream of all projects
  Stream<List<ProjectItem>> streamProjects() {
    return _projectsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProjectItem.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Real-time stream of all registered editors for Manager assignment
  Stream<List<Map<String, dynamic>>> streamEditors() {
    return _usersRef.where('role', isEqualTo: 'editor').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Automatically seeds initial projects if the Firestore collection is empty
  Future<void> seedInitialProjectsIfEmpty() async {
    try {
      final snapshot = await _projectsRef.limit(1).get();
      if (snapshot.docs.isEmpty) {
        final batch = _db.batch();
        for (final project in kInitialProjectsData) {
          final docRef = _projectsRef.doc(project.id);
          batch.set(docRef, project.toMap());
        }
        await batch.commit();
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
  }) async {
    await _usersRef.doc(uid).set({
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
    }, SetOptions(merge: true));
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
}
