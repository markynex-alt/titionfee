import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/student.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_strings.dart';
import '../whatsapp/whatsapp_dialog.dart';

class StudentFeeDialogs {
  /// Shows the fee collection dialog and offers an immediate WhatsApp receipt option
  static void showCollectFee(BuildContext context, Student student) {
    final p = context.read<AppProvider>();
    final isBn = p.appLanguage == 'bn';

    // Parse unpaid payments & deduplicate by month/year
    final rawPayments = p.paymentHistory(student.id);
    final Map<String, DateTime> unpaidMonthMap = {};
    for (final pmt in rawPayments) {
      if (pmt['status'] == 'paid') continue;
      final dateStr = pmt['date']?.toString();
      if (dateStr == null) continue;
      final d = DateTime.tryParse(dateStr);
      if (d != null) {
        final key = "${d.year}-${d.month}";
        unpaidMonthMap[key] = DateTime(d.year, d.month, 1);
      }
    }

    final payments = unpaidMonthMap.values.toList()
      ..sort((a, b) => a.compareTo(b));

    if (payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(p.tr('no_unpaid_months')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    DateTime selectedMonth = payments.first;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isBn ? "${student.name}-এর ফি গ্রহণ" : "Collect Fee for ${student.name}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${p.tr('monthly_billed')} ${p.currencySymbol} ${student.monthlyFee.toInt()}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DateTime>(
                initialValue: selectedMonth,
                decoration: InputDecoration(
                  labelText: isBn ? "বকেয়া মাস নির্বাচন করুন" : "Select Unpaid Month",
                  prefixIcon: const Icon(Icons.event_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: payments.map((d) {
                  final mName = DateFormat.MMMM().format(d);
                  final label = "${AppStrings.formatMonth(mName, lang: p.appLanguage)} ${d.year}";
                  return DropdownMenuItem(value: d, child: Text(label));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedMonth = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(p.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                p.collectFee(
                  student.id,
                  student.monthlyFee,
                  month: selectedMonth.month,
                  year: selectedMonth.year,
                );
                final monthName = DateFormat.MMMM().format(selectedMonth);
                final monthFormatted = AppStrings.formatMonth(monthName, lang: p.appLanguage);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(p.tr('fee_collected_success').replaceAll('%s', monthFormatted)),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    action: student.phone.isNotEmpty
                        ? SnackBarAction(
                            label: isBn ? "হোয়াটসঅ্যাপ রসিদ" : "WhatsApp Receipt",
                            textColor: Colors.white,
                            onPressed: () {
                              WhatsAppDialog.show(
                                context,
                                student: student,
                                initialType: WhatsAppMessageType.receipt,
                                initialReceiptData: {
                                  'month': "$monthFormatted ${selectedMonth.year}",
                                  'amount': student.monthlyFee,
                                  'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
                                },
                              );
                            },
                          )
                        : null,
                  ),
                );
              },
              child: Text(p.tr('confirm_collection')),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the assign month dialog
  static void showAssignMonth(BuildContext context, Student student) {
    final p = context.read<AppProvider>();
    final isBn = p.appLanguage == 'bn';
    final now = DateTime.now();

    int tempMonth = now.month;
    int tempYear = now.year;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isBn ? "${student.name}-এর জন্য মাস বরাদ্দ" : "Assign Month for ${student.name}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: tempMonth,
                  decoration: InputDecoration(
                    labelText: p.tr('month_label'),
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: List.generate(12, (index) {
                    final monthIndex = index + 1;
                    final mName = DateFormat.MMMM().format(DateTime(0, monthIndex));
                    return DropdownMenuItem(
                      value: monthIndex,
                      child: Text(
                        AppStrings.formatMonth(mName, lang: p.appLanguage),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                  onChanged: (v) => setDialogState(() => tempMonth = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: tempYear,
                  decoration: InputDecoration(
                    labelText: p.tr('year_label'),
                    prefixIcon: const Icon(Icons.event_note_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [now.year - 1, now.year, now.year + 1]
                      .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text(
                              y.toString(),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => tempYear = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(p.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                final assigned = p.assignMonth(
                  studentId: student.id,
                  month: tempMonth,
                  year: tempYear,
                  amount: student.monthlyFee,
                );
                final monthName = DateFormat.MMMM().format(DateTime(0, tempMonth));
                final monthFormatted = AppStrings.formatMonth(monthName, lang: p.appLanguage);
                if (assigned) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isBn
                            ? "${student.name}-এর জন্য $monthFormatted $tempYear এর ফি ধার্য করা হয়েছে"
                            : "Month assigned successfully to ${student.name}",
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isBn
                            ? "${student.name}-এর জন্য $monthFormatted $tempYear এর ফি ইতিমধ্যে নির্ধারিত রয়েছে"
                            : "Month $monthFormatted $tempYear is already assigned to ${student.name}",
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(isBn ? "ফি ধার্য করুন" : "Assign Fee"),
            ),
          ],
        ),
      ),
    );
  }
}
