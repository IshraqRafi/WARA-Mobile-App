class AppInfo {
  static const String name = 'wara.io';
  static const String tagline = 'Media Agency Operating System';
  static const String version = 'v2.5.0';
  static const String logoPath = 'assets/wara.png';
}

enum UserRole { manager, editor }

enum ProjectStatus { open, claimed, submitted, approved }

class AgencyModel {
  final String id;
  final String name;
  final String managerUid;
  final String managerName;
  final String joinKey;
  final DateTime createdAt;

  const AgencyModel({
    required this.id,
    required this.name,
    required this.managerUid,
    required this.managerName,
    required this.joinKey,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'managerUid': managerUid,
      'managerName': managerName,
      'joinKey': joinKey,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AgencyModel.fromMap(String id, Map<String, dynamic> map) {
    return AgencyModel(
      id: id,
      name: map['name'] as String? ?? 'Agency',
      managerUid: map['managerUid'] as String? ?? '',
      managerName: map['managerName'] as String? ?? 'Manager',
      joinKey: (map['joinKey'] as String? ?? '').toUpperCase(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ProjectItem {
  final String id;
  final String? agencyId;
  final String title;
  final String clientName;
  /// Legacy client budget once stored on the (editor-readable) project doc.
  /// Read-only fallback: new code keeps the client price in
  /// `projects/{id}/private/finance` and never writes this field.
  final double? legacyClientBudget;
  final double editorPayout;
  final String deadlineStr;
  final int deadlineHoursLeft;
  final String description;
  final List<String> requiredSkills;
  final String? claimedByEditorId;
  final String? claimedByEditorName;
  final DateTime? claimedAt;
  final ProjectStatus status;
  final String? submissionLink;
  final String? submissionNote;
  final String? submittedAt;
  final bool isOverdue;
  /// When the manager approved (= paid) the work; null on legacy docs.
  final DateTime? approvedAt;
  /// Absolute deadline (drives live countdowns); null on legacy docs, which
  /// only have the static [deadlineHoursLeft].
  final DateTime? deadlineAt;

  const ProjectItem({
    required this.id,
    this.agencyId,
    required this.title,
    required this.clientName,
    this.legacyClientBudget,
    required this.editorPayout,
    required this.deadlineStr,
    required this.deadlineHoursLeft,
    required this.description,
    required this.requiredSkills,
    this.claimedByEditorId,
    this.claimedByEditorName,
    this.claimedAt,
    this.status = ProjectStatus.open,
    this.submissionLink,
    this.submissionNote,
    this.submittedAt,
    this.isOverdue = false,
    this.approvedAt,
    this.deadlineAt,
  });

  bool get canReturn => status == ProjectStatus.claimed && deadlineHoursLeft > 72;

  ProjectItem copyWith({
    String? agencyId,
    double? editorPayout,
    String? deadlineStr,
    int? deadlineHoursLeft,
    String? claimedByEditorId,
    String? claimedByEditorName,
    DateTime? claimedAt,
    ProjectStatus? status,
    String? submissionLink,
    String? submissionNote,
    String? submittedAt,
    bool? isOverdue,
    DateTime? approvedAt,
    DateTime? deadlineAt,
  }) {
    return ProjectItem(
      id: id,
      agencyId: agencyId ?? this.agencyId,
      title: title,
      clientName: clientName,
      legacyClientBudget: legacyClientBudget,
      editorPayout: editorPayout ?? this.editorPayout,
      deadlineStr: deadlineStr ?? this.deadlineStr,
      deadlineHoursLeft: deadlineHoursLeft ?? this.deadlineHoursLeft,
      description: description,
      requiredSkills: requiredSkills,
      claimedByEditorId: claimedByEditorId,
      claimedByEditorName: claimedByEditorName,
      claimedAt: claimedAt ?? this.claimedAt,
      status: status ?? this.status,
      submissionLink: submissionLink ?? this.submissionLink,
      submissionNote: submissionNote ?? this.submissionNote,
      submittedAt: submittedAt ?? this.submittedAt,
      isOverdue: isOverdue ?? this.isOverdue,
      approvedAt: approvedAt ?? this.approvedAt,
      deadlineAt: deadlineAt ?? this.deadlineAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (agencyId != null) 'agencyId': agencyId,
      'title': title,
      'clientName': clientName,
      'editorPayout': editorPayout,
      'deadlineStr': deadlineStr,
      'deadlineHoursLeft': deadlineHoursLeft,
      'description': description,
      'requiredSkills': requiredSkills,
      'claimedByEditorId': claimedByEditorId,
      'claimedByEditorName': claimedByEditorName,
      'claimedAt': claimedAt?.toIso8601String(),
      'status': status.name,
      'submissionLink': submissionLink,
      'submissionNote': submissionNote,
      'submittedAt': submittedAt,
      'isOverdue': isOverdue,
      if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
      if (deadlineAt != null) 'deadlineAt': deadlineAt!.toIso8601String(),
    };
  }

  factory ProjectItem.fromMap(String id, Map<String, dynamic> map) {
    return ProjectItem(
      id: id,
      agencyId: map['agencyId'] as String?,
      title: map['title'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      legacyClientBudget: (map['clientBudget'] as num?)?.toDouble(),
      editorPayout: (map['editorPayout'] as num?)?.toDouble() ?? 0.0,
      deadlineStr: map['deadlineStr'] as String? ?? '',
      deadlineHoursLeft: (map['deadlineHoursLeft'] as num?)?.toInt() ?? 0,
      description: map['description'] as String? ?? '',
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      claimedByEditorId: map['claimedByEditorId'] as String?,
      claimedByEditorName: map['claimedByEditorName'] as String?,
      claimedAt: map['claimedAt'] != null ? DateTime.tryParse(map['claimedAt'] as String) : null,
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProjectStatus.open,
      ),
      submissionLink: map['submissionLink'] as String?,
      submissionNote: map['submissionNote'] as String?,
      submittedAt: map['submittedAt'] as String?,
      isOverdue: map['isOverdue'] as bool? ?? false,
      approvedAt: _date(map['approvedAt']),
      deadlineAt: _date(map['deadlineAt']),
    );
  }
}

/// ISO string (or anything with toDate(), e.g. a Timestamp) to DateTime.
DateTime? _date(Object? v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  try {
    return (v as dynamic).toDate() as DateTime;
  } catch (_) {
    return null;
  }
}

/// Manager-only pricing for a project, stored at
/// `projects/{id}/private/finance`. Editors can never read it (rules).
class ProjectFinance {
  final double clientPrice;
  final String currency;
  const ProjectFinance({required this.clientPrice, this.currency = 'BDT'});

  factory ProjectFinance.fromMap(Map<String, dynamic> map) => ProjectFinance(
        clientPrice: (map['clientPrice'] as num?)?.toDouble() ?? 0,
        currency: map['currency'] as String? ?? 'BDT',
      );
}

/// Margin of [clientPrice] over [payout]; null when the price is unknown.
({double amount, double percent})? projectMargin(double? clientPrice, double payout) {
  if (clientPrice == null || clientPrice <= 0) return null;
  final amount = clientPrice - payout;
  return (amount: amount, percent: amount / clientPrice * 100);
}
