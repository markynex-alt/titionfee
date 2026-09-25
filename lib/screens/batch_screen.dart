import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../models/batch.dart';
import '../dialoges/subscription_dialog.dart';
import '../utils/app_strings.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _syncBatches(showLoading: false);
  }

  Future<void> _syncBatches({bool showLoading = true}) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted && showLoading) setState(() => isLoading = true);
      if (mounted) {
        await context.read<AppProvider>().loadBatchesFromFirebase();
      }
      if (mounted && showLoading) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final totalStudents = p.batches.fold<int>(
      0,
          (sum, batch) => sum + p.studentsByBatch(batch.id).length,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          p.tr('batches_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          // Top Add Button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.deepPurple, size: 26),
            tooltip: p.tr('create_new_batch'),
            onPressed: _addBatchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: p.tr('sync_batches_tooltip'),
            onPressed: () async {
              await _syncBatches();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(p.tr('batches_synced')),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Top Header Stats with Quick Add Button
          _buildHeaderStats(p.batches.length, totalStudents),

          Expanded(
            child: p.batches.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: p.batches.length,
              itemBuilder: (context, index) {
                final batch = p.batches[index];
                final studentCount =
                    p.studentsByBatch(batch.id).length;

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
                    border: Border.all(
                        color: Colors.grey.shade200, width: 1),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      onTap: () => _openBatchStudents(batch),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Colors.deepPurple,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        batch.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            // Expanded to prevent 4.8px right overflow
                            Expanded(
                              child: Text(
                                p.appLanguage == 'bn'
                                    ? "$studentCount জন শিক্ষার্থী"
                                    : "$studentCount enrolled students",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.deepPurple,
                              size: 22,
                            ),
                            tooltip: p.tr('assign_month'),
                            onPressed: () =>
                                _assignMonthDialog(batch),
                          ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              if (value == 'view_students') {
                                _openBatchStudents(batch);
                              } else if (value == 'assign_month') {
                                _assignMonthDialog(batch);
                              } else if (value == 'edit') {
                                _editBatchDialog(batch);
                              } else if (value == 'delete') {
                                _deleteBatchDialog(batch);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'view_students',
                                child: Row(
                                  children: [
                                    const Icon(Icons.people_alt_outlined,
                                        size: 18, color: Colors.deepPurple),
                                    const SizedBox(width: 8),
                                    Text(p.appLanguage == 'bn' ? "শিক্ষার্থী দেখুন" : "View Students"),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'assign_month',
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_available,
                                        size: 18),
                                    const SizedBox(width: 8),
                                    Text(p.tr('assign_month')),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_outlined,
                                        size: 18),
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
                                    const Icon(Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(
                                      p.tr('delete_batch_title'),
                                      style: const TextStyle(
                                          color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  // ---------- HEADER STATS & TOP ADD BUTTON ----------
  Widget _buildHeaderStats(int batchCount, int studentCount) {
    final p = context.watch<AppProvider>();
    return Container(
      margin: const EdgeInsets.all(16),
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
                Expanded(child: _buildStatItem(p.tr('total_batches_stat'), "$batchCount", Icons.groups)),
                Container(height: 28, width: 1, color: Colors.white30),
                const SizedBox(width: 8),
                Expanded(child: _buildStatItem(p.tr('total_students_stat'), "$studentCount", Icons.school)),
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
            onPressed: _addBatchDialog,
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
              Icons.format_list_bulleted_add,
              size: 56,
              color: Colors.deepPurple.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            p.tr('no_batches_title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.tr('no_batches_subtitle'),
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
            onPressed: _addBatchDialog,
            icon: const Icon(Icons.add_rounded),
            label: Text(p.tr('create_first_batch')),
          ),
        ],
      ),
    );
  }

  // ---------- ADD BATCH ----------
  void _addBatchDialog() {
    final p = context.read<AppProvider>();
    if (!p.canAddBatch) {
      SubscriptionDialog.show(
        context,
        reasonMessage: p.tr('batch_limit_msg'),
      );
      return;
    }

    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          p.tr('create_new_batch'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: p.tr('batch_name_label'),
            hintText: p.tr('batch_name_hint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.school_outlined),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;

              if (!p.canAddBatch) {
                Navigator.pop(context);
                SubscriptionDialog.show(
                  context,
                  reasonMessage: p.tr('batch_limit_msg'),
                );
                return;
              }

              Navigator.pop(context);
              await p.addBatch(ctrl.text.trim());
              await _syncBatches();
            },
            child: Text(p.tr('save_batch'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------- EDIT BATCH ----------
  void _editBatchDialog(Batch batch) {
    final ctrl = TextEditingController(text: batch.name);
    final p = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          p.tr('edit_batch_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: p.tr('batch_name_label'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.edit_outlined),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;

              Navigator.pop(context);
              await p.updateBatch(batch.id, ctrl.text.trim());
              await _syncBatches();
            },
            child: Text(p.tr('update'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------- DELETE BATCH ----------
  void _deleteBatchDialog(Batch batch) {
    final p = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          p.tr('delete_batch_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          p.appLanguage == 'bn'
              ? "আপনি কি নিশ্চিতভাবে '${batch.name}' ব্যাচটি মুছে ফেলতে চান? এতে থাকা শিক্ষার্থীরা ব্যাচহীন হিসেবে সংরক্ষিত থাকবে।"
              : "Are you sure you want to delete '${batch.name}'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(p.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await p.deleteBatch(batch.id);
              await _syncBatches();
            },
            child: Text(p.tr('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------- VIEW STUDENTS ----------
  void _openBatchStudents(Batch batch) {
    final students = context.read<AppProvider>().studentsByBatch(batch.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    batch.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.read<AppProvider>().appLanguage == 'bn'
                          ? "${students.length} জন শিক্ষার্থী"
                          : "${students.length} Students",
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              students.isEmpty
                  ? Expanded(
                child: Center(
                  child: Text(
                    context.read<AppProvider>().tr('no_students_in_batch'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
                  : Expanded(
                child: ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = students[i];
                    final p = context.read<AppProvider>();
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: Text(
                            s.name.isNotEmpty
                                ? s.name[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          p.tr('student_id_prefix').replaceAll('%s', s.id),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          "${p.currencySymbol} ${s.monthlyFee.toInt()}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- ASSIGN MONTH ----------
  void _assignMonthDialog(Batch batch) {
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
        builder: (context, setState) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isBn ? "${batch.name} ব্যাচে ফি ধার্য করুন" : "Assign Month to ${batch.name}",
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
                      .map(
                        (m) => DropdownMenuItem(
                      value: m,
                      child: Text(
                        AppStrings.formatMonth(DateFormat.MMMM().format(DateTime(0, m)), lang: p.appLanguage),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (v) => setState(() => tempMonth = v!),
                ),
                Container(height: 20, width: 1, color: Colors.grey.shade400),
                DropdownButton<int>(
                  value: tempYear,
                  underline: const SizedBox(),
                  items: years
                      .map(
                        (y) => DropdownMenuItem(
                      value: y,
                      child: Text(
                        y.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (v) => setState(() => tempYear = v!),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                p.assignMonthToBatch(
                  batch.id,
                  month: tempMonth,
                  year: tempYear,
                );
                final monthName = DateFormat.MMMM().format(DateTime(0, tempMonth));
                final monthFormatted = AppStrings.formatMonth(monthName, lang: p.appLanguage);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isBn
                          ? "${batch.name} ব্যাচে $monthFormatted $tempYear এর ফি ধার্য করা হয়েছে"
                          : "Month ($monthFormatted $tempYear) assigned to ${batch.name}",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
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
}