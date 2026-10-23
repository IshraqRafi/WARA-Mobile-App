import '../../notifications/domain/notification_models.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firestore_service.dart';
import '../../payments/domain/payout.dart';
import '../../auth/domain/auth_provider.dart';
import '../../../shared/motion/haptics.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Agency editors, one shared Firestore listener per agency. Widgets watch
/// this instead of calling `streamEditors` in build (which re-subscribed on
/// every rebuild).
final editorsProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String?>(
  (ref, agencyId) => ref.watch(firestoreServiceProvider).streamEditors(agencyId: agencyId),
);

/// The signed-in user's own doc, live. Empty when signed out.
final myProfileProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) return Stream.value(const {});
  return ref.watch(firestoreServiceProvider).streamUserDoc(uid);
});

/// All agency members (managers + editors), shared like [editorsProvider].
final teamMembersProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String?>(
  (ref, agencyId) => ref.watch(firestoreServiceProvider).streamAgencyTeamMembers(agencyId: agencyId),
);

/// Adapts an [AsyncValue] to the [AsyncSnapshot] shape StreamBuilder used.
AsyncSnapshot<T> asSnapshot<T>(AsyncValue<T> v) {
  if (v.hasValue) return AsyncSnapshot<T>.withData(ConnectionState.active, v.requireValue);
  if (v.hasError) return AsyncSnapshot<T>.withError(ConnectionState.active, v.error!, v.stackTrace ?? StackTrace.empty);
  return AsyncSnapshot<T>.waiting();
}

/// Last load error from the projects stream (null when healthy).
final projectsErrorProvider = StateProvider<Object?>((ref) => null);

/// True once the projects stream has delivered its first snapshot
/// (drives the skeleton loaders).
final projectsLoadedProvider = StateProvider<bool>((ref) => false);

/// Marketplace offers the editor swiped away this session (local only).
final hiddenOffersProvider = StateProvider<Set<String>>((ref) => const {});

/// Id of the expanded card per list (one open card per list).
final expandedCardProvider = StateProvider.family<String?, String>((ref, listId) => null);

class ProjectsNotifier extends StateNotifier<List<ProjectItem>> {
  final FirestoreService _firestoreService;
  final String? _agencyId;
  final void Function(Object? error)? _onError;
  final VoidCallback? _onLoaded;
  StreamSubscription<List<ProjectItem>>? _subscription;

  /// Signed-in user, used as the sender of in-app notifications.
  final ({String id, String name})? actor;

  ProjectsNotifier(this._firestoreService, [this._agencyId, this._onError, this._onLoaded, this.actor])
      : super(const []) {
    _subscribe();
  }

  ProjectItem? _byId(String id) => state.where((p) => p.id == id).firstOrNull;

  /// Notify the project's editor (manager actions).
  void _notifyEditor(ProjectItem? p, NotificationType type, String title, [String body = '']) {
    final a = actor;
    final to = p?.claimedByEditorId;
    if (a == null || p == null || to == null) return;
    _firestoreService.notifyUser(
        to, AppNotification.draft(type: type, title: title, body: body, fromUid: a.id, projectId: p.id));
  }

  /// Re-open the projects stream (used by the Retry button).
  void retry() {
    _onError?.call(null);
    _subscribe();
  }

  Completer<void>? _refresh;

  /// Pull-to-refresh: re-subscribes and completes when the fresh snapshot
  /// (or an error) arrives, or after 8s at most.
  Future<void> refresh() {
    _refresh?.complete();
    final c = _refresh = Completer<void>();
    _subscribe();
    if ((_agencyId ?? '').isEmpty) _completeRefresh();
    return c.future.timeout(const Duration(seconds: 8), onTimeout: () {});
  }

