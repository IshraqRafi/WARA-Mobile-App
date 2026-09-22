import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_logo.dart';

class ManagerFinanceScreen extends StatelessWidget {
  const ManagerFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
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
                        Text('Agency Finances', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'Bank balance, client retainers & editor payouts',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bank Balance Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(color: colors.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03), blurRadius: 20, spreadRadius: 1),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('CURRENT AGENCY BANK BALANCE', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                        Icon(Icons.account_balance_rounded, color: colors.primary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('৳15,000.00', style: TextStyle(color: colors.text, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.trending_up_rounded, color: colors.primary, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Monthly Recurring Retainers (MRR): ৳12,000/mo',
                            style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Client Retainers Section
              Text('CLIENT RETAINER BREAKDOWN', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              Column(
                children: kInitialClientsData.map((client) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Text(client.logoEmoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(client.name, style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('${client.activeProjects} Active Projects', style: TextStyle(color: colors.muted, fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('৳${client.monthlyAmount.toInt()}/mo', style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Paid Retainer', style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Editor Payouts Statistics Section
              Text('EDITOR PAYOUTS & DISBURSEMENTS', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              Column(
                children: [
                  {
                    'name': 'Walid Islam',
                    'role': 'Senior Editor • Lead Contractor',
                    'earned': 2900.0,
                    'projects': 2,
                    'share': 0.59,
                  },
                  {
                    'name': 'Ishraq Rafi',
                    'role': '3D Motion Specialist',
                    'earned': 2000.0,
                    'projects': 1,
                    'share': 0.41,
                  },
                ].map((ed) {
                  final name = ed['name'] as String;
                  final role = ed['role'] as String;
                  final earned = ed['earned'] as double;
                  final projects = ed['projects'] as int;
                  final share = ed['share'] as double;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold)),
                                  Text(role, style: TextStyle(color: colors.muted, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('৳${earned.toInt()}', style: TextStyle(color: colors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('$projects Completed Projects', style: TextStyle(color: colors.muted, fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: share,
                            backgroundColor: colors.surface,
                            valueColor: AlwaysStoppedAnimation(colors.primary),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
