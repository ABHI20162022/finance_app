import 'package:flutter/material.dart';
import 'models/finance_model.dart'; // 1. ఇది చాలా ముఖ్యం (loadFinanceDataFromPrefs కోసం)
import 'screens/income_screen.dart';
import 'screens/expence_screen.dart';
import 'screens/shopping_screen.dart';
import 'screens/assets_liabilities_screen.dart';

void main() async {
  // ఫ్లట్టర్ బైండింగ్స్ ఇనిషియలైజ్ చేయడం
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. యాప్ స్టార్ట్ అవ్వగానే లోకల్ స్టోరేజ్ నుండి సేవ్ అయిన డేటాను మెమరీలోకి తెచ్చుకోవడం!
  await loadFinanceDataFromPrefs();
  
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const MainDashboardScreen(),
    );
  }
}

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Finance Dashboard'),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Income Management Card
          _buildDashboardCard(
            context,
            title: 'Income Management',
            subtitle: 'Track your earnings, salary and income sources',
            icon: Icons.arrow_downward,
            color: Colors.green,
            destination: const IncomeScreen(),
          ),
          const SizedBox(height: 16),

          // 2. Expence Tracking Card
          _buildDashboardCard(
            context,
            title: 'Expence Tracking',
            subtitle: 'Monitor your daily spending and bills',
            icon: Icons.arrow_upward,
            color: Colors.red,
            destination: const ExpenceScreen(),
          ),
          const SizedBox(height: 16),

          // 3. Shopping Management Card
          _buildDashboardCard(
            context,
            title: 'Shopping Management',
            subtitle: 'Categories, shops, required lists & bill viewer',
            icon: Icons.shopping_cart,
            color: Colors.orange,
            destination: const ShoppingScreen(),
          ),
          const SizedBox(height: 16),

          // 4. Assets & Liabilities Card
          _buildDashboardCard(
            context,
            title: 'Assets & Liabilities',
            subtitle: 'Track your properties, savings, loans & net worth',
            icon: Icons.account_balance,
            color: Colors.teal,
            destination: const AssetsLiabilitiesScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}