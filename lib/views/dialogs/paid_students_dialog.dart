import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../utils/app_strings.dart';

void showPaidStudentsDialog(
    BuildContext context, {
      required String title,
      required List<Map<String, dynamic>> paidPayments,
      required List dynamicStudents,
      DateTime? filterDate,
    }) {
  final p = Provider.of<AppProvider>(context, listen: false);
  final isBn = p.appLanguage == 'bn';
  final displayTitle = AppStrings.formatMonth(title, lang: p.appLanguage);

  final filteredPayments = paidPayments.where((e) {
    if (filterDate == null) return true;
    final d = DateTime.parse(e['date']);
    return d.month == filterDate.month && d.year == filterDate.year;
  }).toList();

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isBn ? '$displayTitle পরিশোধিত শিক্ষার্থী তালিকা' : '$title Payments',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: filteredPayments.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              p.tr('no_paid_students_msg'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            itemCount: filteredPayments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final payment = filteredPayments[index];
              final studentId = payment['studentId']?.toString();

              final matchingStudents = dynamicStudents.where(
                    (s) => s.id?.toString() == studentId,
              );

              final student = matchingStudents.isNotEmpty ? matchingStudents.first : null;
              final studentName = student?.name ?? (isBn ? 'শিক্ষার্থী আইডি: $studentId' : 'Student ID: $studentId');
              final date = DateTime.parse(payment['date']);
              final dateFormatted = DateFormat('dd MMM yyyy').format(date);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  isBn ? 'পরিশোধের তারিখ: $dateFormatted' : 'Paid on $dateFormatted',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Text(
                  '${p.currencySymbol}${payment['amount']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(p.tr('close')),
          ),
        ],
      );
    },
  );
}