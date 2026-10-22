import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WaraNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool hasBadge;
  final String? tooltip;

  const WaraNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.hasBadge = false,
    this.tooltip,
  });
}

/// Bottom navigation dock for WARA: icon plus a short visible label,
/// with tooltip and screen-reader semantics on every tab.
///
/// Features animated pill highlights, theme-adaptive surfaces,
/// and safe-area compliance across both Editor and Manager shells.
class WaraBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<WaraNavItem> items;

  const WaraBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: '${item.label} tab',
                  excludeSemantics: true,
                  child: Tooltip(
                    message: item.tooltip ?? item.label,
                    child: InkResponse(
                      onTap: () => onItemSelected(index),
                      containedInkWell: true,
                      highlightColor: Colors.transparent,
                      splashColor: colors.primary.withValues(alpha: 0.12),
                      radius: 28,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primaryTint
                                  : Colors.transparent,
                              borderRadius: AppRadius.brPill,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  isSelected
                                      ? (item.selectedIcon ?? item.icon)
                                      : item.icon,
                                  size: 24,
                                  color: isSelected
                                      ? colors.primary
                                      : colors.muted,
                                ),
                                if (item.hasBadge)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colors.surface,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textScaler: MediaQuery.textScalerOf(
                              context,
                            ).clamp(maxScaleFactor: 1.2),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? colors.primary
                                  : colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
