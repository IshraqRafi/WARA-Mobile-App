import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/domain/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Bar ───────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: const Center(
                      child: Text('W', style: TextStyle(color: kPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.agencyName ?? 'Wara Media Group',
                        style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${user?.name ?? 'Alex Vance'} • ${user?.role ?? 'Director'}',
                        style: const TextStyle(color: kMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: const [
                        CircleAvatar(radius: 4, backgroundColor: Colors.white),
                        SizedBox(width: 6),
                        Text('Live OS', style: TextStyle(color: kText, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Executive Summary Metrics Grid ───────────────────────────
              Row(
                children: const [
                  Expanded(
                    child: _MetricCard(
                      label: 'Agency MRR',
                      value: '৳12,000',
                      trend: '+14% vs last mo',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Avg Campaign ROAS',
                      value: '4.3x',
                      trend: 'Target: 3.5x',
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                    child: _MetricCard(
                      label: 'Active Clients',
                      value: '4 Retainers',
                      trend: '1 Onboarding',
                      icon: Icons.business_center_outlined,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Monthly Ad Spend',
                      value: '৳45.3K',
                      trend: '68% of Budget',
                      icon: Icons.pie_chart_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Quick Actions Bar ────────────────────────────────────────
              const Text(
                'QUICK ACTIONS',
                style: TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ActionChip(icon: Icons.add_rounded, label: 'New Campaign', onTap: () {}),
                    const SizedBox(width: 10),
                    _ActionChip(icon: Icons.person_add_alt_outlined, label: 'Add Client', onTap: () {}),
                    const SizedBox(width: 10),
                    _ActionChip(icon: Icons.ios_share_rounded, label: 'Export Report', onTap: () {}),
                    const SizedBox(width: 10),
                    _ActionChip(icon: Icons.tune_rounded, label: 'Manage Budget', onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Revenue & Ad Spend Chart ─────────────────────────────────
              const Text(
                'MEDIA AD SPEND vs REVENUE (LAST 6 MOS)',
                style: TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder),
                ),
                height: 200,
                child: const _AdSpendChart(),
              ),
              const SizedBox(height: 28),

              // ── Active Campaigns List ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'ACTIVE CAMPAIGNS',
                    style: TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                  ),
                  Text('View All', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),

              Column(
                children: kInitialCampaigns.map((camp) => _CampaignRow(campaign: camp)).toList(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
              Icon(icon, color: kText, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(trend, style: const TextStyle(color: kMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: kPrimary, size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CampaignRow extends StatelessWidget {
  final CampaignItem campaign;

  const _CampaignRow({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final progress = campaign.spent / campaign.budget;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${campaign.clientName} • ${campaign.platform}',
                      style: const TextStyle(color: kMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kBorder),
                ),
                child: Text(
                  '${campaign.roas}x ROAS',
                  style: const TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: kSurface,
              valueColor: const AlwaysStoppedAnimation(kPrimary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ৳${campaign.spent.toInt()} / ৳${campaign.budget.toInt()}',
                style: const TextStyle(color: kMuted, fontSize: 11),
              ),
              Text(
                '${(progress * 100).toInt()}% Used',
                style: const TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdSpendChart extends StatelessWidget {
  const _AdSpendChart();

  @override
  Widget build(BuildContext context) {
    const months = ['Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];
    final data = [
      {'spend': 28.0, 'rev': 110.0},
      {'spend': 32.0, 'rev': 135.0},
      {'spend': 38.0, 'rev': 160.0},
      {'spend': 41.0, 'rev': 180.0},
      {'spend': 42.0, 'rev': 195.0},
      {'spend': 45.3, 'rev': 215.0},
    ];

    return BarChart(
      BarChartData(
        maxY: 240,
        barGroups: List.generate(data.length, (i) {
          final spend = data[i]['spend']!;
          final rev = data[i]['rev']!;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: spend,
                color: kMuted,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: rev,
                color: kPrimary,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  months[v.toInt()],
                  style: const TextStyle(color: kMuted, fontSize: 11),
                ),
              ),
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}
