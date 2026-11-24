import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/finance_model.dart';
import 'screens/income_screen.dart';
import 'screens/expence_screen.dart';
import 'screens/shopping_screen.dart';
import 'screens/assets_liabilities_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/reminders_info_screen.dart';
import 'screens/fixed_expenses_screen.dart';
import 'screens/activation_screen.dart';
import 'utils/backup_helper.dart';

const String adminPhoneNumber = "8985498085";
String? startupErrorMessage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await loadFinanceDataFromPrefs();
  } catch (e) {
    startupErrorMessage = "Finance load error: $e";
  }

  try {
    await loadAllAssetsLoansData();
  } catch (e) {
    startupErrorMessage = (startupErrorMessage == null)
        ? "Assets/Loans load error: $e"
        : "$startupErrorMessage\nAssets/Loans load error: $e";
  }

  bool isAllowed = false;
  try {
    isAllowed = await checkAppAccessPermission();
  } catch (e) {
    startupErrorMessage = (startupErrorMessage == null)
        ? "Permission check error: $e"
        : "$startupErrorMessage\nPermission check error: $e";
  }

  runApp(FinanceApp(isAllowed: isAllowed));
}

Future<bool> checkAppAccessPermission() async {
  bool isTestingOnLaptop = true;
  if (isTestingOnLaptop) {
    return true;
  }

  final prefs = await SharedPreferences.getInstance();

  String? savedPhone = prefs.getString('user_phone');
  if (savedPhone == adminPhoneNumber) {
    return true;
  }

  bool isActivated = prefs.getBool('is_activated') ?? false;
  if (!isActivated) return false;

  String? expiryStr = prefs.getString('app_expiry_date');
  if (expiryStr == null) return false;

  try {
    int day = int.parse(expiryStr.substring(0, 2));
    int month = int.parse(expiryStr.substring(2, 4));
    int year = int.parse(expiryStr.substring(4, 8));
    DateTime expiryDate = DateTime(year, month, day, 23, 59, 59);

    DateTime now = DateTime.now();
    if (now.isBefore(expiryDate)) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

class FinanceApp extends StatelessWidget {
  final bool isAllowed;
  const FinanceApp({super.key, required this.isAllowed});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: isAllowed ? const MainDashboardScreen() : const ActivationScreen(),
    );
  }
}

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  Future<void> _handleDataRestored() async {
    await loadFinanceDataFromPrefs();
    await loadExpenseScreenData();
    await loadIncomeScreenData();
    await loadAllAssetsLoansData();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBackupRestoreSection() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.backup, size: 18),
            label: const Text('Backup'),
            onPressed: () async {
              try {
                await BackupHelper.exportBackupFile();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Backup JSON ready! Save to Google Drive, WhatsApp, or Files.',
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Backup failed: $e')),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('Restore'),
            onPressed: () async {
              try {
                final restored = await BackupHelper.importBackupFile();
                if (!restored) return;
                await _handleDataRestored();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backup restored successfully!'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restore failed: $e')),
                );
              }
            },
          ),
        ),
      ],
    );
  }

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
          if (startupErrorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                border: Border.all(color: Colors.amber.shade800),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                startupErrorMessage!,
                style: const TextStyle(color: Colors.black87, fontSize: 13),
              ),
            ),
          ],
          _buildBackupRestoreSection(),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            title: 'Income Management',
            subtitle: 'Track your earnings, salary and income sources',
            icon: Icons.arrow_downward,
            color: Colors.green,
            destination: const IncomeScreen(),
          ),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            title: 'Expence Tracking',
            subtitle: 'Monitor your daily spending and bills',
            icon: Icons.arrow_upward,
            color: Colors.red,
            destination: const ExpenceScreen(),
          ),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            title: 'Shopping Management',
            subtitle: 'Categories, shops, required lists & bill viewer',
            icon: Icons.shopping_cart,
            color: Colors.orange,
            destination: const ShoppingScreen(),
          ),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            title: 'Assets & Liabilities',
            subtitle: 'Track your properties, savings, loans & net worth',
            icon: Icons.account_balance,
            color: Colors.teal,
            destination: const AssetsLiabilitiesScreen(),
          ),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            title: 'Financial Reports',
            subtitle:
                'View overall income, expenses, net balance & category breakdown',
            icon: Icons.bar_chart,
            color: Colors.blue,
            destination: const ReportsScreen(),
          ),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            title: 'Reminders & General Info',
            subtitle: 'Manage your payment reminders and important notes',
            icon: Icons.notifications_active,
            color: Colors.indigo,
            destination: const RemindersInfoScreen(),
          ),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            title: 'Fixed Expenses & Fees Tracker',
            subtitle:
                'Track school fees, bus fees & remaining balance for children',
            icon: Icons.account_balance_wallet,
            color: Colors.purple,
            destination: const FixedExpensesScreen(),
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
