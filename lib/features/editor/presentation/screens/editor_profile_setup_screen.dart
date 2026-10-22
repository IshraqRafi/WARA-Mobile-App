import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_section_header.dart';
import '../../../../shared/widgets/wara_status_chip.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../auth/domain/auth_provider.dart';

class EditorProfileSetupScreen extends ConsumerStatefulWidget {
  const EditorProfileSetupScreen({super.key});

  @override
  ConsumerState<EditorProfileSetupScreen> createState() => _EditorProfileSetupScreenState();
}

class _EditorProfileSetupScreenState extends ConsumerState<EditorProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _photoCtrl;
  late TextEditingController _specializationCtrl;
  late TextEditingController _portfolioCtrl;
  late TextEditingController _agencyKeyCtrl;

  final List<String> _availableSkills = [
    'Video Editing',
    'Color Grading',
    'Sound Design',
    'Motion Graphics',
    '3D Motion',
    'VFX',
    'Thumbnail Design',
    'Audio Mastering',
    'Storyboarding',
  ];

  late Set<String> _selectedSkills;
  int _hoursPerWeek = 35;
  final List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late Set<String> _selectedDays;
  bool _isLoading = false;
  bool _isLeaving = false;

  /// Snapshot of the initial form values, used to detect unsaved edits.
  late final String _initialSnapshot;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _photoCtrl = TextEditingController(text: user?.photoUrl ?? '');
    _specializationCtrl = TextEditingController(text: user?.specialization ?? 'Video Editor & Colorist');
    _portfolioCtrl = TextEditingController(text: user?.portfolioLink ?? '');
    _agencyKeyCtrl = TextEditingController(text: user?.agencyJoinKey ?? '');
    _selectedSkills = user?.skills.isNotEmpty == true ? user!.skills.toSet() : {'Video Editing', 'Color Grading', 'Sound Design'};
    _selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};
    _initialSnapshot = _formSnapshot();
  }

  String _formSnapshot() => [
    _nameCtrl.text,
    _photoCtrl.text,
    _specializationCtrl.text,
    _portfolioCtrl.text,
    _agencyKeyCtrl.text,
    (_selectedSkills.toList()..sort()).join(','),
    _hoursPerWeek,
    (_selectedDays.toList()..sort()).join(','),
  ].join('|');

  bool get _hasUnsavedChanges => _formSnapshot() != _initialSnapshot;

  /// Back to login: the router would bounce a signed-in user with an
  /// incomplete profile straight back here, so we sign out first.
  Future<void> _backToLogin() async {
    if (_isLoading || _isLeaving) return;
    if (_hasUnsavedChanges) {
      final colors = context.colors;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard profile?'),
          content: Text('Your changes will be lost and you will be signed out.', style: TextStyle(color: colors.muted)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Back to login')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _isLeaving = true);
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _photoCtrl.dispose();
    _specializationCtrl.dispose();
    _portfolioCtrl.dispose();
    _agencyKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      WaraToast.show(context, message: 'Select at least one skill', icon: Icons.warning_amber_rounded);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .completeProfile(
            name: _nameCtrl.text.trim(),
            specialization: _specializationCtrl.text.trim(),
            skills: _selectedSkills.toList(),
            hoursPerWeek: _hoursPerWeek,
            activeDays: _selectedDays.toList(),
            portfolioLink: _portfolioCtrl.text.trim(),
            photoUrl: _photoCtrl.text.trim(),
            agencyJoinKey: _agencyKeyCtrl.text.trim(),
          );

      if (mounted) {
        WaraToast.show(context, message: 'Profile saved', icon: Icons.check_circle_rounded);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        WaraToast.show(context, message: 'Failed to save profile: $e', icon: Icons.error_outline_rounded);
      }
    }
  }

  Widget _label(String text, {Widget? trailing}) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(text, style: t.labelLarge)),
          ?trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final margin = AppSpacing.screenMargin(context);
    const gap = SizedBox(height: AppSpacing.lg);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToLogin();
      },
      child: Scaffold(
        backgroundColor: colors.bg,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to login',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: (_isLoading || _isLeaving) ? null : _backToLogin,
          ),
          title: const Text('Editor profile'),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(margin, AppSpacing.sm, margin, AppSpacing.xl),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Header ─────────────────────────────────────
                            Center(
                              child: WaraAvatar(
                                name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Editor',
                                photoUrl: _photoCtrl.text.trim().isNotEmpty ? _photoCtrl.text.trim() : null,
                                radius: 36,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text('Editor profile', textAlign: TextAlign.center, style: text.headlineSmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Set up your creative identity so managers can discover and assign projects to you.',
                              textAlign: TextAlign.center,
                              style: text.bodyMedium?.copyWith(color: colors.muted),
                            ),

                            // ── Agency ─────────────────────────────────────
                            WaraSectionCard(
                              title: 'Agency',
                              divided: false,
                              contentPadding: const EdgeInsets.all(AppSpacing.lg),
                              children: [
                                _label('Agency join key',
                                    trailing: const WaraStatusChip(label: 'Required', tone: WaraTone.warning)),
                                TextFormField(
                                  controller: _agencyKeyCtrl,
                                  textCapitalization: TextCapitalization.characters,
                                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your agency join key' : null,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. STUD-7K4M2Q',
                                    prefixIcon: Icon(Icons.vpn_key_rounded),
                                  ),
                                ),
                              ],
                            ),

                            // ── About you ──────────────────────────────────
                            WaraSectionCard(
                              title: 'About you',
                              divided: false,
                              contentPadding: const EdgeInsets.all(AppSpacing.lg),
                              children: [
                                _label('Full name'),
                                TextFormField(
                                  controller: _nameCtrl,
                                  onChanged: (_) => setState(() {}),
                                  style: text.bodyLarge,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                                  decoration: const InputDecoration(
                                    hintText: 'Your full name',
                                    prefixIcon: Icon(Icons.person_outline_rounded),
                                  ),
                                ),
                                gap,
                                _label('Primary specialization'),
                                TextFormField(
                                  controller: _specializationCtrl,
                                  style: text.bodyLarge,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify your specialization' : null,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Senior Video Editor & Colorist',
                                    prefixIcon: Icon(Icons.work_outline_rounded),
                                  ),
                                ),
                                gap,
                                _label('Profile picture URL (optional)'),
                                TextFormField(
                                  controller: _photoCtrl,
                                  onChanged: (_) => setState(() {}),
                                  style: text.bodyLarge,
                                  decoration: const InputDecoration(
                                    hintText: 'https://… image link',
                                    prefixIcon: Icon(Icons.image_outlined),
                                  ),
                                ),
                              ],
                            ),

                            // ── Skills ─────────────────────────────────────
                            WaraSectionCard(
                              title: 'Skills',
                              subtitle: '${_selectedSkills.length} selected',
                              divided: false,
                              contentPadding: const EdgeInsets.all(AppSpacing.lg),
                              children: [
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: _availableSkills.map((skill) {
                                    final isSelected = _selectedSkills.contains(skill);
                                    return FilterChip(
                                      label: Text(
                                        skill,
                                        style: text.labelMedium?.copyWith(color: isSelected ? onPrimary : colors.text),
                                      ),
                                      selected: isSelected,
                                      onSelected: (val) {
                                        setState(() {
                                          if (val) {
                                            _selectedSkills.add(skill);
                                          } else {
                                            _selectedSkills.remove(skill);
                                          }
                                        });
                                      },
                                      backgroundColor: colors.surface,
                                      selectedColor: colors.primary,
                                      checkmarkColor: onPrimary,
                                      side: BorderSide(color: isSelected ? colors.primary : colors.border),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),

                            // ── Availability ───────────────────────────────
                            WaraSectionCard(
                              title: 'Availability',
                              divided: false,
                              contentPadding: const EdgeInsets.all(AppSpacing.lg),
                              children: [
                                _label('Weekly hours',
                                    trailing: Text('$_hoursPerWeek h / week', style: text.labelLarge)),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: colors.primary,
                                    inactiveTrackColor: colors.border,
                                    thumbColor: colors.primary,
                                    overlayColor: colors.primaryTint,
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: _hoursPerWeek.toDouble(),
                                    min: 10,
                                    max: 60,
                                    divisions: 10,
                                    label: '$_hoursPerWeek hrs',
                                    onChanged: (v) => setState(() => _hoursPerWeek = v.round()),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _label('Active working days'),
                                Row(
                                  children: _allDays.map((day) {
                                    final isSelected = _selectedDays.contains(day);
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: Semantics(
                                          button: true,
                                          selected: isSelected,
                                          child: InkWell(
                                            borderRadius: AppRadius.brSm,
                                            onTap: () {
                                              setState(() {
                                                if (isSelected) {
                                                  if (_selectedDays.length > 1) _selectedDays.remove(day);
                                                } else {
                                                  _selectedDays.add(day);
                                                }
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 150),
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: isSelected ? colors.primary : colors.surface,
                                                borderRadius: AppRadius.brSm,
                                                border: Border.all(color: isSelected ? colors.primary : colors.border),
                                              ),
                                              child: Center(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    day,
                                                    style: text.labelMedium?.copyWith(color: isSelected ? onPrimary : colors.text),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),

                            // ── Portfolio ──────────────────────────────────
                            WaraSectionCard(
                              title: 'Portfolio',
                              divided: false,
                              contentPadding: const EdgeInsets.all(AppSpacing.lg),
                              children: [
                                _label('Showreel / portfolio link (optional)'),
                                TextFormField(
                                  controller: _portfolioCtrl,
                                  style: text.bodyLarge,
                                  keyboardType: TextInputType.url,
                                  decoration: const InputDecoration(
                                    hintText: 'Vimeo, Behance or Drive link',
                                    prefixIcon: Icon(Icons.link_rounded),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // ── Pinned save bar ────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(color: colors.bg, border: Border(top: BorderSide(color: colors.border))),
                  padding: EdgeInsets.fromLTRB(margin, AppSpacing.md, margin, AppSpacing.md),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSave,
                          child: _isLoading
                              ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(color: onPrimary, strokeWidth: 2.5))
                              : const Text('Save profile'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
