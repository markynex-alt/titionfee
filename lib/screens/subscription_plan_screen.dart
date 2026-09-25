import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../models/subscription_plan.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  final String? initialReason;

  const SubscriptionPlanScreen({super.key, this.initialReason});

  static Future<void> navigate(BuildContext context, {String? reason}) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionPlanScreen(initialReason: reason),
      ),
    );
  }

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  int _selectedDuration = 1; // 1, 3, 6, 12 months
  final TextEditingController _codeCtrl = TextEditingController();
  bool _isActivating = false;
  String? _activationStatus;
  bool _isSuccess = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  int _calculateDiscountedPrice(double baseMonthlyPrice, int months) {
    if (baseMonthlyPrice <= 0) return 0;
    final total = baseMonthlyPrice * months;
    if (months == 3) {
      return (total * 0.95).round();
    } else if (months == 6) {
      return (total * 0.90).round();
    } else if (months == 12) {
      return (total * 0.80).round();
    }
    return total.round();
  }

  String _formatNumber(int number, bool isBn) {
    final s = number.toString();
    if (!isBn) return s;
    const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var res = s;
    for (int i = 0; i < 10; i++) {
      res = res.replaceAll(enDigits[i], bnDigits[i]);
    }
    return res;
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
            ? p.tr('code_activated_success')
            : p.tr('invalid_code_msg');
      });
      if (success) {
        _codeCtrl.clear();
      }
    }
  }

  void _showWebsitePurchaseDialog(BuildContext context, AppProvider p, SubscriptionPlan plan) {
    final isBn = p.appLanguage == 'bn';
    final months = _selectedDuration;
    final totalPrice = _calculateDiscountedPrice(plan.priceMonthly, months);
    final formattedPrice = _formatNumber(totalPrice, isBn);
    final formattedMonths = _formatNumber(months, isBn);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.deepPurple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? plan.nameBn : plan.nameEn,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        Text(
                          isBn
                              ? "$formattedMonths মাসের জন্য: $formattedPrice ৳"
                              : "Duration: $months Month(s) • Total: $totalPrice BDT",
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.tr('order_on_website_desc'),
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildChip("bKash", const Color(0xFFE2136E)),
                        _buildChip("Nagad", const Color(0xFFF7941D)),
                        _buildChip("Rocket", const Color(0xFF8C3494)),
                        _buildChip("Bank Cards", const Color(0xFF1E293B)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(
                  p.tr('copy_website_link'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: "https://tuitionfee.app/pricing"));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(p.tr('website_link_copied')),
                      backgroundColor: Colors.teal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final isBn = p.appLanguage == 'bn';
    final currentPlan = p.currentPlan;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          p.tr('subscription_plans_pricing'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                final nextLang = isBn ? 'en' : 'bn';
                p.setAppLanguage(nextLang);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isBn ? Colors.green.shade50 : Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isBn ? Colors.green.shade300 : Colors.indigo.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 16,
                      color: isBn ? Colors.green.shade800 : Colors.indigo.shade800,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isBn ? "বাংলা" : "EN",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isBn ? Colors.green.shade800 : Colors.indigo.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth >= 960;
          final isMedium = constraints.maxWidth >= 600 && constraints.maxWidth < 960;
          final horizontalPadding = isLarge ? 48.0 : (isMedium ? 28.0 : 16.0);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Warning banner if redirected due to quota limit
                    if (widget.initialReason != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.initialReason!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Top Active Status Card
                    _buildActiveQuotaCard(p, isBn, currentPlan),
                    const SizedBox(height: 24),

                    // Duration Selector Section
                    _buildDurationSelector(p, isBn),
                    const SizedBox(height: 20),

                    // Responsive Pricing Cards Grid
                    _buildResponsivePricingGrid(p, isBn, currentPlan, isLarge, isMedium),
                    const SizedBox(height: 28),

                    // Free Tier & Activation License Section
                    _buildActivationSection(p, isBn),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- ACTIVE QUOTA CARD ----------------
  Widget _buildActiveQuotaCard(AppProvider p, bool isBn, SubscriptionPlan currentPlan) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, const Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade900.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.tr('active_plan'),
                        style: TextStyle(fontSize: 12, color: Colors.indigo.shade200),
                      ),
                      Text(
                        isBn ? currentPlan.nameBn : currentPlan.nameEn,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p.tr('current_plan_badge'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF451A03),
                  ),
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
                      "${_formatNumber(p.batches.length, isBn)} / ${currentPlan.isUnlimitedBatches ? p.tr('unlimited') : _formatNumber(currentPlan.batchLimit, isBn)}",
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
                      "${_formatNumber(p.students.length, isBn)} / ${currentPlan.isUnlimitedStudents ? p.tr('unlimited') : _formatNumber(currentPlan.studentLimit, isBn)}",
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
          if (p.planExpiryDate != null) ...[
            const SizedBox(height: 12),
            Text(
              "${isBn ? 'মেয়াদ উত্তীর্ণের তারিখ: ' : 'Expiry Date: '}${DateFormat('dd MMM yyyy').format(p.planExpiryDate!)}",
              style: TextStyle(fontSize: 12, color: Colors.amber.shade300),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- DURATION SELECTOR ----------------
  Widget _buildDurationSelector(AppProvider p, bool isBn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.tr('plan_duration'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDurationChip(1, p.tr('month_1'), null),
              const SizedBox(width: 8),
              _buildDurationChip(3, p.tr('month_3'), p.tr('save_5_pct')),
              const SizedBox(width: 8),
              _buildDurationChip(6, p.tr('month_6'), p.tr('save_10_pct')),
              const SizedBox(width: 8),
              _buildDurationChip(12, p.tr('month_12'), p.tr('save_20_pct')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationChip(int months, String label, String? discount) {
    final isSelected = _selectedDuration == months;
    return InkWell(
      onTap: () => setState(() => _selectedDuration = months),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.deepPurple.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            if (discount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  discount,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------- RESPONSIVE PRICING GRID ----------------
  Widget _buildResponsivePricingGrid(
      AppProvider p,
      bool isBn,
      SubscriptionPlan currentPlan,
      bool isLarge,
      bool isMedium,
      ) {
    final freePlan = SubscriptionPlan.defaultPlans.firstWhere((x) => x.id == 'free');
    final starterPlan = SubscriptionPlan.defaultPlans.firstWhere((x) => x.id == 'starter');
    final standardPlan = SubscriptionPlan.defaultPlans.firstWhere((x) => x.id == 'standard');
    final unlimitedPlan = SubscriptionPlan.defaultPlans.firstWhere((x) => x.id == 'unlimited');

    final cards = [
      _buildCardWidget(
        p: p,
        isBn: isBn,
        plan: freePlan,
        isCurrent: currentPlan.id == freePlan.id,
        badgeText: p.tr('free_badge'),
        accentColor: const Color(0xFF475569),
        highlight: false,
      ),
      _buildCardWidget(
        p: p,
        isBn: isBn,
        plan: starterPlan,
        isCurrent: currentPlan.id == starterPlan.id,
        badgeText: "30 ৳",
        accentColor: Colors.blue.shade700,
        highlight: false,
      ),
      _buildCardWidget(
        p: p,
        isBn: isBn,
        plan: standardPlan,
        isCurrent: currentPlan.id == standardPlan.id,
        badgeText: p.tr('popular_badge'),
        accentColor: Colors.deepOrange.shade600,
        highlight: true,
      ),
      _buildCardWidget(
        p: p,
        isBn: isBn,
        plan: unlimitedPlan,
        isCurrent: currentPlan.id == unlimitedPlan.id,
        badgeText: p.tr('best_value_badge'),
        accentColor: Colors.deepPurple,
        highlight: false,
      ),
    ];

    if (isLarge) {
      // 4 columns on wide displays
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cards
            .map((c) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: c,
          ),
        ))
            .toList(),
      );
    } else if (isMedium) {
      // 2x2 grid on tablets
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.only(right: 6), child: cards[0])),
              Expanded(child: Padding(padding: const EdgeInsets.only(left: 6), child: cards[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.only(right: 6), child: cards[2])),
              Expanded(child: Padding(padding: const EdgeInsets.only(left: 6), child: cards[3])),
            ],
          ),
        ],
      );
    } else {
      // Single column on phones
      return Column(
        children: cards
            .map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: c,
        ))
            .toList(),
      );
    }
  }

  // ---------------- PLAN CARD ITEM ----------------
  Widget _buildCardWidget({
    required AppProvider p,
    required bool isBn,
    required SubscriptionPlan plan,
    required bool isCurrent,
    required String badgeText,
    required Color accentColor,
    required bool highlight,
  }) {
    final months = _selectedDuration;
    final totalPrice = _calculateDiscountedPrice(plan.priceMonthly, months);
    final formattedPrice = _formatNumber(totalPrice, isBn);
    final formattedBasePrice = _formatNumber(plan.priceMonthly.round(), isBn);
    final formattedBatches = plan.isUnlimitedBatches
        ? p.tr('unlimited')
        : _formatNumber(plan.batchLimit, isBn);
    final formattedStudents = plan.isUnlimitedStudents
        ? p.tr('unlimited')
        : _formatNumber(plan.studentLimit, isBn);

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
                Flexible(
                  child: Text(
                    isBn ? plan.nameBn : plan.nameEn,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: highlight ? accentColor : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.green.shade100
                        : accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCurrent ? (isBn ? 'সক্রিয়' : 'ACTIVE') : badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.green.shade800 : accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price Display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.isFree ? (isBn ? '০ ৳' : '0 ৳') : "$formattedPrice ৳",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: highlight ? accentColor : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plan.isFree
                          ? (isBn ? '/ চিরকাল ফ্রি' : '/ forever')
                          : (months == 1
                          ? (isBn ? '/ মাস' : '/ month')
                          : (isBn ? " ($months মাসে)" : " ($months mo)")),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                if (!plan.isFree && months > 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    "${isBn ? 'মাসিক ভিত্তি: ' : 'Base rate: '}$formattedBasePrice ৳",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Features list
                _buildFeatureRow(
                  icon: Icons.group_work_outlined,
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
                    onPressed: () => _showWebsitePurchaseDialog(context, p, plan),
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

  // ---------------- ACTIVATION CODE SECTION ----------------
  Widget _buildActivationSection(AppProvider p, bool isBn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.vpn_key_rounded, color: Colors.deepPurple, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.tr('have_activation_code'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      p.tr('enter_activation_code'),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: p.tr('activation_code_hint'),
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isActivating ? null : () => _handleActivation(p),
                child: _isActivating
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : Text(
                  p.tr('activate_btn'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          if (_activationStatus != null) ...[
            const SizedBox(height: 10),
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
    );
  }
}
