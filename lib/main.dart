import 'package:flutter/material.dart';
import 'screens/income_screen.dart';
import 'screens/expence_screen.dart';
import 'screens/shopping_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/assets_liabilities_screen.dart';
import 'screens/reports_screen.dart';

void main() {
  runApp(const FinanceManagerApp());
}

class FinanceManagerApp extends StatelessWidget {
  const FinanceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance & Shopping Manager',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  // అన్ని ప్రధాన స్క్రీన్‌ల లిస్ట్
  final List<Widget> _screens = [
    const IncomeScreen(),
    const ExpenceScreen(),
    const ShoppingScreen(),
    const RemindersScreen(),
    const AssetsLiabilitiesScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red.shade700,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Income'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Expense'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Shopping'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Assets & Debt'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}