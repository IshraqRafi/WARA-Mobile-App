import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final totalRetainers = kInitialClients.fold<double>(0, (sum, item) => sum + item.monthlyRetainer);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Client Roster',
                        style: TextStyle(color: kText, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Retainers & Account Health',
                        style: TextStyle(color: kMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_alt_outlined, color: kText),
                    style: IconButton.styleFrom(
                      backgroundColor: kSurface,
                      side: const BorderSide(color: kBorder),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Retainer Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL MONTHLY RETAINERS', style: TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                        const SizedBox(height: 6),
                        Text(
                          '৳${totalRetainers.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: const TextStyle(color: kText, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kBorder),
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: kPrimary, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'ACCOUNTS DIRECTORY',
                style: TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),

              // Client List
              Expanded(
                child: ListView.builder(
                  itemCount: kInitialClients.length,
                  itemBuilder: (context, index) {
                    final client = kInitialClients[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kBorder),
                            ),
                            child: Center(
                              child: Text(client.avatarUrl, style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: const TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${client.category} • ${client.activeCampaignsCount} Active Campaigns',
                                  style: const TextStyle(color: kMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '৳${client.monthlyRetainer.toInt()}/mo',
                                style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kSurface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Text(
                                  client.status,
                                  style: const TextStyle(color: kPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
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
