import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../models/subscription_plan.dart';

class EditSubscriptionDialog extends StatefulWidget {
  const EditSubscriptionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const EditSubscriptionDialog(),
    );
  }

  @override
  State<EditSubscriptionDialog> createState() => _EditSubscriptionDialogState();
}

class _EditSubscriptionDialogState extends State<EditSubscriptionDialog> {
  late String _selectedPlanId;
  DateTime? _selectedExpiry;
  bool _isPermanent = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>();
    _selectedPlanId = p.currentPlanId;
    _selectedExpiry = p.planExpiryDate;
    if (_selectedPlanId == 'free' || _selectedExpiry == null) {
      _isPermanent = true;
    }
  }

  void _applyQuickDuration(int months) {
    setState(() {
      _isPermanent = false;
      final now = DateTime.now();
      _selectedExpiry = DateTime(now.year, now.month + months, now.day);
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final initial = _selectedExpiry != null && _selectedExpiry!.isAfter(now)
        ? _selectedExpiry!
        : now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      setState(() {
        _isPermanent = false;
        _selectedExpiry = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final p = context.read<AppProvider>();
    final isBn = p.appLanguage == 'bn';

    final effectiveExpiry = (_selectedPlanId == 'free' || _isPermanent)
        ? null
        : (_selectedExpiry ?? DateTime.now().add(const Duration(days: 30)));

    await p.updateSubscriptionManually(
      planId: _selectedPlanId,
      expiryDate: effectiveExpiry,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBn
              ? "সাবস্ক্রিপশন সফলভাবে আপডেট করা হয়েছে!"
              : "Subscription successfully updated!",
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final isBn = p.appLanguage == 'bn';
    final plans = SubscriptionPlan.defaultPlans;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_calendar_rounded,
                          color: Colors.deepPurple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn ? "সাবস্ক্রিপশন ও প্যাকেজ এডিট" : "Edit Package & Validity",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            isBn
                                ? "প্যাকেজের নাম ও মেয়াদ পরিবর্তন করুন"
                                : "Customize plan tier and validation date",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Section 1: Choose Package Name
              Text(
                isBn ? "১. প্যাকেজ নির্বাচন করুন:" : "1. Select Package Tier:",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Column(
                children: plans.map((plan) {
                  final isSelected = _selectedPlanId == plan.id;
                  final color = plan.id == 'unlimited'
                      ? Colors.deepPurple
                      : (plan.id == 'standard'
                          ? Colors.orange.shade800
                          : (plan.id == 'starter' ? Colors.teal : Colors.grey.shade700));

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPlanId = plan.id;
                        if (plan.id == 'free') {
                          _isPermanent = true;
                        } else if (_isPermanent) {
                          _isPermanent = false;
                          _selectedExpiry = DateTime.now().add(const Duration(days: 30));
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.08) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
                            color: isSelected ? color : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isBn ? plan.nameBn : plan.nameEn,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected ? color : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        plan.isFree
                                            ? (isBn ? "ফ্রি" : "Free")
                                            : "${plan.priceMonthly.round()} ৳/${isBn ? 'মাস' : 'mo'}",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${isBn ? 'ব্যাচ: ' : 'Batches: '}${plan.isUnlimitedBatches ? (isBn ? 'সীমাহীন' : 'Unlimited') : plan.batchLimit} • ${isBn ? 'শিক্ষার্থী: ' : 'Students: '}${plan.isUnlimitedStudents ? (isBn ? 'সীমাহীন' : 'Unlimited') : plan.studentLimit}",
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Section 2: Validation / Expiry Setting
              if (_selectedPlanId != 'free') ...[
                Text(
                  isBn ? "২. মেয়াদের সময়সীমা নির্ধারণ (Validation):" : "2. Set Validation / Expiry:",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),

                // Quick buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDurationChip("+1 ${isBn ? 'মাস' : 'Month'}", 1),
                    _buildDurationChip("+3 ${isBn ? 'মাস' : 'Months'}", 3),
                    _buildDurationChip("+6 ${isBn ? 'মাস' : 'Months'}", 6),
                    _buildDurationChip("+1 ${isBn ? 'বছর' : 'Year'}", 12),
                    ActionChip(
                      label: Text(
                        isBn ? "আজীবন / লাইফটাইম" : "Permanent / Lifetime",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isPermanent ? Colors.deepPurple : Colors.black87,
                        ),
                      ),
                      backgroundColor: _isPermanent ? Colors.deepPurple.shade50 : Colors.grey.shade100,
                      side: BorderSide(
                        color: _isPermanent ? Colors.deepPurple : Colors.grey.shade300,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPermanent = true;
                          _selectedExpiry = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Expiry Date Display & Date Picker Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: Colors.deepOrange, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? "মেয়াদ উত্তীর্ণের তারিখ" : "Active Validation Until",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isPermanent
                                  ? (isBn ? "আজীবন মেয়াদ (Permanent)" : "Lifetime / Permanent")
                                  : (_selectedExpiry != null
                                      ? DateFormat('dd MMMM yyyy').format(_selectedExpiry!)
                                      : (isBn ? "তারিখ নির্ধারণ করুন" : "Pick Date")),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: Text(isBn ? "তারিখ নির্বাচন" : "Pick Date"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.deepOrange,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _pickCustomDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Save Action Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  _isSaving
                      ? (isBn ? "সংরক্ষণ করা হচ্ছে..." : "Saving...")
                      : (isBn ? "পরিবর্তনগুলো সংরক্ষণ করুন" : "Save Changes"),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isSaving ? null : _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip(String label, int months) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month + months, now.day);
    final isSelected = !_isPermanent &&
        _selectedExpiry != null &&
        _selectedExpiry!.year == target.year &&
        _selectedExpiry!.month == target.month &&
        _selectedExpiry!.day == target.day;

    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.deepPurple : Colors.black87,
        ),
      ),
      backgroundColor: isSelected ? Colors.deepPurple.shade50 : Colors.grey.shade100,
      side: BorderSide(
        color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
      ),
      onPressed: () => _applyQuickDuration(months),
    );
  }
}
