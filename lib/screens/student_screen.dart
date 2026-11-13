
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/student/student_card.dart';
import '../widgets/student/student_header_stats.dart';
import '../widgets/student/student_fee_dialogs.dart';
import '../widgets/student/student_add_edit_dialog.dart';
import '../widgets/whatsapp/whatsapp_dialog.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().syncDataInBackground();
      }
    });
  }

  Future<void> _refreshStudents() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await context.read<AppProvider>().restoreFromFirebase(merge: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _deleteStudent(BuildContext context, String id) {
    final p = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          p.tr('delete_student_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(p.tr('delete_student_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(p.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              await p.deleteStudent(id);

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(p.tr('student_deleted_success')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(p.tr('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    final query = _searchQuery.trim().toLowerCase();

    final filteredStudents = p.students.where((s) {
      final matchesSearch = query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.id.toLowerCase().contains(query) ||
          (s.phone.isNotEmpty && s.phone.contains(query));

      var matchesBatch = true;

      if (_selectedBatchFilter != null) {
        final batchName = p.batchNameById(_selectedBatchFilter!);

        matchesBatch = s.batchId == _selectedBatchFilter ||
            s.batchId.toLowerCase() == batchName.toLowerCase();
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.sizeOf(context).width < 360 ? 17 : 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_alt_1_outlined,
              color: Colors.deepPurple,
              size: 24,
            ),
            tooltip: p.tr('add_new_student'),
            onPressed: () => StudentAddEditDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: p.tr('sync_students_tooltip'),
            onPressed: _loading
                ? null
                : () async {
              await _refreshStudents();

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(p.tr('students_list_updated')),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final horizontalPadding = width >= 900
              ? 24.0
              : width >= 600
              ? 16.0
              : 8.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: Column(
                  children: [
                    StudentHeaderStats(
                      totalStudents: p.students.length,
                      totalBatches: p.batches.length,
                      studentsLabel: p.tr('total_students_stat'),
                      batchesLabel: p.tr('total_batches_stat'),
                      addLabel: p.tr('add'),
                      onAdd: () =>
                          StudentAddEditDialog.show(context),
                    ),
                    _buildSearchAndFilterBar(p),
                    Expanded(
                      child: filteredStudents.isEmpty
                          ? _buildEmptyState(p)
                          : ListView.builder(
                        physics:
                        const BouncingScrollPhysics(),
                        itemCount: filteredStudents.length,
                        padding: const EdgeInsets.only(
                          top: 4,
                          bottom: 80,
                        ),
                        itemBuilder: (context, index) {
                          final student =
                          filteredStudents[index];
                          final batchName =
                          p.batchNameById(student.batchId);

                          return StudentCard(
                            student: student,
                            batchName: batchName,
                            onEdit: () =>
                                StudentAddEditDialog.show(
                                  context,
                                  student: student,
                                ),
                            onDelete: () => _deleteStudent(
                              context,
                              student.id,
                            ),
                            onAssignMonth: () =>
                                StudentFeeDialogs.showAssignMonth(
                                  context,
                                  student,
                                ),
                            onCollectFee: () =>
                                StudentFeeDialogs.showCollectFee(
                                  context,
                                  student,
                                ),
                            onWhatsApp: () =>
                                WhatsAppDialog.show(
                                  context,
                                  student: student,
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
        },
      ),
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
                hint: Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 18, color: Colors.deepPurple),
                    const SizedBox(width: 4),
                    Text(p.tr('batch_label'), style: const TextStyle(fontSize: 13)),
                  ],
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(p.tr('all_batches_filter')),
                  ),
                  ...p.batches.map(
                    (b) => DropdownMenuItem<String?>(
                      value: b.id,
                      child: Text(
                        b.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
  Widget _buildEmptyState(AppProvider p) {
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
            onPressed: () => StudentAddEditDialog.show(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(p.tr('add_new_student')),
          ),
        ],
      ),
    );
  }
}