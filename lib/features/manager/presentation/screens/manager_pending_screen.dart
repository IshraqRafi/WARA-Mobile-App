import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../projects/domain/project_provider.dart';

class ManagerPendingScreen extends ConsumerStatefulWidget {
  const ManagerPendingScreen({super.key});

  @override
  ConsumerState<ManagerPendingScreen> createState() => _ManagerPendingScreenState();
}

class _ManagerPendingScreenState extends ConsumerState<ManagerPendingScreen> {
  String _sortBy = 'time'; // 'time' or 'money'

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final projects = ref.watch(projectsProvider);

    // Filter pending works (claimed or submitted)
    final pendingProjects = projects.where((p) => p.status != ProjectStatus.approved).toList();

    // Sort based on selection
    if (_sortBy == 'time') {
      pendingProjects.sort((a, b) => a.deadlineHoursLeft.compareTo(b.deadlineHoursLeft));
    } else {
      pendingProjects.sort((a, b) => b.clientBudget.compareTo(a.clientBudget));
    }

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo
              Row(
                children: [
                  const WaraLogo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pending Deliverables', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'Time-sensitive client deliverables & review status',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter & Sort Control Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text('Sort By:', style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => _sortBy = 'time'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _sortBy == 'time' ? colors.primary : colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _sortBy == 'time' ? colors.primary : colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: _sortBy == 'time' ? (colors.isDark ? Colors.black : Colors.white) : colors.muted),
                            const SizedBox(width: 6),
                            Text('Urgent Deadline', style: TextStyle(color: _sortBy == 'time' ? (colors.isDark ? Colors.black : Colors.white) : colors.text, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _sortBy = 'money'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _sortBy == 'money' ? colors.primary : colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _sortBy == 'money' ? colors.primary : colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 14, color: _sortBy == 'money' ? (colors.isDark ? Colors.black : Colors.white) : colors.muted),
                            const SizedBox(width: 4),
                            Text('Payout (৳ High)', style: TextStyle(color: _sortBy == 'money' ? (colors.isDark ? Colors.black : Colors.white) : colors.text, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pending Projects List
              Expanded(
                child: pendingProjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_outlined, color: colors.muted, size: 48),
                            const SizedBox(height: 12),
                            Text('No pending deliverables!', style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('All agency deliverables are approved and up to date.', style: TextStyle(color: colors.muted, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: pendingProjects.length,
                        itemBuilder: (context, index) {
                          final item = pendingProjects[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                                      child: Text(item.clientName, style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: item.deadlineHoursLeft <= 12 ? colors.primary.withValues(alpha: 0.15) : colors.surface,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: colors.border),
                                      ),
                                      child: Text(
                                        item.deadlineStr,
                                        style: TextStyle(
                                          color: item.deadlineHoursLeft <= 12 ? colors.primary : colors.muted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(item.title, style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(item.description, style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4)),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Client Contract Value', style: TextStyle(color: colors.muted, fontSize: 11)),
                                        Text('৳${item.clientBudget.toInt()}', style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Assigned Editor', style: TextStyle(color: colors.muted, fontSize: 11)),
                                        Text(item.claimedByEditorName ?? 'Unassigned', style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
