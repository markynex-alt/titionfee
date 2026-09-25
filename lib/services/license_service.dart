import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LicenseResult {
  final bool isValid;
  final String tier;
  final int months;
  final String message;
  final bool isPendingVerification;

  const LicenseResult({
    required this.isValid,
    this.tier = 'free',
    this.months = 0,
    required this.message,
    this.isPendingVerification = false,
  });
}

class LicenseService {
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
          message: '$tierName প্ল্যান ($months মাস) সফলভাবে সক্রিয় হয়েছে!',
        );
      } else {
        return const LicenseResult(
          isValid: false,
          message: 'লাইসেন্স কোডটি সঠিক নয়। অনুগ্রহ করে সঠিক কোড দিন।',
        );
      }
    }

    // 3. Online Verification: Check Firestore approved_licenses / license_keys collection
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
          message: 'অনলাইন লাইসেন্স সফলভাবে সক্রিয় হয়েছে!',
        );
      }
    } catch (_) {}

    // 4. bKash / Nagad Transaction ID submission (Must NOT give free instant access to random words!)
    // Transaction IDs in Bangladesh are alphanumeric, typically 8-12 characters (e.g. BLA892187, 9KJ2871A)
    final trxRegex = RegExp(r'^[A-Z0-9]{8,14}$');
    if (trxRegex.hasMatch(clean)) {
      try {
        final firestore = FirebaseFirestore.instance;
        // Submit for admin review
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
        message: 'TrxID ($clean) যাচাইয়ের জন্য জমা দেওয়া হয়েছে। এডমিন ভেরিফাই করলে আপনার প্ল্যান সক্রিয় হবে। দ্রুত সক্রিয় করতে 01825690912 নম্বরে যোগাযোগ করুন।',
      );
    }

    return const LicenseResult(
      isValid: false,
      message: 'ভুল বা অনিবন্ধিত অ্যাক্টিভেশন কোড। র্যান্ডম কোড গ্রহণযোগ্য নয়।',
    );
  }
}
