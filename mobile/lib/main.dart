import 'package:flutter/material.dart';
import 'screens/profile_screen.dart';
import 'screens/map_screen.dart';
import 'screens/report_screen.dart';
import 'screens/notices_screen.dart';
import 'models/barrier.dart';

void main() {
  runApp(const ViaLibreApp());
}

class ViaLibreApp extends StatelessWidget {
  const ViaLibreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VíaLibre',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A192F),
        primaryColor: const Color(0xFFFFB300),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFB300),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF0F2444),
          error: Color(0xFFEF4444),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF071224),
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFFFFFFF)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFCBD5E1)),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  AccessibilityProfile _profile = AccessibilityProfile.wheelchair;

  void _onProfileSelected(AccessibilityProfile profile) {
    setState(() {
      _profile = profile;
      _currentIndex = 1; // Avanza a la pantalla de ruta
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProfileScreen(
        selectedProfile: _profile,
        onProfileChanged: _onProfileSelected,
      ),
      MapScreen(profile: _profile),
      ReportScreen(profile: _profile),
      const NoticesScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF071224),
        indicatorColor: const Color(0xFFFFB300),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.accessible),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'Ruta',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_a_photo_outlined),
            label: 'Reportar',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            label: 'Avisos',
          ),
        ],
      ),
    );
  }
}
