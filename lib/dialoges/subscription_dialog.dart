import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../utils/app_strings.dart';
import '../screens/subscription_plan_screen.dart';

class SubscriptionDialog extends StatefulWidget {
  final String? reasonMessage;

  const SubscriptionDialog({super.key, this.reasonMessage});

  static Future<void> show(BuildContext context, {String? reasonMessage}) {
    return showDialog<void>(
      context: context,
      builder: (_) => SubscriptionDialog(reasonMessage: reasonMessage),
    );
  }

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _isActivating = false;
  String? _activationStatus;
  bool _isSuccess = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleActivation(AppProvider p) async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isActivating = true;
      _activationStatus = null;
    });

    final success = await p.activatePlanWithCode(code);

    if (mounted) {
      setState(() {
        _isActivating = false;
        _isSuccess = success;
        _activationStatus = success
            ? AppStrings.get('code_activated_success', lang: p.appLanguage)
            : AppStrings.get('invalid_code_msg', lang: p.appLanguage);
      });
      if (success) {
        _codeCtrl.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final lang = p.appLanguage;
    final isBn = lang == 'bn';
    final currentPlan = p.currentPlan;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.get('subscription_section_title', lang: lang),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isBn
                                    ? "৫ ব্যাচ ও ১০ শিক্ষার্থীর উপরে প্ল্যান প্রয়োজন"
                                    : "Upgrade for more than 5 batches & 10 students",
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Reason banner if triggered by limit
              if (widget.reasonMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.reasonMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Current Status Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBn ? "আপনার বর্তমান প্যাকেজ:" : "Current Package:",
                          style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade700),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isBn ? currentPlan.nameBn : currentPlan.nameEn,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${isBn ? 'ব্যাচ সংখ্যা: ' : 'Batches: '}${p.batches.length} / ${currentPlan.isUnlimitedBatches ? (isBn ? 'সীমাহীন' : 'Unlimited') : currentPlan.batchLimit}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "${isBn ? 'শিক্ষার্থী: ' : 'Students: '}${p.students.length} / ${currentPlan.isUnlimitedStudents ? (isBn ? 'সীমাহীন' : 'Unlimited') : currentPlan.studentLimit}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (p.planExpiryDate != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        "${isBn ? 'মেয়াদ উত্তীর্ণের তারিখ: ' : 'Expires on: '}${DateFormat('dd MMM yyyy').format(p.planExpiryDate!)}",
                        style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade900),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Plans list
              Text(
                isBn ? "ওয়েবসাইট থেকে উপলব্ধ প্ল্যানসমূহ:" : "Available Plans on Website:",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Free tier card
              _buildPlanCard(
                context,
                title: isBn ? "১. ফ্রি প্যাকেজ (Free)" : "1. Free Tier",
                price: isBn ? "০ ৳ / ফ্রি" : "0 BDT / Free",
                description: isBn
                    ? "সর্বোচ্চ ৫টি ব্যাচ এবং ১০ জন শিক্ষার্থী (সম্পূর্ণ বিনামূল্যে)"
                    : "Up to 5 batches & 10 students (Free forever)",
                badge: isBn ? "ডিফল্ট" : "Default",
                isCurrent: currentPlan.id == 'free',
                color: Colors.grey.shade700,
              ),
              const SizedBox(height: 8),

              // Plan 1: 5 batches & 10 students = 30 Taka
              _buildPlanCard(
                context,
                title: isBn ? "২. স্টার্টার প্ল্যান (Starter)" : "2. Starter Plan",
                price: "30 ৳ / ${isBn ? 'মাস' : 'month'}",
                description: isBn
                    ? "৫টি ব্যাচ এবং ১০ জন শিক্ষার্থী (১ বা একাধিক মাসের জন্য কেনা যাবে)"
                    : "5 batches & 10 students (Purchase for 1 or more months)",
                badge: "30 ৳",
                isCurrent: currentPlan.id == 'starter',
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 8),

              // Plan 2: 10 batches and 20 students = 50 Taka
              _buildPlanCard(
                context,
                title: isBn ? "৩. স্ট্যান্ডার্ড প্ল্যান (Standard)" : "3. Standard Plan",
                price: "50 ৳ / ${isBn ? 'মাস' : 'month'}",
                description: isBn
                    ? "১০টি ব্যাচ এবং ২০ জন শিক্ষার্থী (জনপ্রিয় প্যাকেজ)"
                    : "10 batches & 20 students (Most popular plan)",
                badge: isBn ? "জনপ্রিয় (৫০ ৳)" : "Popular (50 ৳)",
                isCurrent: currentPlan.id == 'standard',
                color: Colors.orange.shade800,
              ),
              const SizedBox(height: 8),

              // Plan 3: Unlimited batches and students = 200 Taka
              _buildPlanCard(
                context,
                title: isBn ? "৪. আনলিমিটেড প্রো (Unlimited)" : "4. Unlimited Pro",
                price: "200 ৳ / ${isBn ? 'মাস' : 'month'}",
                description: isBn
                    ? "সীমাহীন ব্যাচ ও সীমাহীন শিক্ষার্থী (সকল ফিচারের পূর্ণ এক্সেস)"
                    : "Unlimited batches & students (Best for coaching centers)",
                badge: isBn ? "সীমাহীন (২০০ ৳)" : "Unlimited (200 ৳)",
                isCurrent: currentPlan.id == 'unlimited',
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 18),

              // Open Full Plan Page Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.launch_rounded, size: 18),
                label: Text(
                  AppStrings.get('open_full_plan_page', lang: lang),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  SubscriptionPlanScreen.navigate(context, reason: widget.reasonMessage);
                },
              ),
              const SizedBox(height: 10),

              // Website Purchase Link Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                label: Text(
                  AppStrings.get('view_plans_website', lang: lang),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isBn
                            ? "ওয়েবসাইট লিঙ্ক: https://tuitionfee.app/pricing (অথবা লোকাল ওয়েব পোর্টাল খুলুন)"
                            : "Website link: https://tuitionfee.app/pricing (Or open web portal)",
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.teal,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Activation Code Input Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('enter_activation_code', lang: lang),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: AppStrings.get('activation_code_hint', lang: lang),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isActivating ? null : () => _handleActivation(p),
                          child: _isActivating
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : Text(AppStrings.get('activate_btn', lang: lang)),
                        ),
                      ],
                    ),
                    if (_activationStatus != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _activationStatus!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
      BuildContext context, {
        required String title,
        required String price,
        required String description,
        required String badge,
        required bool isCurrent,
        required Color color,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? color : Colors.grey.shade200,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}
