import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../providers/app_provider.dart';
import '../dialoges/subscription_dialog.dart';
import '../screens/subscription_plan_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: "1222743060-292lpfs5ktq5tgfhupfveu62lt7rv5kh.apps.googleusercontent.com",
  );
  bool _isAuthLoading = false;

  void _showPlayStoreSha1HelpDialog() {
    final isBn = context.read<AppProvider>().appLanguage == 'bn';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isBn ? "গুগল সাইন-ইন সমাধান (SHA-1)" : "Play Store Google Sign-In Fix",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBn
                    ? "প্লে স্টোর থেকে ডাউনলোড করা অ্যাপে গুগল সাইন-ইন ব্যর্থ হওয়ার কারণ: গুগল প্লে কনসোলে অ্যাপ সাইনিং কি-এর SHA-1 ফিঙ্গারপ্রিন্ট ফায়ারবেস কনসোলে যুক্ত করা হয়নি।"
                    : "When downloaded from Google Play Store, Google re-signs the app with Google's Play App Signing Key. Your Firebase Console requires this SHA-1 fingerprint.",
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? "সহজ ৩টি পদক্ষেপ:" : "Quick 3 Steps to Fix:",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isBn
                          ? "১. Google Play Console-এ যান -> App integrity -> App signing\n২. 'App signing key certificate SHA-1' কপি করুন\n৩. Firebase Console -> Project Settings -> Android App-এ গিয়ে 'Add fingerprint' এ পেস্ট করুন!"
                          : "1. Google Play Console -> App integrity -> App signing\n2. Copy 'App signing key certificate SHA-1'\n3. Firebase Console -> Project Settings -> Android App -> Add fingerprint & paste!",
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isBn
                    ? "✓ নোট: আপনার অ্যাপের লোকাল ডাটাবেস সম্পূর্ণ সচল রয়েছে। আপনি এখনই কোনো সমস্যা ছাড়াই ব্যাচ ও শিক্ষার্থী পরিচালনা করতে পারেন।"
                    : "✓ Note: Local offline mode is active and working normally. You can continue managing batches and students without interruption.",
                style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? "বুঝেছি" : "Got It"),
          ),
        ],
      ),
    );
  }

  String _getUserName(User? user) {
    if (user == null) return "Guest (Offline Mode)";
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    if (user.email != null && user.email!.contains('@')) {
      final namePart = user.email!.split('@').first;
      return namePart
          .split(RegExp(r'[._-]'))
          .where((s) => s.isNotEmpty)
          .map((str) => str[0].toUpperCase() + str.substring(1))
          .join(' ');
    }
    return "User";
  }

  // ---------------- GOOGLE SIGN IN ----------------
  Future<void> _loginWithGoogle() async {
    try {
      setState(() => _isAuthLoading = true);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isAuthLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      if (!mounted) return;

      final provider = context.read<AppProvider>();
      // Seamlessly restore/merge cloud records with local Hive
      await provider.restoreFromFirebase(merge: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.tr('success')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      if (errStr.contains('10') || errStr.contains('sign_in_failed') || errStr.contains('ApiException')) {
        _showPlayStoreSha1HelpDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sign-in error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthLoading = false);
      }
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Logout"),
        content: const Text(
          "Are you sure you want to sign out? Your local data will remain safe on your device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      setState(() => _isAuthLoading = true);
      await _auth.signOut();
      await _googleSignIn.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Signed out. Operating in Local Offline Mode."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logout error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAuthLoading = false);
      }
    }
  }

  // ---------------- BACKUP TO FIREBASE ----------------
  Future<void> _handleBackup(AppProvider p) async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sign in with Google first to backup your data."),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await p.backupToFirebase();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "All local data backed up to Firebase Cloud!"
              : "Backup failed: ${p.syncStatusMessage}",
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------- RESTORE FROM FIREBASE ----------------
  Future<void> _handleRestore(AppProvider p) async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sign in with Google first to restore data."),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Restore from Cloud"),
        content: const Text(
          "Do you want to download your cloud data? Local data will be safely merged so no entries are lost.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Merge & Restore"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await p.restoreFromFirebase(merge: true);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Data successfully restored and merged from Firebase!"
              : "Restore failed: ${p.syncStatusMessage}",
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------- RESET LOCAL DATA ----------------
  Future<void> _handleResetLocalData(AppProvider p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Clear Local Database"),
        content: const Text(
          "Are you sure you want to clear local data from this device? If you backed up to Firebase, you can restore it later.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await p.clearLocalData();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Local data cleared."),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------- CURRENCY DIALOG ----------------
  void _showCurrencyPicker(AppProvider p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Select Currency Symbol"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("৳ (BDT Taka)"),
              leading: const Icon(Icons.currency_exchange),
              trailing: p.currencySymbol == '৳'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                p.setCurrencySymbol('৳');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text("TK (Text Taka)"),
              leading: const Icon(Icons.currency_exchange),
              trailing: p.currencySymbol == 'TK'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                p.setCurrencySymbol('TK');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text("\$ (Dollar)"),
              leading: const Icon(Icons.attach_money),
              trailing: p.currencySymbol == '\$'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                p.setCurrencySymbol('\$');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text("₹ (Rupee)"),
              leading: const Icon(Icons.currency_rupee),
              trailing: p.currencySymbol == '₹'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                p.setCurrencySymbol('₹');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatSyncTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "Never synced";
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24 && dt.day == now.day) {
        return "Today at ${DateFormat('hh:mm a').format(dt)}";
      }
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final user = _auth.currentUser;
    final isLoggedIn = user != null;
    final userName = _getUserName(user);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.tr('settings_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              p.tr('settings_subtitle'),
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Account & Profile Header Card
              _buildAccountCard(p, user, isLoggedIn, userName),
              const SizedBox(height: 16),

              // 2. Subscription & Plans
              _buildSubscriptionCard(p),
              const SizedBox(height: 16),

              // 3. Storage & Cloud Sync Section
              _buildStorageSyncCard(p, isLoggedIn),
              const SizedBox(height: 16),

              // 4. Local Database Statistics
              _buildDatabaseOverview(p),
              const SizedBox(height: 16),

              // 5. App Preferences (Currency, Language Ban/En, Clear Data)
              _buildPreferencesCard(p),
              const SizedBox(height: 16),

              // 6. App Info & Version
              _buildAppInfoCard(p),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- ACCOUNT CARD ----------------
  void _showEditOrgDialog(AppProvider p) {
    final orgCtrl = TextEditingController(text: p.organizationName);
    final phoneCtrl = TextEditingController(text: p.contactPhone);
    final isBn = p.appLanguage == 'bn';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isBn ? "প্রতিষ্ঠানের তথ্য" : "Organization Details",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: orgCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: isBn ? "কোচিং / প্রতিষ্ঠানের নাম" : "Organization Name",
                prefixIcon: const Icon(Icons.business_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: isBn ? "যোগাযোগের ফোন নম্বর" : "Contact Phone",
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(p.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await p.saveOrganizationProfile(
                orgName: orgCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBn ? "তথ্য সংরক্ষিত হয়েছে" : "Profile updated successfully!"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(p.tr('save')),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AppProvider p, User? user, bool isLoggedIn, String userName) {
    final hasOrg = p.organizationName.isNotEmpty || p.contactPhone.isNotEmpty;
    final isBn = p.appLanguage == 'bn';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLoggedIn ? Colors.deepPurple : Colors.grey.shade300,
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.deepPurple.shade50,
                  child: user?.photoURL != null
                      ? ClipOval(
                    child: Image.network(
                      user!.photoURL!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  )
                      : Text(
                    isLoggedIn && userName.isNotEmpty
                        ? userName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isLoggedIn ? Colors.deepPurple : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? "Offline Local Mode",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLoggedIn
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLoggedIn ? Icons.cloud_done : Icons.cloud_off,
                            size: 13,
                            color: isLoggedIn ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLoggedIn ? "Firebase Connected" : "Local Storage Active",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isLoggedIn ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasOrg) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_rounded, size: 18, color: Colors.deepPurple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.organizationName.isNotEmpty)
                          Text(
                            p.organizationName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple),
                          ),
                        if (p.contactPhone.isNotEmpty)
                          Text(
                            p.contactPhone,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.deepPurple),
                    tooltip: isBn ? "তথ্য পরিবর্তন" : "Edit Profile",
                    onPressed: () => _showEditOrgDialog(p),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _showEditOrgDialog(p),
                icon: const Icon(Icons.add_business_outlined, size: 16, color: Colors.deepPurple),
                label: Text(
                  isBn ? "+ প্রতিষ্ঠানের তথ্য যুক্ত করুন" : "+ Add Organization Info",
                  style: const TextStyle(fontSize: 12, color: Colors.deepPurple, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (_isAuthLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (!isLoggedIn)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onPressed: _loginWithGoogle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                    ),
                    child: const Icon(
                      Icons.g_mobiledata_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Sign in with Google to Sync",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.shade100),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                "Sign Out",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: _logout,
            ),
        ],
      ),
    );
  }

  // ---------------- STORAGE & CLOUD SYNC CARD ----------------
  Widget _buildStorageSyncCard(AppProvider p, bool isLoggedIn) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sync_rounded, color: Colors.deepPurple, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Data Storage & Firebase Sync",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              "Your tuition data is always stored locally on your phone (Hive) for instant offline speed. Connect to Firebase to back up and restore across devices.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Auto Sync Toggle
          SwitchListTile(
            title: const Text(
              "Auto-Sync Changes",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              "Automatically update Firebase when changes are made",
              style: TextStyle(fontSize: 12),
            ),
            value: p.isAutoSyncEnabled,
            activeThumbColor: Colors.deepPurple,
            onChanged: (val) => p.setAutoSyncEnabled(val),
          ),
          const Divider(height: 1),

          // Last Sync Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Last Cloud Sync:",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatSyncTime(p.lastSyncTime),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Manual Backup & Restore Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: p.isSyncing
                ? Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    p.syncStatusMessage ?? "Syncing...",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
                : Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text(
                      "Backup to Cloud",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _handleBackup(p),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text(
                      "Restore Data",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _handleRestore(p),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- DATABASE OVERVIEW CARD ----------------
  Widget _buildDatabaseOverview(AppProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storage_rounded, color: Colors.indigo, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                "Local Storage Statistics",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  "Batches",
                  "${p.batches.length}",
                  Icons.group_outlined,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  "Students",
                  "${p.students.length}",
                  Icons.school_outlined,
                  Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  "Payments",
                  "${p.paymentBox.length}",
                  Icons.receipt_long_outlined,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SUBSCRIPTION & PLANS CARD ----------------
  Widget _buildSubscriptionCard(AppProvider p) {
    final isBn = p.appLanguage == 'bn';
    final plan = p.currentPlan;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      p.tr('subscription_section_title'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: plan.isFree ? Colors.grey.shade100 : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isBn ? plan.nameBn : plan.nameEn,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: plan.isFree ? Colors.grey.shade800 : Colors.deepOrange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              isBn
                  ? "৫টি ব্যাচ ও ১০ জন শিক্ষার্থী পর্যন্ত বিনামূল্যে। এর অধিক ব্যবহারের জন্য আমাদের ওয়েবসাইট থেকে ৩টি প্রিমিয়াম প্ল্যানের যেকোনো একটি নির্বাচন করুন।"
                  : "Up to 5 batches & 10 students are free. Upgrade to higher plans on our website for unlimited access.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? "ব্যাচ কোটা" : "Batch Quota",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${p.batches.length} / ${plan.isUnlimitedBatches ? (isBn ? 'সীমাহীন' : 'Unlimited') : plan.batchLimit}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? "শিক্ষার্থী কোটা" : "Student Quota",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${p.students.length} / ${plan.isUnlimitedStudents ? (isBn ? 'সীমাহীন' : 'Unlimited') : plan.studentLimit}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, size: 16, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBn
                        ? "বিকাশ ও নগদ পার্সোনাল: ${AppProvider.ownerBkashNagadNumber}"
                        : "bKash & Nagad: ${AppProvider.ownerBkashNagadNumber}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: AppProvider.ownerBkashNagadNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isBn ? "নম্বর কপি করা হয়েছে" : "Payment number copied!"),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Text(
                      isBn ? "কপি" : "Copy",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                  label: Text(
                    p.tr('subscription_plans_pricing'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => SubscriptionPlanScreen.navigate(context),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade800,
                    side: BorderSide(color: Colors.grey.shade300),
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.vpn_key_outlined, size: 16),
                  label: Text(
                    p.tr('enter_activation_code'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => SubscriptionDialog.show(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- LANGUAGE PICKER DIALOG ----------------
  void _showLanguagePicker(AppProvider p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(p.tr('app_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("English"),
              leading: const Icon(Icons.language),
              trailing: p.appLanguage == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                p.setAppLanguage('en');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text("বাংলা (Bangla)"),
              leading: const Icon(Icons.translate),
              trailing: p.appLanguage == 'bn'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                p.setAppLanguage('bn');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- PREFERENCES CARD ----------------
  Widget _buildPreferencesCard(AppProvider p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.blue, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  p.tr('preferences_title'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Language Selector Option (Ban / En)
          ListTile(
            leading: const Icon(Icons.translate_rounded, color: Colors.indigo),
            title: Text(p.tr('app_language'), style: const TextStyle(fontSize: 14)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.appLanguage == 'bn' ? "বাংলা (Ban)" : "English",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: () => _showLanguagePicker(p),
          ),
          const Divider(height: 1),

          // Currency Symbol
          ListTile(
            leading: const Icon(Icons.currency_exchange, color: Colors.green),
            title: Text(p.tr('currency_symbol'), style: const TextStyle(fontSize: 14)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.currencySymbol,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: () => _showCurrencyPicker(p),
          ),
          const Divider(height: 1),

          // Clear Local Data
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            title: Text(
              p.tr('clear_local_data'),
              style: const TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
            subtitle: Text(
              p.tr('clear_local_data_desc'),
              style: const TextStyle(fontSize: 11),
            ),
            onTap: () => _handleResetLocalData(p),
          ),
        ],
      ),
    );
  }

  // ---------------- APP INFO CARD ----------------
  Widget _buildAppInfoCard(AppProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: Colors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                p.tr('about_app'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.tr('app_name_label'), style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Text(p.tr('app_name_value'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.tr('app_version_label'), style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const Text("v1.1.0+5", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.tr('offline_support_label'), style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Text(p.tr('offline_support_val'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.tr('cloud_db_label'), style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Text(p.tr('cloud_db_val'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
            ],
          ),
        ],
      ),
    );
  }
}