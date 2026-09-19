import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/batch.dart';
import '../models/student.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Box get batchBox => Hive.box('batches');
  Box get studentBox => Hive.box('students');
  Box get paymentBox => Hive.box('payments');
  Box get settingsBox => Hive.box('settings');

  // ================= BATCH =================

  List<Batch> get batches => batchBox.values.map((e) {
    final m = Map<String, dynamic>.from(e);
    return Batch(id: m['id'], name: m['name']);
  }).toList();

  Future<void> addBatch(String name) async {
    if (name.trim().isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    batchBox.put(id, {'id': id, 'name': name});
    notifyListeners();
    await _saveBatchesToFirebase();
  }

  Future<void> updateBatch(String id, String name) async {
    batchBox.put(id, {'id': id, 'name': name});
    notifyListeners();
    await _saveBatchesToFirebase();
  }

  Future<void> deleteBatch(String id) async {
    batchBox.delete(id);
    for (var k in studentBox.keys) {
      final s = studentBox.get(k);
      if (s != null && s['batchId'] == id) {
        studentBox.put(k, {...s, 'batchId': ''});
      }
    }
    notifyListeners();
    await _saveBatchesToFirebase();
  }

  Future<void> _saveBatchesToFirebase() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    await _firestore.collection('batches').doc(user.email).set({
      'batches': batches.map((b) => {'id': b.id, 'name': b.name}).toList(),
    });
  }

  Future<void> loadBatchesFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final doc = await _firestore.collection('batches').doc(user.email).get();
    if (!doc.exists) return;

    await batchBox.clear();
    for (final b in List.from(doc['batches'])) {
      batchBox.put(b['id'], b);
    }
    notifyListeners();
  }

  String batchNameById(String id) =>
      batchBox.get(id)?['name'] ?? 'No Batch';

  // ================= STUDENT =================

  List<Student> get students => studentBox.values.map((e) {
    final m = Map<String, dynamic>.from(e);
    return Student(
      id: m['id'],
      name: m['name'],
      studentClass: m['class'],
      phone: m['phone'],
      monthlyFee: (m['fee'] ?? 0).toDouble(),
      batchId: m['batchId'],
    );
  }).toList();

  List<Student> studentsByBatch(String batchId) =>
      students.where((s) => s.batchId == batchId).toList();

  String generateStudentId() {
    final year = DateTime.now().year % 100; // last 2 digits (e.g. 26)
    final yearPrefix = year.toString().padLeft(2, '0');

    final currentYearIds = students
        .map((s) => s.id)
        .where((id) => id.startsWith(yearPrefix))
        .toList();

    int nextNumber = 1;

    if (currentYearIds.isNotEmpty) {
      final numbers = currentYearIds.map((id) {
        return int.tryParse(id.substring(2)) ?? 0;
      }).toList();

      nextNumber = numbers.reduce((a, b) => a > b ? a : b) + 1;
    }

    if (nextNumber > 999) {
      throw Exception("Student ID limit reached for year $yearPrefix");
    }

    final suffix = nextNumber.toString().padLeft(3, '0');
    return '$yearPrefix$suffix';
  }

  Future<void> addStudent({
    required String name,
    required String studentClass,
    required String phone,
    required double fee,
    required String batchId,
  }) async {
    final id = generateStudentId();
    studentBox.put(id, {
      'id': id,
      'name': name,
      'class': studentClass,
      'phone': phone,
      'fee': fee,
      'batchId': batchId,
    });
    notifyListeners();
    await _saveStudentsToFirebase();
  }

  Future<void> updateStudent({
    required String id,
    required String name,
    required String studentClass,
    required String phone,
    required double fee,
    required String batchId,
  }) async {
    studentBox.put(id, {
      'id': id,
      'name': name,
      'class': studentClass,
      'phone': phone,
      'fee': fee,
      'batchId': batchId,
    });
    notifyListeners();
    await _saveStudentsToFirebase();
  }

  Future<void> deleteStudent(String id) async {
    studentBox.delete(id);
    notifyListeners();
    await _saveStudentsToFirebase();
  }

  Future<void> _saveStudentsToFirebase() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    await _firestore.collection('students').doc(user.email).set({
      'students': students
          .map((s) => {
        'id': s.id,
        'name': s.name,
        'class': s.studentClass,
        'phone': s.phone,
        'fee': s.monthlyFee,
        'batchId': s.batchId,
      })
          .toList(),
    });
  }

  Future<void> loadStudentsFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final doc = await _firestore.collection('students').doc(user.email).get();
    if (!doc.exists) return;

    await studentBox.clear();
    for (final s in List.from(doc['students'])) {
      studentBox.put(s['id'], s);
    }
    notifyListeners();
  }

  // ================= PAYMENTS =================

  void assignMonth({
    required String studentId,
    required int month,
    required int year,
    required double amount,
  }) {
    final exists = paymentBox.values.any((p) {
      if (p['studentId'] != studentId) return false;
      final d = DateTime.parse(p['date']);
      return d.month == month && d.year == year;
    });
    if (exists) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    paymentBox.put(id, {
      'id': id,
      'studentId': studentId,
      'amount': amount,
      'status': 'assigned',
      'date': DateTime(year, month, 1).toIso8601String(),
      'synced': false,
    });

    notifyListeners();
    syncPaymentsToFirebase();
  }

  void assignMonthToBatch(
      String batchId, {
        required int month,
        required int year,
      }) {
    for (final s in studentsByBatch(batchId)) {
      assignMonth(
        studentId: s.id,
        month: month,
        year: year,
        amount: s.monthlyFee,
      );
    }
    notifyListeners();
  }

  void collectFee(
      String studentId,
      double amount, {
        required int month,
        required int year,
      }) {
    final key = paymentBox.keys.cast<String?>().firstWhere(
          (k) {
        final p = Map<String, dynamic>.from(paymentBox.get(k));
        final d = DateTime.parse(p['date']);
        return p['studentId'] == studentId &&
            d.month == month &&
            d.year == year;
      },
      orElse: () => null,
    );

    if (key != null) {
      final p = Map<String, dynamic>.from(paymentBox.get(key));
      p['amount'] = amount;
      p['status'] = 'paid';
      p['synced'] = false;
      paymentBox.put(key, p);
      notifyListeners();
      syncPaymentsToFirebase();
    }
  }

  void cancelFee(
      String studentId, {
        required int month,
        required int year,
        required double originalMonthlyFee,
      }) {
    final key = paymentBox.keys.cast<String?>().firstWhere(
          (k) {
        final p = Map<String, dynamic>.from(paymentBox.get(k));
        final d = DateTime.parse(p['date']);
        return p['studentId'] == studentId &&
            d.month == month &&
            d.year == year;
      },
      orElse: () => null,
    );

    if (key != null) {
      final p = Map<String, dynamic>.from(paymentBox.get(key));
      p['amount'] = originalMonthlyFee;
      p['status'] = 'assigned';
      p['synced'] = false;
      paymentBox.put(key, p);
      notifyListeners();
      syncPaymentsToFirebase();
    }
  }

  List<Map<String, dynamic>> paymentHistory(String studentId) {
    final studentExists = studentBox.containsKey(studentId);
    if (!studentExists) return [];

    return paymentBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['studentId'] == studentId)
        .toList();
  }

  double get totalIncome {
    final activeStudentIds = students.map((s) => s.id).toSet();
    return paymentBox.values.fold(0.0, (sum, e) {
      final p = Map<String, dynamic>.from(e);
      if (activeStudentIds.contains(p['studentId']) && p['status'] == 'paid') {
        return sum + (p['amount'] ?? 0);
      }
      return sum;
    });
  }

  // ================= PAYMENT FIREBASE SYNC =================

  Future<void> syncPaymentsToFirebase() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    for (final key in paymentBox.keys) {
      final p = Map<String, dynamic>.from(paymentBox.get(key));
      if (p['synced'] == true) continue;

      await _firestore
          .collection('payments')
          .doc(user.email)
          .collection('items')
          .doc(key)
          .set(p);

      paymentBox.put(key, {...p, 'synced': true});
    }
  }

  Future<void> loadPaymentsFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final snap = await _firestore
        .collection('payments')
        .doc(user.email)
        .collection('items')
        .get();

    for (final d in snap.docs) {
      paymentBox.put(d.id, {...d.data(), 'synced': true});
    }
    notifyListeners();
  }
}