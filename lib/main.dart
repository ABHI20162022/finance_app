import 'package:flutter/material.dart';
import 'income_screen.dart';
import 'expense_screen.dart';
import 'shopping_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance & Shopping Manager',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  // ప్రత్యేక స్క్రీన్‌కి వెళ్లడానికి నావిగేషన్ ఫంక్షన్
  void _navigateToModule(BuildContext context, String title, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.teal[900],
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: screen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finance & Shopping Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[900],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. INCOME TAB (ఒకదాని కింద ఒకటి)
            _buildCategoryCard(
              context,
              title: 'Income Management',
              subtitle: 'ఆదాయ వివరాలు మరియు ఎంట్రీలు',
              icon: Icons.account_balance_wallet,
              color: Colors.green[700]!,
              onTap: () => _navigateToModule(context, 'Income Management', const IncomeScreen()),
            ),
            const SizedBox(height: 16),

            // 2. EXPENSE TAB
            _buildCategoryCard(
              context,
              title: 'Expense Management',
              subtitle: 'ఖర్చుల వివరాలు మరియు ఎంట్రీలు',
              icon: Icons.money_off,
              color: Colors.red[700]!,
              onTap: () => _navigateToModule(context, 'Expense Management', const ExpenseScreen()),
            ),
            const SizedBox(height: 16),

            // 3. SHOPPING TAB
            _buildCategoryCard(
              context,
              title: 'Shopping & Materials',
              subtitle: 'ముడి సరుకులు మరియు కొనుగోళ్ల జాబితా',
              icon: Icons.shopping_cart,
              color: Colors.indigo[800]!,
              onTap: () => _navigateToModule(context, 'Shopping & Materials', const ShoppingScreen()),
            ),
          ],
        ),
      ),
    );
  }

  // విడివిడిగా ఒకదాని కింద ఒకటి కనిపించే కార్డ్ డిజైన్
  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}