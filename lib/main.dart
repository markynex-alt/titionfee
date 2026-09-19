import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/batch_screen.dart';
import 'screens/student_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/account_screen.dart'; // make sure this file exists

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open all boxes used in AppProvider
  await Hive.openBox('batches');
  await Hive.openBox('students');
  await Hive.openBox('payments');
  await Hive.openBox('settings');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MainNav(),
      ),
=======
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
>>>>>>> 4d468ac3f4498ed06e9535c71266a6cff83aa7e6
    );
  }
}

<<<<<<< HEAD
class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int index = 0;

  void _navigateToTab(int tabIndex) {
    setState(() {
      index = tabIndex;
    });
=======
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
>>>>>>> 4d468ac3f4498ed06e9535c71266a6cff83aa7e6
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final pages = [
      HomeScreen(onNavigate: _navigateToTab), // Pass the callback here
      const BatchScreen(),
      const StudentScreen(),
      const AccountScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: "Home"),
          NavigationDestination(icon: Icon(Icons.group), label: "Batch"),
          NavigationDestination(icon: Icon(Icons.school), label: "Students"),
          NavigationDestination(icon: Icon(Icons.account_circle), label: "Account"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
=======
    return const FirstScreen(); // Load your first screen normally
>>>>>>> 4d468ac3f4498ed06e9535c71266a6cff83aa7e6
  }
}
