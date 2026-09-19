import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showPaidStudentsDialog(
    BuildContext context, {
      required String title,
      required List<Map<String, dynamic>> paidPayments,
      required List dynamicStudents,
      DateTime? filterDate,
    }) {
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
                '$title Payments',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: filteredPayments.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No paid records found for this period.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
              final studentName = student?.name ?? 'Student ID: $studentId';
              final date = DateTime.parse(payment['date']);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Paid on ${DateFormat('dd MMM yyyy').format(date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Text(
                  '৳${payment['amount']}',
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
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}