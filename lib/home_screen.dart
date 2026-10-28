import 'package:flutter/material.dart';
import 'income_screen.dart';
import 'screens/expence_screen.dart';
import 'screens/shopping_screen.dart';
import 'screens/assets_liabilities_screen.dart';

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
    'screen': ExpenceScreen(),
  },
  {
    'title': 'Shopping Management',
    'subtitle': 'Categories, shops, required lists & bill viewer',
    'icon': Icons.shopping_cart,
    'color': Colors.orange,
    'screen': const ShoppingScreen(),
  },
  {
    'title': 'Assets & Liabilities',
    'subtitle': 'Track properties, savings, loans & net worth',
    'icon': Icons.account_balance,
    'color': Colors.teal,
    'screen': const AssetsLiabilitiesScreen(),
  },
  {
    'title': 'Reports & Analytics',
    'subtitle': 'View financial summaries and date filters',
    'icon': Icons.bar_chart,
    'color': Colors.amber.shade800,
    'screen': const IncomeScreen(), // అవసరమైన స్క్రీన్ కి మార్చుకోవచ్చు
  },
  {
    'title': 'Settings & Backup',
    'subtitle': 'App preferences and data management',
    'icon': Icons.settings,
    'color': Colors.blueGrey,
    'screen': const IncomeScreen(), // అవసరమైన స్క్రీన్ కి మార్చుకోవచ్చు
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
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: kMainHeadings.length,
          itemBuilder: (context, index) {
            final heading = kMainHeadings[index];
            final Color itemColor = heading['color'];
            
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: itemColor.withOpacity(0.2),
                  child: Icon(heading['icon'], color: itemColor),
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