import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tuition_fee/providers/app_provider.dart';
import 'package:tuition_fee/utils/app_colors.dart';
import 'package:tuition_fee/utils/formatters.dart';
import 'package:tuition_fee/dialoges/month_due_dialog.dart';
import 'package:tuition_fee/views/dialogs/paid_students_dialog.dart';
import 'package:tuition_fee/views/home/widgets/grid_tile_card.dart';
import 'package:tuition_fee/views/home/widgets/recent_fee_card.dart';
import 'package:tuition_fee/views/home/widgets/sticky_header.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final now = DateTime.now();

    final activeStudentIds = p.students
        .map((s) => s.id)
        .where((id) => id.isNotEmpty)
        .toSet();

    final previousMonthDate = DateTime(now.year, now.month - 1, 1);
    final doublePreviousMonthDate = DateTime(now.year, now.month - 2, 1);

    final previousMonthName = DateFormat('MMM').format(previousMonthDate);
    final doublePreviousMonthName = DateFormat('MMM').format(doublePreviousMonthDate);

    final paid = <Map<String, dynamic>>[];
    final assigned = <Map<String, dynamic>>[];

    double totalIncome = 0.0;
    double totalDue = 0.0;
    double monthPaidAmount = 0.0;
    double prevMonthPaidAmount = 0.0;
    double doublePrevMonthPaidAmount = 0.0;
    double prevMonthDueAmount = 0.0;
    double doublePrevMonthDueAmount = 0.0;

    // Single pass over payments for peak load performance
    for (final e in p.paymentBox.values) {
      if (e is! Map) continue;
      final studentId = e['studentId']?.toString() ?? '';
      if (!activeStudentIds.contains(studentId)) continue;

      final m = Map<String, dynamic>.from(e);
      final amt = (m['amount'] as num?)?.toDouble() ?? 0.0;
      final status = m['status']?.toString();

      DateTime? d;
      try {
        if (m['date'] != null) d = DateTime.parse(m['date']);
      } catch (_) {}

      if (status == 'paid') {
        paid.add(m);
        totalIncome += amt;
        if (d != null) {
          if (d.month == now.month && d.year == now.year) {
            monthPaidAmount += amt;
          } else if (d.month == previousMonthDate.month && d.year == previousMonthDate.year) {
            prevMonthPaidAmount += amt;
          } else if (d.month == doublePreviousMonthDate.month && d.year == doublePreviousMonthDate.year) {
            doublePrevMonthPaidAmount += amt;
          }
        }
      } else if (status == 'assigned') {
        assigned.add(m);
        totalDue += amt;
        if (d != null) {
          if (d.month == previousMonthDate.month && d.year == previousMonthDate.year) {
            prevMonthDueAmount += amt;
          } else if (d.month == doublePreviousMonthDate.month && d.year == doublePreviousMonthDate.year) {
            doublePrevMonthDueAmount += amt;
          }
        }
      }
    }

    // Sort recent feeds chronologically descending
    paid.sort((a, b) {
      final da = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    assigned.sort((a, b) {
      final da = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: HomeStickyHeader(minHeight: 128, maxHeight: 148),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      GridTileCard(
                        title: 'Students',
                        subtitle: '${p.students.length} registered',
                        icon: Icons.school,
                        iconBgColor: AppColors.primaryIconBg,
                        cardBgColor: AppColors.primaryTileBg,
                        onTap: () => onNavigate?.call(2),
                      ),
                      GridTileCard(
                        title: 'Batches',
                        subtitle: '${p.batches.length} active',
                        icon: Icons.groups,
                        iconBgColor: const Color(0xFFFF9800),
                        cardBgColor: const Color(0xFFFFF3E0),
                        onTap: () => onNavigate?.call(1),
                      ),
                      GridTileCard(
                        title: '$previousMonthName Due',
                        subtitle: Formatters.formatCurrency(prevMonthDueAmount),
                        icon: Icons.history,
                        iconBgColor: const Color(0xFFFF5722),
                        cardBgColor: const Color(0xFFFBE9E7),
                        onTap: () => showMonthDueStudentsDialog(
                          context,
                          monthName: previousMonthName,
                          targetDate: previousMonthDate,
                          assignedPayments: assigned,
                          students: p.students,
                        ),
                      ),
                      GridTileCard(
                        title: '$doublePreviousMonthName Due',
                        subtitle: Formatters.formatCurrency(doublePrevMonthDueAmount),
                        icon: Icons.history_toggle_off_rounded,
                        iconBgColor: AppColors.warningIconBg,
                        cardBgColor: AppColors.warningTileBg,
                        onTap: () => showMonthDueStudentsDialog(
                          context,
                          monthName: doublePreviousMonthName,
                          targetDate: doublePreviousMonthDate,
                          assignedPayments: assigned,
                          students: p.students,
                        ),
                      ),
                      GridTileCard(
                        title: 'Total Due',
                        subtitle: Formatters.formatCurrency(totalDue),
                        icon: Icons.warning_amber_rounded,
                        iconBgColor: AppColors.warningIconBg,
                        cardBgColor: AppColors.warningTileBg,
                        onTap: () => showMonthDueStudentsDialog(
                          context,
                          monthName: 'Total',
                          targetDate: now,
                          assignedPayments: assigned,
                          students: p.students,
                        ),
                      ),
                      GridTileCard(
                        title: 'This Month Paid',
                        subtitle: Formatters.formatCurrency(monthPaidAmount),
                        icon: Icons.trending_up,
                        iconBgColor: const Color(0xFF00BCD4),
                        cardBgColor: const Color(0xE1E0F7FA),
                        onTap: () => showPaidStudentsDialog(
                          context,
                          title: 'This Month',
                          paidPayments: paid,
                          dynamicStudents: p.students,
                          filterDate: now,
                        ),
                      ),
                      GridTileCard(
                        title: '$previousMonthName Paid',
                        subtitle: Formatters.formatCurrency(prevMonthPaidAmount),
                        icon: Icons.verified_outlined,
                        iconBgColor: AppColors.successIconBg,
                        cardBgColor: AppColors.successTileBg,
                        onTap: () => showPaidStudentsDialog(
                          context,
                          title: previousMonthName,
                          paidPayments: paid,
                          dynamicStudents: p.students,
                          filterDate: previousMonthDate,
                        ),
                      ),
                      GridTileCard(
                        title: '$doublePreviousMonthName Paid',
                        subtitle: Formatters.formatCurrency(doublePrevMonthPaidAmount),
                        icon: Icons.task_alt,
                        iconBgColor: const Color(0xFF2E7D32),
                        cardBgColor: const Color(0xFFDCEDC8),
                        onTap: () => showPaidStudentsDialog(
                          context,
                          title: doublePreviousMonthName,
                          paidPayments: paid,
                          dynamicStudents: p.students,
                          filterDate: doublePreviousMonthDate,
                        ),
                      ),
                      GridTileCard(
                        title: 'Overall Paid',
                        subtitle: Formatters.formatCurrency(totalIncome),
                        icon: Icons.check_circle_outline,
                        iconBgColor: AppColors.headerGradientStart,
                        cardBgColor: const Color(0xFFE8EAF6),
                        onTap: () => showPaidStudentsDialog(
                          context,
                          title: 'Overall',
                          paidPayments: paid,
                          dynamicStudents: p.students,
                          filterDate: null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Recent Paid Fees',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigate?.call(3),
                        child: const Text('View All', style: TextStyle(color: Colors.deepPurple)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (paid.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text("No fees collected yet", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ...paid.take(3).map((e) {
                      DateTime? d;
                      try {
                        d = DateTime.parse(e['date']);
                      } catch (_) {}
                      final dateStr = d != null ? '${d.day}/${d.month}/${d.year}' : 'N/A';
                      return RecentFeeCard(
                        title: 'Student ID: ${e['studentId']}',
                        dateText: dateStr,
                        amount: '${p.currencySymbol} ${e['amount']}',
                        badgeText: 'Paid',
                        badgeColor: Colors.purple.shade50,
                        badgeTextColor: Colors.purple,
                        iconBg: const Color(0xFFF0EFFF),
                      );
                    }),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Recent Due Fees',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigate?.call(3),
                        child: const Text('View All', style: TextStyle(color: Colors.deepPurple)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (assigned.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text("No fees currently due", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ...assigned.take(3).map((e) {
                      DateTime? d;
                      try {
                        d = DateTime.parse(e['date']);
                      } catch (_) {}
                      final dateStr = d != null ? '${d.day}/${d.month}/${d.year}' : 'N/A';
                      return RecentFeeCard(
                        title: 'Student ID: ${e['studentId']}',
                        dateText: dateStr,
                        amount: '${p.currencySymbol} ${e['amount']}',
                        badgeText: 'Due',
                        badgeColor: Colors.orange.shade50,
                        badgeTextColor: Colors.orange.shade800,
                        iconBg: const Color(0xFFFFF3E0),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}