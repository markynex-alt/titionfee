import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/batch.dart';
import '../models/student.dart';
import '../models/subscription_plan.dart';
import '../services/license_service.dart';
import '../utils/app_strings.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Box get batchBox => Hive.box('batches');
  Box get studentBox => Hive.box('students');
  Box get paymentBox => Hive.box('payments');
  Box get settingsBox => Hive.box('settings');

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _syncStatusMessage;
  String? get syncStatusMessage => _syncStatusMessage;

  // Language Settings
  String get appLanguage =>
      settingsBox.get('app_language', defaultValue: 'en') as String;

  Future<void> setAppLanguage(String lang) async {
    await settingsBox.put('app_language', lang);
    notifyListeners();
  }

  String tr(String key) => AppStrings.get(key, lang: appLanguage);

  // Subscription & Plan Limits
  String get currentPlanId {
    final expiry = planExpiryDate;
    final planId = settingsBox.get('plan_id', defaultValue: 'free') as String;
    if (planId != 'free' && expiry != null && DateTime.now().isAfter(expiry)) {
      // Revert expired plan to free tier
      return 'free';
    }
    return planId;
  }

  DateTime? get planExpiryDate {
    final expStr = settingsBox.get('plan_expiry') as String?;
    if (expStr == null || expStr.isEmpty) return null;
    return DateTime.tryParse(expStr);
  }

  SubscriptionPlan get currentPlan => SubscriptionPlan.getById(currentPlanId);

  int get maxAllowedBatches => currentPlan.batchLimit;
  int get maxAllowedStudents => currentPlan.studentLimit;

  bool get canAddBatch {
    if (maxAllowedBatches == -1) return true;
    return batches.length < maxAllowedBatches;
  }

  bool get canAddStudent {
    if (maxAllowedStudents == -1) return true;
    return students.length < maxAllowedStudents;
  }

  static const String ownerBkashNagadNumber = "01825690912";

  // Organization Profile
  String get organizationName =>
      settingsBox.get('org_name', defaultValue: '') as String;

  String get contactPhone =>
      settingsBox.get('contact_phone', defaultValue: '') as String;

  bool get isOnboardingCompleted =>
      settingsBox.get('onboarding_completed', defaultValue: false) as bool;

  Future<void> saveOrganizationProfile({
    required String orgName,
    required String phone,
  }) async {
    final cleanOrg = orgName.trim();
    final cleanPhone = phone.trim();
    await settingsBox.put('org_name', cleanOrg);
    await settingsBox.put('contact_phone', cleanPhone);
    await settingsBox.put('onboarding_completed', true);
    notifyListeners();

    // Sync organization data to Firebase Cloud if user is signed in
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      try {
        await _firestore.collection('organizations').doc(user.email).set({
          'org_name': cleanOrg,
          'contact_phone': cleanPhone,
          'email': user.email,
          'display_name': user.displayName ?? '',
          'photo_url': user.photoURL ?? '',
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _firestore.collection('users').doc(user.email).set({
          'org_name': cleanOrg,
          'contact_phone': cleanPhone,
          'email': user.email,
          'display_name': user.displayName ?? '',
          'photo_url': user.photoURL ?? '',
          'last_active': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> completeOnboarding() async {
    await settingsBox.put('onboarding_completed', true);
    notifyListeners();
  }

  Future<LicenseResult> verifyAndActivateLicense(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) {
      return const LicenseResult(
        isValid: false,
        message: 'অনুগ্রহ করে অ্যাক্টিভেশন কোড বা TrxID দিন।',
      );
    }

    final user = _auth.currentUser;
    final result = await LicenseService.verifyCode(
      code: clean,
      userEmail: user?.email ?? '',
      orgName: organizationName,
      phone: contactPhone,
    );

    if (result.isValid) {
      final now = DateTime.now();
      // Increase validity: if current plan is already valid in future, extend from that date!
      final existingExpiry = planExpiryDate;
      final baseDate = (existingExpiry != null && existingExpiry.isAfter(now))
          ? existingExpiry
          : now;
      final expiry = DateTime(baseDate.year, baseDate.month + result.months, baseDate.day);

      await settingsBox.put('plan_id', result.tier);
      await settingsBox.put('plan_expiry', expiry.toIso8601String());
      await settingsBox.put('activation_code', clean);
      await settingsBox.put('payment_number', ownerBkashNagadNumber);

      notifyListeners();

      if (user != null && user.email != null) {
        try {
          await _firestore.collection('subscriptions').doc(user.email).set({
            'plan_id': result.tier,
            'plan_expiry': expiry.toIso8601String(),
            'activation_code': clean,
            'payment_number': ownerBkashNagadNumber,
            'org_name': organizationName,
            'contact_phone': contactPhone,
            'updated_at': now.toIso8601String(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    }

    return result;
  }

  Future<bool> activatePlanWithCode(String code) async {
    final res = await verifyAndActivateLicense(code);
    return res.isValid;
  }

  // Settings
  bool get isAutoSyncEnabled =>
      settingsBox.get('auto_sync', defaultValue: true) as bool;

  Future<void> setAutoSyncEnabled(bool enabled) async {
    await settingsBox.put('auto_sync', enabled);
    notifyListeners();
  }

  String? get lastSyncTime => settingsBox.get('last_sync_time') as String?;

  String get currencySymbol =>
      settingsBox.get('currency_symbol', defaultValue: '৳') as String;

  Future<void> setCurrencySymbol(String symbol) async {
    await settingsBox.put('currency_symbol', symbol);
    notifyListeners();
  }

  // ================= BATCH =================

  List<Batch> get batches {
    final list = <Batch>[];
    for (final e in batchBox.values) {
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        list.add(Batch(id: m['id']?.toString() ?? '', name: m['name']?.toString() ?? ''));
      }
    }
    return list;
  }

  Future<void> addBatch(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await batchBox.put(id, {'id': id, 'name': trimmed});
    notifyListeners();
    _triggerAutoSync();
  }

  Future<void> updateBatch(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await batchBox.put(id, {'id': id, 'name': trimmed});
    notifyListeners();
    _triggerAutoSync();
  }

  Future<void> deleteBatch(String id) async {
    await batchBox.delete(id);
    for (var k in studentBox.keys) {
      final s = studentBox.get(k);
      if (s is Map && s['batchId'] == id) {
        final updated = Map<String, dynamic>.from(s);
        updated['batchId'] = '';
        await studentBox.put(k, updated);
      }
    }
    notifyListeners();
    _triggerAutoSync();
  }

  String batchNameById(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return 'No Batch';
    final data = batchBox.get(trimmed);
    if (data is Map && data['name'] != null && data['name'].toString().trim().isNotEmpty) {
      return data['name'].toString().trim();
    }
    // Also match against batches list by id or name
    for (final b in batches) {
      if (b.id == trimmed || b.name.toLowerCase() == trimmed.toLowerCase()) {
        return b.name;
      }
    }
    return trimmed;
  }

  // ================= STUDENT =================

  List<Student> get students {
    final list = <Student>[];
    for (final e in studentBox.values) {
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        final bId = (m['batchId'] ?? m['batch'] ?? '').toString();
        list.add(Student(
          id: m['id']?.toString() ?? '',
          name: m['name']?.toString() ?? '',
          studentClass: (m['class'] ?? m['studentClass'] ?? '').toString(),
          phone: m['phone']?.toString() ?? '',
          monthlyFee: (m['fee'] ?? m['monthlyFee'] as num?)?.toDouble() ?? 0.0,
          batchId: bId,
        ));
      }
    }
    return list;
  }

  List<Student> studentsByBatch(String batchIdentifier) {
    final trimmed = batchIdentifier.trim();
    if (trimmed.isEmpty) return [];

    final matchingBatch = batches.where(
      (b) => b.id.trim() == trimmed || b.name.trim().toLowerCase() == trimmed.toLowerCase()
    ).firstOrNull;

    final targetId = matchingBatch?.id.trim() ?? trimmed;
    final targetName = matchingBatch?.name.trim().toLowerCase();

    return students.where((s) {
      final sBatch = s.batchId.trim();
      if (sBatch.isEmpty) return false;
      return sBatch == targetId ||
             sBatch == trimmed ||
             (targetName != null && sBatch.toLowerCase() == targetName) ||
             (matchingBatch != null && sBatch == matchingBatch.name.trim());
    }).toList();
  }

  String generateStudentId() {
    final year = DateTime.now().year % 100; // e.g. 26
    final yearPrefix = year.toString().padLeft(2, '0');

    final currentYearIds = students
        .map((s) => s.id)
        .where((id) => id.startsWith(yearPrefix))
        .toList();

    int nextNumber = 1;
    if (currentYearIds.isNotEmpty) {
      final numbers = currentYearIds.map((id) {
        final sub = id.length > 2 ? id.substring(2) : '0';
        return int.tryParse(sub) ?? 0;
      }).toList();

      nextNumber = numbers.reduce((a, b) => a > b ? a : b) + 1;
    }

    final suffix = nextNumber.toString().padLeft(3, '0');
    return '$yearPrefix$suffix';
  }

  Future<void> addStudent({
    required String name,
    required String studentClass,
    String? phone,
    required double fee,
    required String batchId,
  }) async {
    final id = generateStudentId();
    final safePhone = phone?.trim() ?? '';
    await studentBox.put(id, {
      'id': id,
      'name': name.trim(),
      'class': studentClass.trim(),
      'phone': safePhone,
      'fee': fee,
      'batchId': batchId,
    });
    notifyListeners();
    _triggerAutoSync();
  }

  Future<void> updateStudent({
    required String id,
    required String name,
    required String studentClass,
    String? phone,
    required double fee,
    required String batchId,
  }) async {
    final safePhone = phone?.trim() ?? '';
    await studentBox.put(id, {
      'id': id,
      'name': name.trim(),
      'class': studentClass.trim(),
      'phone': safePhone,
      'fee': fee,
      'batchId': batchId,
    });
    notifyListeners();
    _triggerAutoSync();
  }

  Future<void> deleteStudent(String id) async {
    await studentBox.delete(id);
    notifyListeners();
    _triggerAutoSync();
  }

  // ================= PAYMENTS =================

  bool assignMonth({
    required String studentId,
    required int month,
    required int year,
    required double amount,
  }) {
    final exists = paymentBox.values.any((p) {
      if (p is! Map) return false;
      if (p['studentId']?.toString() != studentId) return false;
      try {
        final d = DateTime.parse(p['date']);
        return d.month == month && d.year == year;
      } catch (_) {
        return false;
      }
    });
    if (exists) return false;

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
    _triggerAutoSync();
    return true;
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
        final p = paymentBox.get(k);
        if (p is! Map) return false;
        try {
          final d = DateTime.parse(p['date']);
          return p['studentId'] == studentId &&
              d.month == month &&
              d.year == year;
        } catch (_) {
          return false;
        }
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
      _triggerAutoSync();
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
        final p = paymentBox.get(k);
        if (p is! Map) return false;
        try {
          final d = DateTime.parse(p['date']);
          return p['studentId'] == studentId &&
              d.month == month &&
              d.year == year;
        } catch (_) {
          return false;
        }
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
      _triggerAutoSync();
    }
  }

  List<Map<String, dynamic>> paymentHistory(String studentId) {
    if (!studentBox.containsKey(studentId) && !students.any((s) => s.id == studentId)) {
      return [];
    }

    final list = <Map<String, dynamic>>[];
    for (final e in paymentBox.values) {
      if (e is Map && e['studentId']?.toString() == studentId) {
        list.add(Map<String, dynamic>.from(e));
      }
    }
    // Sort chronologically
    list.sort((a, b) {
      final da = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
      return da.compareTo(db);
    });
    return list;
  }

  // Optimized single-pass metrics calculation
  ({double totalIncome, double totalDue}) getFinancialSummary() {
    final activeStudentIds = students.map((s) => s.id).toSet();
    double income = 0.0;
    double due = 0.0;

    for (final e in paymentBox.values) {
      if (e is Map) {
        final sId = e['studentId']?.toString() ?? '';
        if (activeStudentIds.contains(sId)) {
          final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
          if (e['status'] == 'paid') {
            income += amt;
          } else if (e['status'] == 'assigned') {
            due += amt;
          }
        }
      }
    }
    return (totalIncome: income, totalDue: due);
  }

  double get totalIncome => getFinancialSummary().totalIncome;
  double get totalDue => getFinancialSummary().totalDue;

  // Pre-indexes payments by studentId for lightning fast Account screen lookups
  Map<String, List<Map<String, dynamic>>> get groupedPayments {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final e in paymentBox.values) {
      if (e is Map) {
        final sId = e['studentId']?.toString() ?? '';
        if (sId.isNotEmpty) {
          map.putIfAbsent(sId, () => []).add(Map<String, dynamic>.from(e));
        }
      }
    }
    return map;
  }

  // ================= FIREBASE SYNC & BACKUP =================

  void _triggerAutoSync() {
    if (isAutoSyncEnabled) {
      syncDataInBackground();
    }
  }

  Future<void> syncDataInBackground() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    try {
      await _saveBatchesToFirebase();
      await _saveStudentsToFirebase();
      await syncPaymentsToFirebase();
      await settingsBox.put('last_sync_time', DateTime.now().toIso8601String());
    } catch (_) {
      // Background sync failures should not interrupt UI
    }
  }

  Future<bool> backupToFirebase() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      _syncStatusMessage = "Please sign in with Google to backup.";
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _syncStatusMessage = "Backing up data to Firebase...";
    notifyListeners();

    try {
      await _saveBatchesToFirebase();
      await _saveStudentsToFirebase();
      await syncPaymentsToFirebase();

      // Backup Subscription & Preferences
      await _firestore.collection('subscriptions').doc(user.email).set({
        'plan_id': currentPlanId,
        'plan_expiry': settingsBox.get('plan_expiry'),
        'activation_code': settingsBox.get('activation_code'),
        'app_language': appLanguage,
        'currency_symbol': currencySymbol,
      }, SetOptions(merge: true));

      final now = DateTime.now().toIso8601String();
      await settingsBox.put('last_sync_time', now);

      _syncStatusMessage = "Backup complete!";
      return true;
    } catch (e) {
      _syncStatusMessage = "Backup error: $e";
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> restoreFromFirebase({bool merge = true}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      _syncStatusMessage = "Please sign in with Google to restore.";
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _syncStatusMessage = "Restoring data from Firebase...";
    notifyListeners();

    try {
      // 1. Batches
      final batchDoc = await _firestore.collection('batches').doc(user.email).get();
      if (batchDoc.exists && batchDoc.data() != null) {
        final cloudBatches = List.from(batchDoc.data()?['batches'] ?? []);
        if (!merge) await batchBox.clear();
        for (final b in cloudBatches) {
          if (b is Map && b['id'] != null) {
            await batchBox.put(b['id'], b);
          }
        }
      }

      // 2. Students
      final studentDoc = await _firestore.collection('students').doc(user.email).get();
      if (studentDoc.exists && studentDoc.data() != null) {
        final cloudStudents = List.from(studentDoc.data()?['students'] ?? []);
        if (!merge) await studentBox.clear();
        for (final s in cloudStudents) {
          if (s is Map && s['id'] != null) {
            await studentBox.put(s['id'], s);
          }
        }
      }

      // 3. Payments
      final paymentSnap = await _firestore
          .collection('payments')
          .doc(user.email)
          .collection('items')
          .get();

      if (!merge) await paymentBox.clear();
      for (final doc in paymentSnap.docs) {
        await paymentBox.put(doc.id, {...doc.data(), 'synced': true});
      }

      // 4. Subscription & Preferences
      final subDoc = await _firestore.collection('subscriptions').doc(user.email).get();
      if (subDoc.exists && subDoc.data() != null) {
        final data = subDoc.data()!;
        if (data['plan_id'] != null) {
          await settingsBox.put('plan_id', data['plan_id']);
        }
        if (data['plan_expiry'] != null) {
          await settingsBox.put('plan_expiry', data['plan_expiry']);
        }
        if (data['activation_code'] != null) {
          await settingsBox.put('activation_code', data['activation_code']);
        }
      }

      final now = DateTime.now().toIso8601String();
      await settingsBox.put('last_sync_time', now);
      _syncStatusMessage = "Data restored successfully!";
      return true;
    } catch (e) {
      _syncStatusMessage = "Restore error: $e";
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _saveBatchesToFirebase() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    await _firestore.collection('batches').doc(user.email).set({
      'batches': batches.map((b) => {'id': b.id, 'name': b.name}).toList(),
    });
  }

  Future<void> loadBatchesFromFirebase() async {
    await restoreFromFirebase(merge: true);
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
    await restoreFromFirebase(merge: true);
  }

  Future<void> syncPaymentsToFirebase() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    for (final key in paymentBox.keys) {
      final raw = paymentBox.get(key);
      if (raw is! Map) continue;
      final p = Map<String, dynamic>.from(raw);
      if (p['synced'] == true) continue;

      await _firestore
          .collection('payments')
          .doc(user.email)
          .collection('items')
          .doc(key.toString())
          .set(p);

      paymentBox.put(key, {...p, 'synced': true});
    }
  }

  Future<void> loadPaymentsFromFirebase() async {
    await restoreFromFirebase(merge: true);
  }

  // Clear local database safely with notification
  Future<void> clearLocalData() async {
    await batchBox.clear();
    await studentBox.clear();
    await paymentBox.clear();
    notifyListeners();
  }
}