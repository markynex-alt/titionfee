import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../models/student.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Student? _selectedStudent;
  List<Student> _matchingStudents = [];
  bool _showAllPayments = false;
  bool _isSyncing = false;
  String _paymentFilter = 'All'; // 'All', 'Pending', 'Paid'

  @override
  void initState() {
    super.initState();
    // Non-blocking background sync if auto-sync is on
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().syncDataInBackground();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _refreshAccountData() async {
    setState(() => _isSyncing = true);
    final p = context.read<AppProvider>();
    await p.restoreFromFirebase(merge: true);
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  // ---------- SEARCH LOGIC ----------
  void _onSearchChanged(String input, AppProvider p) {
    final query = input.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _matchingStudents = [];
        _selectedStudent = null;
        _showAllPayments = false;
      });
      return;
    }

    // Match by ID, Name, or Phone
    final matched = p.students.where((s) {
      final sId = s.id.toLowerCase();
      final sName = s.name.toLowerCase();
      final sPhone = s.phone.toLowerCase();
      return sId == query ||
          sId.contains(query) ||
          sName.contains(query) ||
          (sPhone.isNotEmpty && sPhone.contains(query));
    }).toList();

    // Check if there is an exact match for ID or Name
    final exactMatch = matched.where((s) =>
    s.id.toLowerCase() == query || s.name.toLowerCase() == query).toList();

    setState(() {
      _matchingStudents = matched;
      if (exactMatch.isNotEmpty) {
        _selectedStudent = exactMatch.first;
      } else if (matched.length == 1) {
        _selectedStudent = matched.first;
      } else {
        // If query doesn't single out a student yet, keep current selection or null
        if (_selectedStudent != null && !matched.contains(_selectedStudent)) {
          _selectedStudent = null;
        }
      }
    });
  }

  void _onSearchSubmitted(String input, AppProvider p) {
    _searchFocusNode.unfocus();
    final query = input.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _matchingStudents = [];
        _selectedStudent = null;
      });
      return;
    }

    final matched = p.students.where((s) {
      final sId = s.id.toLowerCase();
      final sName = s.name.toLowerCase();
      final sPhone = s.phone.toLowerCase();
      return sId == query ||
          sId.contains(query) ||
          sName.contains(query) ||
          (sPhone.isNotEmpty && sPhone.contains(query));
    }).toList();

    setState(() {
      _matchingStudents = matched;
      if (matched.isNotEmpty) {
        _selectedStudent = matched.first;
      } else {
        _selectedStudent = null;
      }
    });
  }

  void _selectStudent(Student student) {
    _searchFocusNode.unfocus();
    setState(() {
      _selectedStudent = student;
      _searchCtrl.text = student.name;
      _matchingStudents = [student];
      _showAllPayments = false;
    });
  }

  // ---------- CANCEL FEE DIALOG ----------
  void _cancelFeeDialog(AppProvider p, Student student, Map<String, dynamic> record) {
    final date = DateTime.parse(record['date']);
    final monthYear = DateFormat.yMMMM().format(date);
    final amount = (record['amount'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cancel Fee Collection"),
        content: Text(
          "Are you sure you want to cancel the collected fee of ${p.currencySymbol} ${amount.toInt()} for $monthYear?\n\nThis will mark the payment as Pending Due.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep Paid"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              p.cancelFee(
                student.id,
                month: date.month,
                year: date.year,
                originalMonthlyFee: student.monthlyFee,
              );

              Navigator.pop(context);
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Payment for $monthYear has been reset to Pending"),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("Yes, Reset to Pending"),
          ),
        ],
      ),
    );
  }

  // ---------- COLLECT FEE DIALOG ----------
  void _collectFeeDialog(AppProvider p, Student student) {
    final payments = p.paymentHistory(student.id);

    final assignedMonths = payments
        .where((pmt) => pmt['status'] != 'paid')
        .map((pmt) => DateTime.parse(pmt['date']))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (assignedMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No unpaid months available for this student"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amountCtrl = TextEditingController(text: student.monthlyFee.toInt().toString());
    DateTime selectedMonth = assignedMonths.first;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Collect Fee: ${student.name}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<DateTime>(
                initialValue: selectedMonth,
                decoration: InputDecoration(
                  labelText: "Month to Collect",
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: assignedMonths.map((d) {
                  final label = DateFormat.yMMMM().format(d);
                  return DropdownMenuItem(value: d, child: Text(label));
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedMonth = v);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount (${p.currencySymbol})",
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text.trim());
                if (amt == null || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a valid amount")),
                  );
                  return;
                }

                p.collectFee(
                  student.id,
                  amt,
                  month: selectedMonth.month,
                  year: selectedMonth.year,
                );

                Navigator.pop(context);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Fee collected for ${DateFormat.MMMM().format(selectedMonth)}: ${p.currencySymbol} ${amt.toInt()}",
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Confirm Collection"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final summary = p.getFinancialSummary();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          "Student Account",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Accounts',
            onPressed: () async {
              await _refreshAccountData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Account records updated"),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Overall Header Stats (Collected vs Pending)
              _buildHeaderStats(summary.totalIncome, summary.totalDue, p.currencySymbol),
              const SizedBox(height: 12),

              // 2. Search Bar
              _buildSearchBar(p),
              const SizedBox(height: 8),

              // 3. Search Suggestions / Matching Student Chips
              if (_matchingStudents.length > 1)
                _buildStudentSuggestions(p),

              const SizedBox(height: 12),

              // 4. Main Content: Selected Student Ledger OR Initial State
              if (_selectedStudent != null)
                _buildStudentLedgerSection(p, _selectedStudent!)
              else if (_searchCtrl.text.trim().isNotEmpty && _matchingStudents.isEmpty)
                _buildNoStudentFound()
              else
                _buildQuickSelectSection(p),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- HEADER STATS ----------
  Widget _buildHeaderStats(double collected, double pending, String currency) {
    return Container(
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
        children: [
          Expanded(
            child: _buildStatItem(
              "Total Collected",
              "$currency ${collected.toInt()}",
              Icons.account_balance_wallet_outlined,
            ),
          ),
          Container(height: 32, width: 1, color: Colors.white24),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatItem(
              "Total Pending",
              "$currency ${pending.toInt()}",
              Icons.hourglass_top_outlined,
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
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

  // ---------- SEARCH BAR ----------
  Widget _buildSearchBar(AppProvider p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onChanged: (v) => _onSearchChanged(v, p),
        onSubmitted: (v) => _onSearchSubmitted(v, p),
        decoration: InputDecoration(
          hintText: "Enter student ID (e.g. 26001) or name...",
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search, color: Colors.deepPurple, size: 22),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () {
              _searchCtrl.clear();
              setState(() {
                _matchingStudents = [];
                _selectedStudent = null;
                _showAllPayments = false;
              });
            },
          )
              : IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.deepPurple, size: 20),
            onPressed: () => _onSearchSubmitted(_searchCtrl.text, p),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ---------- STUDENT SUGGESTIONS CHIPS ----------
  Widget _buildStudentSuggestions(AppProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            "Found ${_matchingStudents.length} matching students. Tap to open:",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _matchingStudents.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final student = _matchingStudents[i];
              final isSelected = _selectedStudent?.id == student.id;

              return ChoiceChip(
                label: Text("ID: ${student.id} - ${student.name}"),
                selected: isSelected,
                selectedColor: Colors.deepPurple,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                  ),
                ),
                onSelected: (_) => _selectStudent(student),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------- COMPLETE STUDENT LEDGER SECTION ----------
  Widget _buildStudentLedgerSection(AppProvider p, Student s) {
    final batchName = p.batchNameById(s.batchId);
    final payments = p.paymentHistory(s.id);

    double studentCollected = 0;
    double studentPending = 0;
    int unpaidMonthsCount = 0;

    for (var r in payments) {
      final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
      if (r['status'] == 'paid') {
        studentCollected += amt;
      } else {
        studentPending += amt;
        unpaidMonthsCount++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Student Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "ID: ${s.id}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s.phone.isNotEmpty ? s.phone : "No phone",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text(
                      "Collect Fee",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _collectFeeDialog(p, s),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Expanded(child: _buildSubDetailItem("Class", s.studentClass)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSubDetailItem("Batch", batchName)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSubDetailItem("Monthly Fee", "${p.currencySymbol} ${s.monthlyFee.toInt()}")),
                ],
              ),
              const SizedBox(height: 12),
              // Student Balance Pills
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Paid",
                            style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "${p.currencySymbol} ${studentCollected.toInt()}",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: unpaidMonthsCount > 0 ? Colors.red.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pending Due ($unpaidMonthsCount mos)",
                            style: TextStyle(
                              fontSize: 11,
                              color: unpaidMonthsCount > 0 ? Colors.red.shade700 : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "${p.currencySymbol} ${studentPending.toInt()}",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: unpaidMonthsCount > 0 ? Colors.red.shade800 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Ledger Title & Filter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                "Payment Ledger",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterButton('All'),
                const SizedBox(width: 4),
                _buildFilterButton('Pending'),
                const SizedBox(width: 4),
                _buildFilterButton('Paid'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Payment History Items
        _buildPaymentLedgerList(p, s, payments),
      ],
    );
  }

  Widget _buildSubDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String filter) {
    final isSelected = _paymentFilter == filter;
    return InkWell(
      onTap: () => setState(() => _paymentFilter = filter),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ---------- PAYMENT LEDGER LIST ----------
  Widget _buildPaymentLedgerList(AppProvider p, Student s, List<Map<String, dynamic>> allPayments) {
    var filtered = allPayments;
    if (_paymentFilter == 'Pending') {
      filtered = allPayments.where((e) => e['status'] != 'paid').toList();
    } else if (_paymentFilter == 'Paid') {
      filtered = allPayments.where((e) => e['status'] == 'paid').toList();
    }

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            _paymentFilter == 'All'
                ? "No fee months assigned to this student yet."
                : "No $_paymentFilter records found.",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    final rowsToShow = _showAllPayments ? filtered : filtered.take(6).toList();

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rowsToShow.length,
          itemBuilder: (context, i) {
            final record = rowsToShow[i];
            final date = DateTime.parse(record['date']);
            final monthYear = DateFormat.yMMMM().format(date);
            final isPaid = record['status'] == 'paid';
            final amount = (record['amount'] as num?)?.toDouble() ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPaid ? Icons.check_circle_rounded : Icons.pending_outlined,
                      color: isPaid ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthYear,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPaid ? "Status: Fee Cleared" : "Status: Pending Due",
                          style: TextStyle(
                            fontSize: 11,
                            color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${p.currencySymbol} ${amount.toInt()}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isPaid)
                        InkWell(
                          onTap: () => _cancelFeeDialog(p, s, record),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.undo, size: 12, color: Colors.red),
                                SizedBox(width: 2),
                                Text(
                                  "Reset",
                                  style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        InkWell(
                          onTap: () => _collectFeeDialog(p, s),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "Pay Now",
                              style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        if (filtered.length > 6)
          TextButton.icon(
            onPressed: () => setState(() => _showAllPayments = !_showAllPayments),
            icon: Icon(_showAllPayments ? Icons.expand_less : Icons.expand_more),
            label: Text(_showAllPayments
                ? "Show Fewer"
                : "View All (${filtered.length}) Months"),
          ),
      ],
    );
  }

  // ---------- QUICK SELECT LIST WHEN EMPTY ----------
  Widget _buildQuickSelectSection(AppProvider p) {
    if (p.students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_search_rounded, size: 48, color: Colors.deepPurple.shade300),
              ),
              const SizedBox(height: 16),
              const Text(
                "No Students Registered",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                "Add students from the Students tab to view their account ledgers.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Select Student to View Ledger",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                "Quick Select",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: p.students.length,
          itemBuilder: (context, i) {
            final s = p.students[i];
            final batchName = p.batchNameById(s.batchId);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                onTap: () => _selectStudent(s),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.deepPurple.shade50,
                  child: Text(
                    s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                title: Text(
                  s.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  "ID: ${s.id}  •  Batch: $batchName",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- NO STUDENT FOUND ----------
  Widget _buildNoStudentFound() {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 48, color: Colors.deepPurple.shade300),
            ),
            const SizedBox(height: 16),
            const Text(
              "No Student Found",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              "No student matches '${_searchCtrl.text.trim()}'. Please verify the student ID or name.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}