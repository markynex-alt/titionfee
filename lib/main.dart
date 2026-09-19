import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/batch_screen.dart';
import 'screens/student_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/account_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // If Firebase init options fail on an unconfigured target, try fallback
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }

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
      child: MaterialApp(
        title: "Tuition Fee Manager",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            primary: const Color(0xFF5B4DFF),
            surface: const Color(0xFFF8F9FA),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1E1E2E),
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E2E),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            elevation: 8,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFEDE7F6),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFF5B4DFF));
              }
              return const IconThemeData(color: Colors.grey);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B4DFF),
                );
              }
              return const TextStyle(fontSize: 12, color: Colors.grey);
            }),
          ),
        ),
        home: const MainNav(),
      ),
    );
  }
}

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
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigate: _navigateToTab),
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
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: "Home"),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: "Batch"),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: "Students"),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: "Account"),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
