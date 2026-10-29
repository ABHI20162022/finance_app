import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController keyController = TextEditingController();

  void _verifyAndActivate() async {
    String phone = phoneController.text.trim();
    String enteredKey = keyController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit Mobile Number!')),
      );
      return;
    }

    // కీ ఫార్మాట్ చెకింగ్: ABHI- తో స్టార్ట్ అవ్వాలి (ఉదా: ABHI-01122026)
    if (enteredKey.startsWith("ABHI-") && enteredKey.length >= 13) {
      String expiryDateStr = enteredKey.replaceAll("ABHI-", ""); // e.g., 01122026

      try {
        // డేట్ సరిగ్గా ఉందో లేదో పార్స్ చేసి చెక్ చేద్దాం
        int day = int.parse(expiryDateStr.substring(0, 2));
        int month = int.parse(expiryDateStr.substring(2, 4));
        int year = int.parse(expiryDateStr.substring(4, 8));
        DateTime expiryDate = DateTime(year, month, day, 23, 59, 59);

        // కీ లో ఇచ్చిన ఎక్స్‌పైరీ డేట్ ఇంకా ముగియలేదని నిర్ధారించుకోవడం
        if (DateTime.now().isAfter(expiryDate)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This Activation Key has already expired!')),
          );
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_phone', phone);
        await prefs.setString('app_expiry_date', expiryDateStr);
        await prefs.setBool('is_activated', true);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Date format in Key! Use ABHI-DDMMYYYY')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Activation Key format!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Activation Required'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  'Activation Needed',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please enter your Mobile Number and the Activation Key provided by the Administrator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Your Mobile Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Activation Key',
                    // వాటర్‌మార్క్ (hintText) పూర్తిగా తొలగించబడింది
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _verifyAndActivate,
                  child: const Text('Activate App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}