import 'package:flutter_test/flutter_test.dart';
import 'package:tuition_fee/services/license_service.dart';
import 'package:tuition_fee/services/whatsapp_service.dart';

void main() {
  group('WhatsApp Notification System Tests', () {
    test('Phone number formatting correctly normalizes BD numbers', () {
      expect(WhatsAppService.formatPhoneNumber('01825690912'), '8801825690912');
      expect(WhatsAppService.formatPhoneNumber('+8801825690912'), '8801825690912');
      expect(WhatsAppService.formatPhoneNumber('8801825690912'), '8801825690912');
      expect(WhatsAppService.formatPhoneNumber('01825-690912'), '8801825690912');
    });

    test('Student Admission message generation', () {
      final bnMsg = WhatsAppService.getAdmissionMessage(
        orgName: 'বিজ্ঞান একাডেমি',
        contactPhone: '01825690912',
        studentName: 'রাকিব হাসান',
        studentId: 'ST-001',
        studentClass: 'Class 9',
        batchName: 'Morning Batch',
        monthlyFee: 500,
        isBn: true,
      );

      expect(bnMsg.contains('বিজ্ঞান একাডেমি'), isTrue);
      expect(bnMsg.contains('রাকিব হাসান'), isTrue);
      expect(bnMsg.contains('ST-001'), isTrue);
      expect(bnMsg.contains('500 ৳'), isTrue);

      final enMsg = WhatsAppService.getAdmissionMessage(
        orgName: 'Science Academy',
        contactPhone: '01825690912',
        studentName: 'Rakib Hasan',
        studentId: 'ST-001',
        studentClass: 'Class 9',
        batchName: 'Morning Batch',
        monthlyFee: 500,
        isBn: false,
      );

      expect(enMsg.contains('Science Academy'), isTrue);
      expect(enMsg.contains('Rakib Hasan'), isTrue);
      expect(enMsg.contains('500 BDT'), isTrue);
    });

    test('Due Fee reminder message generation', () {
      final msg = WhatsAppService.getDueFeeMessage(
        orgName: 'বিজ্ঞান একাডেমি',
        contactPhone: '01825690912',
        studentName: 'তানভীর',
        studentId: 'ST-002',
        unpaidMonths: 'সেপ্টেম্বর, অক্টোবর',
        totalDue: 1000,
        isBn: true,
      );

      expect(msg.contains('বকেয়া ফি বিজ্ঞপ্তি'), isTrue);
      expect(msg.contains('তানভীর'), isTrue);
      expect(msg.contains('সেপ্টেম্বর, অক্টোবর'), isTrue);
      expect(msg.contains('1000 ৳'), isTrue);
    });

    test('Fee Receipt message generation', () {
      final msg = WhatsAppService.getFeeReceiptMessage(
        orgName: 'বিজ্ঞান একাডেমি',
        contactPhone: '01825690912',
        studentName: 'তানভীর',
        studentId: 'ST-002',
        monthPaid: 'সেপ্টেম্বর ২০২৬',
        amount: 500,
        dateFormatted: '25 Sep 2026',
        isBn: true,
      );

      expect(msg.contains('ফি প্রাপ্তি রসিদ'), isTrue);
      expect(msg.contains('সেপ্টেম্বর ২০২৬'), isTrue);
      expect(msg.contains('500 ৳'), isTrue);
      expect(msg.contains('25 Sep 2026'), isTrue);
    });

    test('Exam Notice message generation with subject and date', () {
      final msg = WhatsAppService.getExamNoticeMessage(
        orgName: 'বিজ্ঞান একাডেমি',
        contactPhone: '01825690912',
        studentOrBatch: 'HSC Batch 2026',
        subject: 'পদার্থবিজ্ঞান ১ম পত্র',
        examDate: '28 Sep 2026',
        examTime: '10:00 AM',
        isBn: true,
      );

      expect(msg.contains('পরীক্ষার সময়সূচি ও নোটিশ'), isTrue);
      expect(msg.contains('পদার্থবিজ্ঞান ১ম পত্র'), isTrue);
      expect(msg.contains('28 Sep 2026'), isTrue);
      expect(msg.contains('10:00 AM'), isTrue);
    });
  });

  group('Cryptographic License Security Tests', () {
    test('Random activation codes are strictly rejected', () async {
      final result1 = await LicenseService.verifyCode(
        code: 'ASDFGH',
        userEmail: 'test@example.com',
        orgName: 'Test Org',
        phone: '01825690912',
      );
      expect(result1.isValid, isFalse);

      final result2 = await LicenseService.verifyCode(
        code: 'RANDOM123',
        userEmail: 'test@example.com',
        orgName: 'Test Org',
        phone: '01825690912',
      );
      expect(result2.isValid, isFalse);
    });

    test('Master VIP code activates Unlimited Pro plan', () async {
      final result = await LicenseService.verifyCode(
        code: 'TF-VIP-01825690912-PRO',
        userEmail: 'owner@gmail.com',
        orgName: 'Tuition Manager Official',
        phone: '01825690912',
      );

      expect(result.isValid, isTrue);
      expect(result.tier, 'unlimited');
      expect(result.months, 12);
    });

    test('Cryptographically signed license key is verified successfully', () async {
      final validKey = LicenseService.generateLicenseKey('STANDARD', 3);
      final result = await LicenseService.verifyCode(
        code: validKey,
        userEmail: 'user@gmail.com',
        orgName: 'My Coaching',
        phone: '01825690912',
      );

      expect(result.isValid, isTrue);
      expect(result.tier, 'standard');
      expect(result.months, 3);
    });

    test('Tampered license key checksum is rejected', () async {
      final tamperedKey = 'TF-STANDARD-3M-DEADBEEF';
      final result = await LicenseService.verifyCode(
        code: tamperedKey,
        userEmail: 'user@gmail.com',
        orgName: 'My Coaching',
        phone: '01825690912',
      );

      expect(result.isValid, isFalse);
    });
  });
}
