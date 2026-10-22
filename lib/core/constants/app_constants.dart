import 'package:flutter/material.dart';

class AppInfo {
  static const String name = 'wara.io';
  static const String tagline = 'Media Agency Operating System';
  static const String version = 'v2.5.0';
  static const String logoPath = 'assets/wara.png';
}

// B&W Palette Constants
const Color kBg       = Color(0xFF0A0A0A); // Deep black background
const Color kSurface  = Color(0xFF161616); // Dark grey surface
const Color kCard     = Color(0xFF1E1E1E); // Elevated card grey
const Color kPrimary  = Color(0xFFFFFFFF); // Pure white primary accent
const Color kText     = Color(0xFFF0F0F0); // Off-white main text
const Color kMuted    = Color(0xFF757575); // Neutral grey secondary text
const Color kBorder   = Color(0xFF2C2C2C); // Subtle border outline
const Color kWarningRed = Color(0xFFFF4D4D); // Warning red for overdue projects

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
  final double clientBudget;
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

  const ProjectItem({
    required this.id,
    this.agencyId,
    required this.title,
    required this.clientName,
    required this.clientBudget,
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
  }) {
    return ProjectItem(
      id: id,
      agencyId: agencyId ?? this.agencyId,
      title: title,
      clientName: clientName,
      clientBudget: clientBudget,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (agencyId != null) 'agencyId': agencyId,
      'title': title,
      'clientName': clientName,
      'clientBudget': clientBudget,
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
    };
  }

  factory ProjectItem.fromMap(String id, Map<String, dynamic> map) {
    return ProjectItem(
      id: id,
      agencyId: map['agencyId'] as String?,
      title: map['title'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      clientBudget: (map['clientBudget'] as num?)?.toDouble() ?? 0.0,
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
    );
  }
}
