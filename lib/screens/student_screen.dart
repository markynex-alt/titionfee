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
              foregroundColor: Colors.white,
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
            child: Text(p.tr('delete')),
          ),
        ],
      ),
    );
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
            onPressed: () => StudentAddEditDialog.show(context),
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
                // Top Metrics & Add Action Card
                StudentHeaderStats(
                  totalStudents: p.students.length,
                  totalBatches: p.batches.length,
                  studentsLabel: p.tr('total_students_stat'),
                  batchesLabel: p.tr('total_batches_stat'),
                  addLabel: p.tr('add'),
                  onAdd: () => StudentAddEditDialog.show(context),
                ),

                // Search and Filter Row
                _buildSearchAndFilterBar(p),

                // Student List / Empty State
                Expanded(
                  child: filteredStudents.isEmpty
                      ? _buildEmptyState(p)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredStudents.length,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            final s = filteredStudents[index];
                            final batchName = p.batchNameById(s.batchId);

                            return StudentCard(
                              student: s,
                              batchName: batchName,
                              onEdit: () => StudentAddEditDialog.show(context, student: s),
                              onDelete: () => _deleteStudent(context, s.id),
                              onAssignMonth: () => StudentFeeDialogs.showAssignMonth(context, s),
                              onCollectFee: () => StudentFeeDialogs.showCollectFee(context, s),
                              onWhatsApp: () => WhatsAppDialog.show(context, student: s),
                            );
                          },
                        ),
                ),
              ],
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