  void _completeRefresh() {
    final c = _refresh;
    _refresh = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  void _subscribe() {
    _subscription?.cancel();
    final agencyId = _agencyId;
    // No agency yet (editor still onboarding): nothing to load.
    if (agencyId == null || agencyId.isEmpty) {
      state = const [];
      return;
    }
    // Listen to real-time updates from Cloud Firestore scoped by agencyId
    _subscription = _firestoreService.streamProjects(agencyId: agencyId).listen(
      (projects) {
        _onError?.call(null);
        _onLoaded?.call();
        state = projects;
        _completeRefresh();
      },
      onError: (Object err) {
        // Keep the local state, but surface the failure to the UI.
        debugPrint('Projects stream error: $err');
        _onError?.call(err);
        _completeRefresh();
      },
    );
  }

  @override
  void dispose() {
    _completeRefresh();
    _subscription?.cancel();
    super.dispose();
  }

  /// Returns null on success, else a short user-facing error.
  Future<String?> createNewProject({
    required String title,
    required String clientName,
    double? clientPrice,
    String? createdBy,
    required double editorPayout,
    required int deadlineDays,
    required String description,
    required List<String> skills,
  }) async {
    final newId = 'p_${DateTime.now().millisecondsSinceEpoch}';
    final deadlineHours = deadlineDays * 24;
    final newItem = ProjectItem(
      id: newId,
      agencyId: _agencyId,
      title: title,
      clientName: clientName,
      editorPayout: editorPayout,
      deadlineStr: '$deadlineDays Days Left ($deadlineHours Hours)',
      deadlineHoursLeft: deadlineHours,
      deadlineAt: DateTime.now().add(Duration(hours: deadlineHours)),
      postedAt: DateTime.now(),
      description: description,
      requiredSkills: skills.isEmpty ? ['Video Editing'] : skills,
      status: ProjectStatus.open,
    );

    // Optimistic local update
    state = [newItem, ...state];

    try {
      final priced = await _firestoreService.createProject(newItem, clientPrice: clientPrice, updatedBy: createdBy);
      return priced ? null : 'Client price not saved';
    } catch (e) {
      debugPrint('createProject failed: $e');
      // Roll back so the list never shows a ghost that vanishes later.
      if (mounted) state = state.where((p) => p.id != newId).toList();
      return 'Couldn\'t publish project';
    }
  }

  Future<bool> setArchived(String projectId, bool archived) async {
    final before = state;
    state = [for (final p in state) p.id == projectId ? p.copyWith(archived: archived) : p];
    try {
      await _firestoreService.setProjectArchived(projectId, archived);
      return true;
    } catch (e) {
      debugPrint('archive failed: $e');
      if (mounted) state = before;
      return false;
    }
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
    double? clientPrice,
    String? updatedBy,
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
            deadlineAt: DateTime.now().add(Duration(hours: deadlineHours)),
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
      'deadlineAt': DateTime.now().add(Duration(hours: deadlineHours)).toIso8601String(),
      'description': description,
    });
    if (clientPrice != null && clientPrice > 0) {
      _firestoreService.setProjectFinance(projectId, clientPrice,
          updatedBy: updatedBy, dropLegacy: target.legacyClientBudget != null);
    }
    return true;
  }

  /// Claims an open project. The local state updates optimistically; the
  /// returned future completes when Firestore accepts the write, and on
  /// failure the local change is rolled back and the error rethrown.
  Future<void> claimProject(String projectId, String editorId, String editorName) async {
    Haptics.statusChange(ProjectStatus.claimed);
    final now = DateTime.now();
    final previous = state.where((p) => p.id == projectId).firstOrNull;

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
    try {
      await _firestoreService.claimProject(projectId, editorId, editorName);
    } on AlreadyTakenException {
      // Lost the race: the stream will bring the winner's state; drop ours.
      state = [for (final item in state) if (item.id != projectId) item];
      rethrow;
    } catch (_) {
      if (previous != null) {
        state = [for (final item in state) if (item.id == projectId) previous else item];
      }
      rethrow;
    }
  }

  bool returnProject(String projectId) {
    final target = state.firstWhere((p) => p.id == projectId);
    if (!target.canReturn) {
      return false;
    }
    Haptics.statusChange(ProjectStatus.open);

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
            deadlineAt: DateTime.now().add(Duration(hours: newHoursLeft)),
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
    Haptics.statusChange(ProjectStatus.open);
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
            deadlineAt: DateTime.now().add(const Duration(hours: 24)),
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
    Haptics.statusChange(ProjectStatus.submitted);
    final nowStr = 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    final current = state.where((p) => p.id == projectId).firstOrNull;
    final version = (current?.submissionVersion ?? 0) + 1;
    final at = current?.deadlineAt;
    final late = at != null ? DateTime.now().isAfter(at) : (current?.isOverdue ?? false);

    // Optimistic update
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            status: ProjectStatus.submitted,
            submissionLink: submissionLink,
            submissionNote: submissionNote,
            submittedAt: nowStr,
            submissionVersion: version,
            submittedLate: late,
          )
        else
          item
    ];

    // Cloud Firestore write
    _firestoreService.submitWork(projectId, submissionLink, submissionNote, nowStr, version: version, late: late);
    final a = actor, agency = _agencyId;
    if (a != null && agency != null && current != null) {
      _firestoreService.managerUidOf(agency).then((m) {
        if (m == null) return;
        _firestoreService.notifyUser(
          m,
          AppNotification.draft(
            type: NotificationType.submitted,
            title: '${a.name.isEmpty ? 'Editor' : a.name} submitted v$version',
            body: current.title,
            fromUid: a.id,
            projectId: projectId,
          ),
        );
      });
    }
  }

  /// Approve (= paid) after a simulated bKash payment: one receipt per
  /// project, one 'Payment received' note per editor.
  Future<void> payWithBkash(List<ProjectItem> projects, {required String trxId, required String wallet}) async {
    final a = actor;
    final agencyId = _agencyId;
    if (a == null || agencyId == null || projects.isEmpty) return;
    for (final p in projects) {
      approveProject(p.id, notify: false);
    }
    await _firestoreService.recordPayouts(agencyId, [
      for (final p in projects)
        PayoutRecord(
          projectId: p.id,
          projectTitle: p.title,
          trxId: trxId,
          amount: p.editorPayout,
          editorId: p.claimedByEditorId ?? '',
          wallet: maskWallet(wallet),
        ),
    ], a.id);
    final byEditor = <String, double>{};
    for (final p in projects) {
      final e = p.claimedByEditorId;
      if (e != null) byEditor[e] = (byEditor[e] ?? 0) + p.editorPayout;
    }
    for (final e in byEditor.entries) {
      await _firestoreService.notifyUser(
        e.key,
        AppNotification.draft(
          type: NotificationType.payment,
          title: 'Payment received',
          body: '${takaAmount(e.value)} · TrxID $trxId',
          fromUid: a.id,
          projectId: projects.length == 1 ? projects.first.id : null,
        ),
      );
    }
    final total = projects.fold<double>(0, (s, p) => s + p.editorPayout);
    await _firestoreService.logToSelf(
      a.id,
      AppNotification.draft(
        type: NotificationType.payment,
        title: projects.length == 1 ? 'Paid · ${projects.first.title}' : 'Paid ${projects.length} projects',
        body: '${takaAmount(total)} · TrxID $trxId',
        fromUid: a.id,
        projectId: projects.length == 1 ? projects.first.id : null,
      ),
    );
  }

  void approveProject(String projectId, {bool notify = true}) {
    Haptics.statusChange(ProjectStatus.approved);
    // Optimistic update
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(status: ProjectStatus.approved, approvedAt: DateTime.now())
        else
          item
    ];

    // Cloud Firestore write
    _firestoreService.approveProject(projectId);
    final p = _byId(projectId);
    if (notify) _notifyEditor(p, NotificationType.approved, 'Approved', p?.title ?? '');
  }

  void requestRevision(String projectId, String feedback) {
    Haptics.statusChange(ProjectStatus.claimed);
    final p = _byId(projectId);
    _notifyEditor(p, NotificationType.revision, 'Revision requested: ${p?.title ?? ''}', feedback);
    // Optimistic update
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            status: ProjectStatus.claimed,
            submissionNote: 'Revision Request: $feedback',
            revisionNotes: feedback,
            revisionChecks: const [],
          )
        else
          item
    ];

    // Cloud Firestore write
    _firestoreService.requestRevision(projectId, feedback);
  }

  /// Tick/untick revision item [index] on [projectId] (stored per project).
  void toggleRevisionCheck(String projectId, int index) {
    Haptics.tick();
    List<int>? next;
    state = [
      for (final item in state)
        if (item.id == projectId)
          item.copyWith(
            revisionChecks: next = item.revisionChecks.contains(index)
                ? (List.of(item.revisionChecks)..remove(index))
                : ([...item.revisionChecks, index]..sort()),
          )
        else
          item
    ];
    if (next != null) _firestoreService.updateProject(projectId, {'revisionChecks': next});
  }

  void assignProject(String projectId, String editorId, String editorName) {
    Haptics.statusChange(ProjectStatus.claimed);
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
    _notifyEditor(_byId(projectId), NotificationType.assigned, 'New assignment', _byId(projectId)?.title ?? '');
  }
}

