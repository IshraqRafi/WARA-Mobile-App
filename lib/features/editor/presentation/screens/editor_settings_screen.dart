import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../../shared/widgets/wara_theme_toggle.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../auth/domain/auth_provider.dart';

class EditorSettingsScreen extends ConsumerStatefulWidget {
  const EditorSettingsScreen({super.key});

  @override
  ConsumerState<EditorSettingsScreen> createState() => _EditorSettingsScreenState();
}

class _EditorSettingsScreenState extends ConsumerState<EditorSettingsScreen> {
  static const _allSkills = [
    'Video Editing',
    'Color Grading',
    '3D Motion',
    'Sound Design',
    'VFX',
    'Thumbnail Design',
    'Animation',
    'Scriptwriting',
  ];

  static const _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void _showEditProfileModal(BuildContext context, UserSession? user) {
    final colors = context.colors;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final photoCtrl = TextEditingController(text: user?.photoUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: colors.muted.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: colors.primary, size: 24),
                    const SizedBox(width: 10),
                    Text('Edit Profile Details', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Update your full name and profile picture across all agency projects.',
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Live Avatar Preview
                Center(
                  child: Column(
                    children: [
                      WaraAvatar(
                        name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : user?.name,
                        photoUrl: photoCtrl.text.trim().isNotEmpty ? photoCtrl.text.trim() : null,
                        radius: 36,
                        fontSize: 22,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Live Avatar Preview',
                        style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Name Input
                Text('Full Name', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  onChanged: (_) => setModalState(() {}),
                  style: TextStyle(color: colors.text, fontSize: 14),
                  decoration: InputDecoration(
                    fillColor: colors.surface,
                    filled: true,
                    hintText: 'e.g. Walid Islam',
                    hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: colors.muted, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Profile Picture URL Input
                Text('Profile Picture URL', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: photoCtrl,
                  onChanged: (_) => setModalState(() {}),
                  style: TextStyle(color: colors.text, fontSize: 14),
                  decoration: InputDecoration(
                    fillColor: colors.surface,
                    filled: true,
                    hintText: 'https://images.unsplash.com/... or hosted image',
                    hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                    prefixIcon: Icon(Icons.image_outlined, color: colors.muted, size: 20),
                    suffixIcon: photoCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: colors.muted, size: 18),
                            onPressed: () {
                              photoCtrl.clear();
                              setModalState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 If left blank, your avatar displays two letters: first letter of your surname and then real name.',
                  style: TextStyle(color: colors.muted, fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Cancel', style: TextStyle(color: colors.muted, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final newName = nameCtrl.text.trim();
                          final newPhoto = photoCtrl.text.trim();
                          if (newName.isEmpty) {
                            WaraToast.show(context, message: 'Please enter a valid name.', icon: Icons.warning_amber_rounded);
                            return;
                          }

                          await ref.read(authProvider.notifier).updateProfile(
                                name: newName,
                                photoUrl: newPhoto,
                              );

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (context.mounted) {
                            WaraToast.show(context, message: '✅ Profile updated successfully!', icon: Icons.check_circle_rounded);
                          }
                        },
                        icon: Icon(Icons.save_rounded, size: 18, color: colors.isDark ? Colors.black : Colors.white),
                        label: Text('Save Changes', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(authProvider).user;
    final currentSkills = user?.skills ?? ['Video Editing', 'Color Grading'];
    final currentHours = user?.hoursPerWeek ?? 35;
    final currentDays = user?.activeDays ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Sun/Moon Theme Toggle
              Row(
                children: [
                  const WaraLogo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('wara.io', style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                        Text(
                          'Your creative profile & settings',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const WaraThemeToggle(),
                ],
              ),
              const SizedBox(height: 24),

              // Profile Card (Clickable to Edit)
              GestureDetector(
                onTap: () => _showEditProfileModal(context, user),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      WaraAvatar(
                        name: user?.name,
                        photoUrl: user?.photoUrl,
                        radius: 26,
                        fontSize: 16,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user?.name ?? 'Walid Islam',
                                    style: TextStyle(color: colors.text, fontSize: 17, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.edit_outlined, color: colors.muted, size: 14),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(user?.email ?? 'walid.islam@wara.io', style: TextStyle(color: colors.muted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                              child: Text('Creative Editor • Tap to Edit', style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border),
                        ),
                        child: Icon(Icons.chevron_right_rounded, color: colors.primary, size: 18),
                      ),
                    ],
                  ),
                ),
              ),

              // Connected Agency Workspace Room Badge
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.meeting_room_rounded, color: colors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.agencyName.isNotEmpty == true ? user!.agencyName : 'Wara Media Group',
                            style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Connected Agency Room • Key: ${user?.agencyJoinKey ?? "WARA-7742"}',
                            style: TextStyle(color: colors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Joined', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Skills Customizer
              Text('CREATIVE SKILLS TAXONOMY', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text('Managers match project assignments based on your active skill set.', style: TextStyle(color: colors.muted, fontSize: 12)),
              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allSkills.map<Widget>((skill) {
                  final isSelected = currentSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (selected) {
                      final updated = List<String>.from(currentSkills);
                      if (selected) {
                        updated.add(skill);
                      } else {
                        updated.remove(skill);
                      }
                      ref.read(authProvider.notifier).updateEditorSkills(updated);
                    },
                    backgroundColor: colors.card,
                    selectedColor: colors.primary,
                    checkmarkColor: colors.isDark ? Colors.black : Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.text,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? colors.primary : colors.border),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Availability & Time Schedule
              Text('WORKING AVAILABILITY & SCHEDULE', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Weekly Work Capacity', style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('$currentHours hrs/week', style: TextStyle(color: colors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: currentHours.toDouble(),
                      min: 10,
                      max: 60,
                      divisions: 10,
                      activeColor: colors.primary,
                      inactiveColor: colors.surface,
                      onChanged: (val) {
                        ref.read(authProvider.notifier).updateEditorSchedule(val.toInt(), currentDays);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Active Working Days', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _allDays.map((day) {
                        final isActive = currentDays.contains(day);
                        return GestureDetector(
                          onTap: () {
                            final updated = List<String>.from(currentDays);
                            if (isActive) {
                              updated.remove(day);
                            } else {
                              updated.add(day);
                            }
                            ref.read(authProvider.notifier).updateEditorSchedule(currentHours, updated);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isActive ? colors.primary : colors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: isActive ? colors.primary : colors.border),
                            ),
                            child: Center(
                              child: Text(
                                day[0],
                                style: TextStyle(
                                  color: isActive ? (colors.isDark ? Colors.black : Colors.white) : colors.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  icon: Icon(Icons.logout_rounded, color: colors.muted, size: 18),
                  label: Text('Sign Out of Editor Portal', style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colors.border),
                    backgroundColor: colors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
