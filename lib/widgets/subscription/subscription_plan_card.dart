import 'package:flutter/material.dart';
import '../../models/subscription_plan.dart';
import '../../providers/app_provider.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final AppProvider provider;
  final bool isBn;
  final SubscriptionPlan plan;
  final bool isCurrent;
  final String badgeText;
  final Color accentColor;
  final bool highlight;
  final int selectedDuration;
  final int totalPrice;
  final String formattedPrice;
  final String formattedBasePrice;
  final String formattedBatches;
  final String formattedStudents;
  final VoidCallback onSelect;

  const SubscriptionPlanCard({
    super.key,
    required this.provider,
    required this.isBn,
    required this.plan,
    required this.isCurrent,
    required this.badgeText,
    required this.accentColor,
    required this.highlight,
    required this.selectedDuration,
    required this.totalPrice,
    required this.formattedPrice,
    required this.formattedBasePrice,
    required this.formattedBatches,
    required this.formattedStudents,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = provider;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent
              ? Colors.green.shade600
              : (highlight ? accentColor : Colors.grey.shade200),
          width: isCurrent || highlight ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (highlight ? accentColor : Colors.black).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: highlight ? accentColor.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name(p.appLanguage),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: highlight ? accentColor : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        plan.description(p.appLanguage),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (badgeText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.green.shade600 : accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Price Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.isFree ? (isBn ? '০ ৳' : '0 BDT') : "$formattedPrice ৳",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: highlight ? accentColor : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selectedDuration == 1
                          ? p.tr('per_month_unit')
                          : "/ $selectedDuration${isBn ? ' মাস' : ' Months'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                if (!plan.isFree && selectedDuration > 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    "${isBn ? 'নিয়মিত: ' : 'Regular: '}$formattedBasePrice ৳${p.tr('per_month_unit')}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Features
                _buildFeatureRow(
                  icon: Icons.groups_outlined,
                  text: "${isBn ? 'ব্যাচ: ' : 'Batches: '}$formattedBatches",
                ),
                const SizedBox(height: 8),
                _buildFeatureRow(
                  icon: Icons.person_outline,
                  text: "${isBn ? 'শিক্ষার্থী: ' : 'Students: '}$formattedStudents",
                ),
                const SizedBox(height: 8),
                _buildFeatureRow(
                  icon: Icons.offline_bolt_outlined,
                  text: p.tr('offline_speed_feature'),
                ),
                const SizedBox(height: 8),
                _buildFeatureRow(
                  icon: Icons.cloud_done_outlined,
                  text: p.tr('cloud_sync_feature'),
                ),
                const SizedBox(height: 16),

                // Action Button
                if (plan.isFree) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {},
                    child: Text(
                      isCurrent
                          ? (isBn ? 'বর্তমানে সক্রিয়' : 'Currently Active')
                          : (isBn ? 'ডিফল্ট ফ্রি' : 'Default Free'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: highlight ? accentColor : const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onSelect,
                    child: Text(
                      isCurrent
                          ? (isBn ? 'মেয়াদ বাড়ান' : 'Renew / Extend')
                          : (isBn ? 'প্ল্যান নির্বাচন করুন' : 'Select Plan'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.green.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
