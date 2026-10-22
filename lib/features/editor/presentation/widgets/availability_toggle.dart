import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';

/// Available / Busy switch shown to managers in assign + editor lists.
class AvailabilityToggle extends StatelessWidget {
  final bool available;
  final ValueChanged<bool>? onChanged;
  const AvailabilityToggle({super.key, required this.available, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final tone = available ? c.success : c.warning;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
      child: Row(children: [
        AnimatedContainer(
          duration: Motion.of(context),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(available ? 'Available' : 'Busy', key: const ValueKey('availability_label'),
              style: t.bodyMedium?.copyWith(color: c.text, fontWeight: FontWeight.w500)),
        ),
        Switch(
          key: const ValueKey('availability_switch'),
          value: available,
          onChanged: onChanged == null
              ? null
              : (v) {
                  Haptics.tick();
                  onChanged!(v);
                },
        ),
      ]),
    );
  }
}
