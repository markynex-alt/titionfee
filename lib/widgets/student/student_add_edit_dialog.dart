import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dialoges/subscription_dialog.dart';
import '../../models/student.dart';
import '../../providers/app_provider.dart';
import '../whatsapp/whatsapp_dialog.dart';

class StudentAddEditDialog {
  static void show(BuildContext context, {Student? student}) {
    final p = context.read<AppProvider>();

    if (student == null && !p.canAddStudent) {
      SubscriptionDialog.show(
        context,
        reasonMessage: p.tr('student_limit_msg'),
      );
      return;
    }

    final nameCtrl = TextEditingController(text: student?.name ?? '');
    final classCtrl = TextEditingController(text: student?.studentClass ?? '');
    final phoneCtrl = TextEditingController(text: student?.phone ?? '');
    final feeCtrl = TextEditingController(
      text: student != null
          ? (student.monthlyFee % 1 == 0
              ? student.monthlyFee.toInt().toString()
              : student.monthlyFee.toString())
          : '',
    );

    // Resolve initial batchId safely
    String? batchId;
    if (student != null) {
      final rawBatch = student.batchId.trim();
      final matchById = p.batches.where((b) => b.id.trim() == rawBatch).firstOrNull;
      if (matchById != null) {
        batchId = matchById.id;
      } else {
        final matchByName = p.batches
            .where((b) => b.name.trim().toLowerCase() == rawBatch.toLowerCase())
            .firstOrNull;
        if (matchByName != null) {
          batchId = matchByName.id;
        } else if (p.batches.isNotEmpty) {
          batchId = p.batches.first.id;
        } else {
          batchId = '';
        }
      }
    } else {
      if (p.batches.isNotEmpty) {
        batchId = p.batches.first.id;
      } else {
        batchId = '';
      }
    }

    final hasBatches = p.batches.isNotEmpty;
    if (hasBatches && !p.batches.any((b) => b.id == batchId)) {
      batchId = p.batches.first.id;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            student == null ? p.tr('add_new_student') : p.tr('edit_student_details'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: p.tr('student_name_label'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: classCtrl,
                  decoration: InputDecoration(
                    labelText: p.tr('student_class_label'),
                    prefixIcon: const Icon(Icons.class_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: p.tr('phone_number_optional'),
                    hintText: p.tr('optional'),
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "${p.tr('monthly_fee_label')} (${p.currencySymbol}) *",
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: hasBatches ? batchId : '',
                  decoration: InputDecoration(
                    labelText: p.tr('assign_batch_label'),
                    prefixIcon: const Icon(Icons.groups_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: !hasBatches
                      ? [
                          DropdownMenuItem(
                            value: '',
                            child: Text(p.tr('no_batches_title')),
                          )
                        ]
                      : p.batches
                          .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                          .toList(),
                  onChanged: hasBatches
                      ? (v) => setDialogState(() => batchId = v)
                      : null,
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
              onPressed: () async {
                // Phone number is NOT required!
                if (nameCtrl.text.trim().isEmpty ||
                    classCtrl.text.trim().isEmpty ||
                    feeCtrl.text.trim().isEmpty ||
                    (hasBatches && (batchId == null || batchId!.isEmpty))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(p.tr('fill_required_fields')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                final fee = double.tryParse(feeCtrl.text.trim());
                if (fee == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(p.tr('valid_fee_error')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                if (student == null && !p.canAddStudent) {
                  Navigator.pop(dialogCtx);
                  SubscriptionDialog.show(
                    context,
                    reasonMessage: p.tr('student_limit_msg'),
                  );
                  return;
                }

                Navigator.pop(dialogCtx);

                final safeBatchId = batchId ?? '';
                final isBn = p.appLanguage == 'bn';
                final studentName = nameCtrl.text.trim();
                final studentPhone = phoneCtrl.text.trim();

                if (student == null) {
                  await p.addStudent(
                    name: studentName,
                    studentClass: classCtrl.text.trim(),
                    phone: studentPhone, // optional
                    fee: fee,
                    batchId: safeBatchId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(p.tr('student_added_success').replaceAll('%s', studentName)),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        action: studentPhone.isNotEmpty
                            ? SnackBarAction(
                                label: isBn ? "ভর্তি মেসেজ" : "WhatsApp",
                                textColor: Colors.white,
                                onPressed: () {
                                  final newStudent = p.students.lastWhere(
                                    (s) => s.name == studentName,
                                    orElse: () => p.students.first,
                                  );
                                  WhatsAppDialog.show(
                                    context,
                                    student: newStudent,
                                    initialType: WhatsAppMessageType.admission,
                                  );
                                },
                              )
                            : null,
                      ),
                    );
                  }
                } else {
                  await p.updateStudent(
                    id: student.id,
                    name: studentName,
                    studentClass: classCtrl.text.trim(),
                    phone: studentPhone, // optional
                    fee: fee,
                    batchId: safeBatchId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(p.tr('student_updated_success').replaceAll('%s', studentName)),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Text(student == null ? p.tr('save') : p.tr('update')),
            ),
          ],
        ),
      ),
    );
  }
}
