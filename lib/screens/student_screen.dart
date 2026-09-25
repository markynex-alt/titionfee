import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../dialoges/subscription_dialog.dart';
import '../utils/app_strings.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  bool _loading = false;
  String _searchQuery = '';
  String? _selectedBatchFilter;

  @override
  void initState() {
    super.initState();
    // Non-blocking background sync if auto-sync is on
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().syncDataInBackground();
    });
  }

  Future<void> _refreshStudents() async {
    setState(() => _loading = true);
    final p = context.read<AppProvider>();
    await p.restoreFromFirebase(merge: true);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    // Filter students by Search Query and Batch
    final query = _searchQuery.trim().toLowerCase();
    final filteredStudents = p.students.where((s) {
      final matchesSearch = query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.id.toLowerCase().contains(query) ||
          (s.phone.isNotEmpty && s.phone.contains(query));

      bool matchesBatch = true;
      if (_selectedBatchFilter != null) {
        final bName = p.batchNameById(_selectedBatchFilter!);
        matchesBatch = s.batchId == _selectedBatchFilter ||
            s.batchId.toLowerCase() == bName.toLowerCase();
      }

      return matchesSearch && matchesBatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          p.tr('students_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.deepPurple, size: 24),
            tooltip: p.tr('add_new_student'),
            onPressed: () => _showAddEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: p.tr('sync_students_tooltip'),
            onPressed: () async {
              await _refreshStudents();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(p.tr('students_list_updated')),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Top Metrics & Add Action Card (Overflow safe)
          _buildHeaderStats(p.students.length, p.batches.length),

          // Search & Batch Filter Bar
          _buildSearchAndFilterBar(p),

          // Student List View
          Expanded(
            child: filteredStudents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredStudents.length,
              itemBuilder: (context, i) {
                final s = filteredStudents[i];
                final batchName = p.batchNameById(s.batchId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.deepPurple.shade50,
                        child: Text(
                          s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.tr('class_prefix').replaceAll('%s', s.studentClass),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.phone.isNotEmpty
                                        ? "ID: ${s.id}  •  ${s.phone}"
                                        : "ID: ${s.id}  •  ${p.tr('no_phone')}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: s.phone.isNotEmpty ? Colors.grey.shade700 : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.tr('batch_prefix').replaceAll('%s', batchName),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${p.currencySymbol} ${s.monthlyFee.toInt()}",
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
                      trailing: PopupMenuButton<String>(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (v) {
                          if (v == 'edit') {
                            _showAddEditDialog(context, student: s);
                          } else if (v == 'delete') {
                            _deleteStudent(context, s.id);
                          } else if (v == 'assign') {
                            _assignMonth(context, s);
                          } else if (v == 'collect') {
                            _collectFeeDialog(context, s);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'collect',
                            child: Row(
                              children: [
                                const Icon(Icons.payments_outlined, size: 18, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(p.tr('collect_fee_title')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'assign',
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.deepPurple),
                                const SizedBox(width: 8),
                                Text(p.tr('assign_month')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(p.tr('edit')),
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
                                Text(p.tr('delete_student_title'), style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- HEADER STATS & ACTION BUTTON ----------
  Widget _buildHeaderStats(int totalStudents, int totalBatches) {
    final p = context.watch<AppProvider>();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildStatItem(p.tr('total_students_stat'), "$totalStudents", Icons.school)),
                Container(height: 28, width: 1, color: Colors.white30),
                const SizedBox(width: 8),
                Expanded(child: _buildStatItem(p.tr('total_batches_stat'), "$totalBatches", Icons.groups)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _showAddEditDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              p.tr('add'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- SEARCH AND FILTER BAR ----------
  Widget _buildSearchAndFilterBar(AppProvider p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: p.tr('search_student_hint'),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedBatchFilter,
                hint: Text(p.appLanguage == 'bn' ? "ব্যাচ" : "Batch", style: const TextStyle(fontSize: 13)),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(p.tr('all_batches'), style: const TextStyle(fontSize: 13)),
                  ),
                  ...p.batches.map(
                        (b) => DropdownMenuItem<String?>(
                      value: b.id,
                      child: Text(b.name, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedBatchFilter = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- EMPTY STATE ----------
  Widget _buildEmptyState() {
    final p = context.watch<AppProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off_outlined,
              size: 56,
              color: Colors.deepPurple.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            p.tr('no_students_found'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.tr('no_students_subtitle'),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _showAddEditDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(p.tr('add_new_student')),
          ),
        ],
      ),
    );
  }

  // ---------- ADD / EDIT DIALOG ----------
  void _showAddEditDialog(BuildContext context, {dynamic student}) {
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
      final rawBatch = (student.batchId as String? ?? '').trim();
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
        builder: (context, setDialogState) => AlertDialog(
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
              onPressed: () => Navigator.pop(context),
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
                  Navigator.pop(context);
                  SubscriptionDialog.show(
                    context,
                    reasonMessage: p.tr('student_limit_msg'),
                  );
                  return;
                }

                Navigator.pop(context);

                final safeBatchId = batchId ?? '';
                if (student == null) {
                  await p.addStudent(
                    name: nameCtrl.text.trim(),
                    studentClass: classCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(), // optional!
                    fee: fee,
                    batchId: safeBatchId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(p.tr('student_added_success').replaceAll('%s', nameCtrl.text.trim())),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  await p.updateStudent(
                    id: student.id,
                    name: nameCtrl.text.trim(),
                    studentClass: classCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(), // optional!
                    fee: fee,
                    batchId: safeBatchId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(p.tr('student_updated_success').replaceAll('%s', nameCtrl.text.trim())),
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

  // ---------- DELETE DIALOG ----------
  void _deleteStudent(BuildContext context, String id) {
    final p = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(p.tr('delete_student_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(p.tr('delete_student_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(p.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await p.deleteStudent(id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(p.tr('student_deleted_success')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(p.tr('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------- ASSIGN MONTH DIALOG ----------
  void _assignMonth(BuildContext context, dynamic student) {
    final p = context.read<AppProvider>();
    final isBn = p.appLanguage == 'bn';
    DateTime now = DateTime.now();
    int tempMonth = now.month;
    int tempYear = now.year;

    final years = List.generate(10, (i) => now.year - 2 + i);
    final months = List.generate(12, (i) => i + 1);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isBn ? "${student.name}-এর ফি নির্ধারণ" : "Assign Month to ${student.name}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<int>(
                  value: tempMonth,
                  underline: const SizedBox(),
                  items: months
                      .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(
                      AppStrings.formatMonth(DateFormat.MMMM().format(DateTime(0, m)), lang: p.appLanguage),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => tempMonth = v!),
                ),
                Container(height: 20, width: 1, color: Colors.grey.shade400),
                DropdownButton<int>(
                  value: tempYear,
                  underline: const SizedBox(),
                  items: years
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
              onPressed: () => Navigator.pop(context),
              child: Text(p.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
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
              child: Text(
                isBn ? "ফি ধার্য করুন" : "Assign Fee",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- COLLECT FEE DIALOG ----------
  void _collectFeeDialog(BuildContext context, dynamic student) {
    final p = context.read<AppProvider>();
    final isBn = p.appLanguage == 'bn';

    // Safely parse unpaid payments & deduplicate by month/year
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
        builder: (context, setDialogState) => AlertDialog(
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
              onPressed: () => Navigator.pop(context),
              child: Text(p.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
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
                  ),
                );
              },
              child: Text(p.tr('confirm_collection'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}