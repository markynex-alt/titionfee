import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student.dart';
import '../../providers/app_provider.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final String batchName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssignMonth;
  final VoidCallback onCollectFee;
  final VoidCallback onWhatsApp;

  const StudentCard({
    super.key,
    required this.student,
    required this.batchName,
    required this.onEdit,
    required this.onDelete,
    required this.onAssignMonth,
    required this.onCollectFee,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final s = student;
    final isBn = context.watch<AppProvider>().appLanguage == 'bn';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.deepPurple.shade50,
          child: Text(
            s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          s.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${isBn ? 'শ্রেণি: ' : 'Class '}${s.studentClass}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (s.phone.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone, size: 10, color: Colors.green),
                          const SizedBox(width: 2),
                          Text(
                            s.phone,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${isBn ? 'ব্যাচ: ' : 'Batch: '}$batchName",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Text(
                    "৳ ${s.monthlyFee.toInt()}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 21),
              tooltip: isBn ? 'হোয়াটসঅ্যাপ মেসেজ' : 'WhatsApp Message',
              onPressed: onWhatsApp,
            ),
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (v) {
                if (v == 'whatsapp') {
                  onWhatsApp();
                } else if (v == 'edit') {
                  onEdit();
                } else if (v == 'delete') {
                  onDelete();
                } else if (v == 'assign') {
                  onAssignMonth();
                } else if (v == 'collect') {
                  onCollectFee();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'whatsapp',
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF25D366)),
                      const SizedBox(width: 8),
                      Text(isBn ? 'হোয়াটসঅ্যাপ নোটিশ' : 'WhatsApp Notice'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'collect',
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(isBn ? 'ফি গ্রহণ করুন' : 'Collect Fee'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'assign',
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(isBn ? 'মাস বরাদ্দ করুন' : 'Assign Month'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(isBn ? 'সম্পাদনা' : 'Edit'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        isBn ? 'মুছে ফেলুন' : 'Delete',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
