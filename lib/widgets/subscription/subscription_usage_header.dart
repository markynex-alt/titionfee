import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/subscription_plan.dart';
import '../../providers/app_provider.dart';
import '../../dialoges/edit_subscription_dialog.dart';

class SubscriptionUsageHeader extends StatelessWidget {
  final AppProvider provider;
  final SubscriptionPlan currentPlan;
  final bool isBn;
  final String Function(dynamic, bool) formatNumber;

  const SubscriptionUsageHeader({
    super.key,
    required this.provider,
    required this.currentPlan,
    required this.isBn,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final p = provider;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.tr('current_plan_label'),
                    style: TextStyle(
                      color: Colors.indigo.shade100,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentPlan.name(p.appLanguage),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.tr('active_status'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? "ব্যাচ ব্যবহার" : "Batches Used",
                      style: TextStyle(fontSize: 12, color: Colors.indigo.shade200),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${formatNumber(p.batches.length, isBn)} / ${currentPlan.isUnlimitedBatches ? p.tr('unlimited') : formatNumber(currentPlan.batchLimit, isBn)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? "শিক্ষার্থী ব্যবহার" : "Students Used",
                      style: TextStyle(fontSize: 12, color: Colors.indigo.shade200),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${formatNumber(p.students.length, isBn)} / ${currentPlan.isUnlimitedStudents ? p.tr('unlimited') : formatNumber(currentPlan.studentLimit, isBn)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentPlan.isFree
                      ? (isBn ? "ভ্যালিডেশন: আজীবন মেয়াদ (Permanent)" : "Validation: Permanent (Always Free)")
                      : (p.planExpiryDate != null
                          ? "${isBn ? 'মেয়াদ উত্তীর্ণ: ' : 'Valid until: '}${DateFormat('dd MMM yyyy').format(p.planExpiryDate!)}"
                          : (isBn ? "ভ্যালিডেশন: সক্রিয়" : "Validation: Active")),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade200,
                  ),
                ),
              ),
              if (!currentPlan.isFree && p.planDaysRemaining != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.isPlanExpired
                        ? Colors.red.withValues(alpha: 0.3)
                        : (p.planDaysRemaining! <= 7
                            ? Colors.orange.withValues(alpha: 0.3)
                            : Colors.greenAccent.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    p.isPlanExpired
                        ? (isBn ? "মেয়াদ শেষ" : "Expired")
                        : (isBn ? "${p.planDaysRemaining} দিন বাকি" : "${p.planDaysRemaining}d Left"),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: p.isPlanExpired
                          ? Colors.redAccent
                          : (p.planDaysRemaining! <= 7 ? Colors.orangeAccent : Colors.greenAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              InkWell(
                onTap: () => EditSubscriptionDialog.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        isBn ? "এডিট" : "Edit",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
