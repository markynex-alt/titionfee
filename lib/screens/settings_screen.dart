import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool isLoading = false;

  // Helper to extract a formatted name from email if displayName is null
  String _getUserName(User? user) {
    if (user == null) return "Not Logged In";
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null && user.email!.contains('@')) {
      final namePart = user.email!.split('@').first;
      return namePart
          .split(RegExp(r'[._-]'))
          .map((str) => str.isNotEmpty
          ? str[0].toUpperCase() + str.substring(1)
          : '')
          .join(' ');
    }
    return "User";
  }

  // ---------------- GOOGLE LOGIN ----------------
  Future<void> _loginWithGoogle() async {
    try {
      setState(() => isLoading = true);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled login

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      if (!mounted) return;

      // Sync user data with Firebase upon successful login
      final provider = context.read<AppProvider>();
      await provider.loadBatchesFromFirebase();
      await provider.loadStudentsFromFirebase();
      await provider.loadPaymentsFromFirebase();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login successful & data synced"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> _logout() async {
    try {
      setState(() => isLoading = true);
      await _auth.signOut();
      await _googleSignIn.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Account Card
              _buildAccountCard(user),
              const SizedBox(height: 20),

              // App Information Section
              _buildAppInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- ACCOUNT CARD ----------
  Widget _buildAccountCard(User? user) {
    final isLoggedIn = user != null;
    final userName = _getUserName(user);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isLoggedIn
                    ? Colors.deepPurple.shade300
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.deepPurple.shade50,
              child: user?.photoURL != null
                  ? ClipOval(
                child: Image.network(
                  user!.photoURL!,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 32,
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
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isLoggedIn
                      ? Colors.deepPurple
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // --- DISPLAY USER NAME ---
          Text(
            userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),

          // --- DISPLAY EMAIL OR HELPER TEXT ---
          Text(
            user?.email ?? "Sign in with Google to backup and sync your data.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(),
            )
          else if (!isLoggedIn)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onPressed: _loginWithGoogle,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Sign in with Google",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.redAccent),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                "Logout Account",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: _logout,
            ),
        ],
      ),
    );
  }

  // ---------- APP INFO SECTION ----------
  Widget _buildAppInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_sync_outlined,
                  color: Colors.deepPurple, size: 20),
            ),
            title: const Text(
              "Cloud Backup",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              "Syncs local Hive database with Firestore",
              style: TextStyle(fontSize: 12),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
            ),
            title: const Text(
              "App Version",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            trailing: const Text(
              "v1.0.0",
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}