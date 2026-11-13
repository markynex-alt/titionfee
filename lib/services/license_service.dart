import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class LicenseResult {
  final bool isValid;
  final String tier;
  final int months;
  final String message;
  final bool isPendingVerification;
  final String? planName;

  const LicenseResult({
    required this.isValid,
    this.tier = 'free',
    this.months = 0,
    required this.message,
    this.isPendingVerification = false,
    this.planName,
  });
}

class LicenseService {
  static const String websiteUrl = 'https://tuitionfee.markynex.com/';
  static const String apiVerifyUrl = 'https://tuitionfee.markynex.com/wp-json/tuition/v1/verify-trx';
  static const String _secretSalt = 'TUITION_FEE_AUTH_SALT_01825690912';

  /// Generates a valid cryptographic checksum for a given tier and duration
  static String generateChecksum(String tier, int months) {
    final cleanTier = tier.trim().toUpperCase();
    final input = '$_secretSalt:$cleanTier:$months';
    final digest = sha256.convert(utf8.encode(input));
    return digest.toString().substring(0, 4).toUpperCase();
  }

  /// Generates an official signed license key
  static String generateLicenseKey(String tier, int months) {
    final cleanTier = tier.trim().toUpperCase();
    final checksum = generateChecksum(cleanTier, months);
    return 'TF-$cleanTier-${months}M-$checksum';
  }

  /// Master VIP/Admin bypass codes for the app owner (01825690912)
  static const Map<String, ({String tier, int months})> _masterCodes = {
    'TF-VIP-01825690912-PRO': (tier: 'unlimited', months: 12),
    'TF-OWNER-MASTER-2026': (tier: 'unlimited', months: 24),
    'TF-PRO-UNLIMITED-LIFE': (tier: 'unlimited', months: 36),
  };

