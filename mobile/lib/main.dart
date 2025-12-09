import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/dashboard_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/account_screen.dart';

void main() async {
  runApp(const ProviderScope(child: CropAIModernApp()));
}

class CropAIModernApp extends StatelessWidget {
  const CropAIModernApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop AI Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D7377),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const CropAIDashboard(),
    );
  }
}

class CropAIDashboard extends StatefulWidget {
  const CropAIDashboard({Key? key}) : super(key: key);

  @override
  State<CropAIDashboard> createState() => _CropAIDashboardState();
}

class _CropAIDashboardState extends State<CropAIDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MarketplaceScreen(),
    const AlertsScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_rounded),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Marketplace',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_rounded),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
