import 'package:flutter/material.dart';
import 'backup_actions_bar.dart';
import 'expence_screen.dart';
import 'finance_model.dart';
import 'income_screen.dart';

class BackupHomeScreen extends StatefulWidget {
  const BackupHomeScreen({super.key});

  @override
  State<BackupHomeScreen> createState() => _BackupHomeScreenState();
}

class _BackupHomeScreenState extends State<BackupHomeScreen> {
  Future<void> _reloadAllModules() async {
    await loadFinanceDataFromPrefs();
    await loadExpenseScreenData();
    await loadIncomeScreenData();
    // భవిష్యత్తులో వచ్చే మిగిలిన మాడ్యూల్స్ లోడ్ ఫంక్షన్లను ఇక్కడ కలపండి
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackupRestoreBar(onRestored: _reloadAllModules),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpenceScreen()),
                );
              },
              child: const Text('Open Expense Screen'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IncomeScreen()),
                );
              },
              child: const Text('Open Income Screen'),
            ),
          ],
        ),
      ),
    );
  }
}