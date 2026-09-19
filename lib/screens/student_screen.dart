import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';

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

      final matchesBatch = _selectedBatchFilter == null || s.batchId == _selectedBatchFilter;

      return matchesSearch && matchesBatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          "Students",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.deepPurple, size: 24),
            tooltip: 'Add Student',
            onPressed: () => _showAddEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Students',
            onPressed: () async {
              await _refreshStudents();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Students list updated"),
                    duration: Duration(seconds: 1),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Class: ${s.studentClass}",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
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
                                        : "ID: ${s.id}  •  No phone",
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
                                    "Batch: $batchName",
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
                          const PopupMenuItem(
                            value: 'collect',
                            child: Row(
                              children: [
                                Icon(Icons.payments_outlined, size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text("Collect Fee"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'assign',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month_outlined, size: 18, color: Colors.deepPurple),
                                SizedBox(width: 8),
                                Text("Assign Month"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text("Edit Details"),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text("Delete Student", style: TextStyle(color: Colors.red)),
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
                Expanded(child: _buildStatItem("Students", "$totalStudents", Icons.school)),
                Container(height: 28, width: 1, color: Colors.white30),
                const SizedBox(width: 8),
                Expanded(child: _buildStatItem("Batches", "$totalBatches", Icons.groups)),
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
            label: const Text(
              "Add",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                hintText: "Search student, ID, phone...",
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
                hint: const Text("Batch", style: TextStyle(fontSize: 13)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text("All Batches", style: TextStyle(fontSize: 13)),
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
          const Text(
            "No Students Found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Add a student or adjust your search filters.",
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
            label: const Text("Add First Student"),
          ),
        ],
      ),
    );
  }

  // ---------- ADD / EDIT DIALOG ----------
  void _showAddEditDialog(BuildContext context, {dynamic student}) {
    final p = context.read<AppProvider>();

    final nameCtrl = TextEditingController(text: student?.name ?? '');
    final classCtrl = TextEditingController(text: student?.studentClass ?? '');
    final phoneCtrl = TextEditingController(text: student?.phone ?? '');
    final feeCtrl = TextEditingController(
        text: student != null ? student.monthlyFee.toString() : '');
    String? batchId = student?.batchId;

    // Default to first batch if adding new and batch exists
    if (batchId == null && p.batches.isNotEmpty) {
      batchId = p.batches.first.id;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            student == null ? "Add New Student" : "Edit Student Details",
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
                    labelText: "Student Name *",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: classCtrl,
                  decoration: InputDecoration(
                    labelText: "Class *",
                    prefixIcon: const Icon(Icons.class_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number (Optional)",
                    hintText: "Optional",
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Monthly Fee (${p.currencySymbol}) *",
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: batchId,
                  decoration: InputDecoration(
                    labelText: "Assign Batch *",
                    prefixIcon: const Icon(Icons.groups_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: p.batches.isEmpty
                      ? [
                    const DropdownMenuItem(
                      value: '',
                      child: Text("No batches created yet"),
                    )
                  ]
                      : p.batches
                      .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => batchId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
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
                    batchId == null ||
                    batchId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill all required fields (Name, Class, Fee, Batch)"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                final fee = double.tryParse(feeCtrl.text.trim());
                if (fee == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a valid monthly fee"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                if (student == null) {
                  await p.addStudent(
                    name: nameCtrl.text.trim(),
                    studentClass: classCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(), // optional!
                    fee: fee,
                    batchId: batchId!,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Student ${nameCtrl.text.trim()} added successfully"),
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
                    batchId: batchId!,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Student ${nameCtrl.text.trim()} updated"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Text(student == null ? "Save" : "Update"),
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
        title: const Text("Delete Student", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this student record? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await p.deleteStudent(id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------- ASSIGN MONTH DIALOG ----------
  void _assignMonth(BuildContext context, dynamic student) {
    final p = context.read<AppProvider>();
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
            "Assign Month to ${student.name}",
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
                      DateFormat.MMMM().format(DateTime(0, m)),
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
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                p.assignMonth(
                  studentId: student.id,
                  month: tempMonth,
                  year: tempYear,
                  amount: student.monthlyFee,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Month assigned successfully to ${student.name}",
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Assign Fee", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- COLLECT FEE DIALOG ----------
  void _collectFeeDialog(BuildContext context, dynamic student) {
    final p = context.read<AppProvider>();
    final payments = p
        .paymentHistory(student.id)
        .where((pmt) => pmt['status'] != 'paid')
        .map((pmt) => DateTime.parse(pmt['date']))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No unpaid months available for this student"),
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
            "Collect Fee for ${student.name}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Monthly Fee: ${p.currencySymbol} ${student.monthlyFee.toInt()}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DateTime>(
                initialValue: selectedMonth,
                decoration: InputDecoration(
                  labelText: "Select Unpaid Month",
                  prefixIcon: const Icon(Icons.event_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: payments.map((d) {
                  final label = DateFormat.yMMMM().format(d);
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
              child: const Text("Cancel"),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Fee collected for ${DateFormat.MMMM().format(selectedMonth)}"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Confirm Collection", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}