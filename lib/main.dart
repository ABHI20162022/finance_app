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

// మీ అసలు అడ్మిన్ ఫోన్ నెంబర్ ఇక్కడ ఇవ్వండి
const String adminPhoneNumber = "8985498085"; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadFinanceDataFromPrefs();
  
  bool isAllowed = await checkAppAccessPermission();

  runApp(FinanceApp(isAllowed: isAllowed));
}

Future<bool> checkAppAccessPermission() async {
  // ---------------------------------------------------------
  // 🛠️ లాప్‌టాప్ టెస్టింగ్ మోడ్:
  // ప్రస్తుతం టెస్ట్ చేయడానికి 'true' లో ఉంచండి. 
  // మీరు ఫైనల్ APK బిల్డ్ చేసేటప్పుడు దీన్ని 'false' చేయాలి!
  // ---------------------------------------------------------
  bool isTestingOnLaptop = false; 
  if (isTestingOnLaptop) {
    return true; 
  }

  final prefs = await SharedPreferences.getInstance();
  
  // అడ్మిన్ ఫోన్ నెంబర్ చెకింగ్
  String? savedPhone = prefs.getString('user_phone');
  if (savedPhone == adminPhoneNumber) {
    return true;
  }

  // సాధారణ యూజర్ కోసం ఆక్టివేషన్ & ఎక్స్‌పైరీ చెకింగ్
  bool isActivated = prefs.getBool('is_activated') ?? false;
  if (!isActivated) return false;

  String? expiryStr = prefs.getString('app_expiry_date'); // Format: DDMMYYYY
  if (expiryStr == null) return false;

  try {
    int day = int.parse(expiryStr.substring(0, 2));
    int month = int.parse(expiryStr.substring(2, 4));
    int year = int.parse(expiryStr.substring(4, 8));
    DateTime expiryDate = DateTime(year, month, day, 23, 59, 59);

    DateTime now = DateTime.now();
    if (now.isBefore(expiryDate)) {
      return true; // గడువు ఉంది
    } else {
      return false; // గడువు ముగిసింది
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
          const SizedBox(height: 16),

          // 5. Financial Reports Card
          _buildDashboardCard(
            context,
            title: 'Financial Reports',
            subtitle: 'View overall income, expenses, net balance & category breakdown',
            icon: Icons.bar_chart,
            color: Colors.blue,
            destination: const ReportsScreen(),
          ),
          const SizedBox(height: 16),

          // 6. Reminders & General Information Card
          _buildDashboardCard(
            context,
            title: 'Reminders & General Info',
            subtitle: 'Manage your payment reminders and important notes',
            icon: Icons.notifications_active,
            color: Colors.indigo,
            destination: const RemindersInfoScreen(),
          ),
          const SizedBox(height: 16),

          // 7. Fixed Expenses & Fees Tracker Card
          _buildDashboardCard(
            context,
            title: 'Fixed Expenses & Fees Tracker',
            subtitle: 'Track school fees, bus fees & remaining balance for children',
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