import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/student.dart';
import '../../providers/app_provider.dart';
import '../../services/whatsapp_service.dart';
import '../../utils/app_strings.dart';

enum WhatsAppMessageType {
  admission,
  dueFee,
  receipt,
  exam,
}

class WhatsAppDialog extends StatefulWidget {
  final Student student;
  final WhatsAppMessageType initialType;
  final Map<String, dynamic>? initialReceiptData;

  const WhatsAppDialog({
    super.key,
    required this.student,
    this.initialType = WhatsAppMessageType.dueFee,
    this.initialReceiptData,
  });

  static Future<void> show(
    BuildContext context, {
    required Student student,
    WhatsAppMessageType initialType = WhatsAppMessageType.dueFee,
    Map<String, dynamic>? initialReceiptData,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => WhatsAppDialog(
        student: student,
        initialType: initialType,
        initialReceiptData: initialReceiptData,
      ),
    );
  }

  @override
  State<WhatsAppDialog> createState() => _WhatsAppDialogState();
}

class _WhatsAppDialogState extends State<WhatsAppDialog> {
  late WhatsAppMessageType _currentType;
  late TextEditingController _phoneCtrl;
  late TextEditingController _messageCtrl;

  // Exam specific controllers
  final TextEditingController _examSubjectCtrl = TextEditingController(text: 'General Science');
  final TextEditingController _examDateCtrl = TextEditingController();
  final TextEditingController _examTimeCtrl = TextEditingController(text: '10:00 AM');

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _phoneCtrl = TextEditingController(text: widget.student.phone);
    _messageCtrl = TextEditingController();

