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

class EditorProfile {
  final String id;
  final String name;
  final String email;
  final List<String> skills;
  final int hoursPerWeek;
  final List<String> activeDays;
  final double totalEarned;

  const EditorProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.skills,
    required this.hoursPerWeek,
    required this.activeDays,
    required this.totalEarned,
  });
}

class ClientRetainer {
  final String id;
  final String name;
  final String logoEmoji;
  final double monthlyAmount;
  final int activeProjects;
  final String status;

  const ClientRetainer({
    required this.id,
    required this.name,
    required this.logoEmoji,
    required this.monthlyAmount,
    required this.activeProjects,
    required this.status,
  });
}

class CampaignItem {
  final String id;
  final String title;
  final String clientName;
  final String platform;
  final String status;
  final double budget;
  final double spent;
  final double roas;

  const CampaignItem({
    required this.id,
    required this.title,
    required this.clientName,
    required this.platform,
    required this.status,
    required this.budget,
    required this.spent,
    required this.roas,
  });
}

class ClientInfo {
  final String id;
  final String name;
  final String avatarUrl;
  final String category;
  final int activeCampaignsCount;
  final double monthlyRetainer;
  final String status;

  const ClientInfo({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.category,
    required this.activeCampaignsCount,
    required this.monthlyRetainer,
    required this.status,
  });
}

const List<CampaignItem> kInitialCampaigns = [
  CampaignItem(
    id: 'camp1',
    title: 'LuxeLiving Summer Collection Launch',
    clientName: 'LuxeLiving Apparel',
    platform: 'Meta Ads',
    status: 'Active',
    budget: 15000.0,
    spent: 9800.0,
    roas: 4.2,
  ),
  CampaignItem(
    id: 'camp2',
    title: 'NeuraTech Product Awareness',
    clientName: 'NeuraTech Systems',
    platform: 'Google Ads',
    status: 'Active',
    budget: 12000.0,
    spent: 7200.0,
    roas: 3.8,
  ),
  CampaignItem(
    id: 'camp3',
    title: 'Aero Dynamics Brand Story',
    clientName: 'Aero Dynamics Co.',
    platform: 'TikTok Ads',
    status: 'Review',
    budget: 8000.0,
    spent: 8000.0,
    roas: 5.1,
  ),
  CampaignItem(
    id: 'camp4',
    title: 'FinPulse Q3 Lead Generation',
    clientName: 'FinPulse Software',
    platform: 'Meta Ads',
    status: 'Draft',
    budget: 10000.0,
    spent: 0.0,
    roas: 0.0,
  ),
];

const List<ClientInfo> kInitialClients = [
  ClientInfo(
    id: 'cl1',
    name: 'Aero Dynamics Co.',
    avatarUrl: '🏎️',
    category: 'Automotive',
    activeCampaignsCount: 3,
    monthlyRetainer: 4500.0,
    status: 'Healthy',
  ),
  ClientInfo(
    id: 'cl2',
    name: 'NeuraTech Systems',
    avatarUrl: '🤖',
    category: 'Technology',
    activeCampaignsCount: 2,
    monthlyRetainer: 3800.0,
    status: 'Healthy',
  ),
  ClientInfo(
    id: 'cl3',
    name: 'LuxeLiving Apparel',
    avatarUrl: '🛍️',
    category: 'Fashion & Retail',
    activeCampaignsCount: 2,
    monthlyRetainer: 2500.0,
    status: 'Healthy',
  ),
  ClientInfo(
    id: 'cl4',
    name: 'FinPulse Software',
    avatarUrl: '💳',
    category: 'FinTech',
    activeCampaignsCount: 1,
    monthlyRetainer: 1200.0,
    status: 'Healthy',
  ),
];

