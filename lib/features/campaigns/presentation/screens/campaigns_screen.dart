import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  String _selectedTab = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedTab == 'All'
        ? kInitialCampaigns
        : kInitialCampaigns.where((c) => c.status == _selectedTab).toList();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Add Campaign Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Campaigns',
                        style: TextStyle(color: kText, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Media & Ad Deliverables Workspace',
                        style: TextStyle(color: kMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Campaign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Active', 'Review', 'Draft'].map((tab) {
                    final isSelected = _selectedTab == tab;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = tab),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimary : kSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? kPrimary : kBorder),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isSelected ? Colors.black : kText,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Campaign List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No campaigns in this view',
                          style: TextStyle(color: kMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final progress = item.spent / item.budget;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: kBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: kSurface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: kBorder),
                                      ),
                                      child: Text(
                                        item.platform,
                                        style: const TextStyle(color: kText, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: item.status == 'Active' ? kPrimary.withValues(alpha: 0.15) : kSurface,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: item.status == 'Active' ? kPrimary : kBorder),
                                      ),
                                      child: Text(
                                        item.status,
                                        style: TextStyle(
                                          color: item.status == 'Active' ? kPrimary : kMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.title,
                                  style: const TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Client: ${item.clientName}',
                                  style: const TextStyle(color: kMuted, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Ad Spend', style: TextStyle(color: kMuted, fontSize: 11)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '৳${item.spent.toInt()} / ৳${item.budget.toInt()}',
                                          style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Target ROAS', style: TextStyle(color: kMuted, fontSize: 11)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.roas}x',
                                          style: const TextStyle(color: kPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0.0, 1.0),
                                    backgroundColor: kSurface,
                                    valueColor: const AlwaysStoppedAnimation(kPrimary),
                                    minHeight: 6,
                                  ),
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