    final now = DateTime.now();
    _examDateCtrl.text = DateFormat('dd MMM yyyy').format(now.add(const Duration(days: 3)));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateCurrentTemplate();
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    _examSubjectCtrl.dispose();
    _examDateCtrl.dispose();
    _examTimeCtrl.dispose();
    super.dispose();
  }

  void _generateCurrentTemplate() {
    final p = context.read<AppProvider>();
    final isBn = p.appLanguage == 'bn';
    final s = widget.student;
    final batchName = p.batchNameById(s.batchId);
    final orgName = p.organizationName;
    final contact = p.contactPhone;

    String msg = '';

    switch (_currentType) {
      case WhatsAppMessageType.admission:
        msg = WhatsAppService.getAdmissionMessage(
          orgName: orgName,
          contactPhone: contact,
          studentName: s.name,
          studentId: s.id,
          studentClass: s.studentClass,
          batchName: batchName,
          monthlyFee: s.monthlyFee,
          isBn: isBn,
        );
        break;

      case WhatsAppMessageType.dueFee:
        final rawHistory = p.paymentHistory(s.id);
        final unpaidList = <String>[];
        double totalDue = 0.0;

        for (final item in rawHistory) {
          if (item['status'] != 'paid') {
            final dateStr = item['date']?.toString();
            if (dateStr != null) {
              final d = DateTime.tryParse(dateStr);
              if (d != null) {
                final monthName = DateFormat.MMMM().format(d);
                final formatted = "${AppStrings.formatMonth(monthName, lang: p.appLanguage)} ${d.year}";
                unpaidList.add(formatted);
                totalDue += (item['amount'] as num?)?.toDouble() ?? s.monthlyFee;
              }
            }
          }
        }

        final unpaidStr = unpaidList.isEmpty
            ? (isBn ? "চলতি মাস" : "Current Month")
            : unpaidList.join(', ');
        if (totalDue == 0.0) totalDue = s.monthlyFee;

        msg = WhatsAppService.getDueFeeMessage(
          orgName: orgName,
          contactPhone: contact,
          studentName: s.name,
          studentId: s.id,
          unpaidMonths: unpaidStr,
          totalDue: totalDue,
          isBn: isBn,
        );
        break;

      case WhatsAppMessageType.receipt:
        String monthPaid = isBn ? "চলতি মাস" : "Current Month";
        double amount = s.monthlyFee;
        String dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

        if (widget.initialReceiptData != null) {
          final data = widget.initialReceiptData!;
          monthPaid = data['month']?.toString() ?? monthPaid;
          amount = (data['amount'] as num?)?.toDouble() ?? amount;
          dateStr = data['date']?.toString() ?? dateStr;
        }

        msg = WhatsAppService.getFeeReceiptMessage(
          orgName: orgName,
          contactPhone: contact,
          studentName: s.name,
          studentId: s.id,
          monthPaid: monthPaid,
          amount: amount,
          dateFormatted: dateStr,
          isBn: isBn,
        );
        break;

      case WhatsAppMessageType.exam:
        msg = WhatsAppService.getExamNoticeMessage(
          orgName: orgName,
          contactPhone: contact,
          studentOrBatch: "$batchName (${s.name})",
          subject: _examSubjectCtrl.text.trim(),
          examDate: _examDateCtrl.text.trim(),
          examTime: _examTimeCtrl.text.trim(),
          isBn: isBn,
        );
        break;
    }

    setState(() {
      _messageCtrl.text = msg;
    });
  }

  Future<void> _handleSend() async {
    final phone = _phoneCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    final p = context.read<AppProvider>();
    final isBn = p.appLanguage == 'bn';

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? "অনুগ্রহ করে শিক্ষার্থীর ফোন নম্বর দিন" : "Please enter student's phone number"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? "মেসেজ খালি থাকতে পারে না" : "Message cannot be empty"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await WhatsAppService.sendMessage(phone: phone, message: message);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn
                ? "হোয়াটসঅ্যাপ অ্যাপ খুলতে সমস্যা হয়েছে। ফোনে হোয়াটসঅ্যাপ ইনস্টল আছে কিনা যাচাই করুন।"
                : "Could not launch WhatsApp. Please check if WhatsApp is installed.",
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final isBn = p.appLanguage == 'bn';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? "হোয়াটসঅ্যাপ নোটিফিকেশন" : "Send WhatsApp Notification",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "${widget.student.name} • ${p.batchNameById(widget.student.batchId)}",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Category Selector Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTypeChip(
                      type: WhatsAppMessageType.dueFee,
                      label: isBn ? "বকেয়া ফি" : "Due Fee",
                      icon: Icons.notifications_active_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeChip(
                      type: WhatsAppMessageType.receipt,
                      label: isBn ? "ফি রসিদ" : "Fee Receipt",
                      icon: Icons.receipt_long_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeChip(
                      type: WhatsAppMessageType.admission,
                      label: isBn ? "ভর্তি তথ্য" : "Admission",
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeChip(
                      type: WhatsAppMessageType.exam,
                      label: isBn ? "পরীক্ষার নোটিশ" : "Exam Schedule",
                      icon: Icons.assignment_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Student WhatsApp Number
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isBn ? "শিক্ষার্থীর হোয়াটসঅ্যাপ নম্বর *" : "Student WhatsApp Number *",
                  hintText: "01XXXXXXXXX",
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF25D366)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // Exam-specific fields if exam type is selected
              if (_currentType == WhatsAppMessageType.exam) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _examSubjectCtrl,
                        onChanged: (_) => _generateCurrentTemplate(),
                        decoration: InputDecoration(
                          labelText: isBn ? "বিষয়" : "Subject",
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _examTimeCtrl,
                        onChanged: (_) => _generateCurrentTemplate(),
                        decoration: InputDecoration(
                          labelText: isBn ? "সময়" : "Time",
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _examDateCtrl,
                  onChanged: (_) => _generateCurrentTemplate(),
                  decoration: InputDecoration(
                    labelText: isBn ? "পরীক্ষার তারিখ" : "Exam Date",
                    prefixIcon: const Icon(Icons.event),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Message Preview & Edit
              Text(
                isBn ? "মেসেজ প্রিভিউ (প্রয়োজনে এডিট করতে পারেন):" : "Message Preview & Customize:",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _messageCtrl,
                maxLines: 7,
                style: const TextStyle(fontSize: 12, height: 1.35),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Send Action Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  isBn ? "হোয়াটসঅ্যাপে পাঠান" : "Send on WhatsApp",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _handleSend,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip({
    required WhatsAppMessageType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentType == type;
    return InkWell(
      onTap: () {
        setState(() => _currentType = type);
        _generateCurrentTemplate();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF25D366) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF25D366) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
