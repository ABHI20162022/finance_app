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

class SimpleLoanRecord {
  String id;
  String title;
  double amount;
  double bankCharges;
  double interest;
  String loanType; // 'Loan Taken', 'Loan Given'
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

// Global Storage
List<EmiCategory> globalEmiCategories = [];
List<SimpleLoanRecord> globalLoanRecords = [];

// Local Storage Helpers
Future<void> saveAllAssetsLoansData() async {
  final prefs = await SharedPreferences.getInstance();

  var emiData = globalEmiCategories
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

  var loanRecordsData = globalLoanRecords
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

  String? emiStr = prefs.getString('saved_emi_categories_v6');
  if (emiStr != null) {
    List decoded = jsonDecode(emiStr);
    globalEmiCategories = decoded
        .map((cMap) => EmiCategory(
              id: cMap['id'],
              name: cMap['name'],
              entries: (cMap['entries'] as List? ?? [])
                  .map((eMap) => EmiEntryItem(
                        id: eMap['id'],
                        emiName: eMap['emiName'],
                        date: eMap['date'],
                        loanAmount: (eMap['loanAmount'] as num).toDouble(),
                        bankCharges: (eMap['bankCharges'] as num).toDouble(),
                        interest: (eMap['interest'] as num).toDouble(),
                        numberOfEmis: eMap['numberOfEmis'] ?? 1,
                        totalLoanAmount:
                            (eMap['totalLoanAmount'] as num).toDouble(),
                        perMonthEmi:
                            (eMap['perMonthEmi'] as num?)?.toDouble() ?? 0.0,
                        paidRecords: (eMap['paidRecords'] as List? ?? [])
                            .map((prMap) => EmiPaidRecord(
                                  id: prMap['id'],
                                  paidDate: prMap['paidDate'],
                                  installmentNumber: prMap['installmentNumber'],
                                  paidAmount:
                                      (prMap['paidAmount'] as num).toDouble(),
                                  fine: (prMap['fine'] as num?)?.toDouble() ?? 0.0,
                                  remainingAmount: (prMap['remainingAmount']
                                          as num)
                                      .toDouble(),
                                ))
                            .toList(),
                      ))
                  .toList(),
            ))
        .toList();
  }

  String? loanRecStr = prefs.getString('saved_loan_records_v6');
  if (loanRecStr != null) {
    List decoded = jsonDecode(loanRecStr);
    globalLoanRecords = decoded
        .map((map) => SimpleLoanRecord(
              id: map['id'],
              title: map['title'],
              amount: (map['amount'] as num).toDouble(),
              bankCharges: (map['bankCharges'] as num?)?.toDouble() ?? 0.0,
              interest: (map['interest'] as num?)?.toDouble() ?? 0.0,
              loanType: map['loanType'],
              date: map['date'],
              isClosed: map['isClosed'] ?? false,
            ))
        .toList();
  }
}

DateTime? _parseDate(String dateStr) {
  try {
    List<String> parts = dateStr.split('-');
    if (parts.length == 3) {
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);
      return DateTime(year, month, day);
    }
  } catch (_) {}
  return null;
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
    setState(() {});
  }

  double get _totalEmiLoanAmount {
    double total = 0.0;
    for (var cat in globalEmiCategories) {
      for (var entry in cat.entries) {
        int rem = entry.numberOfEmis - entry.paidRecords.length;
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
      _totalEmiLoanAmount + _getLoanTypeTotal('Loan Taken');

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
          // 1. LOAN (Opens Sub-menu: EMI & Loan Taken)
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
          // 2. LOAN GIVEN
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
        int rem = entry.numberOfEmis - entry.paidRecords.length;
        if (rem > 0) {
          total += entry.totalLoanAmount;
        }
      }
    }
    return total;
  }

  double get _totalLoanTaken {
    return globalLoanRecords
        .where((r) => r.loanType == 'Loan Taken' && !r.isClosed)
        .fold(0.0, (sum, r) => sum + r.amount + r.bankCharges + r.interest);
  }

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
          // 1. EMI
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
          // 2. LOAN TAKEN
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
                    builder: (context) => const SimpleLoanTypeScreen(
                      loanType: 'Loan Taken',
                      themeColor: Colors.deepOrange,
                    ),
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
              subtitle: const Text('Loans borrowed from others',
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
                  Navigator.pop(context);
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
                  int rem = e.numberOfEmis - e.paidRecords.length;
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
    List<EmiEntryItem> allActiveEntries = [];
    for (var cat in globalEmiCategories) {
      for (var e in cat.entries) {
        int rem = e.numberOfEmis - e.paidRecords.length;
        if (rem > 0) {
          allActiveEntries.add(e);
        }
      }
    }
    List<String> emiNamesList = ['All'];
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
    DateTime? fromDate = _parseDate(fromDateController.text.trim());
    DateTime? toDate = _parseDate(toDateController.text.trim());
    List<EmiEntryItem> filteredEntries = allActiveEntries.where((e) {
      if (selectedFilterEmiName != 'All' && e.emiName != selectedFilterEmiName) {
        return false;
      }
      if (fromDate != null || toDate != null) {
        DateTime? entryDate = _parseDate(e.date);
        if (entryDate != null) {
          if (fromDate != null && entryDate.isBefore(fromDate)) return false;
          if (toDate != null && entryDate.isAfter(toDate)) return false;
        }
      }
      return true;
    }).toList();
    double grandTotal =
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
                      int paidCount = e.paidRecords.length;
                      int remainingInstallments = e.numberOfEmis - paidCount;
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
                                  border: Border.all(
                                      color: Colors.grey.shade300),
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
    String defaultDate =
        '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}';
    final dateController =
        TextEditingController(text: editingEntry?.date ?? defaultDate);
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
            double loanAmt =
                double.tryParse(loanAmtController.text.trim()) ?? 0.0;
            double charges =
                double.tryParse(bankChargesController.text.trim()) ?? 0.0;
            double interest =
                double.tryParse(interestController.text.trim()) ?? 0.0;
            int numEmis = int.tryParse(numEmisController.text.trim()) ?? 1;
            double totalLoanAmount = loanAmt + charges + interest;
            double perMonthEmi = numEmis > 0 ? totalLoanAmount / numEmis : 0.0;

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
                      String dateStr = dateController.text.trim().isNotEmpty
                          ? dateController.text.trim()
                          : defaultDate;
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
                      Navigator.pop(context);
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
    final paidDateController = TextEditingController(
        text:
            '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}');
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
                double paidAmt =
                    double.tryParse(paidAmountController.text.trim()) ?? 0.0;
                double fineAmt =
                    double.tryParse(fineController.text.trim()) ?? 0.0;
                if (paidAmt > 0) {
                  int nextInstallmentNum = entry.paidRecords.length + 1;
                  double previousTotalPaid = entry.paidRecords.fold(
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
                  Navigator.pop(context);
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
    List<EmiEntryItem> activeEntries = widget.emiCategory.entries.where((e) {
      int rem = e.numberOfEmis - e.paidRecords.length;
      return rem > 0;
    }).toList();
    double categoryTotal =
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
                      int paidCount = entry.paidRecords.length;
                      int remainingInstallments =
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
// SCREEN FOR LOAN TYPES (Loan Taken, Loan Given)
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
    String defaultDate =
        '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}';
    final dateController =
        TextEditingController(text: editingRecord?.date ?? defaultDate);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            double amt = double.tryParse(amountController.text.trim()) ?? 0.0;
            double charges =
                double.tryParse(bankChargesController.text.trim()) ?? 0.0;
            double interest =
                double.tryParse(interestController.text.trim()) ?? 0.0;
            double totalLoanAmount = amt + charges + interest;

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
                      String dateStr = dateController.text.trim().isNotEmpty
                          ? dateController.text.trim()
                          : defaultDate;
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
                      Navigator.pop(context);
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
    DateTime? fromDate = _parseDate(fromDateController.text.trim());
    DateTime? toDate = _parseDate(toDateController.text.trim());
    final records = globalLoanRecords.where((r) {
      if (r.loanType != widget.loanType || r.isClosed) return false;
      if (fromDate != null || toDate != null) {
        DateTime? recDate = _parseDate(r.date);
        if (recDate != null) {
          if (fromDate != null && recDate.isBefore(fromDate)) return false;
          if (toDate != null && recDate.isAfter(toDate)) return false;
        }
      }
      return true;
    }).toList();

    double total = records.fold(
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
                      double recTotal =
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
            SimpleLoanHistoryTab(
                loanType: 'Loan Taken', color: Colors.deepOrange),
            SimpleLoanHistoryTab(loanType: 'Loan Given', color: Colors.blue),
          ],
        ),
      ),
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
    List<EmiEntryItem> historyEntries = [];
    for (var cat in globalEmiCategories) {
      for (var e in cat.entries) {
        int rem = e.numberOfEmis - e.paidRecords.length;
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
              double recTotal = rec.amount + rec.bankCharges + rec.interest;

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
