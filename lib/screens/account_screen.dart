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
  final TextEditingController searchCtrl = TextEditingController();
  List<Student> filteredStudents = [];
  bool _showAllPayments = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _refreshAccountData();
    });
  }

  Future<void> _refreshAccountData() async {
    setState(() => _loading = true);
    final p = context.read<AppProvider>();
    await p.loadPaymentsFromFirebase();
    await p.syncPaymentsToFirebase();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  // ---------- MULTI-TERM SEARCH LOGIC ----------
  void searchStudent(AppProvider p, {bool dismissKeyboard = false}) {
    final rawInput = searchCtrl.text.trim();

    if (dismissKeyboard) {
      FocusScope.of(context).unfocus();
    }

    if (rawInput.isEmpty) {
      setState(() {
        filteredStudents = [];
        _showAllPayments = false;
      });
      return;
    }

    final terms = rawInput
        .split(RegExp(r'[,/\s]+'))
        .where((t) => t.isNotEmpty)
        .map((t) => t.toLowerCase())
        .toList();

    if (terms.isEmpty) {
      setState(() {
        filteredStudents = [];
      });
      return;
    }

    final matched = p.students.where((s) {
      final sId = s.id.toLowerCase();
      final sName = s.name.toLowerCase();
      final sPhone = s.phone.toLowerCase();

      return terms.any((term) =>
      sId == term ||
          sId.contains(term) ||
          sName.contains(term) ||
          sPhone.contains(term));
    }).toList();

    setState(() {
      filteredStudents = matched;
      _showAllPayments = false;
    });
  }

  // ---------- CANCEL FEE DIALOG ----------
  void _cancelFeeDialog(AppProvider p, Student student, Map<String, dynamic> record) {
    final date = DateTime.parse(record['date']);
    final monthYear = DateFormat.yMMMM().format(date);
    final amount = (record['amount'] ?? 0).toDouble();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cancel Fee Collection"),
        content: Text(
          "Are you sure you want to cancel the collected fee of TK ${amount.toInt()} for $monthYear?\n\nThis will mark the payment as Pending.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep Paid"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
                  content: Text("Payment for $monthYear has been cancelled"),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text("Yes, Cancel Fee", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------- COLLECT FEE DIALOG ----------
  void _collectFeeDialog(AppProvider p, Student student) {
    final payments = p.paymentHistory(student.id);

    final assignedMonths = payments
        .map((e) => Map<String, dynamic>.from(e))
        .where((pmt) => pmt['status'] != 'paid')
        .map((pmt) => DateTime.parse(pmt['date']))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (assignedMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No unpaid months available for this student")),
      );
      return;
    }

    final amountCtrl = TextEditingController(text: student.monthlyFee.toString());
    DateTime selectedMonth = assignedMonths.first;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Collect Fee for ${student.name}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                enabled: false,
                decoration: InputDecoration(
                  labelText: "Fee Amount (TK)",
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DateTime>(
                value: selectedMonth,
                decoration: InputDecoration(
                  labelText: "Select Unpaid Month",
                  prefixIcon: const Icon(Icons.event_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: assignedMonths.map((d) {
                  final label = DateFormat.yMMMM().format(d);
                  return DropdownMenuItem<DateTime>(
                    value: d,
                    child: Text(label),
                  );
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text);
                if (amount != null) {
                  p.collectFee(
                    student.id,
                    amount,
                    month: selectedMonth.month,
                    year: selectedMonth.year,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Fee collected for ${DateFormat.MMMM().format(selectedMonth)}"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {});
                }
              },
              child: const Text("Confirm Collection",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    final displayList = searchCtrl.text.trim().isEmpty ? <Student>[] : filteredStudents;

    double totalCollected = 0;
    double totalPending = 0;

    for (var s in p.students) {
      final history = p.paymentHistory(s.id);
      for (var record in history) {
        final rMap = Map<String, dynamic>.from(record);
        final amt = (rMap['amount'] ?? 0).toDouble();
        if (rMap['status'] == 'paid') {
          totalCollected += amt;
        } else {
          totalPending += amt;
        }
      }
    }

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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Accounts',
            onPressed: () async {
              await _refreshAccountData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Account records updated"),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderStats(totalCollected, totalPending),
              const SizedBox(height: 12),
              _buildSearchBar(p),
              const SizedBox(height: 16),

              if (displayList.isNotEmpty) ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final student = displayList[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStudentCard(student, p),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Payment Ledger",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.payments_outlined, size: 16),
                              label: const Text(
                                "Collect Fee",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              onPressed: () => _collectFeeDialog(p, student),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentLedger(p, student),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ] else
                _buildInitialOrEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- HEADER STATS ----------
  Widget _buildHeaderStats(double collected, double pending) {
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
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    "Collected",
                    "TK ${collected.toInt()}",
                    Icons.account_balance_wallet_outlined,
                  ),
                ),
                Container(height: 28, width: 1, color: Colors.white30),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    "Pending",
                    "TK ${pending.toInt()}",
                    Icons.pending_actions_outlined,
                  ),
                ),
              ],
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
            color: Colors.white.withOpacity(0.2),
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
                  fontSize: 15,
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
    return TextField(
      controller: searchCtrl,
      textInputAction: TextInputAction.search,
      onChanged: (v) => searchStudent(p, dismissKeyboard: false),
      onSubmitted: (_) => searchStudent(p, dismissKeyboard: true),
      decoration: InputDecoration(
        hintText: "Enter student ID, name, or phone number...",
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: searchCtrl.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear, size: 18),
          onPressed: () {
            searchCtrl.clear();
            setState(() {
              filteredStudents = [];
              _showAllPayments = false;
            });
          },
        )
            : IconButton(
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          onPressed: () => searchStudent(p, dismissKeyboard: true),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  // ---------- STUDENT CARD ----------
  Widget _buildStudentCard(Student s, AppProvider p) {
    final batchName = p.batchNameById(s.batchId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "ID: ${s.id}  •  ${s.phone}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Batch: $batchName",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              Text(
                "Monthly Fee: TK ${s.monthlyFee}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- PAYMENT LEDGER ----------
  Widget _buildPaymentLedger(AppProvider p, Student student) {
    final payments = p
        .paymentHistory(student.id)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            "No fee months assigned to this student yet.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    payments.sort((a, b) {
      final statusA = a['status'] == 'paid' ? 1 : 0;
      final statusB = b['status'] == 'paid' ? 1 : 0;
      if (statusA != statusB) return statusA - statusB;
      return DateTime.parse(a['date']).compareTo(DateTime.parse(b['date']));
    });

    final rowsToShow =
    _showAllPayments ? payments : payments.take(5).toList();

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
            final amount = (record['amount'] ?? 0).toDouble();
            final paymentId = record['id'] ?? "N/A";

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPaid ? Colors.green.shade200 : Colors.red.shade200,
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
                      isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
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
                        Text(
                          "Ref: $paymentId",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "TK ${amount.toInt()}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                              isPaid ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPaid ? "Paid" : "Pending",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                          if (isPaid) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () =>
                                  _cancelFeeDialog(p, student, record),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.cancel_outlined,
                                  size: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        if (payments.length > 5)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showAllPayments = !_showAllPayments;
              });
            },
            icon: Icon(_showAllPayments ? Icons.expand_less : Icons.expand_more),
            label: Text(_showAllPayments
                ? "Show Fewer Months"
                : "See All (${payments.length}) Months"),
          ),
      ],
    );
  }

  // ---------- INITIAL OR EMPTY STATE ----------
  Widget _buildInitialOrEmptyState() {
    final isSearching = searchCtrl.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.person_search_rounded,
                size: 48,
                color: Colors.deepPurple.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? "No Student Found" : "Search Student",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? "No matching student record found for your query."
                  : "Enter a student ID, name, or phone number above to view account details.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}