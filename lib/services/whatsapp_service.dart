import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Cleans and formats phone number for international WhatsApp standards (Bangladesh 880 prefix)
  static String formatPhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('+')) {
      clean = clean.substring(1);
    }
    // If starts with 01X, prepend 880
    if (clean.startsWith('01') && clean.length == 11) {
      clean = '88$clean';
    }
    return clean;
  }

  /// Sends a WhatsApp message using url_launcher with deep link fallback
  static Future<bool> sendMessage({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = formatPhoneNumber(phone);
    if (cleanPhone.isEmpty) return false;

    final encodedText = Uri.encodeComponent(message);

    // 1. Try native WhatsApp scheme
    final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText');
    if (await canLaunchUrl(nativeUri)) {
      return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
    }

    // 2. Fallback to web WhatsApp / wa.me
    final webUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');
    if (await canLaunchUrl(webUri)) {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  /// 1. Student Admission Confirmation Template
  static String getAdmissionMessage({
    required String orgName,
    required String contactPhone,
    required String studentName,
    required String studentId,
    required String studentClass,
    required String batchName,
    required double monthlyFee,
    bool isBn = true,
  }) {
    final header = orgName.isNotEmpty ? orgName : 'Tuition Fee Management';
    if (isBn) {
      return '''🎓 *[$header]*
----------------------------------------
অভিনন্দন! আপনার ভর্তি সফলভাবে সম্পন্ন হয়েছে।

👤 শিক্ষার্থীর নাম: $studentName
🆔 শিক্ষার্থী আইডি: $studentId
📚 শ্রেণি: $studentClass
👥 ব্যাচ: $batchName
💰 মাসিক ফি: ${monthlyFee.toInt()} ৳
${contactPhone.isNotEmpty ? '📞 যোগাযোগ: $contactPhone\n' : ''}
নিয়মিত ক্লাসে উপস্থিতি এবং উজ্জ্বল ভবিষ্যৎ কামনা করছি।
ধন্যবাদ!''';
    } else {
      return '''🎓 *[$header]*
----------------------------------------
Congratulations! Your admission has been confirmed.

👤 Student Name: $studentName
🆔 Student ID: $studentId
📚 Class: $studentClass
👥 Batch: $batchName
💰 Monthly Fee: ${monthlyFee.toInt()} BDT
${contactPhone.isNotEmpty ? '📞 Contact: $contactPhone\n' : ''}
We wish you a successful learning journey!
Thank you.''';
    }
  }

  /// 2. Due Fee Reminder Template
  static String getDueFeeMessage({
    required String orgName,
    required String contactPhone,
    required String studentName,
    required String studentId,
    required String unpaidMonths,
    required double totalDue,
    bool isBn = true,
  }) {
    final header = orgName.isNotEmpty ? orgName : 'Tuition Fee Management';
    if (isBn) {
      return '''📢 *[$header] - বকেয়া ফি বিজ্ঞপ্তি*
----------------------------------------
সম্মানিত অভিভাবক/শিক্ষার্থী,
$studentName (আইডি: $studentId)-এর টিউশন ফি বকেয়া রয়েছে।

🗓️ বকেয়া মাস: $unpaidMonths
💵 মোট বকেয়া ফি: ${totalDue.toInt()} ৳
${contactPhone.isNotEmpty ? '📱 বিকাশ/নগদ পেমেন্ট নম্বর: $contactPhone\n' : ''}
অনুগ্রহ করে বকেয়া ফি পরিশোধ করে পড়াশোনার ধারাবাহিকতা বজায় রাখুন।
ধন্যবাদ!''';
    } else {
      return '''📢 *[$header] - Due Fee Notice*
----------------------------------------
Dear Student/Parent,
This is a gentle reminder regarding unpaid tuition fees for $studentName (ID: $studentId).

🗓️ Unpaid Month(s): $unpaidMonths
💵 Total Due Amount: ${totalDue.toInt()} BDT
${contactPhone.isNotEmpty ? '📱 Payment (bKash/Nagad): $contactPhone\n' : ''}
Kindly settle the due fees at your earliest convenience.
Thank you!''';
    }
  }

  /// 3. Fee Collection Receipt Template
  static String getFeeReceiptMessage({
    required String orgName,
    required String contactPhone,
    required String studentName,
    required String studentId,
    required String monthPaid,
    required double amount,
    required String dateFormatted,
    bool isBn = true,
  }) {
    final header = orgName.isNotEmpty ? orgName : 'Tuition Fee Management';
    if (isBn) {
      return '''🧾 *[$header] - ফি প্রাপ্তি রসিদ*
----------------------------------------
আপনার মাসিক টিউশন ফি সফলভাবে গৃহীত হয়েছে।

👤 শিক্ষার্থীর নাম: $studentName
🆔 আইডি: $studentId
🗓️ পরিশোধিত মাস: $monthPaid
💵 গৃহীত টাকা: ${amount.toInt()} ৳
📅 জমার তারিখ: $dateFormatted
${contactPhone.isNotEmpty ? '📞 যোগাযোগ: $contactPhone\n' : ''}
ফি পরিশোধের জন্য ধন্যবাদ!''';
    } else {
      return '''🧾 *[$header] - Fee Receipt*
----------------------------------------
Your monthly tuition fee has been received successfully.

👤 Student: $studentName
🆔 ID: $studentId
🗓️ Paid Month: $monthPaid
💵 Amount Received: ${amount.toInt()} BDT
📅 Payment Date: $dateFormatted
${contactPhone.isNotEmpty ? '📞 Contact: $contactPhone\n' : ''}
Thank you for your payment!''';
    }
  }

  /// 4. Exam Schedule / Notice Template
  static String getExamNoticeMessage({
    required String orgName,
    required String contactPhone,
    required String studentOrBatch,
    required String subject,
    required String examDate,
    required String examTime,
    String? instructions,
    bool isBn = true,
  }) {
    final header = orgName.isNotEmpty ? orgName : 'Tuition Fee Management';
    final extra = instructions != null && instructions.trim().isNotEmpty
        ? '\n📍 বিশেষ নির্দেশনা: ${instructions.trim()}'
        : '';

    if (isBn) {
      return '''📝 *[$header] - পরীক্ষার সময়সূচি ও নোটিশ*
----------------------------------------
আসন্ন পরীক্ষার গুরুত্বপূর্ণ তথ্য:

🎯 ব্যাচ/শিক্ষার্থী: $studentOrBatch
📖 বিষয়: $subject
📅 পরীক্ষার তারিখ: $examDate
⏰ সময়: $examTime$extra
${contactPhone.isNotEmpty ? '\n📞 হেল্পলাইন: $contactPhone' : ''}
পরীক্ষায় ভালো ফলাফলের জন্য শুভকামনা রইল!''';
    } else {
      return '''📝 *[$header] - Exam Schedule Notice*
----------------------------------------
Upcoming exam schedule details:

🎯 Target: $studentOrBatch
📖 Subject: $subject
📅 Exam Date: $examDate
⏰ Time: $examTime${extra.isNotEmpty ? '\n📍 Instructions: $instructions' : ''}
${contactPhone.isNotEmpty ? '\n📞 Contact: $contactPhone' : ''}
Wishing you the very best for your exams!''';
    }
  }
}
