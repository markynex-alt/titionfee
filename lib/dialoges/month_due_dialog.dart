import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../utils/app_strings.dart';

void showMonthDueStudentsDialog(
    BuildContext context, {
      required String monthName,
      required DateTime targetDate,
      required List<Map<String, dynamic>> assignedPayments,
      required List<dynamic> students,
    }) {
  final p = Provider.of<AppProvider>(context, listen: false);
  final isBn = p.appLanguage == 'bn';
  final displayMonthName = AppStrings.formatMonth(monthName, lang: p.appLanguage);
  final formatter = NumberFormat("#,##,##0", "en_IN");
  final bool isTotalMode = monthName.toLowerCase() == 'total';

  // 1. Create a Set of existing active student IDs for fast lookup
  final activeStudentIds = students
      .map((s) => s is Map ? s['id']?.toString() : s.id?.toString())
      .where((id) => id != null && id.isNotEmpty)
      .toSet();

  // 2. Filter out payments belonging to deleted students
  final validAssignedPayments = assignedPayments.where((e) {
    final sId = e['studentId']?.toString() ?? '';
    return activeStudentIds.contains(sId);
  }).toList();

  final List<Map<String, dynamic>> monthDues = [];

  if (isTotalMode) {
    // Group valid payments by studentId to aggregate amount and collect month names
    final Map<String, Map<String, dynamic>> studentTotals = {};

    for (var payment in validAssignedPayments) {
      final studentId = payment['studentId']?.toString() ?? '';
      final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;

      String paymentMonth = '';
      if (payment['date'] != null) {
        try {
          final d = DateTime.parse(payment['date']);
          paymentMonth = DateFormat('MMM').format(d);
        } catch (_) {}
      }

      if (studentId.isNotEmpty) {
        if (!studentTotals.containsKey(studentId)) {
          studentTotals[studentId] = {
            'studentId': studentId,
            'amount': 0.0,
            'months': <String>[],
          };
        }

        studentTotals[studentId]!['amount'] =
            (studentTotals[studentId]!['amount'] as double) + amount;

        if (paymentMonth.isNotEmpty &&
            !(studentTotals[studentId]!['months'] as List<String>)
                .contains(paymentMonth)) {
          (studentTotals[studentId]!['months'] as List<String>)
              .add(paymentMonth);
        }
      }
    }

    monthDues.addAll(studentTotals.values);
  } else {
    // Filter valid payments for the specified month and year
    monthDues.addAll(validAssignedPayments.where((e) {
      final d = DateTime.parse(e['date']);
      return d.month == targetDate.month && d.year == targetDate.year;
    }));
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFBE9E7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.history,
                color: Color(0xFFFF5722),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isBn ? '$displayMonthName বকেয়া শিক্ষার্থী তালিকা' : '$monthName Due Students',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: monthDues.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 40),
                const SizedBox(height: 8),
                Text(
                  p.tr('no_due_students_msg'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: monthDues.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = monthDues[index];
              final studentId = item['studentId']?.toString() ?? '';

              // Find matching student by ID safely
              final dynamic student = students.firstWhereOrNull((s) {
                if (s is Map) {
                  return s['id']?.toString() == studentId;
                }
                return s.id?.toString() == studentId;
              });

              // Extract Student Name safely
              String studentName = 'Student #$studentId';
              if (student != null) {
                if (student is Map) {
                  studentName = student['name']?.toString() ?? studentName;
                } else {
                  try {
                    final name = (student as dynamic).name?.toString();
                    if (name != null && name.isNotEmpty) studentName = name;
                  } catch (_) {}
                }
              }

              // Extract Student Class safely across all potential field keys
              String studentClass = 'N/A';
              if (student != null) {
                if (student is Map) {
                  studentClass = student['sClass']?.toString() ??
                      student['studentClass']?.toString() ??
                      student['className']?.toString() ??
                      student['class']?.toString() ??
                      student['batch']?.toString() ??
                      'N/A';
                } else {
                  try {
                    final dynamic s = student;
                    final resolvedClass = s.sClass ??
                        s.studentClass ??
                        s.className ??
                        s.sclass ??
                        s.batch;
                    if (resolvedClass != null) {
                      studentClass = resolvedClass.toString();
                    }
                  } catch (_) {
                    try {
                      final dynamic s = student;
                      studentClass = s.class1?.toString() ?? 'N/A';
                    } catch (_) {
                      studentClass = 'N/A';
                    }
                  }
                }
              }

              final amount = item['amount'] ?? 0;
              final serialNumber = index + 1;

              // Extract months list for subtitle
              String monthText = '';
              if (isTotalMode && item['months'] != null) {
                final List<String> monthsList =
                List<String>.from(item['months']);
                if (monthsList.isNotEmpty) {
                  final formattedMonths = monthsList
                      .map((m) => AppStrings.formatMonth(m, lang: p.appLanguage))
                      .join(', ');
                  monthText = ' ($formattedMonths)';
                }
              }

              final classLabel = isBn ? 'শ্রেণী' : 'Class';
              final idLabel = isBn ? 'আইডি' : 'ID';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$serialNumber.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFFFE0B2),
                      child: Text(
                        studentName.isNotEmpty
                            ? studentName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '$classLabel: $studentClass | $idLabel: $studentId$monthText',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                trailing: Text(
                  '${p.currencySymbol}${formatter.format(amount)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(p.tr('close')),
          ),
        ],
      );
    },
  );
}