import 'package:flutter/material.dart';
import 'income_screen.dart';
import 'expense_screen.dart';

class AppHomeScreen extends StatelessWidget {
  const AppHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // INCOME CARD
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 28,
                  child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 30),
                ),
                title: const Text('INCOME', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                subtitle: const Text('Manage Income & Sources', style: TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IncomeScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            // EXPENSES CARD
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 28,
                  child: Icon(Icons.money_off, color: Colors.white, size: 30),
                ),
                title: const Text('EXPENSES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                subtitle: const Text('Manage Expenses & Outgoings', style: TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    // గమనించండి: ఇక్కడ ExpenseScreen() ముందు 'const' ఉండకూడదు!
                    MaterialPageRoute(builder: (context) => ExpenseScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}