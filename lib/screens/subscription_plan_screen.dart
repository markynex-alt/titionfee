import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subscription_plan.dart';
import '../providers/app_provider.dart';
import '../widgets/subscription/subscription_activation_card.dart';
import '../widgets/subscription/subscription_duration_selector.dart';
import '../widgets/subscription/subscription_plan_card.dart';
import '../widgets/subscription/subscription_usage_header.dart';
import '../widgets/subscription/website_purchase_sheet.dart';

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

  String _formatNumber(dynamic number, bool isBn) {
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

    final result = await p.verifyAndActivateLicense(code);

    if (mounted) {
      setState(() {
        _isActivating = false;
        _isSuccess = result.isValid;
        _activationStatus = result.message;
      });
      if (result.isValid) {
        _codeCtrl.clear();
      }
    }
  }

  void _onSelectPlan(BuildContext context, AppProvider p, SubscriptionPlan plan) {
    final isBn = p.appLanguage == 'bn';
    final months = _selectedDuration;
    final totalPrice = _calculateDiscountedPrice(plan.priceMonthly, months);
    final formattedPrice = _formatNumber(totalPrice, isBn);
    final formattedMonths = _formatNumber(months, isBn);

    WebsitePurchaseSheet.show(
      context,
      provider: p,
      plan: plan,
      selectedDuration: months,
      totalPrice: totalPrice,
      formattedPrice: formattedPrice,
      formattedMonths: formattedMonths,
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
                    SubscriptionUsageHeader(
                      provider: p,
                      currentPlan: currentPlan,
                      isBn: isBn,
                      formatNumber: _formatNumber,
                    ),
                    const SizedBox(height: 24),

                    // Duration Selector Section
                    SubscriptionDurationSelector(
                      provider: p,
                      isBn: isBn,
                      selectedDuration: _selectedDuration,
                      onSelectDuration: (dur) => setState(() => _selectedDuration = dur),
                    ),
                    const SizedBox(height: 20),

                    // Responsive Pricing Cards Grid
                    _buildResponsivePricingGrid(p, isBn, currentPlan, isLarge, isMedium),
                    const SizedBox(height: 28),

                    // Free Tier & Activation License Section
                    SubscriptionActivationCard(
                      provider: p,
                      isBn: isBn,
                      codeController: _codeCtrl,
                      isActivating: _isActivating,
                      activationStatus: _activationStatus,
                      isSuccess: _isSuccess,
                      onActivate: () => _handleActivation(p),
                    ),
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

  // ---------------- RESPONSIVE PRICING GRID ----------------
  Widget _buildResponsivePricingGrid(
    AppProvider p,
    bool isBn,
    SubscriptionPlan currentPlan,
    bool isLarge,
    bool isMedium,
  ) {
    final plans = SubscriptionPlan.defaultPlans;

    final cards = [
      _buildCard(p, isBn, plans[0], currentPlan.id == plans[0].id, p.tr('free_tier_badge'), Colors.grey.shade600, false),
      _buildCard(p, isBn, plans[1], currentPlan.id == plans[1].id, isBn ? 'জনপ্রিয়' : 'Popular', Colors.teal, false),
      _buildCard(p, isBn, plans[2], currentPlan.id == plans[2].id, isBn ? 'সেরা মান' : 'Best Value', Colors.deepPurple, true),
      _buildCard(p, isBn, plans[3], currentPlan.id == plans[3].id, isBn ? 'সর্বোচ্চ' : 'Unlimited', Colors.amber.shade800, false),
    ];

    if (isLarge) {
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

  Widget _buildCard(
    AppProvider p,
    bool isBn,
    SubscriptionPlan plan,
    bool isCurrent,
    String badgeText,
    Color accentColor,
    bool highlight,
  ) {
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

    return SubscriptionPlanCard(
      provider: p,
      isBn: isBn,
      plan: plan,
      isCurrent: isCurrent,
      badgeText: badgeText,
      accentColor: accentColor,
      highlight: highlight,
      selectedDuration: months,
      totalPrice: totalPrice,
      formattedPrice: formattedPrice,
      formattedBasePrice: formattedBasePrice,
      formattedBatches: formattedBatches,
      formattedStudents: formattedStudents,
      onSelect: () => _onSelectPlan(context, p, plan),
    );
  }
}