final projectsProvider = StateNotifierProvider<ProjectsNotifier, List<ProjectItem>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final agencyId = ref.watch(authProvider.select((s) => s.user?.agencyId));
  return ProjectsNotifier(
    firestoreService,
    agencyId,
    (err) {
      if (ref.read(projectsErrorProvider) != err) {
        ref.read(projectsErrorProvider.notifier).state = err;
      }
    },
    () {
      if (!ref.read(projectsLoadedProvider)) {
        ref.read(projectsLoadedProvider.notifier).state = true;
      }
    },
    switch (ref.watch(authProvider.select((s) => s.user?.id))) {
      final String id => (id: id, name: ref.read(authProvider).user?.name ?? ''),
      _ => null,
    },
  );
});

/// Status counts for the stat strip, computed once per projects change
/// (one pass) instead of four `where` scans on every screen build.
typedef ProjectCounts = ({int open, int claimed, int submitted, int overdue});

final projectCountsProvider = Provider<ProjectCounts>((ref) {
  var open = 0, claimed = 0, submitted = 0, overdue = 0;
  for (final p in ref.watch(projectsProvider)) {
    if (p.status == ProjectStatus.open) open++;
    if (p.status == ProjectStatus.claimed) claimed++;
    if (p.status == ProjectStatus.submitted) submitted++;
    if (p.isOverdue) overdue++;
  }
  return (open: open, claimed: claimed, submitted: submitted, overdue: overdue);
});