// Initial Mock Projects Data (Scaled to 1000 - 2000 BDT Range)
final List<ProjectItem> kInitialProjectsData = [
  ProjectItem(
    id: 'p1',
    title: '4K Fashion Commercial Reel & Color Grade',
    clientName: 'LuxeLiving Apparel',
    clientBudget: 3500.0,
    editorPayout: 1400.0,
    deadlineStr: '4 Days Left (96 Hours)',
    deadlineHoursLeft: 96,
    description: 'Edit 60-second high-energy fashion promotional video. Apply cinematic color grade, sound design, and custom speed ramps.',
    requiredSkills: ['Video Editing', 'Color Grading', 'Sound Design'],
    status: ProjectStatus.open,
  ),
  ProjectItem(
    id: 'p2',
    title: '3D Cybernetic Device Animation & VFX',
    clientName: 'NeuraTech Systems',
    clientBudget: 5000.0,
    editorPayout: 2200.0,
    deadlineStr: '5 Days Left (120 Hours)',
    deadlineHoursLeft: 120,
    description: 'Create a 30-second 3D device reveal animation with futuristic HUD elements and motion tracking graphics.',
    requiredSkills: ['3D Motion', 'VFX', 'Animation'],
    status: ProjectStatus.open,
  ),
  ProjectItem(
    id: 'p3',
    title: 'Shorts & TikTok Viral Reel Pack (5 Videos)',
    clientName: 'Aero Dynamics Co.',
    clientBudget: 2800.0,
    editorPayout: 1100.0,
    deadlineStr: '4 Days Left (96 Hours)',
    deadlineHoursLeft: 96,
    description: 'Cut 5 vertical automotive videos with dynamic captions, sound effects, and fast-paced hook intros.',
    requiredSkills: ['Video Editing', 'Thumbnail Design', 'Sound Design'],
    claimedByEditorId: 'editor_1',
    claimedByEditorName: 'Walid Islam (You)',
    status: ProjectStatus.claimed,
  ),
  ProjectItem(
    id: 'p4',
    title: 'SaaS Platform Feature Explainer Video',
    clientName: 'FinPulse Software',
    clientBudget: 4200.0,
    editorPayout: 1800.0,
    deadlineStr: '2 Days Left (48 Hours)',
    deadlineHoursLeft: 48,
    description: '2-minute UI walkthrough animation with professional voiceover sync and clean typography callouts.',
    requiredSkills: ['Motion Graphics', 'Video Editing'],
    claimedByEditorId: 'editor_1',
    claimedByEditorName: 'Walid Islam (You)',
    status: ProjectStatus.claimed,
  ),
  ProjectItem(
    id: 'p5',
    title: 'Podcast Episode Edit & Audio Cleaning',
    clientName: 'LuxeLiving Apparel',
    clientBudget: 1800.0,
    editorPayout: 1200.0,
    deadlineStr: '6 Days Left (144 Hours)',
    deadlineHoursLeft: 144,
    description: 'Full 45-minute multi-cam video podcast edit with lower thirds graphics and noise reduction audio mastering.',
    requiredSkills: ['Video Editing', 'Sound Design'],
    status: ProjectStatus.open,
  ),
  ProjectItem(
    id: 'p6',
    title: 'Automotive Launch Event Teaser',
    clientName: 'Aero Dynamics Co.',
    clientBudget: 3800.0,
    editorPayout: 1500.0,
    deadlineStr: 'OVERDUE (0 Hours Left)',
    deadlineHoursLeft: 0,
    description: 'Urgent event teaser edit. Assigned editor failed to deliver before deadline. Requires immediate editor re-assignment!',
    requiredSkills: ['Video Editing', 'Sound Design'],
    claimedByEditorId: 'editor_2',
    claimedByEditorName: 'Ishraq Rafi',
    status: ProjectStatus.claimed,
    isOverdue: true,
  ),
  ProjectItem(
    id: 'p7',
    title: 'Brand Vision Documentary Teaser',
    clientName: 'Aero Dynamics Co.',
    clientBudget: 6000.0,
    editorPayout: 2000.0,
    deadlineStr: 'Approved & Completed',
    deadlineHoursLeft: 999,
    description: 'Cinematic brand story edit with orchestral music scoring and documentary tone.',
    requiredSkills: ['Video Editing', 'Color Grading'],
    claimedByEditorId: 'editor_2',
    claimedByEditorName: 'Ishraq Rafi',
    status: ProjectStatus.approved,
    submissionLink: 'https://frame.io/w/aero_doc_master',
    submittedAt: 'Yesterday',
  ),
];

const List<ClientRetainer> kInitialClientsData = [
  ClientRetainer(
    id: 'cl1',
    name: 'Aero Dynamics Co.',
    logoEmoji: '🏎️',
    monthlyAmount: 4500.0,
    activeProjects: 3,
    status: 'Healthy',
  ),
  ClientRetainer(
    id: 'cl2',
    name: 'NeuraTech Systems',
    logoEmoji: '🤖',
    monthlyAmount: 3800.0,
    activeProjects: 2,
    status: 'Healthy',
  ),
  ClientRetainer(
    id: 'cl3',
    name: 'LuxeLiving Apparel',
    logoEmoji: '🛍️',
    monthlyAmount: 2500.0,
    activeProjects: 2,
    status: 'Healthy',
  ),
  ClientRetainer(
    id: 'cl4',
    name: 'FinPulse Software',
    logoEmoji: '💳',
    monthlyAmount: 1200.0,
    activeProjects: 1,
    status: 'Healthy',
  ),
];
