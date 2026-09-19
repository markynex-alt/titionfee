import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isAuthLoading = false;

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
        const SnackBar(
          content: Text("Signed in successfully & synchronized with Firebase!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sign-in error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Settings",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "Storage, Cloud Backup & Preferences",
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
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
              _buildAccountCard(user, isLoggedIn, userName),
              const SizedBox(height: 16),

              // 2. Storage & Cloud Sync Section
              _buildStorageSyncCard(p, isLoggedIn),
              const SizedBox(height: 16),

              // 3. Local Database Statistics
              _buildDatabaseOverview(p),
              const SizedBox(height: 16),

              // 4. App Preferences
              _buildPreferencesCard(p),
              const SizedBox(height: 16),

              // 5. App Info & Version
              _buildAppInfoCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- ACCOUNT CARD ----------------
  Widget _buildAccountCard(User? user, bool isLoggedIn, String userName) {
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
                const Text(
                  "Preferences & Maintenance",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.currency_exchange, color: Colors.green),
            title: const Text("Currency Symbol", style: TextStyle(fontSize: 14)),
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
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            title: const Text(
              "Clear Local Data",
              style: TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
            subtitle: const Text(
              "Removes local device database entries",
              style: TextStyle(fontSize: 11),
            ),
            onTap: () => _handleResetLocalData(p),
          ),
        ],
      ),
    );
  }

  // ---------------- APP INFO CARD ----------------
  Widget _buildAppInfoCard() {
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
              const Text(
                "About Application",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Application Name", style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text("Tuition Fee Manager", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Version", style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text("v1.0.0+4", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Offline Support", style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text("Enabled (Hive Engine)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cloud Database", style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text("Firebase Cloud Firestore", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
            ],
          ),
        ],
      ),
    );
  }
}