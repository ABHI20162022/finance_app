import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Models ---
class EmiPaidRecord {
  String id;
  String paidDate;
  int installmentNumber;
  double paidAmount;
  double fine;
  double remainingAmount;

  EmiPaidRecord({
    required this.id,
    required this.paidDate,
    required this.installmentNumber,
    required this.paidAmount,
    this.fine = 0.0,
    required this.remainingAmount,
  });
}

class EmiEntryItem {
  String id;
  String emiName;
  String date; // dd-mm-yyyy (Taken Date)
  double loanAmount;
  double bankCharges;
  double interest;
  int numberOfEmis;
  double totalLoanAmount;
  double perMonthEmi;
  List<EmiPaidRecord> paidRecords;

  EmiEntryItem({
    required this.id,
    required this.emiName,
    required this.date,
    required this.loanAmount,
    required this.bankCharges,
    required this.interest,
    required this.numberOfEmis,
    required this.totalLoanAmount,
    required this.perMonthEmi,
    required this.paidRecords,
  });
}

class EmiCategory {
  String id;
  String name;
  List<EmiEntryItem> entries;

  EmiCategory({
    required this.id,
    required this.name,
    required this.entries,
  });
}

class LoanTakenEntry {
  String id;
  String note;
  String date; // dd-mm-yyyy (Taken Date)
  String repaymentTenureDate; // dd-mm-yyyy (Repayment Tenure Date)
  double principalAmount;
  double rateOfInterest; // % for bank, ₹ per 100/month for rupees
  String interestRateType; // 'percent' or 'rupees'
  bool useFixed30DaysMonth; // true = 30 days/month, false = actual calendar month days
  double bankCharges; // Optional (default 0)
  double interest; // Optional (default 0)
  bool isClosed;
  String? repaidDate; // dd-mm-yyyy
  double? repaidAmount;

  LoanTakenEntry({
    required this.id,
    required this.note,
    required this.date,
    this.repaymentTenureDate = '',
    required this.principalAmount,
    this.rateOfInterest = 0.0,
    this.interestRateType = 'rupees',
    this.useFixed30DaysMonth = false,
    this.bankCharges = 0.0,
    this.interest = 0.0,
    this.isClosed = false,
    this.repaidDate,
    this.repaidAmount,
  });

  double get totalAmount => principalAmount + bankCharges + interest;
}

class LoanTakenPerson {
  String id;
  String name;
  List<LoanTakenEntry> entries;

  LoanTakenPerson({
    required this.id,
    required this.name,
    required this.entries,
  });
}

class SimpleLoanRecord {
  String id;
  String title;
  double amount;
  double bankCharges;
  double interest;
  String loanType; // 'Loan Given'
  String date;
  bool isClosed;

  SimpleLoanRecord({
    required this.id,
    required this.title,
    required this.amount,
    this.bankCharges = 0.0,
    this.interest = 0.0,
    required this.loanType,
    required this.date,
    this.isClosed = false,
  });
}

class TenureBreakdown {
  final int years;
  final int months;
  final int days;
  final double interest;
  final double totalMonthsForInterest;

  TenureBreakdown({
    required this.years,
    required this.months,
    required this.days,
    required this.interest,
    required this.totalMonthsForInterest,
  });

  String get bracketLabel =>
      '($years ${years == 1 ? "Year" : "Years"}, $months ${months == 1 ? "Month" : "Months"}, $days ${days == 1 ? "Day" : "Days"})';
}

// Global Storage
List<EmiCategory> globalEmiCategories = [];
List<LoanTakenPerson> globalLoanTakenPersons = [];
List<SimpleLoanRecord> globalLoanRecords = [];

// Local Storage Helpers
Future<void> saveAllAssetsLoansData() async {
  final prefs = await SharedPreferences.getInstance();

  final emiData = globalEmiCategories
      .map((cat) => {
            'id': cat.id,
            'name': cat.name,
            'entries': cat.entries
                .map((e) => {
                      'id': e.id,
                      'emiName': e.emiName,
                      'date': e.date,
                      'loanAmount': e.loanAmount,
                      'bankCharges': e.bankCharges,
                      'interest': e.interest,
                      'numberOfEmis': e.numberOfEmis,
                      'totalLoanAmount': e.totalLoanAmount,
                      'perMonthEmi': e.perMonthEmi,
                      'paidRecords': e.paidRecords
                          .map((pr) => {
                                'id': pr.id,
                                'paidDate': pr.paidDate,
                                'installmentNumber': pr.installmentNumber,
                                'paidAmount': pr.paidAmount,
                                'fine': pr.fine,
                                'remainingAmount': pr.remainingAmount,
                              })
                          .toList(),
                    })
                .toList(),
          })
      .toList();
  await prefs.setString('saved_emi_categories_v6', jsonEncode(emiData));

  final loanTakenPersonsData = globalLoanTakenPersons
      .map((p) => {
            'id': p.id,
            'name': p.name,
            'entries': p.entries
                .map((e) => {
                      'id': e.id,
                      'note': e.note,
                      'date': e.date,
                      'repaymentTenureDate': e.repaymentTenureDate,
                      'principalAmount': e.principalAmount,
                      'rateOfInterest': e.rateOfInterest,
                      'interestRateType': e.interestRateType,
                      'useFixed30DaysMonth': e.useFixed30DaysMonth,
                      'bankCharges': e.bankCharges,
                      'interest': e.interest,
                      'isClosed': e.isClosed,
                      'repaidDate': e.repaidDate,
                      'repaidAmount': e.repaidAmount,
                    })
                .toList(),
          })
      .toList();
  await prefs.setString(
      'saved_loan_taken_persons_v4', jsonEncode(loanTakenPersonsData));

  final loanRecordsData = globalLoanRecords
      .map((rec) => {
            'id': rec.id,
            'title': rec.title,
            'amount': rec.amount,
            'bankCharges': rec.bankCharges,
            'interest': rec.interest,
            'loanType': rec.loanType,
            'date': rec.date,
            'isClosed': rec.isClosed,
          })
      .toList();
  await prefs.setString('saved_loan_records_v6', jsonEncode(loanRecordsData));
}

