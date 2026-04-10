import 'package:flutter/material.dart';
import 'package:line_oa_food_order/core/models/user_model.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แพ็กเกจ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: SubscriptionTier.values
            .map((tier) => _TierCard(tier: tier))
            .toList(),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final SubscriptionTier tier;

  const _TierCard({required this.tier});

  @override
  Widget build(BuildContext context) {
    final limitText = tier.dailyCustomerLimit == -1
        ? 'ไม่จำกัด'
        : '${tier.dailyCustomerLimit} คน/วัน';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tier.displayName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('รองรับลูกค้า: $limitText'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: tier == SubscriptionTier.free ? null : () {},
                child: Text(tier == SubscriptionTier.free ? 'แพ็กเกจปัจจุบัน' : 'อัปเกรด'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
