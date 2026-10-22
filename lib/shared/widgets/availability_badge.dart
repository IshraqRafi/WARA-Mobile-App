import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Editor availability as stored on users/{uid}.availability.
enum Availability { available, busy }

Availability? parseAvailability(Object? v) => switch (v) {
      'available' => Availability.available,
      'busy' => Availability.busy,
      _ => null,
    };

/// Dot + label. Renders nothing when the editor never set it.
class AvailabilityBadge extends StatelessWidget {
  final Object? value;
  const AvailabilityBadge(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final a = parseAvailability(value);
    if (a == null) return const SizedBox.shrink();
    final c = context.colors;
    final tone = a == Availability.available ? c.success : c.warning;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: tone, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(a == Availability.available ? 'Available' : 'Busy',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tone, fontWeight: FontWeight.w600)),
    ]);
  }
}