/// The signed-in user's id (null when signed out).
final currentUserIdProvider = Provider<String?>((ref) => ref.watch(authProvider.select((s) => s.user?.id)));

/// True when [p] is claimed by [uid]. A null/empty uid owns nothing.
bool isClaimedBy(ProjectItem p, String? uid) =>
    uid != null && uid.isNotEmpty && p.claimedByEditorId == uid;

/// The editor's own projects plus their approved payout total.
({List<ProjectItem> items, int earned}) workspaceFor(Iterable<ProjectItem> projects, String? uid) {
  final items = projects.where((p) => isClaimedBy(p, uid)).toList(growable: false);
  final earned = items
      .where((p) => p.status == ProjectStatus.approved)
      .fold<double>(0, (sum, p) => sum + p.editorPayout)
      .toInt();
  return (items: items, earned: earned);
}

/// Number of in-progress (claimed) projects owned by [uid]: the Workspace badge.
int activeClaimCount(Iterable<ProjectItem> projects, String? uid) =>
    projects.where((p) => isClaimedBy(p, uid) && p.status == ProjectStatus.claimed).length;

/// Projects claimed by the signed-in editor, plus the approved payout total.
final workspaceProjectsProvider = Provider<({List<ProjectItem> items, int earned})>((ref) {
  return workspaceFor(ref.watch(projectsProvider), ref.watch(currentUserIdProvider));
});

/// Workspace tab badge: the signed-in editor's active claims.
/// Offers claimed inside the undo window (not yet written). Counted on the
/// Workspace badge while still open so the hand-off lands on a live count.
final pendingClaimsProvider = StateProvider<Set<String>>((ref) => const {});

final workspaceBadgeProvider = Provider<int>((ref) {
  final projects = ref.watch(projectsProvider);
  final pending = ref.watch(pendingClaimsProvider);
  final stillOpen = projects.where((p) => pending.contains(p.id) && p.status == ProjectStatus.open).length;
  return activeClaimCount(projects, ref.watch(currentUserIdProvider)) + stillOpen;
});

final _isManagerProvider = Provider<bool>((ref) => ref.watch(authProvider.select((s) => s.user?.role == UserRole.manager)));

final _projectIdsProvider = Provider<List<String>>((ref) {
  final ids = ref.watch(projectsProvider).map((p) => p.id).toList()..sort();
  return ids;
});

/// Client prices by project id, from `projects/{id}/private/finance`.
/// Manager-only: editors get an empty map and never touch the private docs.
/// A project without a finance doc is simply absent (UI shows a dash).
final projectFinanceProvider = StreamProvider<Map<String, ProjectFinance>>((ref) {
  if (!ref.watch(_isManagerProvider)) return Stream.value(const {});
  final ids = ref.watch(_projectIdsProvider.select((l) => l.join(','))).split(',').where((s) => s.isNotEmpty).toList();
  if (ids.isEmpty) return Stream.value(const {});
  final service = ref.watch(firestoreServiceProvider);
  final controller = StreamController<Map<String, ProjectFinance>>();
  final values = <String, ProjectFinance>{};
  final subs = <StreamSubscription>[];
  var pending = ids.toSet();
  void emit() {
    if (pending.isEmpty) controller.add(Map.unmodifiable(values));
  }
  for (final id in ids) {
    subs.add(service.streamProjectFinance(id).listen((f) {
      if (f == null) {
        values.remove(id);
      } else {
        values[id] = f;
      }
      pending.remove(id);
      emit();
    }, onError: (Object _) {
      // Missing permission or offline: treat as unknown, keep the rest.
      pending.remove(id);
      emit();
    }));
  }
  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
    controller.close();
  });
  return controller.stream;
});

/// Client price for [p]: the private finance doc, else a legacy
/// `clientBudget` still on the project doc, else null (unknown).
double? clientPriceOf(ProjectItem p, Map<String, ProjectFinance> finance) {
  final f = finance[p.id]?.clientPrice;
  if (f != null && f > 0) return f;
  final legacy = p.legacyClientBudget;
  return (legacy != null && legacy > 0) ? legacy : null;
}

/// '৳1,200'.
String takaAmount(num v) => '৳${v.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
