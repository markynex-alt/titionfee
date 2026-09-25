import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OnboardingDialog(),
    );
  }

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  final TextEditingController _orgCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: "1222743060-292lpfs5ktq5tgfhupfveu62lt7rv5kh.apps.googleusercontent.com",
  );

  bool _isSigningIn = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>();
    _orgCtrl.text = p.organizationName;
    _phoneCtrl.text = p.contactPhone;
  }

  @override
  void dispose() {
    _orgCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isSigningIn = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      if (!mounted) return;
      final p = context.read<AppProvider>();
      await p.restoreFromFirebase(merge: true);

      // Pre-fill fields if restored
      if (_orgCtrl.text.isEmpty && p.organizationName.isNotEmpty) {
        _orgCtrl.text = p.organizationName;
      }
      if (_phoneCtrl.text.isEmpty && p.contactPhone.isNotEmpty) {
        _phoneCtrl.text = p.contactPhone;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().contains('10')
            ? (context.read<AppProvider>().appLanguage == 'bn'
                ? "প্লে স্টোর SHA-1 কি প্রয়োজন। আপনি অফলাইনেও চালিয়ে যেতে পারেন।"
                : "Google Sign-In needs SHA-1 configured. You can still continue offline.")
            : "Google Sign-In: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _handleSave() async {
    final org = _orgCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() => _isSaving = true);
    final p = context.read<AppProvider>();

    await p.saveOrganizationProfile(
      orgName: org,
      phone: phone,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            p.appLanguage == 'bn'
                ? "স্বাগতম! আপনার প্রোফাইল সফলভাবে সংরক্ষিত হয়েছে।"
                : "Welcome! Your organization profile has been saved.",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleSkip() async {
    final p = context.read<AppProvider>();
    if (_orgCtrl.text.trim().isNotEmpty || _phoneCtrl.text.trim().isNotEmpty) {
      await p.saveOrganizationProfile(
        orgName: _orgCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
    } else {
      await p.completeOnboarding();
    }
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final isBn = p.appLanguage == 'bn';
    final user = _auth.currentUser;
    final isLoggedIn = user != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon and Title
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isBn ? "টিউশন ফি ম্যানেজারে স্বাগতম" : "Welcome to Tuition Fee Manager",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
              ),
              const SizedBox(height: 4),
              Text(
                isBn
                    ? "আপনার কোচিং/প্রতিষ্ঠানের নাম এবং যোগাযোগের নম্বর প্রদান করুন।"
                    : "Set up your coaching center or academy details to get started.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),

              // Organization Name Field
              TextField(
                controller: _orgCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: isBn ? "কোচিং / প্রতিষ্ঠানের নাম *" : "Coaching / Organization Name *",
                  hintText: isBn ? "যেমন: বিজ্ঞান একাডেমি" : "e.g. Science Coaching",
                  prefixIcon: const Icon(Icons.business_rounded, color: Colors.deepPurple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Contact Number Field
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isBn ? "যোগাযোগের ফোন নম্বর (হোয়াটসঅ্যাপ)" : "Contact Phone / WhatsApp",
                  hintText: "01XXXXXXXXX",
                  prefixIcon: const Icon(Icons.phone_outlined, color: Colors.deepPurple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Google Sign In Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLoggedIn ? Colors.green.shade50 : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isLoggedIn ? Colors.green.shade200 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isLoggedIn ? Icons.cloud_done : Icons.cloud_sync_outlined,
                          size: 18,
                          color: isLoggedIn ? Colors.green.shade700 : Colors.deepPurple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isLoggedIn
                                ? (isBn ? "ক্লাউড সিঙ্ক সক্রিয়" : "Cloud Sync Active")
                                : (isBn ? "গুগল সাইন-ইন (ক্লাউড ব্যাকআপ)" : "Google Sign-In (Cloud Backup)"),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isLoggedIn ? Colors.green.shade900 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isLoggedIn) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.green.shade200,
                            child: Text(
                              user.displayName?.isNotEmpty == true ? user.displayName![0] : 'U',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        isBn
                            ? "গুগল দিয়ে সাইন ইন করলে আপনার সব ডাটা ক্লাউডে সুরক্ষিত থাকবে।"
                            : "Sign in with Google to sync your students & batches across devices.",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                        icon: _isSigningIn
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login, size: 18, color: Colors.deepPurple),
                        label: Text(
                          isBn ? "গুগল দিয়ে সাইন-ইন করুন" : "Sign In with Google",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Personal bKash & Nagad Validity Extension Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isBn ? "সাবস্ক্রিপশন ও ভ্যালিডিটি বৃদ্ধি" : "Subscription & Validity Extension",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isBn
                          ? "৫টি ব্যাচ বা ১০ শিক্ষার্থীর বেশি ব্যবহারের জন্য আমাদের বিকাশ ও নগদ পার্সোনাল নম্বরে সাবস্ক্রিপশন ফি পাঠিয়ে মেয়াদ বাড়াতে পারবেন:"
                          : "For more than 5 batches or 10 students, pay to our personal bKash/Nagad number to increase validity:",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade800, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2136E),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "bKash/নগদ",
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppProvider.ownerBkashNagadNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(const ClipboardData(text: AppProvider.ownerBkashNagadNumber));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isBn ? "নম্বর কপি করা হয়েছে" : "Payment number copied!"),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isBn ? "কপি" : "Copy",
                                style: const TextStyle(color: Colors.deepPurple, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isBn ? "শুরু করুন" : "Get Started",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _handleSkip,
                child: Text(
                  isBn ? "পরে পূরণ করব (অফলাইন মোড)" : "Skip for now (Offline Mode)",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
