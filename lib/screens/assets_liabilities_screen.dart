import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Models ---
class LoanEntryItem {
  String id;
  String title;
  double loanAmount;
  double bankCharges;
  double interest;
  double totalLiabilityAmount;
  String categoryName;
  String personName;
  String bankName;
  String date; // Taken Date
  bool isPaid; 
  String paidDate; // Paid Date

  LoanEntryItem({
    required this.id,
    required this.title,
    required this.loanAmount,
    required this.bankCharges,
    required this.interest,
    required this.totalLiabilityAmount,
    required this.categoryName,
    required this.personName,
    required this.bankName,
    required this.date,
    this.isPaid = false,
    this.paidDate = '',
  });
}

class LoanCategory {
  String id;
  String name;
  List<LoanEntryItem> items;
  LoanCategory({required this.id, required this.name, required this.items});
}

class PersonBankAccount {
  String id;
  String bankName; 
  double amount; 
  String date;
  PersonBankAccount({
    required this.id,
    required this.bankName,
    required this.amount,
    required this.date,
  });
}

class LoanPerson {
  String id;
  String name;
  List<PersonBankAccount> bankAccounts;
  LoanPerson({required this.id, required this.name, required this.bankAccounts});
}

class AssetLiabilityItem {
  String id;
  String title;
  double amount;
  String mainType; 
  String category;
  String date;
  AssetLiabilityItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.mainType,
    required this.category,
    required this.date,
  });
}

// Global Storage
List<AssetLiabilityItem> globalAssetsLiabilities = [];
List<LoanCategory> globalLoanCategories = [
  LoanCategory(id: '1', name: 'Gold Loan', items: []),
  LoanCategory(id: '2', name: 'Personal Loan', items: []),
];
List<LoanPerson> globalLoanPersons = [];

// Local Storage Helpers for Assets & Liabilities
Future<void> saveAssetsLiabilitiesDataToPrefs() async {
  final prefs = await SharedPreferences.getInstance();

  // 1. Assets & Liabilities
  List<Map<String, dynamic>> alData = globalAssetsLiabilities.map((i) => {
    'id': i.id,
    'title': i.title,
    'amount': i.amount,
    'mainType': i.mainType,
    'category': i.category,
    'date': i.date,
  }).toList();
  await prefs.setString('saved_assets_liabilities_items', jsonEncode(alData));

  // 2. Loan Categories & Entries
  List<Map<String, dynamic>> catData = globalLoanCategories.map((c) => {
    'id': c.id,
    'name': c.name,
    'items': c.items.map((e) => {
      'id': e.id,
      'title': e.title,
      'loanAmount': e.loanAmount,
      'bankCharges': e.bankCharges,
      'interest': e.interest,
      'totalLiabilityAmount': e.totalLiabilityAmount,
      'categoryName': e.categoryName,
      'personName': e.personName,
      'bankName': e.bankName,
      'date': e.date,
      'isPaid': e.isPaid,
      'paidDate': e.paidDate,
    }).toList(),
  }).toList();
  await prefs.setString('saved_loan_categories', jsonEncode(catData));

  // 3. Loan Persons & Bank Accounts
  List<Map<String, dynamic>> personData = globalLoanPersons.map((p) => {
    'id': p.id,
    'name': p.name,
    'bankAccounts': p.bankAccounts.map((b) => {
      'id': b.id,
      'bankName': b.bankName,
      'amount': b.amount,
      'date': b.date,
    }).toList(),
  }).toList();
  await prefs.setString('saved_loan_persons', jsonEncode(personData));
}

Future<void> loadAssetsLiabilitiesDataFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();

  // 1. Assets & Liabilities Load
  String? alStr = prefs.getString('saved_assets_liabilities_items');
  if (alStr != null) {
    List<dynamic> decodedAL = jsonDecode(alStr);
    globalAssetsLiabilities = decodedAL.map((map) => AssetLiabilityItem(
      id: map['id'],
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      mainType: map['mainType'],
      category: map['category'],
      date: map['date'],
    )).toList();
  }

  // 2. Loan Categories Load
  String? catStr = prefs.getString('saved_loan_categories');
  if (catStr != null) {
    List<dynamic> decodedCats = jsonDecode(catStr);
    globalLoanCategories = decodedCats.map((cMap) {
      var entries = (cMap['items'] as List? ?? []).map((eMap) => LoanEntryItem(
        id: eMap['id'],
        title: eMap['title'],
        loanAmount: (eMap['loanAmount'] as num).toDouble(),
        bankCharges: (eMap['bankCharges'] as num).toDouble(),
        interest: (eMap['interest'] as num).toDouble(),
        totalLiabilityAmount: (eMap['totalLiabilityAmount'] as num).toDouble(),
        categoryName: eMap['categoryName'],
        personName: eMap['personName'],
        bankName: eMap['bankName'],
        date: eMap['date'],
        isPaid: eMap['isPaid'] ?? false,
        paidDate: eMap['paidDate'] ?? '',
      )).toList();
      return LoanCategory(id: cMap['id'], name: cMap['name'], items: entries);
    }).toList();
  }

  // 3. Loan Persons Load
  String? personStr = prefs.getString('saved_loan_persons');
  if (personStr != null) {
    List<dynamic> decodedPersons = jsonDecode(personStr);
    globalLoanPersons = decodedPersons.map((pMap) {
      var banks = (pMap['bankAccounts'] as List? ?? []).map((bMap) => PersonBankAccount(
        id: bMap['id'],
        bankName: bMap['bankName'],
        amount: (bMap['amount'] as num).toDouble(),
        date: bMap['date'],
      )).toList();
      return LoanPerson(id: pMap['id'], name: pMap['name'], bankAccounts: banks);
    }).toList();
  }
}

class AssetsLiabilitiesScreen extends StatefulWidget {
  const AssetsLiabilitiesScreen({super.key});

  @override
  State<AssetsLiabilitiesScreen> createState() => _AssetsLiabilitiesScreenState();
}