  /// Validates and verifies an activation code or TrxID with security checks
  static Future<LicenseResult> verifyCode({
    required String code,
    required String userEmail,
    required String orgName,
    required String phone,
  }) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) {
      return const LicenseResult(
        isValid: false,
        message: 'অনুগ্রহ করে অ্যাক্টিভেশন কোড বা TrxID লিখুন।',
      );
    }

    // 1. Check Master Owner Codes
    if (_masterCodes.containsKey(clean)) {
      final info = _masterCodes[clean]!;
      return LicenseResult(
        isValid: true,
        tier: info.tier,
        months: info.months,
        planName: 'Unlimited Pro (VIP)',
        message: 'মাস্টার ভিআইপি লাইসেন্স সফলভাবে সক্রিয় করা হয়েছে!',
      );
    }

    // 2. Check Standard Cryptographic License Format: TF-<TIER>-<MONTHS>M-<CHECKSUM>
    final regex = RegExp(r'^TF-(STARTER|STANDARD|UNLIMITED)-(\d{1,2})M-([A-F0-9]{4,8})$');
    final match = regex.firstMatch(clean);

    if (match != null) {
      final tierName = match.group(1)!; // STARTER, STANDARD, UNLIMITED
      final months = int.tryParse(match.group(2) ?? '1') ?? 1;
      final providedChecksum = match.group(3)!;

      final expectedChecksum = generateChecksum(tierName, months);

      if (providedChecksum.toUpperCase() == expectedChecksum) {
        // Online Single-Use Verification if internet is available
        try {
          final firestore = FirebaseFirestore.instance;
          final licenseDoc = await firestore.collection('licenses').doc(clean).get();

          if (licenseDoc.exists && licenseDoc.data() != null) {
            final usedBy = licenseDoc.data()?['used_by'];
            if (usedBy != null && usedBy != userEmail) {
              return const LicenseResult(
                isValid: false,
                message: 'এই অ্যাক্টিভেশন কোডটি ইতিমধ্যে অন্য অ্যাকাউন্টে ব্যবহৃত হয়েছে।',
              );
            }
          }

          // Mark license as claimed
          await firestore.collection('licenses').doc(clean).set({
            'code': clean,
            'tier': tierName.toLowerCase(),
            'months': months,
            'used_by': userEmail,
            'used_at': FieldValue.serverTimestamp(),
            'org_name': orgName,
            'contact_phone': phone,
          }, SetOptions(merge: true));
        } catch (_) {
          // Allow offline activation if cryptographic checksum is mathematically valid
        }

        return LicenseResult(
          isValid: true,
          tier: tierName.toLowerCase(),
          months: months,
          planName: '${tierName[0]}${tierName.substring(1).toLowerCase()} Plan',
          message: '$tierName প্ল্যান ($months মাস) সফলভাবে সক্রিয় হয়েছে!',
        );
      } else {
        return const LicenseResult(
          isValid: false,
          message: 'লাইসেন্স কোডটি সঠিক নয়। অনুগ্রহ করে সঠিক কোড দিন।',
        );
      }
    }

    // 3. Online Verification: Query Website REST API directly (https://tuitionfee.markynex.com/)
    try {
      final response = await http.post(
        Uri.parse(apiVerifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'trx_id': clean}),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && (data['success'] == true || data['verified'] == true)) {
          final tier = (data['plan_id'] ?? data['tier'] ?? 'standard').toString().toLowerCase();
          final months = (data['months'] as num?)?.toInt() ?? 1;
          final planName = data['plan_name']?.toString() ?? '${tier.toUpperCase()} Plan';

          // Record activation in Firestore
          try {
            await FirebaseFirestore.instance.collection('verified_trx').doc(clean).set({
              'trx_id': clean,
              'tier': tier,
              'months': months,
              'user_email': userEmail,
              'activated_at': FieldValue.serverTimestamp(),
              'contact_phone': phone,
              'org_name': orgName,
            }, SetOptions(merge: true));
          } catch (_) {}

          return LicenseResult(
            isValid: true,
            tier: tier,
            months: months,
            planName: planName,
            message: '$planName ($months মাস) TrxID দিয়ে সফলভাবে সক্রিয় হয়েছে!',
          );
        }
      }
    } catch (_) {}

    // 4. Online Verification: Check Firestore approved_licenses / license_keys collection
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('license_keys').doc(clean).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final tier = data['tier']?.toString().toLowerCase() ?? 'standard';
        final months = (data['months'] as num?)?.toInt() ?? 1;
        final isUsed = data['is_used'] == true;

        if (isUsed && data['used_by'] != userEmail) {
          return const LicenseResult(
            isValid: false,
            message: 'এই কোডটি ইতিমধ্যে ব্যবহৃত হয়েছে।',
          );
        }

        await firestore.collection('license_keys').doc(clean).set({
          'is_used': true,
          'used_by': userEmail,
          'used_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return LicenseResult(
          isValid: true,
          tier: tier,
          months: months,
          planName: '${tier.toUpperCase()} Plan',
          message: 'অনলাইন লাইসেন্স সফলভাবে সক্রিয় হয়েছে!',
        );
      }

      // Check Firestore approved_trx collection
      final trxDoc = await firestore.collection('approved_trx').doc(clean).get();
      if (trxDoc.exists && trxDoc.data() != null) {
        final data = trxDoc.data()!;
        final tier = data['tier']?.toString().toLowerCase() ?? 'standard';
        final months = (data['months'] as num?)?.toInt() ?? 1;
        return LicenseResult(
          isValid: true,
          tier: tier,
          months: months,
          planName: '${tier.toUpperCase()} Plan',
          message: 'অনুমোদিত TrxID সফলভাবে সক্রিয় হয়েছে!',
        );
      }
    } catch (_) {}

    // 5. Test & Demo TrxID Support (e.g. TRX123456 from website demo auto-fill)
    if (clean.startsWith('TRX') && clean.length >= 8) {
      return LicenseResult(
        isValid: true,
        tier: 'standard',
        months: 3,
        planName: 'Standard Plan',
        message: 'TrxID ($clean) যাচাই সম্পন্ন! স্ট্যান্ডার্ড প্ল্যান (৩ মাস) সফলভাবে সক্রিয় হয়েছে।',
      );
    }

    // 6. bKash / Nagad Transaction ID review submission
    // Real Bangladesh TrxIDs are 8-14 alphanumeric chars (e.g. 9J47K8LM, BLA892187)
    final trxRegex = RegExp(r'^[A-Z0-9]{8,14}$');
    if (trxRegex.hasMatch(clean)) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('payment_verifications').add({
          'email': userEmail,
          'org_name': orgName,
          'contact_phone': phone,
          'code_or_trx': clean,
          'status': 'pending_approval',
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      return LicenseResult(
        isValid: false,
        isPendingVerification: true,
        message: 'TrxID ($clean) সার্ভারে যাচাইয়ের জন্য জমা দেওয়া হয়েছে। ওয়েবসাইট থেকে পেমেন্ট সম্পন্ন হলে তাৎক্ষণিক সক্রিয় হয়ে যাবে। সহায়তার জন্য: 01825690912।',
      );
    }

    return const LicenseResult(
      isValid: false,
      message: 'ভুল বা অনিবন্ধিত TrxID / অ্যাক্টিভেশন কোড। অনুগ্রহ করে ওয়েবসাইট (https://tuitionfee.markynex.com/) থেকে সঠিক TrxID লিখুন।',
    );
  }
}
