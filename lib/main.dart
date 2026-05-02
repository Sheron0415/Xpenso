import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = true;
  Map<String, dynamic>? user;
  bool isLoading = true;
  bool showSplash = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  void loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isDark = prefs.getBool('isDark') ?? true;
        isLoading = false;
      });
    }
    
    // Show splash for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => showSplash = false);
    });
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDark = !isDark);
    await prefs.setBool('isDark', isDark);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    Widget homeWidget;
    if (showSplash) {
      homeWidget = const SplashScreen(nextScreen: SizedBox());
    } else if (user == null) {
      homeWidget = LoginPage(onLogin: (u) => setState(() => user = u));
    } else {
      homeWidget = DashboardPage(
        user: user!,
        isDark: isDark,
        onToggleTheme: toggleTheme,
        onLogout: () => setState(() => user = null),
        onUserUpdate: (updatedUser) => setState(() => user = updatedUser),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff0F172A),
        cardColor: const Color(0xff1E293B),
        useMaterial3: true,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: homeWidget,
    );
  }
}
