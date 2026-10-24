import 'package:flutter/material.dart';
import 'income_screen.dart';
import 'screens/expence_screen.dart';

final List<Map<String, dynamic>> kMainHeadings = [
  {
    'title': 'Income Management',
    'subtitle': 'Manage earnings, person balances and deposits',
    'icon': Icons.trending_up,
    'color': Colors.green,
    'screen': const IncomeScreen(),
  },
  {
    'title': 'Expenses Management',
    'subtitle': 'Track expenses, sub-categories and net balance',
    'icon': Icons.trending_down,
    'color': Colors.red,
    'screen': const ExpenceScreen(),
  },
  {
    'title': 'Bank Accounts',
    'subtitle': 'Manage cash and bank accounts',
    'icon': Icons.account_balance,
    'color': Colors.blue,
    'screen': const IncomeScreen(),
  },
  {
    'title': 'Reports & Analytics',
    'subtitle': 'View financial summaries and date filters',
    'icon': Icons.bar_chart,
    'color': Colors.orange,
    'screen': const IncomeScreen(),
  },
  {
    'title': 'Categories',
    'subtitle': 'Setup income and expense categories',
    'icon': Icons.category,
    'color': Colors.purple,
    'screen': const IncomeScreen(),
  },
  {
    'title': 'Settings & Backup',
    'subtitle': 'App preferences and data management',
    'icon': Icons.settings,
    'color': Colors.grey,
    'screen': const IncomeScreen(),
  },
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Finance Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: kMainHeadings.length,
          itemBuilder: (context, index) {
            final heading = kMainHeadings[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (heading['color'] as MaterialColor).shade100,
                  child: Icon(heading['icon'], color: heading['color']),
                ),
                title: Text(
                  heading['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(heading['subtitle']),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => heading['screen']),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}