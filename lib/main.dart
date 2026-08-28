import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/first_screen.dart';
import 'package:in_app_update/in_app_update.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "হাবলু কুইজ",
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const FirstScreenWrapper(), // Wrap first screen to check updates
    );
  }
}

/// This widget wraps your FirstScreen to check app updates
class FirstScreenWrapper extends StatefulWidget {
  const FirstScreenWrapper({super.key});

  @override
  State<FirstScreenWrapper> createState() => _FirstScreenWrapperState();
}

class _FirstScreenWrapperState extends State<FirstScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  /// -------------------------
  /// Check for update using in_app_update package
  /// -------------------------
  Future<void> _checkUpdate() async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Force immediate update
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      // If update check fails, just continue to app
      debugPrint("Update check failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const FirstScreen(); // Load your first screen normally
  }
}
