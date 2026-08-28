import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../utils/bangla_number.dart';
import 'quiz_home.dart';

class ResultPage extends StatefulWidget {
  final double score;

  const ResultPage({super.key, required this.score});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final String messageUrl = "https://markynex.com/result_messages.json";

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String resultMessage = "লোড হচ্ছে...";
  bool loadingMessage = true;

  User? _user;

  double _userTotalScore = 0;
  double _currentScore = 0;

  bool _loginLoading = false;

  @override
  void initState() {
    super.initState();

    _currentScore = widget.score;

    _loadMessage();
    _checkUser();
  }

  Future<void> _checkUser() async {
    _user = _auth.currentUser;

    if (_user == null) return;

    try {
      final doc = await _firestore
          .collection("leaderboard")
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        final email = data["email"]?.toString() ?? "";
        final username = data["username"]?.toString() ?? "User";

        await _saveOrUpdateScore(email: email, username: username);
      }
    } catch (e) {
      debugPrint("Load User Error: $e");
    }
  }

  String maskEmail(String? email) {
    if (email == null || email.isEmpty || !email.contains('@')) {
      return "unknown@email.com";
    }

    final parts = email.split('@');

    if (parts.length < 2) {
      return "unknown@email.com";
    }

    final namePart = parts[0];
    final domainPart = parts[1];

    if (namePart.length <= 1) {
      return "*@$domainPart";
    }

    if (namePart.length <= 3) {
      return "${namePart[0]}***@$domainPart";
    }

    final start = namePart.substring(0, 3);

    final end = namePart.length >= 5
        ? namePart.substring(namePart.length - 2)
        : "";

    return "$start***$end@$domainPart";
  }

  Future<void> _loadMessage() async {
    try {
      final response = await http.get(Uri.parse(messageUrl));

      if (response.statusCode != 200) {
        throw Exception("Failed");
      }

      final List data = json.decode(response.body);

      if (data.isEmpty) {
        throw Exception("Empty JSON");
      }

      List<String> messages = [];

      if (_currentScore > 7) {
        messages = List<String>.from(data[0]["high"] ?? []);
      } else if (_currentScore >= 4) {
        messages = List<String>.from(data[0]["medium"] ?? []);
      } else {
        messages = List<String>.from(data[0]["low"] ?? []);
      }

      setState(() {
        resultMessage = messages.isNotEmpty
            ? messages[Random().nextInt(messages.length)]
            : "অভিনন্দন!";

        loadingMessage = false;
      });
    } catch (e) {
      setState(() {
        resultMessage = "মেসেজ লোড করা যায়নি";
        loadingMessage = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() {
        _loginLoading = true;
      });

      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _loginLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      _user = userCredential.user;

      await _saveOrUpdateScore(
        email: googleUser.email,
        username: googleUser.displayName ?? _user?.displayName ?? "User",
      );

      if (mounted) {
        setState(() {
          _loginLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Google Login Error: $e");

      if (mounted) {
        setState(() {
          _loginLoading = false;
        });
      }
    }
  }

  Future<void> _saveOrUpdateScore({
    required String email,
    required String username,
  }) async {
    if (_user == null) {
      debugPrint("USER IS NULL");
      return;
    }

    try {
      debugPrint("USER UID: ${_user!.uid}");
      debugPrint("EMAIL: $email");
      debugPrint("CURRENT SCORE: $_currentScore");

      final docRef = _firestore.collection("leaderboard").doc(_user!.uid);

      final doc = await docRef.get();

      debugPrint("DOC EXISTS: ${doc.exists}");

      double oldScore = 0;

      if (doc.exists) {
        final data = doc.data()!;

        oldScore = (data["score"] as num?)?.toDouble() ?? 0;

        debugPrint("OLD SCORE: $oldScore");
      }

      final double newScore = oldScore + _currentScore;

      debugPrint("NEW SCORE: $newScore");

      await docRef.set({
        "uid": _user!.uid,
        "username": username,
        "email": email,
        "photoURL": _user!.photoURL,
        "score": newScore,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("SAVE SUCCESS");

      final verify = await docRef.get();

      debugPrint("VERIFY SCORE: ${verify.data()?["score"]}");

      _userTotalScore = newScore;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("SAVE ERROR: $e");
    }
  }

  Widget _buildLeaderboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('leaderboard').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            "Firestore Error:\n${snapshot.error}",
            textAlign: TextAlign.center,
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            "এখনো কোনো স্কোর জমা হয়নি",
            style: TextStyle(fontSize: 16),
          );
        }

        final docs = snapshot.data!.docs.toList();

        docs.sort((a, b) {
          final scoreA = double.tryParse(a['score'].toString()) ?? 0;

          final scoreB = double.tryParse(b['score'].toString()) ?? 0;

          return scoreB.compareTo(scoreA);
        });

        final topFive = docs.take(5).toList();

        return Column(
          children: topFive.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value.data() as Map<String, dynamic>;

            final username = data["username"]?.toString() ?? "User";

            final email = data["email"]?.toString() ?? "";

            final score = double.tryParse(data["score"].toString()) ?? 0;

            IconData icon;
            Color color;

            switch (index) {
              case 0:
                icon = Icons.emoji_events;
                color = Colors.amber;
                break;
              case 1:
                icon = Icons.workspace_premium;
                color = Colors.grey;
                break;
              case 2:
                icon = Icons.workspace_premium;
                color = Colors.brown;
                break;
              default:
                icon = Icons.star;
                color = Colors.indigo;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(blurRadius: 10, color: Colors.black12),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(.15),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(maskEmail(email)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    score.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "ফলাফল",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _user != null
              ? IconButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();

                    await GoogleSignIn().signOut();

                    setState(() {
                      _user = null;
                      _userTotalScore = 0;
                      _currentScore = 0;
                    });
                  },
                  icon: const Icon(Icons.logout),
                )
              : const SizedBox(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade100, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade400,
                      Colors.deepPurple.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "আপনার প্রাপ্ত নম্বর",
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          toBanglaNumber(_currentScore.toStringAsFixed(2)),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().scale(duration: 600.ms),

                    const SizedBox(height: 20),

                    loadingMessage
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            resultMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),

                    const SizedBox(height: 15),

                    const Text(
                      "প্রতি মাসের শীর্ষ স্কোরধারীরা পাবেন আকর্ষণীয় পুরস্কার।",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (_user == null)
                _loginLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _signInWithGoogle,
                          icon: const Icon(Icons.login, color: Colors.white),
                          label: const Text(
                            "Google দিয়ে লগইন করুন",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),

              if (_user != null)
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: _user!.photoURL != null
                                ? NetworkImage(_user!.photoURL!)
                                : null,
                            child: _user!.photoURL == null
                                ? const Icon(Icons.person, size: 35)
                                : null,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "স্বাগতম, ${_user!.displayName}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "মোট স্কোর: ${toBanglaNumber(_userTotalScore.toStringAsFixed(2))}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.leaderboard, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          "শীর্ষ ৫ জনের তালিকা",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildLeaderboard(),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const QuizHome()),
                          );
                        },
                        icon: const Icon(Icons.replay, color: Colors.white),
                        label: const Text(
                          "আবার খেলুন",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
