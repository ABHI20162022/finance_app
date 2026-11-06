import 'package:flutter/material.dart';
import '../models/finance_model.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});
  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setDefaultCurrentMonth();
    _loadData();
  }

  void _setDefaultCurrentMonth() {
    DateTime now = DateTime.now();
    int lastDay = DateTime(now.year, now.month + 1, 0).day;
    fromDateController.text = "01-${now.month.toString().padLeft(2, '0')}-${now.year}";
    toDateController.text = "$lastDay-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  Future<void> _loadData() async {
    await loadFinanceDataFromPrefs();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveData() async {
    await saveFinanceDataToPrefs();
    if (mounted) {
      setState(() {});
    }
  }

  DateTime? _parseDate(String text) {
    try {
      List<String> parts = text.trim().split('-');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  bool _isDateInRange(String dateStr) {
    if (fromDateController.text.trim().isEmpty && toDateController.text.trim().isEmpty) {
      return true;
    }
    DateTime? entryDate = _parseDate(dateStr);
    if (entryDate == null) return true;
    
    DateTime? fDate = _parseDate(fromDateController.text);
    DateTime? tDate = _parseDate(toDateController.text);
    
    if (fDate != null) {
      DateTime start = DateTime(fDate.year, fDate.month, fDate.day);
      if (entryDate.isBefore(start)) return false;
    }
    if (tDate != null) {
      DateTime end = DateTime(tDate.year, tDate.month, tDate.day, 23, 59, 59);
      if (entryDate.isAfter(end)) return false;
    }
    return true;
  }

  bool _isTransferEntry(FinanceItem entry) {
    return entry.category.toLowerCase().contains('transfer') || entry.category.toLowerCase().contains('journal');
  }

  bool _isIncomeEntry(FinanceItem entry) => entry.amount > 0 && !_isTransferEntry(entry);
  bool _isExpenseEntry(FinanceItem entry) => entry.amount < 0 && !_isTransferEntry(entry);

  void _showIncomePersonDialog({PersonData? person}) {
    final controller = TextEditingController(text: person?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(person == null ? 'Add Income Person' : 'Edit Person'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Person Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              String name = controller.text.trim();
              if (name.isNotEmpty) {
                bool exists = globalPersons.any((p) => p.name.toLowerCase() == name.toLowerCase() && p != person);
                if (exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This person name already exists!'), backgroundColor: Colors.red),
                  );
                  return;
                }
                if (person == null) {
                  globalPersons.add(PersonData(
                    id: DateTime.now().toString(),
                    name: name,
                    bankAccounts: [],
                    entries: [],
                  ));
                } else {
                  person.name = name;
                }
                await _saveData();
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showIncomeCategoryDialog({String? oldCategory, int? index}) {
    final controller = TextEditingController(text: oldCategory ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(oldCategory == null ? 'Add Income Category' : 'Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              String name = controller.text.trim();
              if (name.isNotEmpty) {
                if (oldCategory == null) {
                  if (!globalIncomeCategories.contains(name)) {
                    globalIncomeCategories.add(name);
                  }
                } else if (index != null) {
                  globalIncomeCategories[index] = name;
                }
                await _saveData();
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showJournalEntryDialog(BuildContext context, {FinanceItem? existingItem}) {
    if (globalPersons.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kanalisi kanisam 2 Persons undali Journal Entry kosam!'), backgroundColor: Colors.red),
      );
      return;
    }

    String fromPerson = globalPersons.first.name;
    String toPerson = globalPersons[1].name;
    
    if (existingItem != null) {
      fromPerson = existingItem.person;
      if (existingItem.category.startsWith('Journal to ')) {
        toPerson = existingItem.category.replaceFirst('Journal to ', '');
      }
    }

    final amountController = TextEditingController(text: existingItem != null ? existingItem.amount.abs().toString() : '');
    final descController = TextEditingController(text: existingItem?.description ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingItem == null ? 'New Journal Entry' : 'Edit Journal Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: globalPersons.any((p) => p.name == fromPerson) ? fromPerson : globalPersons.first.name,
                      decoration: const InputDecoration(labelText: 'From Person (Debit - Dr)', border: OutlineInputBorder()),
                      items: globalPersons.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                      onChanged: (val) => setDialogState(() => fromPerson = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: globalPersons.any((p) => p.name == toPerson) ? toPerson : globalPersons[1].name,
                      decoration: const InputDecoration(labelText: 'To Person (Credit - Cr)', border: OutlineInputBorder()),
                      items: globalPersons.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                      onChanged: (val) => setDialogState(() => toPerson = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Narration / Description', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (fromPerson == toPerson) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("From and To Persons okate undakudadhu!"), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    double amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amt > 0) {
                      if (existingItem != null) {
                        for (var p in globalPersons) {
                          p.entries.removeWhere((e) => e.id.startsWith(existingItem.id.replaceAll('_dr', '').replaceAll('_cr', '')));
                        }
                      }

                      String baseId = existingItem != null 
                          ? existingItem.id.replaceAll('_dr', '').replaceAll('_cr', '') 
                          : DateTime.now().millisecondsSinceEpoch.toString();
                      
                      String dateNow = existingItem?.date ?? "${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}";
                      String note = descController.text.trim();
                      String narration = note.isNotEmpty ? note : 'Journal Adjustment';

                      PersonData sender = globalPersons.firstWhere((p) => p.name == fromPerson);
                      sender.entries.add(
                        FinanceItem(
                          id: '${baseId}_dr',
                          title: 'Journal Out',
                          amount: -amt,
                          person: fromPerson,
                          category: 'Journal to $toPerson',
                          depositAccount: 'Journal',
                          date: dateNow,
                          description: narration,
                        ),
                      );

                      PersonData receiver = globalPersons.firstWhere((p) => p.name == toPerson);
                      receiver.entries.add(
                        FinanceItem(
                          id: '${baseId}_cr',
                          title: 'Journal In',
                          amount: amt,
                          person: toPerson,
                          category: 'Journal from $fromPerson',
                          depositAccount: 'Journal',
                          date: dateNow,
                          description: narration,
                        ),
                      );

                      await _saveData();
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Journal Entry Saved Successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                  child: const Text('Save Entry'),
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
    double totalIncome = 0;
    double totalExpenses = 0;
    
    for (var person in globalPersons) {
      for (var entry in person.entries) {
        if (_isDateInRange(entry.date)) {
          if (_isIncomeEntry(entry)) {
            totalIncome += entry.amount;
          } else if (_isExpenseEntry(entry)) {
            totalExpenses += entry.amount.abs();
          }
        }
      }
    }
    double netBalance = totalIncome - totalExpenses;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Income & Balance', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.book, size: 24),
              tooltip: 'New Journal Entry',
              onPressed: () => _showJournalEntryDialog(context),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Income Persons'),
              Tab(icon: Icon(Icons.category), text: 'Income Categories'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Statement'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Appula Statement'),
              Tab(icon: Icon(Icons.import_contacts), text: 'Journal Entries'),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.green.shade700,
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Income', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text('₹${totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      color: Colors.red.shade700,
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Expenses', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text('₹${totalExpenses.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      color: netBalance >= 0 ? Colors.blue.shade700 : Colors.red.shade900,
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Net Balance', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text('₹${netBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fromDateController,
                      decoration: const InputDecoration(labelText: 'From (dd-mm-yyyy)', border: OutlineInputBorder(), isDense: true, fillColor: Colors.white, filled: true, contentPadding: EdgeInsets.all(8)),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: toDateController,
                      decoration: const InputDecoration(labelText: 'To (dd-mm-yyyy)', border: OutlineInputBorder(), isDense: true, fillColor: Colors.white, filled: true, contentPadding: EdgeInsets.all(8)),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.green, size: 20),
                    onPressed: () {
                      setState(() {
                        fromDateController.clear();
                        toDateController.clear();
                      });
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Income Persons
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Income Persons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              onPressed: () => _showIncomePersonDialog(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Person'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: globalPersons.isEmpty
                              ? const Center(child: Text('No persons added yet.', textAlign: TextAlign.center))
                              : ListView.builder(
                                  itemCount: globalPersons.length,
                                  itemBuilder: (context, index) {
                                    final person = globalPersons[index];
                                    
                                    double personIncome = 0;
                                    double personExpense = 0;
                                    double personTransferNet = 0;
                                    
                                    for (var e in person.entries) {
                                      if (_isDateInRange(e.date)) {
                                        if (_isTransferEntry(e)) {
                                          personTransferNet += e.amount;
                                        } else {
                                          if (e.amount > 0) personIncome += e.amount;
                                          if (e.amount < 0) personExpense += e.amount.abs();
                                        }
                                      }
                                    }
                                    double personNet = (personIncome - personExpense) + personTransferNet;

                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        leading: const CircleAvatar(backgroundColor: Colors.green, radius: 18, child: Icon(Icons.person, color: Colors.white, size: 20)),
                                        title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        subtitle: Text('Income: ₹${personIncome.toStringAsFixed(2)} | Exp: ₹${personExpense.toStringAsFixed(2)}\nNet Balance: ₹${personNet.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: personNet >= 0 ? Colors.blue.shade800 : Colors.red.shade800)),
                                        isThreeLine: true,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(onTap: () => _showIncomePersonDialog(person: person), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: Colors.blue))),
                                            InkWell(
                                              onTap: () async {
                                                globalPersons.removeAt(index);
                                                await _saveData();
                                              },
                                              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete, size: 18, color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => IncomePersonDetailScreen(
                                                person: person,
                                                fromDateStr: fromDateController.text,
                                                toDateStr: toDateController.text,
                                              ),
                                            ),
                                          ).then((_) async {
                                            await _loadData();
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Income Categories
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Income Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              onPressed: () => _showIncomeCategoryDialog(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Category'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: globalIncomeCategories.isEmpty
                              ? const Center(child: Text('No income categories added yet.', textAlign: TextAlign.center))
                              : ListView.builder(
                                  itemCount: globalIncomeCategories.length,
                                  itemBuilder: (context, index) {
                                    final cat = globalIncomeCategories[index];
                                    double categoryTotal = 0;
                                    for (var p in globalPersons) {
                                      for (var e in p.entries) {
                                        if (e.category.startsWith(cat) && _isDateInRange(e.date) && _isIncomeEntry(e)) {
                                          categoryTotal += e.amount;
                                        }
                                      }
                                    }
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                        leading: const CircleAvatar(backgroundColor: Colors.green, radius: 18, child: Icon(Icons.attach_money, color: Colors.white, size: 18)),
                                        title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        subtitle: Text('Total Income: ₹${categoryTotal.toStringAsFixed(2)}', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(onTap: () => _showIncomeCategoryDialog(oldCategory: cat, index: index), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: Colors.blue))),
                                            InkWell(
                                              onTap: () async {
                                                globalIncomeCategories.removeAt(index);
                                                await _saveData();
                                              },
                                              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete, size: 18, color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => IncomeCategoryDetailScreen(
                                                categoryName: cat,
                                                fromDateStr: fromDateController.text,
                                                toDateStr: toDateController.text,
                                              ),
                                            ),
                                          ).then((_) async {
                                            await _loadData();
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 3: Statement
                  TotalStatementTab(
                    fromDateStr: fromDateController.text,
                    toDateStr: toDateController.text,
                    isDateInRange: _isDateInRange,
                  ),

                  // Tab 4: Appula Statement (Loans & Dues Register with Person Filter linked to main Date filter)
                  AppulaStatementTab(
                    isDateInRange: _isDateInRange,
                    fromDateController: fromDateController,
                    toDateController: toDateController,
                  ),

                  // Tab 5: Journal Entries Tab
                  JournalTab(
                    fromDateStr: fromDateController.text,
                    toDateStr: toDateController.text,
                    isDateInRange: _isDateInRange,
                    onAddJournalClick: () => _showJournalEntryDialog(context),
                    onEditJournalClick: (item) => _showJournalEntryDialog(context, existingItem: item),
                    onDeleteJournalClick: (item) async {
                      for (var p in globalPersons) {
                        p.entries.removeWhere((e) => e.id.startsWith(item.id.replaceAll('_dr', '').replaceAll('_cr', '')));
                      }
                      await _saveData();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Statement Helper Class
class StmtItem {
  final String date;
  final String person;
  final String category;
  final String description;
  final String account;
  final double creditAmount;
  final double debitAmount;
  double runningBalance;
  StmtItem({
    required this.date,
    required this.person,
    required this.category,
    required this.description,
    required this.account,
    required this.creditAmount,
    required this.debitAmount,
    this.runningBalance = 0.0,
  });
}

// Tab 3: Total Statement with Fixed Headings
class TotalStatementTab extends StatefulWidget {
  final String fromDateStr;
  final String toDateStr;
  final bool Function(String) isDateInRange;
  const TotalStatementTab({
    super.key,
    required this.fromDateStr,
    required this.toDateStr,
    required this.isDateInRange,
  });
  @override
  State<TotalStatementTab> createState() => _TotalStatementTabState();
}

class _TotalStatementTabState extends State<TotalStatementTab> {
  String? selectedPersonFilter;
  @override
  Widget build(BuildContext context) {
    List<StmtItem> statementItems = [];
    double totalCredit = 0.0;
    double totalDebit = 0.0;
    
    for (var person in globalPersons) {
      if (selectedPersonFilter != null && selectedPersonFilter!.isNotEmpty && person.name != selectedPersonFilter) {
        continue;
      }
      for (var entry in person.entries) {
        if (widget.isDateInRange(entry.date)) {
          double cr = entry.amount > 0 ? entry.amount : 0.0;
          double dr = entry.amount < 0 ? entry.amount.abs() : 0.0;
          totalCredit += cr;
          totalDebit += dr;
          statementItems.add(StmtItem(
            date: entry.date,
            person: person.name,
            category: entry.category,
            description: entry.description,
            account: entry.depositAccount,
            creditAmount: cr,
            debitAmount: dr,
          ));
        }
      }
    }
    statementItems.sort((a, b) => a.date.compareTo(b.date));
    double currentBal = 0.0;
    for (var item in statementItems) {
      currentBal += (item.creditAmount - item.debitAmount);
      item.runningBalance = currentBal;
    }
    double netBalance = totalCredit - totalDebit;
    List<String> personNames = globalPersons.map((p) => p.name).toList();
    
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Income & Expense Statement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              if (selectedPersonFilter != null)
                TextButton.icon(
                  onPressed: () => setState(() => selectedPersonFilter = null),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Show All', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: selectedPersonFilter,
            decoration: const InputDecoration(
              labelText: 'Filter by Person (Optional)',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            hint: const Text('All Persons (Total Statement)', style: TextStyle(fontSize: 12)),
            items: personNames.map((name) => DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) {
              setState(() {
                selectedPersonFilter = val;
              });
            },
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: Colors.green.shade100,
            child: const Row(
              children: [
                SizedBox(width: 75, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Person & Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Narration / Acc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 70, child: Text('Inflow(Cr)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green), textAlign: TextAlign.right)),
                SizedBox(width: 70, child: Text('Out(Dr)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red), textAlign: TextAlign.right)),
                SizedBox(width: 75, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue), textAlign: TextAlign.right)),
              ],
            ),
          ),

          Expanded(
            child: statementItems.isEmpty
                ? const Center(child: Text('No transactions found.'))
                : ListView.builder(
                    itemCount: statementItems.length,
                    itemBuilder: (context, index) {
                      final item = statementItems[index];
                      String detailsStr = "${item.person} (${item.category})";
                      String narration = "${item.account}${item.description.isNotEmpty ? ' - ${item.description}' : ''}";
                      bool isTransfer = item.category.toLowerCase().contains('transfer') || item.category.toLowerCase().contains('journal');
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                          color: index.isEven ? Colors.white : Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 75, child: Text(item.date, style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 2, child: Text(detailsStr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isTransfer ? Colors.blue.shade800 : Colors.black87))),
                            Expanded(flex: 2, child: Text(narration, style: const TextStyle(fontSize: 11))),
                            SizedBox(
                              width: 70,
                              child: Text(
                                item.creditAmount > 0 ? '₹${item.creditAmount.toStringAsFixed(2)}' : '-',
                                style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(
                              width: 70,
                              child: Text(
                                item.debitAmount > 0 ? '₹${item.debitAmount.toStringAsFixed(2)}' : '-',
                                style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(
                              width: 75,
                              child: Text(
                                '₹${item.runningBalance.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.runningBalance >= 0 ? Colors.blue.shade900 : Colors.red.shade900),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Inflow: ₹${totalCredit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('Total Outflow: ₹${totalDebit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                const Divider(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedPersonFilter == null ? 'Net Balance:' : '$selectedPersonFilter Balance:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('₹${netBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: netBalance >= 0 ? Colors.blue.shade900 : Colors.red.shade900)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Tab 4: Appula Statement (Loans & Dues Register with Person Filter using main date range)
class AppulaStatementTab extends StatefulWidget {
  final bool Function(String) isDateInRange;
  final TextEditingController fromDateController;
  final TextEditingController toDateController;

  const AppulaStatementTab({
    super.key,
    required this.isDateInRange,
    required this.fromDateController,
    required this.toDateController,
  });

  @override
  State<AppulaStatementTab> createState() => _AppulaStatementTabState();
}

class _AppulaStatementTabState extends State<AppulaStatementTab> {
  String? selectedAppuPersonFilter;

  @override
  Widget build(BuildContext context) {
    List<String> personNames = globalPersons.map((p) => p.name).toList();

    List appuItems = [];
    for (var person in globalPersons) {
      if (selectedAppuPersonFilter != null && selectedAppuPersonFilter!.isNotEmpty && person.name != selectedAppuPersonFilter) {
        continue;
      }
      for (var entry in person.entries) {
        if (widget.isDateInRange(entry.date)) {
          appuItems.add({
            'date': entry.date,
            'person': person.name,
            'category': entry.category,
            'narration': entry.description.isNotEmpty ? entry.description : entry.depositAccount,
            'amount': entry.amount,
          });
        }
      }
    }
    appuItems.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Appula Statement (Loans & Dues)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              if (selectedAppuPersonFilter != null)
                TextButton.icon(
                  onPressed: () => setState(() => selectedAppuPersonFilter = null),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Show All', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          
          DropdownButtonFormField<String>(
            value: selectedAppuPersonFilter,
            decoration: const InputDecoration(
              labelText: 'Filter by Person / Credit Card',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            hint: const Text('All Persons (Dues Register)', style: TextStyle(fontSize: 12)),
            items: personNames.map((name) => DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) {
              setState(() {
                selectedAppuPersonFilter = val;
              });
            },
          ),
          const SizedBox(height: 10),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: Colors.amber.shade200,
            child: const Row(
              children: [
                SizedBox(width: 75, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Person & Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Narration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 80, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
              ],
            ),
          ),

          Expanded(
            child: appuItems.isEmpty
                ? const Center(child: Text('No records found for selected filter.'))
                : ListView.builder(
                    itemCount: appuItems.length,
                    itemBuilder: (context, index) {
                      final item = appuItems[index];
                      double amt = item['amount'] as double;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                          color: index.isEven ? Colors.white : Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 75, child: Text(item['date'], style: const TextStyle(fontSize: 11))),
                            Expanded(
                              flex: 2, 
                              child: Text(
                                '${item['person']} (${item['category']})', 
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              flex: 2, 
                              child: Text(
                                item['narration'], 
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                '₹${amt.abs().toStringAsFixed(2)} ${amt < 0 ? "(Dr)" : "(Cr)"}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: amt < 0 ? Colors.red.shade900 : Colors.green.shade900,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Tab 5: Journal Entries Tab
class JournalTab extends StatefulWidget {
  final String fromDateStr;
  final String toDateStr;
  final bool Function(String) isDateInRange;
  final VoidCallback onAddJournalClick;
  final Function(FinanceItem) onEditJournalClick;
  final Function(FinanceItem) onDeleteJournalClick;

  const JournalTab({
    super.key,
    required this.fromDateStr,
    required this.toDateStr,
    required this.isDateInRange,
    required this.onAddJournalClick,
    required this.onEditJournalClick,
    required this.onDeleteJournalClick,
  });

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  @override
  Widget build(BuildContext context) {
    List<FinanceItem> journalEntries = [];
    for (var person in globalPersons) {
      for (var entry in person.entries) {
        if (entry.category.toLowerCase().contains('journal to') && widget.isDateInRange(entry.date)) {
          journalEntries.add(entry);
        }
      }
    }
    journalEntries.sort((a, b) => b.date.compareTo(a.date));

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Journal Register (Adjustments)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: widget.onAddJournalClick,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Entry', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: journalEntries.isEmpty
                ? const Center(child: Text('No journal entries recorded yet.'))
                : ListView.builder(
                    itemCount: journalEntries.length,
                    itemBuilder: (context, index) {
                      final item = journalEntries[index];
                      String receiverName = item.category.replaceFirst('Journal to ', '');
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Date: ${item.date}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                  Row(
                                    children: [
                                      Text('₹${item.amount.abs().toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue.shade900)),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => widget.onEditJournalClick(item),
                                        child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: Colors.blue)),
                                      ),
                                      InkWell(
                                        onTap: () => widget.onDeleteJournalClick(item),
                                        child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete, size: 18, color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 10),
                              Row(
                                children: [
                                  const Text('Debit (Dr - From): ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
                                  Text(item.person, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Text('Credit (Cr - To): ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                                  Text(receiverName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (item.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Narration: ${item.description}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                              ]
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
}

// Category Detail Screen
class IncomeCategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final String? fromDateStr;
  final String? toDateStr;
  const IncomeCategoryDetailScreen({super.key, required this.categoryName, this.fromDateStr, this.toDateStr});
  @override
  State<IncomeCategoryDetailScreen> createState() => _IncomeCategoryDetailScreenState();
}

class _IncomeCategoryDetailScreenState extends State<IncomeCategoryDetailScreen> {
  Future<void> _saveData() async {
    await saveFinanceDataToPrefs();
    if (mounted) {
      setState(() {});
    }
  }

  DateTime? _parseDate(String text) {
    try {
      List<String> parts = text.trim().split('-');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  bool _isDateInRange(String dateStr) {
    if ((widget.fromDateStr == null || widget.fromDateStr!.trim().isEmpty) && (widget.toDateStr == null || widget.toDateStr!.trim().isEmpty)) {
      return true;
    }
    DateTime? entryDate = _parseDate(dateStr);
    if (entryDate == null) return true;
    DateTime? fDate = _parseDate(widget.fromDateStr ?? '');
    DateTime? tDate = _parseDate(widget.toDateStr ?? '');
    if (fDate != null) {
      DateTime start = DateTime(fDate.year, fDate.month, fDate.day);
      if (entryDate.isBefore(start)) return false;
    }
    if (tDate != null) {
      DateTime end = DateTime(tDate.year, tDate.month, tDate.day, 23, 59, 59);
      if (entryDate.isAfter(end)) return false;
    }
    return true;
  }

  void _showAddPersonDialog(StateSetter dialogSetState, Function(String) onPersonAdded) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Income Person'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Person Name', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              String name = controller.text.trim();
              if (name.isNotEmpty) {
                globalPersons.add(PersonData(id: DateTime.now().toString(), name: name, bankAccounts: [], entries: []));
                await _saveData();
                dialogSetState(() {
                  onPersonAdded(name);
                });
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  void _showAddBankDialog(PersonData targetPerson, StateSetter dialogSetState, Function(String) onBankAdded) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Bank Account for ${targetPerson.name}'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              String bankName = controller.text.trim();
              if (bankName.isNotEmpty) {
                targetPerson.bankAccounts.add(bankName);
                await _saveData();
                dialogSetState(() {
                  onBankAdded(bankName);
                });
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _openEntryDialog({FinanceItem? existingItem}) {
    String selectedPerson = existingItem?.person ?? (globalPersons.isNotEmpty ? globalPersons.first.name : '');
    String selectedAccount = existingItem?.depositAccount ?? 'Cash';
    String selectedCategory = existingItem?.category ?? widget.categoryName;
    
    DateTime now = DateTime.now();
    String defaultDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    
    final dateController = TextEditingController(text: existingItem?.date ?? defaultDate);
    final descController = TextEditingController(text: existingItem?.description ?? '');
    final amountController = TextEditingController(text: existingItem != null ? existingItem.amount.abs().toString() : '');
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            PersonData currentP = globalPersons.firstWhere(
              (p) => p.name == selectedPerson,
              orElse: () => globalPersons.isNotEmpty ? globalPersons.first : PersonData(id: '0', name: 'Default', bankAccounts: [], entries: []),
            );
            List<String> accounts = ['Cash', ...currentP.bankAccounts];
            if (!accounts.contains(selectedAccount)) {
              selectedAccount = 'Cash';
            }
            if (!globalIncomeCategories.contains(selectedCategory) && globalIncomeCategories.isNotEmpty) {
              selectedCategory = globalIncomeCategories.first;
            }
            return AlertDialog(
              title: Text(existingItem == null ? 'New Income Entry' : 'Edit Income Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: globalPersons.any((p) => p.name == selectedPerson) ? selectedPerson : (globalPersons.isNotEmpty ? globalPersons.first.name : null),
                            decoration: const InputDecoration(labelText: 'Income Person', border: OutlineInputBorder()),
                            items: globalPersons.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                if (val != null) {
                                  selectedPerson = val;
                                  selectedAccount = 'Cash';
                                }
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () => _showAddPersonDialog(setDialogState, (newName) {
                            selectedPerson = newName;
                            selectedAccount = 'Cash';
                          }),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedAccount,
                            decoration: const InputDecoration(labelText: 'Deposit Account / Cash', border: OutlineInputBorder()),
                            items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                            onChanged: (val) => setDialogState(() => selectedAccount = val!),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () {
                            if (globalPersons.any((p) => p.name == selectedPerson)) {
                              _showAddBankDialog(currentP, setDialogState, (newBank) {
                                selectedAccount = newBank;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (dd-mm-yyyy)', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (amountController.text.trim().isNotEmpty && selectedPerson.isNotEmpty) {
                      double amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                      PersonData target = globalPersons.firstWhere((p) => p.name == selectedPerson);
                      if (existingItem == null) {
                        target.entries.add(
                          FinanceItem(
                            id: DateTime.now().toString(),
                            title: widget.categoryName,
                            amount: amt.abs(),
                            person: selectedPerson,
                            category: widget.categoryName,
                            depositAccount: selectedAccount,
                            date: dateController.text.trim(),
                            description: descController.text.trim(),
                          ),
                        );
                      } else {
                        for (var p in globalPersons) {
                          p.entries.removeWhere((e) => e.id == existingItem.id);
                        }
                        target.entries.add(
                          FinanceItem(
                            id: existingItem.id,
                            title: widget.categoryName,
                            amount: amt.abs(),
                            person: selectedPerson,
                            category: widget.categoryName,
                            depositAccount: selectedAccount,
                            date: dateController.text.trim(),
                            description: descController.text.trim(),
                          ),
                        );
                      }
                      await _saveData();
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Save'),
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
    List<FinanceItem> categoryEntries = [];
    for (var p in globalPersons) {
      for (var e in p.entries) {
        if (e.category.startsWith(widget.categoryName) && _isDateInRange(e.date) && e.amount > 0) {
          categoryEntries.add(e);
        }
      }
    }
    double categoryTotal = categoryEntries.fold(0.0, (sum, item) => sum + item.amount);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} Statement', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total ${widget.categoryName} Income:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    Text('₹${categoryTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openEntryDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Income'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: categoryEntries.isEmpty
                  ? const Center(child: Text('No entries found for this category.'))
                  : ListView.builder(
                      itemCount: categoryEntries.length,
                      itemBuilder: (context, index) {
                        final entry = categoryEntries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            leading: const CircleAvatar(backgroundColor: Colors.green, radius: 18, child: Icon(Icons.attach_money, color: Colors.white, size: 18)),
                            title: Text('${entry.person} - ₹${entry.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Acc: ${entry.depositAccount} | Date: ${entry.date}${entry.description.isNotEmpty ? '\nNote: ${entry.description}' : ''}', style: const TextStyle(fontSize: 12)),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(onTap: () => _openEntryDialog(existingItem: entry), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: Colors.blue))),
                                InkWell(
                                  onTap: () async {
                                    for (var p in globalPersons) {
                                      p.entries.removeWhere((e) => e.id == entry.id);
                                    }
                                    await _saveData();
                                  },
                                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete, size: 18, color: Colors.red)),
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
      ),
    );
  }
}

// Person Detail Screen
class IncomePersonDetailScreen extends StatefulWidget {
  final PersonData person;
  final String? fromDateStr;
  final String? toDateStr;
  const IncomePersonDetailScreen({super.key, required this.person, this.fromDateStr, this.toDateStr});
  @override
  State<IncomePersonDetailScreen> createState() => _IncomePersonDetailScreenState();
}

class _IncomePersonDetailScreenState extends State<IncomePersonDetailScreen> {
  Future<void> _saveData() async {
    await saveFinanceDataToPrefs();
    if (mounted) {
      setState(() {});
    }
  }

  DateTime? _parseDate(String text) {
    try {
      List<String> parts = text.trim().split('-');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  bool _isDateInRange(String dateStr) {
    if ((widget.fromDateStr == null || widget.fromDateStr!.trim().isEmpty) && (widget.toDateStr == null || widget.toDateStr!.trim().isEmpty)) {
      return true;
    }
    DateTime? entryDate = _parseDate(dateStr);
    if (entryDate == null) return true;
    DateTime? fDate = _parseDate(widget.fromDateStr ?? '');
    DateTime? tDate = _parseDate(widget.toDateStr ?? '');
    if (fDate != null) {
      DateTime start = DateTime(fDate.year, fDate.month, fDate.day);
      if (entryDate.isBefore(start)) return false;
    }
    if (tDate != null) {
      DateTime end = DateTime(tDate.year, tDate.month, tDate.day, 23, 59, 59);
      if (entryDate.isAfter(end)) return false;
    }
    return true;
  }

  bool _isTransferEntry(FinanceItem entry) {
    return entry.category.toLowerCase().contains('transfer') || entry.category.toLowerCase().contains('journal');
  }

  void _showAddBankDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Bank Account for ${widget.person.name}'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              String bankName = controller.text.trim();
              if (bankName.isNotEmpty) {
                widget.person.bankAccounts.add(bankName);
                await _saveData();
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayEntries = widget.person.entries.where((e) => _isDateInRange(e.date)).toList();
    double personIncome = displayEntries.where((e) => e.amount > 0 && !_isTransferEntry(e)).fold(0.0, (sum, item) => sum + item.amount);
    double personExpense = displayEntries.where((e) => e.amount < 0 && !_isTransferEntry(e)).fold(0.0, (sum, item) => sum + item.amount.abs());
    double personTransferNet = displayEntries.where((e) => _isTransferEntry(e)).fold(0.0, (sum, item) => sum + item.amount);
    double personNet = (personIncome - personExpense) + personTransferNet;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.person.name}\'s Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Income:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                        Text('₹${personIncome.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Expense:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                        Text('₹${personExpense.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                      ],
                    ),
                    if (personTransferNet != 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Adjustments Net:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                          Text('₹${personTransferNet.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: personTransferNet >= 0 ? Colors.blue.shade800 : Colors.orange.shade800)),
                        ],
                      ),
                    ],
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Net Balance:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                        Text('₹${personNet.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: personNet >= 0 ? Colors.blue.shade900 : Colors.red.shade900)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Bank Accounts: ${widget.person.bankAccounts.isEmpty ? "Cash Only" : widget.person.bankAccounts.join(", ")}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                ElevatedButton.icon(
                  onPressed: _showAddBankDialog,
                  icon: const Icon(Icons.account_balance, size: 14),
                  label: const Text('Add Bank', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('All Transactions History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: displayEntries.isEmpty
                  ? const Center(child: Text('No entries found.'))
                  : ListView.builder(
                      itemCount: displayEntries.length,
                      itemBuilder: (context, index) {
                        final entry = displayEntries[index];
                        bool isTransfer = _isTransferEntry(entry);
                        bool isInc = entry.amount > 0;
                        
                        String typeLabel = "Income";
                        if (isTransfer) {
                          typeLabel = entry.amount < 0 ? "Adjustment Out (Dr)" : "Adjustment In (Cr)";
                        } else if (!isInc) {
                          typeLabel = "Expense";
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            leading: CircleAvatar(
                              backgroundColor: isTransfer ? Colors.blue : (isInc ? Colors.green : Colors.red),
                              radius: 18,
                              child: Icon(
                                isTransfer ? Icons.compare_arrows : (isInc ? Icons.arrow_downward : Icons.arrow_upward),
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            title: Text('${entry.category} - ₹${entry.amount.abs().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Type: $typeLabel | Acc: ${entry.depositAccount} | Date: ${entry.date}${entry.description.isNotEmpty ? '\nNote: ${entry.description}' : ''}', style: const TextStyle(fontSize: 12)),
                            isThreeLine: true,
                            trailing: InkWell(
                              onTap: () async {
                                widget.person.entries.removeWhere((e) => e.id == entry.id);
                                await _saveData();
                              },
                              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete, color: Colors.red, size: 20)),
                            ),
                          ),
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