class _AssetsLiabilitiesScreenState extends State<AssetsLiabilitiesScreen> {
  int _currentScreen = 0;
  LoanCategory? _selectedCategory;
  LoanPerson? _selectedPerson;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await loadAssetsLiabilitiesDataFromPrefs();
    setState(() {});
  }

  double get _totalAssets {
    return globalAssetsLiabilities
        .where((item) => item.mainType == 'Asset')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _totalBorrows {
    return globalAssetsLiabilities
        .where((item) => item.mainType == 'Borrow')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _totalLoansFromCategories {
    double total = 0;
    for (var cat in globalLoanCategories) {
      for (var item in cat.items) {
        if (!item.isPaid) {
          total += item.totalLiabilityAmount;
        }
      }
    }
    return total;
  }

  double get _totalLiabilities => _totalLoansFromCategories + _totalBorrows;
  double get _netWorth => _totalAssets - _totalLiabilities;

  void _openAddEditCategoryDialog({LoanCategory? editingCategory}) {
    final catController = TextEditingController(text: editingCategory?.name ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editingCategory == null ? 'Add Loan Category' : 'Edit Loan Category'),
          content: TextField(
            controller: catController,
            decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (catController.text.isNotEmpty) {
                  setState(() {
                    if (editingCategory != null) {
                      editingCategory.name = catController.text;
                    } else {
                      globalLoanCategories.add(LoanCategory(
                        id: DateTime.now().toString(),
                        name: catController.text,
                        items: [],
                      ));
                    }
                  });
                  await saveAssetsLiabilitiesDataToPrefs();
                  Navigator.pop(context);
                }
              },
              child: Text(editingCategory == null ? 'Add' : 'Save', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _openAddEditLoanPersonDialog({LoanPerson? editingPerson}) {
    final nameController = TextEditingController(text: editingPerson?.name ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editingPerson == null ? 'Add Loan Person' : 'Edit Loan Person'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Person Name', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    if (editingPerson != null) {
                      editingPerson.name = nameController.text;
                    } else {
                      globalLoanPersons.add(LoanPerson(
                        id: DateTime.now().toString(),
                        name: nameController.text,
                        bankAccounts: [],
                      ));
                    }
                  });
                  await saveAssetsLiabilitiesDataToPrefs();
                  Navigator.pop(context);
                }
              },
              child: Text(editingPerson == null ? 'Add Person' : 'Save', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _openAddBankAccountDialog(LoanPerson person, {PersonBankAccount? editingAccount}) {
    final bankController = TextEditingController(text: editingAccount?.bankName ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editingAccount == null ? 'Add Bank Account (${person.name})' : 'Edit Bank Account'),
          content: TextField(
            controller: bankController,
            decoration: const InputDecoration(labelText: 'Bank Name / Account (ఉదా: SBI 235)', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                if (bankController.text.isNotEmpty) {
                  String dateStr = '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}';
                  setState(() {
                    if (editingAccount != null) {
                      editingAccount.bankName = bankController.text;
                    } else {
                      person.bankAccounts.add(PersonBankAccount(
                        id: DateTime.now().toString(),
                        bankName: bankController.text,
                        amount: 0.0,
                        date: dateStr,
                      ));
                    }
                  });
                  await saveAssetsLiabilitiesDataToPrefs();
                  Navigator.pop(context);
                }
              },
              child: Text(editingAccount == null ? 'Add Bank' : 'Save', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _openAddEditLoanEntryDialog(LoanCategory initialCategory, {LoanEntryItem? editingItem}) {
    final titleController = TextEditingController(text: editingItem?.title ?? '');
    final loanAmtController = TextEditingController(text: editingItem != null ? editingItem.loanAmount.toString() : '');
    final chargesController = TextEditingController(text: editingItem != null ? editingItem.bankCharges.toString() : '0');
    final interestController = TextEditingController(text: editingItem != null ? editingItem.interest.toString() : '0');
    String defaultDate = '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}';
    final dateController = TextEditingController(text: editingItem?.date ?? defaultDate);
    LoanCategory selectedCategory = initialCategory;
    String selectedPersonName = editingItem?.personName ?? (globalLoanPersons.isNotEmpty ? globalLoanPersons.first.name : '');
    String selectedBankName = editingItem?.bankName ?? '';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            LoanPerson? currentPersonObj;
            try {
              currentPersonObj = globalLoanPersons.firstWhere((p) => p.name == selectedPersonName);
            } catch (_) {
              currentPersonObj = null;
            }
            List<PersonBankAccount> personBanks = currentPersonObj?.bankAccounts ?? [];
            if (personBanks.isNotEmpty && !personBanks.any((b) => b.bankName == selectedBankName)) {
              selectedBankName = personBanks.first.bankName;
            }
            return AlertDialog(
              title: Text(editingItem == null ? 'Add Loan Entry' : 'Edit Loan Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<LoanCategory>(
                      value: globalLoanCategories.contains(selectedCategory) ? selectedCategory : globalLoanCategories.first,
                      decoration: const InputDecoration(labelText: 'Loan Category', border: OutlineInputBorder()),
                      items: globalLoanCategories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          dialogSetState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Entry Title / Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: 'Taken Date (dd-mm-yyyy)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    globalLoanPersons.isEmpty
                        ? const Text('No loan persons added yet. Please add a person first.', style: TextStyle(color: Colors.red, fontSize: 12))
                        : DropdownButtonFormField<String>(
                            value: globalLoanPersons.any((p) => p.name == selectedPersonName) ? selectedPersonName : globalLoanPersons.first.name,
                            decoration: const InputDecoration(labelText: 'Loan Person', border: OutlineInputBorder()),
                            items: globalLoanPersons.map((p) {
                              return DropdownMenuItem(value: p.name, child: Text(p.name));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                dialogSetState(() {
                                  selectedPersonName = val;
                                  LoanPerson? tempPerson;
                                  try {
                                    tempPerson = globalLoanPersons.firstWhere((p) => p.name == val);
                                  } catch (_) {}
                                  selectedBankName = (tempPerson != null && tempPerson.bankAccounts.isNotEmpty) 
                                      ? tempPerson.bankAccounts.first.bankName 
                                      : ''; 
                                });
                              }
                            },
                          ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: personBanks.any((b) => b.bankName == selectedBankName) ? selectedBankName : (personBanks.isNotEmpty ? personBanks.first.bankName : null),
                      decoration: const InputDecoration(labelText: 'Person Bank Account', border: OutlineInputBorder()),
                      items: personBanks.map((bankObj) {
                        return DropdownMenuItem(value: bankObj.bankName, child: Text(bankObj.bankName));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          dialogSetState(() => selectedBankName = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: loanAmtController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Loan Amount (అసలు)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: chargesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Bank Charges', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: interestController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Interest (వడ్డీ)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && loanAmtController.text.isNotEmpty) {
                      double loanAmt = double.tryParse(loanAmtController.text) ?? 0.0;
                      double charges = double.tryParse(chargesController.text) ?? 0.0;
                      double interest = double.tryParse(interestController.text) ?? 0.0;
                      double totalLiability = loanAmt + charges + interest;
                      String dateStr = dateController.text.isNotEmpty ? dateController.text : defaultDate;
                      
                      setState(() {
                        if (editingItem == null) {
                          selectedCategory.items.add(LoanEntryItem(
                            id: DateTime.now().toString(),
                            title: titleController.text,
                            loanAmount: loanAmt,
                            bankCharges: charges,
                            interest: interest,
                            totalLiabilityAmount: totalLiability,
                            categoryName: selectedCategory.name,
                            personName: selectedPersonName,
                            bankName: selectedBankName.isNotEmpty ? selectedBankName : 'Primary Account',
                            date: dateStr,
                          ));
                          if (selectedPersonName.isNotEmpty) {
                            try {
                              LoanPerson targetPerson = globalLoanPersons.firstWhere((p) => p.name == selectedPersonName);
                              if (targetPerson.bankAccounts.isEmpty) {
                                targetPerson.bankAccounts.add(PersonBankAccount(
                                  id: DateTime.now().toString(),
                                  bankName: selectedBankName.isNotEmpty ? selectedBankName : 'Main Account',
                                  amount: loanAmt,
                                  date: dateStr,
                                ));
                              } else {
                                var bankAcc = targetPerson.bankAccounts.firstWhere(
                                  (b) => b.bankName == selectedBankName,
                                  orElse: () => targetPerson.bankAccounts.first,
                                );
                                bankAcc.amount += loanAmt; 
                              }
                            } catch (_) {}
                          }
                          globalAssetsLiabilities.add(AssetLiabilityItem(
                            id: DateTime.now().toString(),
                            title: '$selectedPersonName Loan Deposit (${selectedCategory.name})',
                            amount: loanAmt,
                            mainType: 'Asset',
                            category: 'Bank Deposit',
                            date: dateStr,
                          ));
                        } else {
                          editingItem.title = titleController.text;
                          editingItem.loanAmount = loanAmt;
                          editingItem.bankCharges = charges;
                          editingItem.interest = interest;
                          editingItem.totalLiabilityAmount = totalLiability;
                          editingItem.date = dateStr;
                        }
                      });
                      await saveAssetsLiabilitiesDataToPrefs();
                      Navigator.pop(context);
                    }
                  },
                  child: Text(editingItem == null ? 'Save Entry' : 'Update', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Repayment (Paid / Nil) Dialog ---
  void _openRepaymentDialog(LoanEntryItem loanItem) {
    final interestController = TextEditingController(text: loanItem.interest.toString());
    String defaultDate = '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}';
    final paidDateController = TextEditingController(text: defaultDate);
    String selectedPayer = loanItem.personName.isNotEmpty ? loanItem.personName : (globalLoanPersons.isNotEmpty ? globalLoanPersons.first.name : '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            double currentInterest = double.tryParse(interestController.text) ?? 0.0;
            double totalAmountToPay = loanItem.loanAmount + loanItem.bankCharges + currentInterest;
            return AlertDialog(
              title: Text('Loan Repayment: ${loanItem.title}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📋 Loan Details & History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          const Divider(height: 8),
                          Text('• Taken Date: ${loanItem.date}'),
                          Text('• Loan Amount (అసలు): ₹${loanItem.loanAmount}'),
                          Text('• Bank Charges: ₹${loanItem.bankCharges}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: paidDateController,
                      decoration: const InputDecoration(labelText: 'Paid Date (dd-mm-yyyy)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: interestController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Interest (వడ్డీ)', border: OutlineInputBorder()),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.red[50],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount to Pay:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹${totalAmountToPay.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: globalLoanPersons.any((p) => p.name == selectedPayer) ? selectedPayer : null,
                      decoration: const InputDecoration(labelText: 'Who is Paying? (Paid By)', border: OutlineInputBorder()),
                      items: globalLoanPersons.map((p) {
                        return DropdownMenuItem(value: p.name, child: Text(p.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          dialogSetState(() => selectedPayer = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    setState(() {
                      loanItem.totalLiabilityAmount = 0.0;
                      loanItem.isPaid = true;
                      loanItem.paidDate = paidDateController.text;
                      loanItem.interest = currentInterest;
                      if (selectedPayer.isNotEmpty) {
                        try {
                          LoanPerson targetPerson = globalLoanPersons.firstWhere((p) => p.name == selectedPayer);
                          for (var bank in targetPerson.bankAccounts) {
                            if (bank.bankName == loanItem.bankName || targetPerson.bankAccounts.length == 1) {
                              bank.amount -= loanItem.loanAmount;
                              if (bank.amount < 0) bank.amount = 0;
                              break;
                            }
                          }
                        } catch (_) {}
                      }
                    });
                    await saveAssetsLiabilitiesDataToPrefs();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Loan Paid Successfully!')),
                    );
                  },
                  child: const Text('Confirm Paid (Nil)', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAddAssetBorrowDialog(String type, {AssetLiabilityItem? editingItem}) {
    final titleController = TextEditingController(text: editingItem?.title ?? '');
    final amountController = TextEditingController(text: editingItem != null ? editingItem.amount.toString() : '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editingItem == null ? 'Add $type' : 'Edit $type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title / Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: type == 'Asset' ? Colors.teal : Colors.orange),
              onPressed: () async {
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  double amt = double.tryParse(amountController.text) ?? 0.0;
                  String dateStr = '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}';
                  setState(() {
                    if (editingItem != null) {
                      editingItem.title = titleController.text;
                      editingItem.amount = amt;
                    } else {
                      globalAssetsLiabilities.add(AssetLiabilityItem(
                        id: DateTime.now().toString(),
                        title: titleController.text,
                        amount: amt,
                        mainType: type,
                        category: type,
                        date: dateStr,
                      ));
                    }
                  });
                  await saveAssetsLiabilitiesDataToPrefs();
                  Navigator.pop(context);
                }
              },
              child: Text(editingItem == null ? 'Add' : 'Save', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        leading: _currentScreen > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (_currentScreen == 4) {
                      _currentScreen = 3;
                    } else if (_currentScreen == 6) {
                      _currentScreen = 5;
                    } else if (_currentScreen == 3 || _currentScreen == 5) {
                      _currentScreen = 2;
                    } else if (_currentScreen == 2) {
                      _currentScreen = 1;
                    } else {
                      _currentScreen = 0;
                    }
                  });
                },
              )
            : null,
      ),
      body: Column(
        children: [
          if (_currentScreen == 0)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                children: [
                  const Text('Net Worth', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal)),
                  Text('₹${_netWorth.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _netWorth >= 0 ? Colors.green : Colors.red)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Assets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                          Text('₹${_totalAssets.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      Container(height: 25, width: 1, color: Colors.teal.shade300),
                      Column(
                        children: [
                          const Text('Total Liabilities', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                          Text('₹${_totalLiabilities.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBodyContent()),
        ],
      ),
      floatingActionButton: _getFloatingActionButton(),
    );
  }

  String _getTitle() {
    if (_currentScreen == 0) return 'Assets & Liabilities';
    if (_currentScreen == 1) return 'Liabilities';
    if (_currentScreen == 2) return 'Loans Management';
    if (_currentScreen == 3) return 'Loan Categories';
    if (_currentScreen == 4) return '${_selectedCategory?.name ?? ''} Entries';
    if (_currentScreen == 5) return 'Loan Persons';
    if (_currentScreen == 6) return '${_selectedPerson?.name ?? ''} Accounts';
    if (_currentScreen == 7) return 'Borrows List';
    if (_currentScreen == 8) return 'Assets List';
    return '';
  }

  Widget _buildBodyContent() {
    if (_currentScreen == 0) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildMenuCard(title: 'Assets', amount: _totalAssets, color: Colors.green, icon: Icons.account_balance_wallet, onTap: () => setState(() => _currentScreen = 8)),
            const SizedBox(height: 12),
            _buildMenuCard(title: 'Liabilities', amount: _totalLiabilities, color: Colors.red, icon: Icons.money_off, onTap: () => setState(() => _currentScreen = 1)),
          ],
        ),
      );
    } else if (_currentScreen == 1) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildMenuCard(title: 'Loans', amount: _totalLoansFromCategories, color: Colors.red, icon: Icons.account_balance, onTap: () => setState(() => _currentScreen = 2)),
            const SizedBox(height: 12),
            _buildMenuCard(title: 'Borrows', amount: _totalBorrows, color: Colors.orange, icon: Icons.person_outline, onTap: () => setState(() => _currentScreen = 7)),
          ],
        ),
      );
    } else if (_currentScreen == 2) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildMenuCard(title: 'Loan Categories', amount: _totalLoansFromCategories, color: Colors.red[800]!, icon: Icons.category, onTap: () => setState(() => _currentScreen = 3)),
            const SizedBox(height: 12),
            _buildMenuCard(title: 'Loan Persons', amount: _totalLoansFromCategories, color: Colors.red[400]!, icon: Icons.people, onTap: () => setState(() => _currentScreen = 5)),
          ],
        ),
      );
    } else if (_currentScreen == 3) {
      return ListView.builder(
        itemCount: globalLoanCategories.length,
        itemBuilder: (context, index) {
          final cat = globalLoanCategories[index];
          double catTotal = cat.items.where((i) => !i.isPaid).fold(0.0, (sum, i) => sum + i.totalLiabilityAmount);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              onTap: () => setState(() { _selectedCategory = cat; _currentScreen = 4; }),
              leading: CircleAvatar(backgroundColor: Colors.red[100], child: const Icon(Icons.account_balance, color: Colors.red)),
              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Active Liability: ₹${catTotal.toStringAsFixed(2)} (${cat.items.length} Total Entries)'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () async {
                  setState(() => globalLoanCategories.removeAt(index));
                  await saveAssetsLiabilitiesDataToPrefs();
                },
              ),
            ),
          );
        },
      );
    } else if (_currentScreen == 4) {
      final category = _selectedCategory;
      if (category == null || category.items.isEmpty) {
        return const Center(child: Text('No entries added yet.\nClick "Add Entry" below.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
      }
      return ListView.builder(
        itemCount: category.items.length,
        itemBuilder: (context, index) {
          final item = category.items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: item.isPaid ? Colors.grey[100] : Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: item.isPaid ? Colors.green[100] : Colors.red[100], 
                child: Icon(item.isPaid ? Icons.check_circle : Icons.description, color: item.isPaid ? Colors.green : Colors.red),
              ),
              title: Text(
                item.title, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  decoration: item.isPaid ? TextDecoration.lineThrough : null,
                  color: item.isPaid ? Colors.grey[700] : Colors.black,
                ),
              ),
              subtitle: Text(
                'Person: ${item.personName} | Bank: ${item.bankName}\n'
                'Loan: ₹${item.loanAmount} + Charges: ₹${item.bankCharges} + Int: ₹${item.interest}\n'
                'Taken: ${item.date} ${item.paidDate.isNotEmpty ? "| Paid: ${item.paidDate}" : ""}\n'
                'Status: ${item.isPaid ? "✅ PAID & CLOSED (Nil)" : "⏳ ACTIVE"}',
                style: TextStyle(color: item.isPaid ? Colors.green[800] : Colors.black87),
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.isPaid ? '₹0.00 (Nil)' : '-₹${item.totalLiabilityAmount.toStringAsFixed(2)}', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: item.isPaid ? Colors.green : Colors.red, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  if (!item.isPaid)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0)),
                      onPressed: () => _openRepaymentDialog(item),
                      child: const Text('Repay', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    onPressed: () => _openAddEditLoanEntryDialog(category, editingItem: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () async {
                      setState(() {
                        category.items.removeAt(index);
                      });
                      await saveAssetsLiabilitiesDataToPrefs();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (_currentScreen == 5) {
      return ListView.builder(
        itemCount: globalLoanPersons.length,
        itemBuilder: (context, index) {
          final person = globalLoanPersons[index];
          double personTotal = person.bankAccounts.fold(0.0, (sum, b) => sum + b.amount);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              onTap: () => setState(() { _selectedPerson = person; _currentScreen = 6; }),
              leading: CircleAvatar(backgroundColor: Colors.red[100], child: const Icon(Icons.person, color: Colors.red)),
              title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Accounts: ${person.bankAccounts.length} | Available Bal: ₹${personTotal.toStringAsFixed(2)}'),
            ),
          );
        },
      );
    } else if (_currentScreen == 6) {
      final person = _selectedPerson;
      if (person == null) return Container();
      return ListView.builder(
        itemCount: person.bankAccounts.length,
        itemBuilder: (context, index) {
          final bankAcc = person.bankAccounts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.teal[100], child: const Icon(Icons.account_balance, color: Colors.teal)),
              title: Text(bankAcc.bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Available Balance: ₹${bankAcc.amount.toStringAsFixed(2)}'),
            ),
          );
        },
      );
    } else if (_currentScreen == 7) {
      final borrows = globalAssetsLiabilities.where((i) => i.mainType == 'Borrow').toList();
      return ListView.builder(
        itemCount: borrows.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(borrows[index].title), 
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹${borrows[index].amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                onPressed: () => _openAddAssetBorrowDialog('Borrow', editingItem: borrows[index]),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () async {
                  setState(() {
                    globalAssetsLiabilities.remove(borrows[index]);
                  });
                  await saveAssetsLiabilitiesDataToPrefs();
                },
              ),
            ],
          ),
        ),
      );
    } else {
      final assets = globalAssetsLiabilities.where((i) => i.mainType == 'Asset').toList();
      return ListView.builder(
        itemCount: assets.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(assets[index].title), 
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹${assets[index].amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                onPressed: () => _openAddAssetBorrowDialog('Asset', editingItem: assets[index]),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () async {
                  setState(() {
                    globalAssetsLiabilities.remove(assets[index]);
                  });
                  await saveAssetsLiabilitiesDataToPrefs();
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget? _getFloatingActionButton() {
    if (_currentScreen == 0) return null;
    return FloatingActionButton.extended(
      onPressed: () {
        if (_currentScreen == 3) {
          _openAddEditCategoryDialog();
        } else if (_currentScreen == 4 && globalLoanCategories.isNotEmpty) {
          _openAddEditLoanEntryDialog(_selectedCategory ?? globalLoanCategories.first);
        } else if (_currentScreen == 5) {
          _openAddEditLoanPersonDialog();
        } else if (_currentScreen == 6 && _selectedPerson != null) {
          _openAddBankAccountDialog(_selectedPerson!);
        } else if (_currentScreen == 7) {
          _openAddAssetBorrowDialog('Borrow');
        } else if (_currentScreen == 8) {
          _openAddAssetBorrowDialog('Asset');
        }
      },
      backgroundColor: Colors.teal[700],
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        _currentScreen == 3 ? 'Add Category' : (_currentScreen == 4 ? 'Add Entry' : (_currentScreen == 5 ? 'Add Person' : (_currentScreen == 6 ? 'Add Bank' : 'Add Item'))),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildMenuCard({required String title, required double amount, required Color color, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}