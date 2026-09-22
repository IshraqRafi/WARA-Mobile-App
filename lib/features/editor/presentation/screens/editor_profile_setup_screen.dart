import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
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

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _photoCtrl = TextEditingController(text: user?.photoUrl ?? '');
    _specializationCtrl = TextEditingController(text: user?.specialization ?? 'Video Editor & Colorist');
    _portfolioCtrl = TextEditingController(text: user?.portfolioLink ?? '');
    _agencyKeyCtrl = TextEditingController(text: user?.agencyJoinKey ?? '');
    _selectedSkills = user?.skills.isNotEmpty == true
        ? user!.skills.toSet()
        : {'Video Editing', 'Color Grading', 'Sound Design'};
    _selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};
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
      WaraToast.show(context, message: 'Please select at least one skill.', icon: Icons.warning_amber_rounded);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).completeProfile(
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
        WaraToast.show(context, message: 'Profile complete! Welcome to wara.io', icon: Icons.check_circle_rounded);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        WaraToast.show(context, message: 'Failed to save profile: $e', icon: Icons.error_outline_rounded);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ───────────────────────────────────────────
                    Center(
                      child: WaraAvatar(
                        name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Editor',
                        photoUrl: _photoCtrl.text.trim().isNotEmpty ? _photoCtrl.text.trim() : null,
                        radius: 36,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Complete Your Editor Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome to wara.io! Set up your creative identity so managers can discover and assign projects to you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.muted, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 28),

                    // ── Form Container ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Agency Join Key / Server Room Key
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.vpn_key_rounded, color: colors.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Agency Room Join Key',
                                      style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Required',
                                        style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ask your Agency Manager for their room join key to enter their workspace.',
                                  style: TextStyle(color: colors.muted, fontSize: 11),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _agencyKeyCtrl,
                                  textCapitalization: TextCapitalization.characters,
                                  style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your agency join key' : null,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. WARA-7742',
                                    hintStyle: TextStyle(color: colors.muted.withValues(alpha: 0.5), fontSize: 13, letterSpacing: 1.0),
                                    prefixIcon: Icon(Icons.meeting_room_outlined, color: colors.primary, size: 20),
                                    fillColor: colors.surface,
                                    filled: true,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Full Name
                          Text('Full Name', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameCtrl,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(color: colors.text, fontSize: 14),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                            decoration: InputDecoration(
                              hintText: 'e.g. Alex Morgan',
                              hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                              prefixIcon: Icon(Icons.person_outline_rounded, color: colors.muted, size: 20),
                              fillColor: colors.card,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Creative Specialization / Role
                          Text('Primary Specialization / Title', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _specializationCtrl,
                            style: TextStyle(color: colors.text, fontSize: 14),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify your specialization' : null,
                            decoration: InputDecoration(
                              hintText: 'e.g. Senior Video Editor & Colorist',
                              hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                              prefixIcon: Icon(Icons.work_outline_rounded, color: colors.muted, size: 20),
                              fillColor: colors.card,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Core Skills Chips
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Core Skills', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('${_selectedSkills.length} selected', style: TextStyle(color: colors.muted, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableSkills.map((skill) {
                              final isSelected = _selectedSkills.contains(skill);
                              return FilterChip(
                                label: Text(
                                  skill,
                                  style: TextStyle(
                                    color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.text,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
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
                                backgroundColor: colors.card,
                                selectedColor: colors.primary,
                                checkmarkColor: colors.isDark ? Colors.black : Colors.white,
                                side: BorderSide(color: isSelected ? colors.primary : colors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Weekly Hours Availability
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Weekly Availability', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('$_hoursPerWeek Hours / week', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: colors.primary,
                              inactiveTrackColor: colors.border,
                              thumbColor: colors.primary,
                              overlayColor: colors.primary.withValues(alpha: 0.1),
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
                          const SizedBox(height: 16),

                          // Active Days
                          Text('Active Working Days', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Row(
                            children: _allDays.map((day) {
                              final isSelected = _selectedDays.contains(day);
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                  child: GestureDetector(
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
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isSelected ? colors.primary : colors.card,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isSelected ? colors.primary : colors.border),
                                      ),
                                      child: Center(
                                        child: Text(
                                          day,
                                          style: TextStyle(
                                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.text,
                                            fontSize: 11,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Portfolio / Reel Link
                          Text('Showreel / Portfolio Link (Optional)', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _portfolioCtrl,
                            style: TextStyle(color: colors.text, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'https://vimeo.com/... or Behance / Drive link',
                              hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                              prefixIcon: Icon(Icons.link_rounded, color: colors.muted, size: 20),
                              fillColor: colors.card,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Profile Picture URL
                          Text('Profile Picture URL (Optional)', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _photoCtrl,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(color: colors.text, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'https://images.unsplash.com/... or image link',
                              hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                              prefixIcon: Icon(Icons.image_outlined, color: colors.muted, size: 20),
                              fillColor: colors.card,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '💡 If left blank, your avatar displays two letters: surname initial + first name initial.',
                            style: TextStyle(color: colors.muted, fontSize: 11),
                          ),
                          const SizedBox(height: 28),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colors.isDark ? Colors.black : Colors.white, strokeWidth: 2.5))
                                  : Text(
                                      'Save Profile & Enter Workspace',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.isDark ? Colors.black : Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
