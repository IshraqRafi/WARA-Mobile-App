import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../projects/domain/project_provider.dart';

class ChatMemberStrip extends ConsumerWidget {
  final void Function(String uid, String name, String? photoUrl) onSelectMember;

  const ChatMemberStrip({
    super.key,
    required this.onSelectMember,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentUser = ref.watch(authProvider).user;
    final agencyId = currentUser?.agencyId;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ref.read(firestoreServiceProvider).streamEditors(agencyId: agencyId),
      builder: (context, snapshot) {
        final editors = snapshot.data ?? [];
        final otherEditors = editors.where((e) => e['uid'] != currentUser?.id).toList();

        // Build list of team members to display (always show at least demo/fallback members if list is empty)
        final List<Map<String, dynamic>> members = [];

        // If current user is an editor, include the Agency Director/Manager in the strip!
        if (currentUser?.role != UserRole.manager) {
          members.add({
            'uid': 'manager_agency_director',
            'name': 'Ishraq Rafi',
            'role': 'Agency Director',
            'isManager': true,
          });
        }

        if (otherEditors.isNotEmpty) {
          members.addAll(otherEditors);
        } else if (currentUser?.role == UserRole.manager) {
          // Demo fallback team members for managers
          members.add({
            'uid': 'demo_editor_walid',
            'name': 'Walid Islam',
            'role': 'Lead Video Editor',
            'isManager': false,
          });
          members.add({
            'uid': 'demo_editor_alex',
            'name': 'Alex Morgan',
            'role': 'Colorist & Sound',
            'isManager': false,
          });
          members.add({
            'uid': 'demo_editor_zack',
            'name': 'Zack Snyder',
            'role': 'VFX & 3D Motion',
            'isManager': false,
          });
        }

        return SizedBox(
          height: 84,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final member = members[index];
              final uid = member['uid'] as String? ?? 'user_$index';
              final name = member['name'] as String? ?? 'Team Member';
              final photo = member['photoUrl'] as String?;
              final isManager = member['isManager'] == true || member['role'] == 'Agency Director';

              final firstName = name.trim().split(' ').first;

              return GestureDetector(
                onTap: () => onSelectMember(uid, name, photo),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isManager ? colors.primary : colors.primary.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: WaraAvatar(
                            name: name,
                            photoUrl: photo,
                            radius: 24,
                            fontSize: 14,
                          ),
                        ),
                        // Online Green Dot
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.surface, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 60,
                      child: Text(
                        firstName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
