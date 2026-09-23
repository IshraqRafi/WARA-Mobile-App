import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WaraNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final bool hasBadge;
  final String? tooltip;

  const WaraNavItem({
    required this.icon,
    this.selectedIcon,
    this.hasBadge = false,
    this.tooltip,
  });
}

/// A sleek, textless, icon-only bottom navigation dock engineered for WARA.
///
/// Features animated pill highlights, zero text clutter, theme-adaptive surfaces,
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
            color: colors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;

              return Expanded(
                child: InkResponse(
                  onTap: () => onItemSelected(index),
                  containedInkWell: true,
                  highlightColor: Colors.transparent,
                  splashColor: colors.primary.withValues(alpha: 0.12),
                  radius: 28,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? colors.primary.withValues(alpha: 0.28)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                            size: 24,
                            color: isSelected
                                ? colors.primary
                                : colors.muted.withValues(alpha: 0.8),
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
