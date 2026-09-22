import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/domain/auth_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class ProjectsNotifier extends StateNotifier<List<ProjectItem>> {
  final FirestoreService _firestoreService;
  final String? _agencyId;
  StreamSubscription<List<ProjectItem>>? _subscription;

  ProjectsNotifier(this._firestoreService, [this._agencyId])
      : super(_agencyId == 'agency_demo_wara' || _agencyId == null
            ? kInitialProjectsData
            : []) {
    _init();
  }

  void _init() {
    // Reset old posts and populate 6 fresh unassigned projects in Cloud Firestore
    if (_agencyId == 'agency_demo_wara' || _agencyId == null) {
      _firestoreService.resetAndSeedFreshProjects();
    }

    // Listen to real-time updates from Cloud Firestore scoped by agencyId
    _subscription = _firestoreService.streamProjects(agencyId: _agencyId).listen(
      (projects) {
        if (projects.isNotEmpty) {
          state = projects;
        } else if (_agencyId != 'agency_demo_wara' && _agencyId != null) {
          state = [];
        }
      },
      onError: (err) {
        // Fallback to local state if offline or permission error
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void createNewProject({
    required String title,
    required String clientName,
    required double clientBudget,
    required double editorPayout,
    required int deadlineDays,
    required String description,
    required List<String> skills,
  }) {
    final newId = 'p_${DateTime.now().millisecondsSinceEpoch}';
    final deadlineHours = deadlineDays * 24;
    final newItem = ProjectItem(
      id: newId,
      agencyId: _agencyId,
      title: title,
      clientName: clientName,
      clientBudget: clientBudget,
      editorPayout: editorPayout,
      deadlineStr: '$deadlineDays Days Left ($deadlineHours Hours)',
      deadlineHoursLeft: deadlineHours,
      description: description,
      requiredSkills: skills.isEmpty ? ['Video Editing'] : skills,
      status: ProjectStatus.open,
    );

    // Optimistic local update
    state = [newItem, ...state];

    // Cloud Firestore write
    _firestoreService.createProject(newItem);
  }

  void deleteProject(String projectId) {
    // Optimistic local removal
    state = state.where((p) => p.id != projectId).toList();

    // Cloud Firestore deletion
    _firestoreService.deleteProject(projectId);
  }

  bool updateOpenProject({
    required String projectId,
    required String title,
    required double editorPayout,
    required int deadlineDays,
    required String description,
  }) {
    final target = state.firstWhere((p) => p.id == projectId);
    if (target.status != ProjectStatus.open) {
      return false;
    }

    final deadlineHours = deadlineDays * 24;
    final newDeadlineStr = '$deadlineDays Days Left ($deadlineHours Hours)';

    // Optimistic update
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            editorPayout: editorPayout,
            deadlineStr: newDeadlineStr,
            deadlineHoursLeft: deadlineHours,
          )
        else
          item
    ];

    // Cloud Firestore write
    _firestoreService.updateProject(projectId, {
      'title': title,
      'editorPayout': editorPayout,
      'deadlineHoursLeft': deadlineHours,
      'deadlineStr': newDeadlineStr,
      'description': description,
    });
    return true;
  }

  void claimProject(String projectId, String editorId, String editorName) {
    final now = DateTime.now();

    // Optimistic update
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            claimedByEditorId: editorId,
            claimedByEditorName: editorName,
            claimedAt: now,
            status: ProjectStatus.claimed,
          )
        else
          item
    ];

    // Cloud Firestore write
    _firestoreService.claimProject(projectId, editorId, editorName);
  }

  bool returnProject(String projectId) {
    final target = state.firstWhere((p) => p.id == projectId);
    if (!target.canReturn) {
      return false;
    }

    final newHoursLeft = (target.deadlineHoursLeft - 24).clamp(0, 9999);
    final daysLeft = (newHoursLeft / 24).ceil();
    final newDeadlineStr = newHoursLeft <= 0
        ? 'OVERDUE (0 Hours Left)'
        : '$daysLeft Days Left ($newHoursLeft Hours)';

    // Optimistic update
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            claimedByEditorId: null,
            claimedByEditorName: null,
            claimedAt: null,
            status: ProjectStatus.open,
            deadlineHoursLeft: newHoursLeft,
            deadlineStr: newDeadlineStr,
            submissionLink: null,
            submissionNote: null,
            submittedAt: null,
            isOverdue: false,
          )
        else
          item
    ];

    // Cloud Firestore write
    _firestoreService.returnProject(projectId, newHoursLeft, newDeadlineStr);
    return true;
  }

  void relistOverdueProject(String projectId, {double? increasedPayout}) {
    final target = state.firstWhere((p) => p.id == projectId);
    final newPayout = increasedPayout ?? target.editorPayout;

    // Optimistic update
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            claimedByEditorId: null,
            claimedByEditorName: null,
            claimedAt: null,
            status: ProjectStatus.open,
            editorPayout: newPayout,
            deadlineHoursLeft: 24,
            deadlineStr: 'Urgent • 24 Hours Left',
            submissionLink: null,
            submissionNote: null,
            submittedAt: null,
            isOverdue: false,
          )
        else
          item
    ];

    // Cloud Firestore write
    _firestoreService.relistOverdueProject(projectId, newPayout);
  }

  void submitWork(String projectId, String submissionLink, String submissionNote) {
    final nowStr = 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    // Optimistic update
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            status: ProjectStatus.submitted,
            submissionLink: submissionLink,
            submissionNote: submissionNote,
            submittedAt: nowStr,
          )
        else
          item
    ];

    // Cloud Firestore write
    _firestoreService.submitWork(projectId, submissionLink, submissionNote, nowStr);
  }

  void approveProject(String projectId) {
    // Optimistic update
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(status: ProjectStatus.approved)
        else
          item
    ];

    // Cloud Firestore write
    _firestoreService.approveProject(projectId);
  }

  void requestRevision(String projectId, String feedback) {
    // Optimistic update
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            status: ProjectStatus.claimed,
            submissionNote: 'Revision Request: $feedback',
          )
        else
          item
    ];

    // Cloud Firestore write
    _firestoreService.requestRevision(projectId, feedback);
  }

  void assignProject(String projectId, String editorId, String editorName) {
    final now = DateTime.now();

    // Optimistic update
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            claimedByEditorId: editorId,
            claimedByEditorName: editorName,
            claimedAt: now,
            status: ProjectStatus.claimed,
          )
        else
          item
    ];

    // Cloud Firestore write
    _firestoreService.assignProject(projectId, editorId, editorName);
  }
}

final projectsProvider = StateNotifierProvider<ProjectsNotifier, List<ProjectItem>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final agencyId = ref.watch(authProvider.select((s) => s.user?.agencyId));
  return ProjectsNotifier(firestoreService, agencyId);
});