Future<void> loadAllAssetsLoansData() async {
  final prefs = await SharedPreferences.getInstance();

  final emiStr = prefs.getString('saved_emi_categories_v6');
  if (emiStr != null && emiStr.isNotEmpty) {
    final decoded = jsonDecode(emiStr);
    if (decoded is List) {
      globalEmiCategories = decoded.map((rawCat) {
        final cMap = Map<String, dynamic>.from(rawCat as Map);
        return EmiCategory(
          id: cMap['id']?.toString() ?? '',
          name: cMap['name']?.toString() ?? '',
          entries: (cMap['entries'] as List? ?? const []).map((rawEntry) {
            final eMap = Map<String, dynamic>.from(rawEntry as Map);
            return EmiEntryItem(
              id: eMap['id']?.toString() ?? '',
              emiName: eMap['emiName']?.toString() ?? '',
              date: eMap['date']?.toString() ?? '',
              loanAmount: (eMap['loanAmount'] as num?)?.toDouble() ?? 0.0,
              bankCharges: (eMap['bankCharges'] as num?)?.toDouble() ?? 0.0,
              interest: (eMap['interest'] as num?)?.toDouble() ?? 0.0,
              numberOfEmis: (eMap['numberOfEmis'] as num?)?.toInt() ?? 1,
              totalLoanAmount:
                  (eMap['totalLoanAmount'] as num?)?.toDouble() ?? 0.0,
              perMonthEmi: (eMap['perMonthEmi'] as num?)?.toDouble() ?? 0.0,
              paidRecords: (eMap['paidRecords'] as List? ?? const [])
                  .map((rawPr) {
                final prMap = Map<String, dynamic>.from(rawPr as Map);
                return EmiPaidRecord(
                  id: prMap['id']?.toString() ?? '',
                  paidDate: prMap['paidDate']?.toString() ?? '',
                  installmentNumber:
                      (prMap['installmentNumber'] as num?)?.toInt() ?? 1,
                  paidAmount: (prMap['paidAmount'] as num?)?.toDouble() ?? 0.0,
                  fine: (prMap['fine'] as num?)?.toDouble() ?? 0.0,
                  remainingAmount:
                      (prMap['remainingAmount'] as num?)?.toDouble() ?? 0.0,
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList();
    } else {
      globalEmiCategories = [];
    }
  } else {
    globalEmiCategories = [];
  }

  final personsStr = prefs.getString('saved_loan_taken_persons_v4') ??
      prefs.getString('saved_loan_taken_persons_v3') ??
      prefs.getString('saved_loan_taken_persons_v2') ??
      prefs.getString('saved_loan_taken_persons_v1');
  if (personsStr != null && personsStr.isNotEmpty) {
    final decoded = jsonDecode(personsStr);
    if (decoded is List) {
      globalLoanTakenPersons = decoded.map((rawPerson) {
        final pMap = Map<String, dynamic>.from(rawPerson as Map);
        return LoanTakenPerson(
          id: pMap['id']?.toString() ?? '',
          name: pMap['name']?.toString() ?? '',
          entries: (pMap['entries'] as List? ?? const []).map((rawEntry) {
            final eMap = Map<String, dynamic>.from(rawEntry as Map);
            return LoanTakenEntry(
              id: eMap['id']?.toString() ?? '',
              note: eMap['note']?.toString() ?? '',
              date: eMap['date']?.toString() ?? '',
              repaymentTenureDate: eMap['repaymentTenureDate']?.toString() ?? '',
              principalAmount:
                  (eMap['principalAmount'] as num?)?.toDouble() ?? 0.0,
              rateOfInterest:
                  (eMap['rateOfInterest'] as num?)?.toDouble() ?? 0.0,
              interestRateType: eMap['interestRateType']?.toString() ?? 'rupees',
              useFixed30DaysMonth: eMap['useFixed30DaysMonth'] == true,
              bankCharges: (eMap['bankCharges'] as num?)?.toDouble() ?? 0.0,
              interest: (eMap['interest'] as num?)?.toDouble() ?? 0.0,
              isClosed: eMap['isClosed'] == true,
              repaidDate: eMap['repaidDate']?.toString(),
              repaidAmount: (eMap['repaidAmount'] as num?)?.toDouble(),
            );
          }).toList(),
        );
      }).toList();
    } else {
      globalLoanTakenPersons = [];
    }
  } else {
    globalLoanTakenPersons = [];
  }

  final loanRecStr = prefs.getString('saved_loan_records_v6');
  if (loanRecStr != null && loanRecStr.isNotEmpty) {
    final decoded = jsonDecode(loanRecStr);
    if (decoded is List) {
      globalLoanRecords = decoded.map((rawRec) {
        final map = Map<String, dynamic>.from(rawRec as Map);
        return SimpleLoanRecord(
          id: map['id']?.toString() ?? '',
          title: map['title']?.toString() ?? '',
          amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
          bankCharges: (map['bankCharges'] as num?)?.toDouble() ?? 0.0,
          interest: (map['interest'] as num?)?.toDouble() ?? 0.0,
          loanType: map['loanType']?.toString() ?? 'Loan Given',
          date: map['date']?.toString() ?? '',
          isClosed: map['isClosed'] == true,
        );
      }).toList();
    } else {
      globalLoanRecords = [];
    }
  } else {
    globalLoanRecords = [];
  }
}

double getActiveLoanTakenTotal() {
  double total = 0.0;
  for (var person in globalLoanTakenPersons) {
    for (var entry in person.entries) {
      if (!entry.isClosed) {
        total += entry.totalAmount;
      }
    }
  }
  return total;
}

DateTime? _parseDate(String dateStr) {
  try {
    final parts = dateStr.trim().split('-');
    if (parts.length == 3) {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    }
  } catch (_) {}
  return null;
}

String _todayFormatted() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
}

int _daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

TenureBreakdown _calculateTenureBreakdown({
  required double principal,
  required double rate,
  required String rateType,
  required String takenDateStr,
  required String repaymentTenureDateStr,
  required bool useFixed30DaysMonth,
}) {
  final DateTime? startRaw = _parseDate(takenDateStr);
  final DateTime? endRaw = _parseDate(repaymentTenureDateStr);
  if (startRaw == null || endRaw == null || !endRaw.isAfter(startRaw)) {
    return TenureBreakdown(
      years: 0,
      months: 0,
      days: 0,
      interest: 0.0,
      totalMonthsForInterest: 0.0,
    );
  }
  final DateTime start = DateTime(startRaw.year, startRaw.month, startRaw.day);
  final DateTime end = DateTime(endRaw.year, endRaw.month, endRaw.day);
  int years = 0;
  int months = 0;
  int days = 0;
  double totalMonthsForInterest = 0.0;
  if (useFixed30DaysMonth) {
    final int totalDays = end.difference(start).inDays;
    final int totalMonths = totalDays ~/ 30;
    days = totalDays % 30;
    years = totalMonths ~/ 12;
    months = totalMonths % 12;
    totalMonthsForInterest = totalMonths + (days / 30.0);
  } else {
    DateTime cursor = start;
    int totalFullMonths = 0;
    while (true) {
      int nextMonth = cursor.month + 1;
      int nextYear = cursor.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear += 1;
      }
      final int maxDayInNextMonth = _daysInMonth(nextYear, nextMonth);
      final int targetDay =
          cursor.day <= maxDayInNextMonth ? cursor.day : maxDayInNextMonth;
      final DateTime nextDate = DateTime(nextYear, nextMonth, targetDay);
      if (!nextDate.isAfter(end)) {
        cursor = nextDate;
        totalFullMonths += 1;
      } else {
        break;
      }
    }
    final int remainingDays = end.difference(cursor).inDays;
    final int currentMonthDays = _daysInMonth(cursor.year, cursor.month);
    years = totalFullMonths ~/ 12;
    months = totalFullMonths % 12;
    days = remainingDays;
    totalMonthsForInterest =
        totalFullMonths + (remainingDays / currentMonthDays);
  }
  double interest = 0.0;
  if (principal > 0 && rate > 0) {
    if (rateType == 'percent') {
      interest = principal * (rate / 100.0) * (totalMonthsForInterest / 12.0);
    } else {
      interest = (principal / 100.0) * rate * totalMonthsForInterest;
    }
  }
  return TenureBreakdown(
    years: years,
    months: months,
    days: days,
    interest: interest,
    totalMonthsForInterest: totalMonthsForInterest,
  );
}

// ============================================================================
// MAIN SCREEN: Only "Loan" and "Loan Given"
// ============================================================================
class AssetsLiabilitiesScreen extends StatefulWidget {
  const AssetsLiabilitiesScreen({super.key});

  @override
  State<AssetsLiabilitiesScreen> createState() =>
      _AssetsLiabilitiesScreenState();
}

class _AssetsLiabilitiesScreenState extends State<AssetsLiabilitiesScreen> {
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await loadAllAssetsLoansData();
    if (mounted) setState(() {});
  }

  double get _totalEmiLoanAmount {
    double total = 0.0;
    for (var cat in globalEmiCategories) {
      for (var entry in cat.entries) {
        final int rem = entry.numberOfEmis - entry.paidRecords.length;
        if (rem > 0) {
          total += entry.totalLoanAmount;
        }
      }
    }
    return total;
  }

  double _getLoanTypeTotal(String type) {
    return globalLoanRecords
        .where((r) => r.loanType == type && !r.isClosed)
        .fold(0.0, (sum, r) => sum + r.amount + r.bankCharges + r.interest);
  }

  double get _combinedLoanTotal =>
      _totalEmiLoanAmount + getActiveLoanTakenTotal();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Loans',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildVerticalOptionCard(
            title: 'Loan',
            subtitle: 'EMI & Loan Taken',
            amount: _combinedLoanTotal,
            color: Colors.red.shade700,
            icon: Icons.account_balance,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoanSubMenuScreen(),
                ),
              ).then((_) => setState(() {}));
            },
            onHistoryTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const MasterHistoryScreen(initialTabType: 'EMI'),
                ),
              ).then((_) => setState(() {}));
            },
          ),
          const SizedBox(height: 10),
          _buildVerticalOptionCard(
            title: 'Loan Given',
            subtitle: 'Loans lent to others',
            amount: _getLoanTypeTotal('Loan Given'),
            color: Colors.blue.shade700,
            icon: Icons.arrow_upward,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SimpleLoanTypeScreen(
                    loanType: 'Loan Given',
                    themeColor: Colors.blue.shade700,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
            onHistoryTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const MasterHistoryScreen(initialTabType: 'Loan Given'),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalOptionCard({
    required String title,
    required String subtitle,
    required double amount,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onHistoryTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          radius: 20,
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.history, size: 20, color: Colors.grey),
              tooltip: 'History',
              onPressed: onHistoryTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SUB-MENU SCREEN INSIDE "LOAN": EMI & Loan Taken
// ============================================================================
class LoanSubMenuScreen extends StatefulWidget {
  const LoanSubMenuScreen({super.key});

  @override
  State<LoanSubMenuScreen> createState() => _LoanSubMenuScreenState();
}

class _LoanSubMenuScreenState extends State<LoanSubMenuScreen> {
  double get _totalEmiLoanAmount {
    double total = 0.0;
    for (var cat in globalEmiCategories) {
      for (var entry in cat.entries) {
        final int rem = entry.numberOfEmis - entry.paidRecords.length;
        if (rem > 0) {
          total += entry.totalLoanAmount;
        }
      }
    }
    return total;
  }

  double get _totalLoanTaken => getActiveLoanTakenTotal();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Loan Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmiMainScreen(),
                  ),
                ).then((_) => setState(() {}));
              },
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade700.withOpacity(0.15),
                radius: 20,
                child: Icon(Icons.calendar_month,
                    color: Colors.red.shade700, size: 20),
              ),
              title: const Text(
                'EMI',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: const Text('Manage EMIs & EMI Statement',
                  style: TextStyle(fontSize: 11)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${_totalEmiLoanAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon:
                        const Icon(Icons.history, size: 20, color: Colors.grey),
                    tooltip: 'EMI History',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MasterHistoryScreen(
                              initialTabType: 'EMI'),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoanTakenMainScreen(),
                  ),
                ).then((_) => setState(() {}));
              },
              leading: CircleAvatar(
                backgroundColor: Colors.deepOrange.withOpacity(0.15),
                radius: 20,
                child: const Icon(Icons.arrow_downward,
                    color: Colors.deepOrange, size: 20),
              ),
              title: const Text(
                'Loan Taken',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: const Text(
                  'Add Person, Statement, Interest & Bank Charges',
                  style: TextStyle(fontSize: 11)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${_totalLoanTaken.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon:
                        const Icon(Icons.history, size: 20, color: Colors.grey),
                    tooltip: 'Loan Taken History',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MasterHistoryScreen(
                              initialTabType: 'Loan Taken'),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LOAN TAKEN MAIN SCREEN: 4 Tabs ("Add Person", "Statement", "Interest", "Bank Charges")
// ============================================================================
class LoanTakenMainScreen extends StatefulWidget {
  const LoanTakenMainScreen({super.key});

  @override
  State<LoanTakenMainScreen> createState() => _LoanTakenMainScreenState();
}

class _LoanTakenMainScreenState extends State<LoanTakenMainScreen> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  void _openAddEditPersonDialog({LoanTakenPerson? editingPerson}) {
    final nameController =
        TextEditingController(text: editingPerson?.name ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editingPerson == null ? 'Add Person' : 'Edit Person'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Person / Lender Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    if (editingPerson != null) {
                      editingPerson.name = nameController.text.trim();
                    } else {
                      globalLoanTakenPersons.add(
                        LoanTakenPerson(
                          id: DateTime.now().toString(),
                          name: nameController.text.trim(),
                          entries: [],
                        ),
                      );
                    }
                  });
                  await saveAllAssetsLoansData();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(editingPerson == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _openRepayLoanDialog(LoanTakenPerson person, LoanTakenEntry entry) {
    final repayDateController = TextEditingController(text: _todayFormatted());
    final repayAmtController =
        TextEditingController(text: entry.totalAmount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Repay Loan - ${person.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repayDateController,
                decoration: const InputDecoration(
                  labelText: 'Repay Date (dd-mm-yyyy)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repayAmtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Repaid Amount (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final double paid =
                    double.tryParse(repayAmtController.text.trim()) ??
                        entry.totalAmount;
                final String rDate = repayDateController.text.trim().isNotEmpty
                    ? repayDateController.text.trim()
                    : _todayFormatted();
                setState(() {
                  entry.isClosed = true;
                  entry.repaidDate = rDate;
                  entry.repaidAmount = paid;
                });
                await saveAllAssetsLoansData();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Confirm Repay & Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddPersonTab() {
    return Scaffold(
      body: globalLoanTakenPersons.isEmpty
          ? const Center(
              child: Text(
                'No persons added yet.\nClick "+ Add Person" button below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: globalLoanTakenPersons.length,
              itemBuilder: (context, index) {
                final person = globalLoanTakenPersons[index];
                final activeEntries =
                    person.entries.where((e) => !e.isClosed).toList();
                final activeTotal = activeEntries.fold(
                    0.0, (sum, e) => sum + e.totalAmount);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LoanTakenPersonEntriesScreen(person: person),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepOrange.withOpacity(0.15),
                          child: const Icon(Icons.person,
                              color: Colors.deepOrange),
                        ),
                        title: Text(
                          person.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Active Entries: ${activeEntries.length} | Active Loan: ₹${activeTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 18, color: Colors.blue),
                              onPressed: () =>
                                  _openAddEditPersonDialog(editingPerson: person),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              onPressed: () async {
                                setState(() {
                                  globalLoanTakenPersons.removeAt(index);
                                });
                                await saveAllAssetsLoansData();
                              },
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                      if (activeEntries.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: Column(
                            children: activeEntries.map((e) {
                              return Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${e.note.isNotEmpty ? e.note : "Loan"} | Date: ${e.date} | ₹${e.totalAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () =>
                                          _openRepayLoanDialog(person, e),
                                      child: const Text('Repay',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditPersonDialog(),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Person'),
      ),
    );
  }

  Widget _buildStatementTab() {
    final List<dynamic> activeRows = [];
    for (var person in globalLoanTakenPersons) {
      for (var entry in person.entries) {
        if (!entry.isClosed) {
          activeRows.add({'person': person, 'entry': entry});
        }
      }
    }
    final double totalActive = activeRows.fold(
        0.0,
        (sum, item) =>
            sum + ((item['entry'] as LoanTakenEntry).totalAmount));
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepOrange.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Active Loan Taken:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.deepOrange),
                ),
                Text(
                  '₹${totalActive.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepOrange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: activeRows.isEmpty
                ? const Center(
                    child: Text(
                      'No active loan entries found.\nAdd a person and add an entry to view statement.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: activeRows.length,
                    itemBuilder: (context, index) {
                      final person =
                          activeRows[index]['person'] as LoanTakenPerson;
                      final entry =
                          activeRows[index]['entry'] as LoanTakenEntry;
                      final String rateText = entry.rateOfInterest > 0
                          ? (entry.interestRateType == 'percent'
                              ? 'Rate: ${entry.rateOfInterest}%'
                              : 'Rate: ₹${entry.rateOfInterest}/100/m')
                          : '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            '${person.name}${entry.note.isNotEmpty ? " - ${entry.note}" : ""}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Date: ${entry.date}${entry.repaymentTenureDate.isNotEmpty ? " | Tenure: ${entry.repaymentTenureDate}" : ""} | Total: ₹${entry.totalAmount.toStringAsFixed(2)}\n'
                            'Loan: ₹${entry.principalAmount.toStringAsFixed(2)} | Int: ₹${entry.interest.toStringAsFixed(2)} | Bank Chg: ₹${entry.bankCharges.toStringAsFixed(2)}${rateText.isNotEmpty ? " | $rateText" : ""}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          isThreeLine: true,
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                            onPressed: () =>
                                _openRepayLoanDialog(person, entry),
                            child: const Text('Repay',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargesTab({required bool isInterest}) {
    final DateTime? fromDate = _parseDate(_fromDateController.text);
    final DateTime? toDate = _parseDate(_toDateController.text);
    final List<dynamic> rows = [];
    for (var person in globalLoanTakenPersons) {
      for (var entry in person.entries) {
        final double val = isInterest ? entry.interest : entry.bankCharges;
        if (val > 0) {
          if (fromDate != null || toDate != null) {
            final DateTime? entryDate = _parseDate(entry.date);
            final DateTime? repaidDate =
                entry.repaidDate != null ? _parseDate(entry.repaidDate!) : null;
            final bool matchesTaken = entryDate != null &&
                (fromDate == null || !entryDate.isBefore(fromDate)) &&
                (toDate == null || !entryDate.isAfter(toDate));
            final bool matchesRepaid = repaidDate != null &&
                (fromDate == null || !repaidDate.isBefore(fromDate)) &&
                (toDate == null || !repaidDate.isAfter(toDate));
            if (!matchesTaken && !matchesRepaid) continue;
          }
          rows.add({
            'person': person,
            'entry': entry,
            'amount': val,
          });
        }
      }
    }
    final double totalAmount = rows.fold(
        0.0, (sum, item) => sum + ((item['amount'] as num).toDouble()));
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromDateController,
                  decoration: const InputDecoration(
                    labelText: 'From (dd-mm-yyyy)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(10),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _toDateController,
                  decoration: const InputDecoration(
                    labelText: 'To (dd-mm-yyyy)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(10),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_fromDateController.text.isNotEmpty ||
                  _toDateController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  tooltip: 'Clear Date Filter',
                  onPressed: () {
                    _fromDateController.clear();
                    _toDateController.clear();
                    setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepOrange.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isInterest
                      ? 'Total Loan Interest:'
                      : 'Total Loan Bank Charges:',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.deepOrange),
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepOrange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      isInterest
                          ? 'No interest entries found for selected filter.'
                          : 'No bank charges found for selected filter.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final person = rows[index]['person'] as LoanTakenPerson;
                      final entry = rows[index]['entry'] as LoanTakenEntry;
                      final double amt =
                          (rows[index]['amount'] as num).toDouble();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isInterest
                                ? Colors.amber.shade100
                                : Colors.blueGrey.shade100,
                            child: Icon(
                              isInterest
                                  ? Icons.percent
                                  : Icons.account_balance_wallet,
                              color: isInterest
                                  ? Colors.amber.shade900
                                  : Colors.blueGrey.shade800,
                            ),
                          ),
                          title: Text(
                            '${person.name}${entry.note.isNotEmpty ? " - ${entry.note}" : ""}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Date: ${entry.date}${entry.repaidDate != null && entry.repaidDate!.isNotEmpty ? " | Repaid: ${entry.repaidDate}" : ""} | ${entry.isClosed ? "Repaid/Closed" : "Active"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${amt.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 18, color: Colors.red),
                                tooltip: isInterest
                                    ? 'Delete Interest'
                                    : 'Delete Bank Charges',
                                onPressed: () async {
                                  setState(() {
                                    if (isInterest) {
                                      entry.interest = 0.0;
                                    } else {
                                      entry.bankCharges = 0.0;
                                    }
                                  });
                                  await saveAllAssetsLoansData();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Loan Taken',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.person_add), text: 'Add Person'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Statement'),
              Tab(icon: Icon(Icons.percent), text: 'Interest'),
              Tab(
                  icon: Icon(Icons.account_balance_wallet),
                  text: 'Bank Charges'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAddPersonTab(),
            _buildStatementTab(),
            _buildChargesTab(isInterest: true),
            _buildChargesTab(isInterest: false),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PERSON ENTRIES SCREEN (Rate of Interest, Rate Type, Repayment Tenure & Auto Interest)
// ============================================================================
class LoanTakenPersonEntriesScreen extends StatefulWidget {
  final LoanTakenPerson person;

  const LoanTakenPersonEntriesScreen({super.key, required this.person});

  @override
  State<LoanTakenPersonEntriesScreen> createState() =>
      _LoanTakenPersonEntriesScreenState();
}

class _LoanTakenPersonEntriesScreenState
    extends State<LoanTakenPersonEntriesScreen> {
  String _defaultRateTypeForPerson() {
    return widget.person.name.toLowerCase().contains('bank')
        ? 'percent'
        : 'rupees';
  }

  void _openAddEditLoanEntryDialog({LoanTakenEntry? editingEntry}) {
    final noteController =
        TextEditingController(text: editingEntry?.note ?? '');
    final dateController =
        TextEditingController(text: editingEntry?.date ?? _todayFormatted());
    final tenureDateController = TextEditingController(
        text: editingEntry?.repaymentTenureDate ?? _todayFormatted());
    final principalController = TextEditingController(
        text: editingEntry != null
            ? editingEntry.principalAmount.toString()
            : '');
    final rateController = TextEditingController(
        text: editingEntry != null && editingEntry.rateOfInterest > 0
            ? editingEntry.rateOfInterest.toString()
            : '');
    String selectedRateType =
        editingEntry?.interestRateType ?? _defaultRateTypeForPerson();
    bool useFixed30DaysMonth = editingEntry?.useFixed30DaysMonth ?? false;
    final bankChargesController = TextEditingController(
        text: editingEntry != null && editingEntry.bankCharges > 0
            ? editingEntry.bankCharges.toString()
            : '');
    final interestController = TextEditingController(
        text: editingEntry != null && editingEntry.interest > 0
            ? editingEntry.interest.toString()
            : '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            final double principal =
                double.tryParse(principalController.text.trim()) ?? 0.0;
            final double rate =
                double.tryParse(rateController.text.trim()) ?? 0.0;
            final double charges =
                double.tryParse(bankChargesController.text.trim()) ?? 0.0;
            final double interest =
                double.tryParse(interestController.text.trim()) ?? 0.0;
            final TenureBreakdown breakdown = _calculateTenureBreakdown(
              principal: principal,
              rate: rate,
              rateType: selectedRateType,
              takenDateStr: dateController.text,
              repaymentTenureDateStr: tenureDateController.text,
              useFixed30DaysMonth: useFixed30DaysMonth,
            );
            final double totalLoanAmount = principal + charges + interest;

            return AlertDialog(
              title: Text(editingEntry == null
                  ? 'Add Entry - ${widget.person.name}'
                  : 'Edit Entry - ${widget.person.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Loan Title / Purpose',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Taken Date (dd-mm-yyyy)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tenureDateController,
                      decoration: const InputDecoration(
                        labelText: 'Repayment Tenure Date (dd-mm-yyyy)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        '30 Days per Month',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        useFixed30DaysMonth
                            ? 'Using 30 days for every month'
                            : 'Using actual month days (28/29/30/31)',
                        style: const TextStyle(fontSize: 11),
                      ),
                      value: useFixed30DaysMonth,
                      onChanged: (val) {
                        dialogSetState(() => useFixed30DaysMonth = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: principalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Loan Amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRateType,
                      decoration: const InputDecoration(
                        labelText: 'Interest Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'percent',
                          child: Text('Bank - Rate of Interest (%)'),
                        ),
                        DropdownMenuItem(
                          value: 'rupees',
                          child: Text('Other - Rupees (₹ per 100 / month)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          dialogSetState(() => selectedRateType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rateController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: selectedRateType == 'percent'
                            ? 'Rate of Interest (%)'
                            : 'Rate of Interest (₹ per 100 / month)',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Interest ${breakdown.bracketLabel}:',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${breakdown.interest.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          if (breakdown.interest > 0)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  interestController.text =
                                      breakdown.interest.toStringAsFixed(2);
                                  dialogSetState(() {});
                                },
                                child: const Text(
                                  'Use Calculated Interest',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: interestController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Interest Amount (₹) - Optional',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bankChargesController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Bank Charges (₹) - Optional',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.deepOrange.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Loan Amount:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '₹${totalLoanAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (principalController.text.trim().isNotEmpty) {
                      final String dateStr =
                          dateController.text.trim().isNotEmpty
                              ? dateController.text.trim()
                              : _todayFormatted();
                      final String tenureStr =
                          tenureDateController.text.trim();
                      final double finalInterest =
                          interestController.text.trim().isNotEmpty
                              ? interest
                              : breakdown.interest;
                      setState(() {
                        if (editingEntry != null) {
                          editingEntry.note = noteController.text.trim();
                          editingEntry.date = dateStr;
                          editingEntry.repaymentTenureDate = tenureStr;
                          editingEntry.principalAmount = principal;
                          editingEntry.rateOfInterest = rate;
                          editingEntry.interestRateType = selectedRateType;
                          editingEntry.useFixed30DaysMonth = useFixed30DaysMonth;
                          editingEntry.interest = finalInterest;
                          editingEntry.bankCharges = charges;
                        } else {
                          widget.person.entries.add(
                            LoanTakenEntry(
                              id: DateTime.now().toString(),
                              note: noteController.text.trim(),
                              date: dateStr,
                              repaymentTenureDate: tenureStr,
                              principalAmount: principal,
                              rateOfInterest: rate,
                              interestRateType: selectedRateType,
                              useFixed30DaysMonth: useFixed30DaysMonth,
                              interest: finalInterest,
                              bankCharges: charges,
                              isClosed: false,
                            ),
                          );
                        }
                      });
                      await saveAllAssetsLoansData();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(editingEntry == null ? 'Save Entry' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openRepayDialog(LoanTakenEntry entry) {
    final repayDateController = TextEditingController(text: _todayFormatted());
    final repayAmtController =
        TextEditingController(text: entry.totalAmount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Repay Loan - ${widget.person.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repayDateController,
                decoration: const InputDecoration(
                  labelText: 'Repay Date (dd-mm-yyyy)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repayAmtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Repaid Amount (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final double paid =
                    double.tryParse(repayAmtController.text.trim()) ??
                        entry.totalAmount;
                final String rDate = repayDateController.text.trim().isNotEmpty
                    ? repayDateController.text.trim()
                    : _todayFormatted();
                setState(() {
                  entry.isClosed = true;
                  entry.repaidDate = rDate;
                  entry.repaidAmount = paid;
                });
                await saveAllAssetsLoansData();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Confirm Repay'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeEntries =
        widget.person.entries.where((e) => !e.isClosed).toList();
    final double activeTotal =
        activeEntries.fold(0.0, (sum, item) => sum + item.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.person.name} - Loans',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepOrange.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Total (${widget.person.name}):',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                Text(
                  '₹${activeTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepOrange),
                ),
              ],
            ),
          ),
          Expanded(
            child: activeEntries.isEmpty
                ? const Center(
                    child: Text(
                      'No active loan entries for this person.\nClick "+ Add Entry" below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: activeEntries.length,
                    itemBuilder: (context, index) {
                      final entry = activeEntries[index];
                      final TenureBreakdown breakdown = _calculateTenureBreakdown(
                        principal: entry.principalAmount,
                        rate: entry.rateOfInterest,
                        rateType: entry.interestRateType,
                        takenDateStr: entry.date,
                        repaymentTenureDateStr: entry.repaymentTenureDate,
                        useFixed30DaysMonth: entry.useFixed30DaysMonth,
                      );
                      final String rateInfo = entry.rateOfInterest > 0
                          ? (entry.interestRateType == 'percent'
                              ? ' | Rate: ${entry.rateOfInterest}%'
                              : ' | Rate: ₹${entry.rateOfInterest}/100/m')
                          : '';
                      final String durationInfo =
                          entry.repaymentTenureDate.isNotEmpty
                              ? ' ${breakdown.bracketLabel}'
                              : '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.note.isNotEmpty
                                        ? entry.note
                                        : widget.person.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    'Total: ₹${entry.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Date: ${entry.date}${entry.repaymentTenureDate.isNotEmpty ? " | Tenure: ${entry.repaymentTenureDate}" : ""}$rateInfo\n'
                                'Loan: ₹${entry.principalAmount.toStringAsFixed(2)} | Interest$durationInfo: ₹${entry.interest.toStringAsFixed(2)} | Bank Charges: ₹${entry.bankCharges.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                    ),
                                    onPressed: () => _openRepayDialog(entry),
                                    child: const Text('Repay',
                                        style: TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.edit,
                                        size: 18, color: Colors.blue),
                                    onPressed: () => _openAddEditLoanEntryDialog(
                                        editingEntry: entry),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    onPressed: () async {
                                      setState(() {
                                        widget.person.entries.remove(entry);
                                      });
                                      await saveAllAssetsLoansData();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditLoanEntryDialog(),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}

// ============================================================================
// EMI MAIN SCREEN: 2 Tabs ("Add EMI" & "EMI Statement")
// ============================================================================
class EmiMainScreen extends StatefulWidget {
  const EmiMainScreen({super.key});

  @override
  State<EmiMainScreen> createState() => _EmiMainScreenState();
}

class _EmiMainScreenState extends State<EmiMainScreen> {
  String selectedFilterEmiName = 'All';
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  void _openAddEditEmiCategoryDialog({EmiCategory? editingCat}) {
    final nameController = TextEditingController(text: editingCat?.name ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editingCat == null ? 'Add EMI Name' : 'Edit EMI Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'EMI Name (e.g., Home Loan EMI, Car EMI)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    if (editingCat != null) {
                      editingCat.name = nameController.text.trim();
                    } else {
                      globalEmiCategories.add(
                        EmiCategory(
                          id: DateTime.now().toString(),
                          name: nameController.text.trim(),
                          entries: [],
                        ),
                      );
                    }
                  });
                  await saveAllAssetsLoansData();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(editingCat == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddEmiTab() {
    return Scaffold(
      body: globalEmiCategories.isEmpty
          ? const Center(
              child: Text(
                'No EMI names added yet.\nClick "+ Add EMI" button below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: globalEmiCategories.length,
              itemBuilder: (context, index) {
                final cat = globalEmiCategories[index];
                double catTotal = 0.0;
                for (var e in cat.entries) {
                  final int rem = e.numberOfEmis - e.paidRecords.length;
                  if (rem > 0) catTotal += e.totalLoanAmount;
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EmiCategoryEntriesScreen(emiCategory: cat),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: Icon(Icons.calendar_month,
                          color: Colors.red.shade700),
                    ),
                    title: Text(
                      cat.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Entries: ${cat.entries.length} | Active Loan: ₹${catTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              size: 18, color: Colors.blue),
                          onPressed: () =>
                              _openAddEditEmiCategoryDialog(editingCat: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 18, color: Colors.red),
                          onPressed: () async {
                            setState(() {
                              globalEmiCategories.removeAt(index);
                            });
                            await saveAllAssetsLoansData();
                          },
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditEmiCategoryDialog(),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add EMI'),
      ),
    );
  }

  Widget _buildEmiStatementTab() {
    final List<EmiEntryItem> allActiveEntries = [];
    for (var cat in globalEmiCategories) {
      for (var e in cat.entries) {
        final int rem = e.numberOfEmis - e.paidRecords.length;
        if (rem > 0) {
          allActiveEntries.add(e);
        }
      }
    }
    final List<String> emiNamesList = ['All'];
    for (var cat in globalEmiCategories) {
      for (var e in cat.entries) {
        if (!emiNamesList.contains(e.emiName)) {
          emiNamesList.add(e.emiName);
        }
      }
    }
    if (!emiNamesList.contains(selectedFilterEmiName)) {
      selectedFilterEmiName = 'All';
    }
    final DateTime? fromDate = _parseDate(fromDateController.text.trim());
    final DateTime? toDate = _parseDate(toDateController.text.trim());
    final List<EmiEntryItem> filteredEntries = allActiveEntries.where((e) {
      if (selectedFilterEmiName != 'All' && e.emiName != selectedFilterEmiName) {
        return false;
      }
      if (fromDate != null || toDate != null) {
        final DateTime? entryDate = _parseDate(e.date);
        if (entryDate != null) {
          if (fromDate != null && entryDate.isBefore(fromDate)) return false;
          if (toDate != null && entryDate.isAfter(toDate)) return false;
        }
      }
      return true;
    }).toList();
    final double grandTotal =
        filteredEntries.fold(0.0, (sum, item) => sum + item.totalLoanAmount);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: selectedFilterEmiName,
                  decoration: const InputDecoration(
                    labelText: 'Filter Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(10),
                  ),
                  items: emiNamesList
                      .map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name,
                              style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedFilterEmiName = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: fromDateController,
                  decoration: const InputDecoration(
                    labelText: 'From (dd-mm-yyyy)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(10),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: toDateController,
                  decoration: const InputDecoration(
                    labelText: 'To (dd-mm-yyyy)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(10),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredEntries.isEmpty
                ? const Center(
                    child: Text(
                      'No active EMI statement records found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final e = filteredEntries[index];
                      final int paidCount = e.paidRecords.length;
                      final int remainingInstallments = e.numberOfEmis - paidCount;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    e.emiName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.red),
                                  ),
                                  Text(
                                    'Date: ${e.date}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const Divider(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      'Monthly Installment: ₹${e.perMonthEmi.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      'Total Installments: ${e.numberOfEmis}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      'Loan: ₹${e.loanAmount.toStringAsFixed(2)} | Chg: ₹${e.bankCharges.toStringAsFixed(2)} | Int: ₹${e.interest.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 11)),
                                  Text(
                                      'Remaining Installments: $remainingInstallments',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Paid Details:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.teal),
                                    ),
                                    const SizedBox(height: 4),
                                    e.paidRecords.isEmpty
                                        ? const Text(
                                            'No EMIs paid yet.',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey),
                                          )
                                        : Column(
                                            children: e.paidRecords.map((pr) {
                                              return Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(vertical: 2),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                        '• Date: ${pr.paidDate} (Inst #${pr.installmentNumber})',
                                                        style: const TextStyle(
                                                            fontSize: 11)),
                                                    Text(
                                                        'Paid: ₹${pr.paidAmount.toStringAsFixed(2)}${pr.fine > 0 ? " | Fine: ₹${pr.fine.toStringAsFixed(2)}" : ""} | Rem: ₹${pr.remainingAmount.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                            color: Colors
                                                                .green)),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Active Loan Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('₹${grandTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.red.shade900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EMI Management',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.add_circle_outline), text: 'Add EMI'),
              Tab(icon: Icon(Icons.receipt_long), text: 'EMI Statement'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAddEmiTab(),
            _buildEmiStatementTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EMI CATEGORY ENTRIES SCREEN
// ============================================================================
class EmiCategoryEntriesScreen extends StatefulWidget {
  final EmiCategory emiCategory;

  const EmiCategoryEntriesScreen({super.key, required this.emiCategory});

  @override
  State<EmiCategoryEntriesScreen> createState() =>
      _EmiCategoryEntriesScreenState();
}

class _EmiCategoryEntriesScreenState extends State<EmiCategoryEntriesScreen> {
  void _openAddEditEmiEntryDialog({EmiEntryItem? editingEntry}) {
    final emiNameController = TextEditingController(
        text: editingEntry?.emiName ?? widget.emiCategory.name);
    final dateController =
        TextEditingController(text: editingEntry?.date ?? _todayFormatted());
    final loanAmtController = TextEditingController(
        text: editingEntry != null ? editingEntry.loanAmount.toString() : '');
    final bankChargesController = TextEditingController(
        text: editingEntry != null ? editingEntry.bankCharges.toString() : '0');
    final interestController = TextEditingController(
        text: editingEntry != null ? editingEntry.interest.toString() : '0');
    final numEmisController = TextEditingController(
        text: editingEntry != null ? editingEntry.numberOfEmis.toString() : '12');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            final double loanAmt =
                double.tryParse(loanAmtController.text.trim()) ?? 0.0;
            final double charges =
                double.tryParse(bankChargesController.text.trim()) ?? 0.0;
            final double interest =
                double.tryParse(interestController.text.trim()) ?? 0.0;
            final int numEmis = int.tryParse(numEmisController.text.trim()) ?? 1;
            final double totalLoanAmount = loanAmt + charges + interest;
            final double perMonthEmi =
                numEmis > 0 ? totalLoanAmount / numEmis : 0.0;

            return AlertDialog(
              title: Text(
                  editingEntry == null ? 'Add EMI Entry' : 'Edit EMI Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emiNameController,
                      decoration: const InputDecoration(
                        labelText: 'EMI Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'EMI Date (dd-mm-yyyy)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: loanAmtController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Loan Amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bankChargesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bank Charges (₹)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: interestController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Interest (₹)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numEmisController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'No. of EMIs',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Loan Amount:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '₹${totalLoanAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Per Month EMI:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '₹${perMonthEmi.toStringAsFixed(2)} / month',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (emiNameController.text.trim().isNotEmpty &&
                        loanAmtController.text.trim().isNotEmpty) {
                      final String dateStr =
                          dateController.text.trim().isNotEmpty
                              ? dateController.text.trim()
                              : _todayFormatted();
                      setState(() {
                        if (editingEntry != null) {
                          editingEntry.emiName = emiNameController.text.trim();
                          editingEntry.date = dateStr;
                          editingEntry.loanAmount = loanAmt;
                          editingEntry.bankCharges = charges;
                          editingEntry.interest = interest;
                          editingEntry.numberOfEmis = numEmis;
                          editingEntry.totalLoanAmount = totalLoanAmount;
                          editingEntry.perMonthEmi = perMonthEmi;
                        } else {
                          widget.emiCategory.entries.add(
                            EmiEntryItem(
                              id: DateTime.now().toString(),
                              emiName: emiNameController.text.trim(),
                              date: dateStr,
                              loanAmount: loanAmt,
                              bankCharges: charges,
                              interest: interest,
                              numberOfEmis: numEmis,
                              totalLoanAmount: totalLoanAmount,
                              perMonthEmi: perMonthEmi,
                              paidRecords: [],
                            ),
                          );
                        }
                      });
                      await saveAllAssetsLoansData();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(editingEntry == null ? 'Save Entry' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openPayEmiDialog(EmiEntryItem entry) {
    final paidDateController = TextEditingController(text: _todayFormatted());
    final paidAmountController =
        TextEditingController(text: entry.perMonthEmi.toStringAsFixed(2));
    final fineController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pay EMI: ${entry.emiName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: paidDateController,
                decoration: const InputDecoration(
                  labelText: 'Paid Date (dd-mm-yyyy)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: paidAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Paid Amount (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fineController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fine / Penalty (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final double paidAmt =
                    double.tryParse(paidAmountController.text.trim()) ?? 0.0;
                final double fineAmt =
                    double.tryParse(fineController.text.trim()) ?? 0.0;
                if (paidAmt > 0) {
                  final int nextInstallmentNum = entry.paidRecords.length + 1;
                  final double previousTotalPaid = entry.paidRecords.fold(
                      0.0, (sum, pr) => sum + pr.paidAmount);
                  double remaining =
                      entry.totalLoanAmount - (previousTotalPaid + paidAmt);
                  if (remaining < 0) remaining = 0;
                  setState(() {
                    entry.paidRecords.add(
                      EmiPaidRecord(
                        id: DateTime.now().toString(),
                        paidDate: paidDateController.text.trim(),
                        installmentNumber: nextInstallmentNum,
                        paidAmount: paidAmt,
                        fine: fineAmt,
                        remainingAmount: remaining,
                      ),
                    );
                  });
                  await saveAllAssetsLoansData();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Confirm Pay'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<EmiEntryItem> activeEntries = widget.emiCategory.entries.where((e) {
      final int rem = e.numberOfEmis - e.paidRecords.length;
      return rem > 0;
    }).toList();
    final double categoryTotal =
        activeEntries.fold(0.0, (sum, item) => sum + item.totalLoanAmount);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.emiCategory.name} - EMI Entries',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Total (${widget.emiCategory.name}):',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red.shade900),
                ),
                Text(
                  '₹${categoryTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red.shade900),
                ),
              ],
            ),
          ),
          Expanded(
            child: activeEntries.isEmpty
                ? const Center(
                    child: Text(
                      'No active EMI entries.\n(All completed entries moved to History).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: activeEntries.length,
                    itemBuilder: (context, index) {
                      final entry = activeEntries[index];
                      final int paidCount = entry.paidRecords.length;
                      final int remainingInstallments =
                          entry.numberOfEmis - paidCount;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.emiName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    'Total: ₹${entry.totalLoanAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Taken Date: ${entry.date} | EMIs: ${entry.numberOfEmis} | Rem: $remainingInstallments\n'
                                'Loan: ₹${entry.loanAmount.toStringAsFixed(2)} | Chg: ₹${entry.bankCharges.toStringAsFixed(2)} | Int: ₹${entry.interest.toStringAsFixed(2)}\n'
                                'Per Month EMI: ₹${entry.perMonthEmi.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                    ),
                                    icon: const Icon(Icons.payment, size: 14),
                                    label: const Text('Pay EMI',
                                        style: TextStyle(fontSize: 11)),
                                    onPressed: () => _openPayEmiDialog(entry),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.edit,
                                        size: 18, color: Colors.blue),
                                    onPressed: () => _openAddEditEmiEntryDialog(
                                        editingEntry: entry),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    onPressed: () async {
                                      setState(() {
                                        widget.emiCategory.entries
                                            .remove(entry);
                                      });
                                      await saveAllAssetsLoansData();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditEmiEntryDialog(),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('EMI Entry'),
      ),
    );
  }
}

// ============================================================================
// SCREEN FOR SIMPLE LOAN TYPE ("Loan Given")
// ============================================================================
class SimpleLoanTypeScreen extends StatefulWidget {
  final String loanType;
  final Color themeColor;

  const SimpleLoanTypeScreen({
    super.key,
    required this.loanType,
    required this.themeColor,
  });

  @override
  State<SimpleLoanTypeScreen> createState() => _SimpleLoanTypeScreenState();
}

class _SimpleLoanTypeScreenState extends State<SimpleLoanTypeScreen> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  void _openAddEditLoanRecordDialog({SimpleLoanRecord? editingRecord}) {
    final titleController =
        TextEditingController(text: editingRecord?.title ?? '');
    final amountController = TextEditingController(
        text: editingRecord != null ? editingRecord.amount.toString() : '');
    final bankChargesController = TextEditingController(
        text:
            editingRecord != null ? editingRecord.bankCharges.toString() : '0');
    final interestController = TextEditingController(
        text: editingRecord != null ? editingRecord.interest.toString() : '0');
    final dateController =
        TextEditingController(text: editingRecord?.date ?? _todayFormatted());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            final double amt =
                double.tryParse(amountController.text.trim()) ?? 0.0;
            final double charges =
                double.tryParse(bankChargesController.text.trim()) ?? 0.0;
            final double interest =
                double.tryParse(interestController.text.trim()) ?? 0.0;
            final double totalLoanAmount = amt + charges + interest;

            return AlertDialog(
              title: Text(editingRecord == null
                  ? 'Add ${widget.loanType}'
                  : 'Edit ${widget.loanType}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Person / Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Principal Amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bankChargesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bank Charges (₹)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: interestController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Interest (₹)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date (dd-mm-yyyy)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Total Amount: ₹${totalLoanAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isNotEmpty &&
                        amountController.text.trim().isNotEmpty) {
                      final String dateStr =
                          dateController.text.trim().isNotEmpty
                              ? dateController.text.trim()
                              : _todayFormatted();
                      setState(() {
                        if (editingRecord != null) {
                          editingRecord.title = titleController.text.trim();
                          editingRecord.amount = amt;
                          editingRecord.bankCharges = charges;
                          editingRecord.interest = interest;
                          editingRecord.date = dateStr;
                        } else {
                          globalLoanRecords.add(
                            SimpleLoanRecord(
                              id: DateTime.now().toString(),
                              title: titleController.text.trim(),
                              amount: amt,
                              bankCharges: charges,
                              interest: interest,
                              loanType: widget.loanType,
                              date: dateStr,
                              isClosed: false,
                            ),
                          );
                        }
                      });
                      await saveAllAssetsLoansData();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(editingRecord == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? fromDate = _parseDate(fromDateController.text.trim());
    final DateTime? toDate = _parseDate(toDateController.text.trim());
    final records = globalLoanRecords.where((r) {
      if (r.loanType != widget.loanType || r.isClosed) return false;
      if (fromDate != null || toDate != null) {
        final DateTime? recDate = _parseDate(r.date);
        if (recDate != null) {
          if (fromDate != null && recDate.isBefore(fromDate)) return false;
          if (toDate != null && recDate.isAfter(toDate)) return false;
        }
      }
      return true;
    }).toList();
    final double total = records.fold(
        0.0, (sum, r) => sum + r.amount + r.bankCharges + r.interest);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loanType,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: fromDateController,
                    decoration: const InputDecoration(
                      labelText: 'From (dd-mm-yyyy)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(10),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: toDateController,
                    decoration: const InputDecoration(
                      labelText: 'To (dd-mm-yyyy)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(10),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: widget.themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.themeColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Total ${widget.loanType}:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: widget.themeColor,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.themeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Text(
                      'No active ${widget.loanType.toLowerCase()} records found.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final rec = records[index];
                      final double recTotal =
                          rec.amount + rec.bankCharges + rec.interest;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        child: ListTile(
                          title: Text(rec.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Date: ${rec.date} | Total: ₹${recTotal.toStringAsFixed(2)}\n'
                              'Principal: ₹${rec.amount.toStringAsFixed(2)} | Chg: ₹${rec.bankCharges.toStringAsFixed(2)} | Int: ₹${rec.interest.toStringAsFixed(2)}'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle,
                                    size: 22, color: Colors.green),
                                tooltip: 'Mark as Closed (Move to History)',
                                onPressed: () async {
                                  setState(() {
                                    rec.isClosed = true;
                                  });
                                  await saveAllAssetsLoansData();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 18, color: Colors.blue),
                                onPressed: () => _openAddEditLoanRecordDialog(
                                    editingRecord: rec),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 18, color: Colors.red),
                                onPressed: () async {
                                  setState(() {
                                    globalLoanRecords.remove(rec);
                                  });
                                  await saveAllAssetsLoansData();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditLoanRecordDialog(),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}

// ============================================================================
// MASTER HISTORY SCREEN (EMI, Loan Taken, Loan Given)
// ============================================================================
class MasterHistoryScreen extends StatelessWidget {
  final String initialTabType;

  const MasterHistoryScreen({super.key, required this.initialTabType});

  int _getInitialIndex(String type) {
    switch (type) {
      case 'EMI':
        return 0;
      case 'Loan Taken':
        return 1;
      case 'Loan Given':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _getInitialIndex(initialTabType),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History Statement',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'EMI History'),
              Tab(text: 'Loan Taken'),
              Tab(text: 'Loan Given'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EmiHistoryTab(),
            LoanTakenHistoryTab(),
            SimpleLoanHistoryTab(loanType: 'Loan Given', color: Colors.blue),
          ],
        ),
      ),
    );
  }
}

class LoanTakenHistoryTab extends StatefulWidget {
  const LoanTakenHistoryTab({super.key});

  @override
  State<LoanTakenHistoryTab> createState() => _LoanTakenHistoryTabState();
}

class _LoanTakenHistoryTabState extends State<LoanTakenHistoryTab> {
  @override
  Widget build(BuildContext context) {
    final List<dynamic> closedItems = [];
    for (var person in globalLoanTakenPersons) {
      for (var entry in person.entries) {
        if (entry.isClosed) {
          closedItems.add({'person': person, 'entry': entry});
        }
      }
    }
    return closedItems.isEmpty
        ? const Center(
            child: Text('No repaid / closed loan taken history found.',
                style: TextStyle(color: Colors.grey)),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: closedItems.length,
            itemBuilder: (context, index) {
              final person = closedItems[index]['person'] as LoanTakenPerson;
              final entry = closedItems[index]['entry'] as LoanTakenEntry;
              final double shownRepaid = entry.repaidAmount ?? entry.totalAmount;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${person.name}${entry.note.isNotEmpty ? " - ${entry.note}" : ""}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.deepOrange),
                          ),
                          Text(
                            'Taken: ${entry.date}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Divider(height: 10),
                      Text(
                          'Loan: ₹${entry.principalAmount.toStringAsFixed(2)} | Interest: ₹${entry.interest.toStringAsFixed(2)} | Bank Charges: ₹${entry.bankCharges.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12)),
                      if (entry.repaidDate != null &&
                          entry.repaidDate!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Repaid Date: ${entry.repaidDate}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.teal),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              'Repaid Amount: ₹${shownRepaid.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.green)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    padding: EdgeInsets.zero),
                                icon: const Icon(Icons.restore, size: 16),
                                label: const Text('Restore',
                                    style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  setState(() {
                                    entry.isClosed = false;
                                  });
                                  await saveAllAssetsLoansData();
                                },
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: EdgeInsets.zero),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete',
                                    style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  setState(() {
                                    person.entries.remove(entry);
                                  });
                                  await saveAllAssetsLoansData();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

class EmiHistoryTab extends StatefulWidget {
  const EmiHistoryTab({super.key});

  @override
  State<EmiHistoryTab> createState() => _EmiHistoryTabState();
}

class _EmiHistoryTabState extends State<EmiHistoryTab> {
  @override
  Widget build(BuildContext context) {
    final List<EmiEntryItem> historyEntries = [];
    for (var cat in globalEmiCategories) {
      for (var e in cat.entries) {
        final int rem = e.numberOfEmis - e.paidRecords.length;
        if (rem <= 0) {
          historyEntries.add(e);
        }
      }
    }
    return historyEntries.isEmpty
        ? const Center(
            child: Text('No completed EMI history found.',
                style: TextStyle(color: Colors.grey)),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: historyEntries.length,
            itemBuilder: (context, index) {
              final e = historyEntries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.emiName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.red),
                          ),
                          Text(
                            'Date: ${e.date}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Divider(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              'Monthly Installment: ₹${e.perMonthEmi.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('Total Installments: ${e.numberOfEmis}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Loan: ₹${e.loanAmount.toStringAsFixed(2)} | Chg: ₹${e.bankCharges.toStringAsFixed(2)} | Int: ₹${e.interest.toStringAsFixed(2)}\n'
                          'Total Loan Amount: ₹${e.totalLoanAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Paid Details:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.teal),
                            ),
                            const SizedBox(height: 4),
                            Column(
                              children: e.paidRecords.map((pr) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          '• Date: ${pr.paidDate} (Inst #${pr.installmentNumber})',
                                          style: const TextStyle(fontSize: 11)),
                                      Text(
                                          'Paid: ₹${pr.paidAmount.toStringAsFixed(2)}${pr.fine > 0 ? " | Fine: ₹${pr.fine.toStringAsFixed(2)}" : ""} | Rem: ₹${pr.remainingAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: EdgeInsets.zero),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete from History',
                              style: TextStyle(fontSize: 11)),
                          onPressed: () async {
                            setState(() {
                              for (var cat in globalEmiCategories) {
                                cat.entries.remove(e);
                              }
                            });
                            await saveAllAssetsLoansData();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

class SimpleLoanHistoryTab extends StatefulWidget {
  final String loanType;
  final Color color;

  const SimpleLoanHistoryTab(
      {super.key, required this.loanType, required this.color});

  @override
  State<SimpleLoanHistoryTab> createState() => _SimpleLoanHistoryTabState();
}

class _SimpleLoanHistoryTabState extends State<SimpleLoanHistoryTab> {
  @override
  Widget build(BuildContext context) {
    final historyRecords = globalLoanRecords
        .where((r) => r.loanType == widget.loanType && r.isClosed)
        .toList();
    return historyRecords.isEmpty
        ? Center(
            child: Text(
                'No closed ${widget.loanType.toLowerCase()} history found.',
                style: const TextStyle(color: Colors.grey)),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: historyRecords.length,
            itemBuilder: (context, index) {
              final rec = historyRecords[index];
              final double recTotal = rec.amount + rec.bankCharges + rec.interest;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rec.title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: widget.color),
                          ),
                          Text(
                            'Date: ${rec.date}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Divider(height: 10),
                      Text(
                          'Principal: ₹${rec.amount.toStringAsFixed(2)} | Chg: ₹${rec.bankCharges.toStringAsFixed(2)} | Int: ₹${rec.interest.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount: ₹${recTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.green)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    padding: EdgeInsets.zero),
                                icon: const Icon(Icons.restore, size: 16),
                                label: const Text('Restore',
                                    style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  setState(() {
                                    rec.isClosed = false;
                                  });
                                  await saveAllAssetsLoansData();
                                },
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: EdgeInsets.zero),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete',
                                    style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  setState(() {
                                    globalLoanRecords.remove(rec);
                                  });
                                  await saveAllAssetsLoansData();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}