import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance_model.dart';

class ExpenceScreen extends StatefulWidget {
  const ExpenceScreen({super.key});
  @override
  State<ExpenceScreen> createState() => _ExpenceScreenState();
}

class _ExpenceScreenState extends State<ExpenceScreen> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  String? selectedFilterPerson;
  String? selectedFilterCategory;

  String? selectedFilterPaidBy;
  String? selectedFilterPaidByCategory;

  @override
  void initState() {
    super.initState();
    _setDefaultMonthDates();
    _loadDataAndRefresh();
  }

  void _setDefaultMonthDates() {
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    fromDateController.text = "${firstDayOfMonth.day.toString().padLeft(2, '0')}-${firstDayOfMonth.month.toString().padLeft(2, '0')}-${firstDayOfMonth.year}";
    toDateController.text = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  Future<void> _loadDataAndRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    String? personsStr = prefs.getString('saved_global_persons');
    if (personsStr != null) {
      List decodedPersons = jsonDecode(personsStr);
      globalPersons = decodedPersons.map((pMap) {
        var entriesList = (pMap['entries'] as List? ?? []).map((eMap) => FinanceItem(
          id: eMap['id'],
          title: eMap['title'],
          amount: (eMap['amount'] as num).toDouble(),
          person: eMap['person'],
          category: eMap['category'],
          depositAccount: eMap['depositAccount'],
          date: eMap['date'],
          description: eMap['description'] ?? '',
        )).toList();
        var banksList = List<String>.from(pMap['bankAccounts'] ?? []);
        return PersonData(
          id: pMap['id'],
          name: pMap['name'],
          bankAccounts: banksList,
          entries: entriesList,
        );
      }).toList();
    }
    String? categoriesStr = prefs.getString('saved_expense_categories');
    if (categoriesStr != null) {
      List decodedCats = jsonDecode(categoriesStr);
      globalExpenseCategories = decodedCats.map((cMap) {
        return ExpenseCategoryData(
          name: cMap['name'],
          subCategories: List<String>.from(cMap['subCategories'] ?? []),
        );
      }).toList();
    }
    setState(() {});
  }

  Future<void> _saveDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    var personsData = globalPersons.map((p) => {
      'id': p.id,
      'name': p.name,
      'bankAccounts': p.bankAccounts,
      'entries': p.entries.map((e) => {
        'id': e.id,
        'title': e.title,
        'amount': e.amount,
        'person': e.person,
        'category': e.category,
        'depositAccount': e.depositAccount,
        'date': e.date,
        'description': e.description,
      }).toList(),
    }).toList();
    
    var categoriesData = globalExpenseCategories.map((c) => {
      'name': c.name,
      'subCategories': c.subCategories,
    }).toList();

    await prefs.setString('saved_global_persons', jsonEncode(personsData));
    await prefs.setString('saved_expense_categories', jsonEncode(categoriesData));
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

  bool _isExpenseEntry(FinanceItem entry) {
    bool isJournalOrTransfer = entry.category.toLowerCase().contains('journal') || entry.category.toLowerCase().contains('transfer');
    return (entry.amount < 0 || entry.amount == 0.0) && !isJournalOrTransfer;
  }

  bool _isIncomeEntry(FinanceItem entry) {
    bool isJournalOrTransfer = entry.category.toLowerCase().contains('journal') || entry.category.toLowerCase().contains('transfer');
    return entry.amount > 0 && !isJournalOrTransfer;
  }

  void _showExpensePersonDialog({PersonData? person}) {
    final controller = TextEditingController(text: person?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(person == null ? 'Add Expense Person' : 'Edit Person'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Person Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  if (person == null) {
                    globalPersons.add(PersonData(
                      id: DateTime.now().toString(),
                      name: controller.text.trim(),
                      bankAccounts: [],
                      entries: [],
                    ));
                  } else {
                    person.name = controller.text.trim();
                  }
                });
                await _saveDataToPrefs();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExpenseCategoryDialog({ExpenseCategoryData? oldCategory, int? index}) {
    final controller = TextEditingController(text: oldCategory?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(oldCategory == null ? 'Add Expense Category' : 'Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              String name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  if (oldCategory == null) {
                    if (!globalExpenseCategories.any((cat) => cat.name == name)) {
                      globalExpenseCategories.add(ExpenseCategoryData(name: name, subCategories: []));
                    }
                  } else if (index != null) {
                    globalExpenseCategories[index].name = name;
                  }
                });
                await _saveDataToPrefs();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalExpenses = 0;
    double totalIncome = 0;
    
    List allStatementEntries = [];
    List allPaidByEntries = [];

    for (var person in globalPersons) {
      for (var entry in person.entries) {
        if (_isDateInRange(entry.date)) {
          if (_isExpenseEntry(entry)) {
            totalExpenses += entry.amount.abs();
            
            String paidBy = person.name;
            String narration = entry.description;
            if (entry.description.contains("Paid by ")) {
              try {
                var parts = entry.description.split(" | ");
                paidBy = parts[0].replaceAll("Paid by ", "").trim();
                narration = parts.length > 1 ? parts.sublist(1).join(" | ") : "";
              } catch (_) {}
            }

            allStatementEntries.add({
              'entry': entry,
              'date': entry.date,
              'expensePerson': entry.person,
              'category': entry.category,
              'paidBy': paidBy,
              'narration': narration,
              'amount': entry.amount.abs(),
            });

            allPaidByEntries.add({
              'entry': entry,
              'date': entry.date,
              'expensePerson': entry.person,
              'category': entry.category,
              'paidBy': paidBy,
              'account': entry.depositAccount,
              'narration': narration,
              'amount': entry.amount.abs(),
            });

          } else if (_isIncomeEntry(entry)) {
            totalIncome += entry.amount;
          }
        }
      }
    }

    double netBalance = totalIncome - totalExpenses;

    List filteredStatement = allStatementEntries.where((item) {
      FinanceItem e = item['entry'];
      bool matchesPerson = selectedFilterPerson == null || selectedFilterPerson == 'All' || e.person == selectedFilterPerson;
      bool matchesCategory = selectedFilterCategory == null || selectedFilterCategory == 'All' || e.category.startsWith(selectedFilterCategory!);
      return matchesPerson && matchesCategory;
    }).toList();

    double statementTotalAmount = filteredStatement.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    List filteredPaidByStatement = allPaidByEntries.where((item) {
      FinanceItem e = item['entry'];
      String paidByPerson = item['paidBy'].toString();
      bool matchesPaidBy = selectedFilterPaidBy == null || selectedFilterPaidBy == 'All' || paidByPerson == selectedFilterPaidBy;
      bool matchesCategory = selectedFilterPaidByCategory == null || selectedFilterPaidByCategory == 'All' || e.category.startsWith(selectedFilterPaidByCategory!);
      return matchesPaidBy && matchesCategory;
    }).toList();

    double totalPaidAmount = filteredPaidByStatement.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expense Management & Statements', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Persons'),
              Tab(icon: Icon(Icons.category), text: 'Categories'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Expense Statement'),
              Tab(icon: Icon(Icons.payment), text: 'Paid By Statement'),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.red.shade700,
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Expenses', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('₹${totalExpenses.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Net Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('₹${netBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    icon: const Icon(Icons.refresh, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        _setDefaultMonthDates();
                      });
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Persons
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Expense Persons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              onPressed: () => _showExpensePersonDialog(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Person'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: globalPersons.isEmpty
                              ? const Center(child: Text('No persons added yet.'))
                              : ListView.builder(
                                  itemCount: globalPersons.length,
                                  itemBuilder: (context, index) {
                                    final person = globalPersons[index];
                                    double personExpense = person.entries.where((e) => _isExpenseEntry(e) && _isDateInRange(e.date) && e.person == person.name).fold(0.0, (sum, e) => sum + e.amount.abs());
                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        leading: const CircleAvatar(backgroundColor: Colors.red, radius: 18, child: Icon(Icons.person, color: Colors.white, size: 20)),
                                        title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        subtitle: Text('Total Exp: ₹${personExpense.toStringAsFixed(2)}\nAccounts: ${person.bankAccounts.isEmpty ? "Cash" : person.bankAccounts.join(", ")}', style: const TextStyle(fontSize: 12)),
                                        isThreeLine: true,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(onTap: () => _showExpensePersonDialog(person: person), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: Colors.blue))),
                                            InkWell(
                                              onTap: () async {
                                                setState(() {
                                                  globalPersons.removeAt(index);
                                                });
                                                await _saveDataToPrefs();
                                              },
                                              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete, size: 18, color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ExpensePersonDetailScreen(
                                                person: person,
                                                fromDateStr: fromDateController.text,
                                                toDateStr: toDateController.text,
                                              ),
                                            ),
                                          ).then((_) async {
                                            await _saveDataToPrefs();
                                            setState(() {});
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

                  // Tab 2: Categories
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Expense Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              onPressed: () => _showExpenseCategoryDialog(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Category'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: globalExpenseCategories.isEmpty
                              ? const Center(child: Text('No expense categories added yet.'))
                              : ListView.builder(
                                  itemCount: globalExpenseCategories.length,
                                  itemBuilder: (context, index) {
                                    final cat = globalExpenseCategories[index];
                                    double categoryTotal = 0;
                                    for (var p in globalPersons) {
                                      for (var e in p.entries) {
                                        if (e.category.startsWith(cat.name) && _isDateInRange(e.date) && _isExpenseEntry(e)) {
                                          categoryTotal += e.amount.abs();
                                        }
                                      }
                                    }
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                        leading: const CircleAvatar(backgroundColor: Colors.red, radius: 18, child: Icon(Icons.shopping_cart, color: Colors.white, size: 18)),
                                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        subtitle: Text('Total Expenses: ₹${categoryTotal.toStringAsFixed(2)}', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(onTap: () => _showExpenseCategoryDialog(oldCategory: cat, index: index), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: Colors.blue))),
                                            InkWell(
                                              onTap: () async {
                                                setState(() {
                                                  globalExpenseCategories.removeAt(index);
                                                });
                                                await _saveDataToPrefs();
                                              },
                                              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete, size: 18, color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ExpenseCategoryDetailScreen(
                                                categoryData: cat,
                                                fromDateStr: fromDateController.text,
                                                toDateStr: toDateController.text,
                                              ),
                                            ),
                                          ).then((_) async {
                                            await _saveDataToPrefs();
                                            setState(() {});
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

                  // Tab 3: Expense Statement
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedFilterPerson ?? 'All',
                                decoration: const InputDecoration(labelText: 'Filter Person', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
                                items: ['All', ...globalPersons.map((p) => p.name)].map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedFilterPerson = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedFilterCategory ?? 'All',
                                decoration: const InputDecoration(labelText: 'Filter Category', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
                                items: ['All', ...globalExpenseCategories.map((c) => c.name)].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedFilterCategory = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: filteredStatement.isEmpty
                              ? const Center(child: Text('No statement records found.'))
                              : SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Table(
                                      border: TableBorder.all(color: Colors.grey.shade300),
                                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                      columnWidths: const {
                                        0: IntrinsicColumnWidth(),
                                        1: IntrinsicColumnWidth(),
                                        2: IntrinsicColumnWidth(),
                                        3: IntrinsicColumnWidth(),
                                        4: IntrinsicColumnWidth(),
                                        5: IntrinsicColumnWidth(),
                                      },
                                      children: [
                                        TableRow(
                                          decoration: BoxDecoration(color: Colors.red.shade700),
                                          children: const [
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Expense Person', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Paid By', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Narration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Amount (₹)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                          ],
                                        ),
                                        ...filteredStatement.map((row) {
                                          return TableRow(
                                            children: [
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row['date'].toString())),
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row['expensePerson'].toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row['category'].toString())),
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row['paidBy'].toString())),
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row['narration'].toString().isEmpty ? '-' : row['narration'].toString())),
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text('₹${(row['amount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Statement Total Expense:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text('₹${statementTotalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  // Tab 4: Paid By Statement
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedFilterPaidBy ?? 'All',
                                decoration: const InputDecoration(labelText: 'Filter Payer', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
                                items: ['All', ...globalPersons.map((p) => p.name)].map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedFilterPaidBy = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedFilterPaidByCategory ?? 'All',
                                decoration: const InputDecoration(labelText: 'Filter Category', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
                                items: ['All', ...globalExpenseCategories.map((c) => c.name)].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedFilterPaidByCategory = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: filteredPaidByStatement.isEmpty
                              ? const Center(child: Text('No paid-by records found.'))
                              : SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Table(
                                      border: TableBorder.all(color: Colors.grey.shade300),
                                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                      columnWidths: const {
                                        0: IntrinsicColumnWidth(),
                                        1: IntrinsicColumnWidth(),
                                        2: IntrinsicColumnWidth(),
                                        3: IntrinsicColumnWidth(),
                                        4: IntrinsicColumnWidth(),
                                        5: IntrinsicColumnWidth(),
                                        6: IntrinsicColumnWidth(),
                                      },
                                      children: [
                                        TableRow(
                                          decoration: BoxDecoration(color: Colors.red.shade700),
                                          children: const [
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Paid By Payer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('For Person', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Narration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8.0), child: Text('Amount Paid (₹)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                          ],
                                        ),
                                        ...filteredPaidByStatement.map((row) {
                                          return TableRow(
                                            children: [
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row['date'].toString())),
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row['paidBy'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row['expensePerson'].toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row['category'].toString())),
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row['account'].toString())),
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row['narration'].toString().isEmpty ? '-' : row['narration'].toString())),
                                              Padding(padding: const EdgeInsets.all(8.0), child: Text('₹${(row['amount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount Paid by Payer:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text('₹${totalPaidAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseCategoryDetailScreen extends StatefulWidget {
  final ExpenseCategoryData categoryData;
  final String? fromDateStr;
  final String? toDateStr;
  const ExpenseCategoryDetailScreen({super.key, required this.categoryData, this.fromDateStr, this.toDateStr});
  @override
  State<ExpenseCategoryDetailScreen> createState() => _ExpenseCategoryDetailScreenState();
}

class _ExpenseCategoryDetailScreenState extends State<ExpenseCategoryDetailScreen> {
  Future<void> _saveDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    var personsData = globalPersons.map((p) => {
      'id': p.id,
      'name': p.name,
      'bankAccounts': p.bankAccounts,
      'entries': p.entries.map((e) => {
        'id': e.id,
        'title': e.title,
        'amount': e.amount,
        'person': e.person,
        'category': e.category,
        'depositAccount': e.depositAccount,
        'date': e.date,
        'description': e.description,
      }).toList(),
    }).toList();
    
    var categoriesData = globalExpenseCategories.map((c) => {
      'name': c.name,
      'subCategories': c.subCategories,
    }).toList();

    await prefs.setString('saved_global_persons', jsonEncode(personsData));
    await prefs.setString('saved_expense_categories', jsonEncode(categoriesData));
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

  bool _isExpenseEntry(FinanceItem entry) {
    bool isJournalOrTransfer = entry.category.toLowerCase().contains('journal') || entry.category.toLowerCase().contains('transfer');
    return (entry.amount < 0 || entry.amount == 0.0) && !isJournalOrTransfer;
  }

  double _getAccountBalance(PersonData person, String accountName) {
    if (accountName == 'Cash') return double.infinity; // Cash has no balance limit check
    double balance = 0;
    for (var p in globalPersons) {
      for (var e in p.entries) {
        if (e.depositAccount == accountName) {
          balance += e.amount;
        }
      }
    }
    return balance;
  }

  void _showAddPersonDialog(StateSetter dialogSetState, Function(String) onPersonAdded) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense Person'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Person Name', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                String name = controller.text.trim();
                setState(() {
                  globalPersons.add(PersonData(id: DateTime.now().toString(), name: name, bankAccounts: [], entries: []));
                });
                await _saveDataToPrefs();
                dialogSetState(() {
                  onPersonAdded(name);
                });
                Navigator.pop(context);
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                String bankName = controller.text.trim();
                setState(() {
                  targetPerson.bankAccounts.add(bankName);
                });
                await _saveDataToPrefs();
                dialogSetState(() {
                  onBankAdded(bankName);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _openEntryDialog({FinanceItem? existingItem}) {
    String selectedExpensePerson = existingItem?.person ?? (globalPersons.isNotEmpty ? globalPersons.first.name : '');
    String selectedCategoryName = widget.categoryData.name;
    String selectedSubCategory = 'General';
    if (existingItem != null && existingItem.category.contains(' - ')) {
      selectedSubCategory = existingItem.category.split(' - ').last;
    } else if (widget.categoryData.subCategories.isNotEmpty) {
      selectedSubCategory = widget.categoryData.subCategories.first;
    }
    
    String selectedWhoPaid = globalPersons.isNotEmpty ? globalPersons.first.name : '';
    if (existingItem != null && existingItem.description.contains("Paid by ")) {
      try {
        String payerName = existingItem.description.split("Paid by ")[1].split(" | ")[0].trim();
        if (globalPersons.any((p) => p.name == payerName)) {
          selectedWhoPaid = payerName;
        }
      } catch (_) {}
    }

    String selectedAccount = existingItem?.depositAccount ?? 'Cash';
    final dateController = TextEditingController(
      text: existingItem?.date ?? "${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}",
    );
    final descController = TextEditingController(
      text: existingItem != null && existingItem.description.contains(" | ") 
          ? existingItem.description.split(" | ").last 
          : (existingItem?.description ?? '')
    );
    final amountController = TextEditingController(text: existingItem != null ? existingItem.amount.abs().toString() : '');
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            PersonData payerPerson = globalPersons.firstWhere(
              (p) => p.name == selectedWhoPaid,
              orElse: () => globalPersons.isNotEmpty ? globalPersons.first : PersonData(id: '0', name: 'Default', bankAccounts: [], entries: []),
            );
            List<String> accounts = ['Cash', ...payerPerson.bankAccounts];
            if (!accounts.contains(selectedAccount)) {
              selectedAccount = 'Cash';
            }
            List<String> subCats = widget.categoryData.subCategories.isEmpty ? ['General'] : widget.categoryData.subCategories;
            if (!subCats.contains(selectedSubCategory)) {
              selectedSubCategory = subCats.first;
            }
            return AlertDialog(
              title: Text(existingItem == null ? 'New Expense (${widget.categoryData.name})' : 'Edit Expense Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: globalPersons.any((p) => p.name == selectedExpensePerson) ? selectedExpensePerson : (globalPersons.isNotEmpty ? globalPersons.first.name : null),
                            decoration: const InputDecoration(labelText: 'Expense Person (Statement)', border: OutlineInputBorder()),
                            items: globalPersons.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                if (val != null) selectedExpensePerson = val;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.red),
                          onPressed: () => _showAddPersonDialog(setDialogState, (newName) {
                            selectedExpensePerson = newName;
                          }),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCategoryName,
                            decoration: const InputDecoration(labelText: 'Expense Category', border: OutlineInputBorder()),
                            items: globalExpenseCategories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedCategoryName = val;
                                  ExpenseCategoryData catObj = globalExpenseCategories.firstWhere((c) => c.name == val, orElse: () => widget.categoryData);
                                  subCats = catObj.subCategories.isEmpty ? ['General'] : catObj.subCategories;
                                  selectedSubCategory = subCats.first;
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.red),
                          onPressed: () {
                            final catController = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: const Text('Add Expense Category'),
                                  content: TextField(controller: catController, decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder())),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                                      onPressed: () async {
                                        String newCat = catController.text.trim();
                                        if (newCat.isNotEmpty) {
                                          setState(() {
                                            if (!globalExpenseCategories.any((c) => c.name == newCat)) {
                                              globalExpenseCategories.add(ExpenseCategoryData(name: newCat, subCategories: []));
                                            }
                                          });
                                          await _saveDataToPrefs();
                                          setDialogState(() {
                                            selectedCategoryName = newCat;
                                          });
                                          Navigator.pop(dialogContext);
                                        }
                                      },
                                      child: const Text('Add'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (subCats.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: subCats.contains(selectedSubCategory) ? selectedSubCategory : subCats.first,
                              decoration: const InputDecoration(labelText: 'Sub Category', border: OutlineInputBorder()),
                              items: subCats.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) => setDialogState(() => selectedSubCategory = val!),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.red),
                            onPressed: () {
                              final subController = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: Text('Add Sub-Category under $selectedCategoryName'),
                                    content: TextField(controller: subController, decoration: const InputDecoration(labelText: 'Sub-Category Name', border: OutlineInputBorder())),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                                        onPressed: () async {
                                          String newSub = subController.text.trim();
                                          if (newSub.isNotEmpty) {
                                            setState(() {
                                              ExpenseCategoryData catObj = globalExpenseCategories.firstWhere((c) => c.name == selectedCategoryName, orElse: () => widget.categoryData);
                                              if (!catObj.subCategories.contains(newSub)) {
                                                catObj.subCategories.add(newSub);
                                              }
                                            });
                                            await _saveDataToPrefs();
                                            setDialogState(() {
                                              selectedSubCategory = newSub;
                                            });
                                            Navigator.pop(dialogContext);
                                          }
                                        },
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: globalPersons.any((p) => p.name == selectedWhoPaid) ? selectedWhoPaid : (globalPersons.isNotEmpty ? globalPersons.first.name : null),
                            decoration: const InputDecoration(labelText: 'Who Paid (Deduction Target)', border: OutlineInputBorder()),
                            items: globalPersons.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                if (val != null) {
                                  selectedWhoPaid = val;
                                  selectedAccount = 'Cash';
                                }
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.red),
                          onPressed: () => _showAddPersonDialog(setDialogState, (newName) {
                            selectedWhoPaid = newName;
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
                            decoration: const InputDecoration(labelText: 'Paid From Account / Cash', border: OutlineInputBorder()),
                            items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                            onChanged: (val) => setDialogState(() => selectedAccount = val!),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.red),
                          onPressed: () {
                            if (globalPersons.any((p) => p.name == selectedWhoPaid)) {
                              _showAddBankDialog(payerPerson, setDialogState, (newBank) {
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
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description / Narration', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    dateController.text = "${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}";
                    descController.clear();
                    amountController.clear();
                  },
                  child: const Text('Reset', style: TextStyle(color: Colors.orange)),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (amountController.text.trim().isNotEmpty && selectedWhoPaid.isNotEmpty && selectedExpensePerson.isNotEmpty) {
                      double amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                      
                      // Check if it is a Loan, Credit Card or Borrowing category (Directly save without balance check)
                      bool isSpecialCategory = selectedCategoryName.toLowerCase().contains('loan') ||
                                              selectedCategoryName.toLowerCase().contains('credit') ||
                                              selectedCategoryName.toLowerCase().contains('appulu') ||
                                              selectedCategoryName.toLowerCase().contains('debt') ||
                                              selectedCategoryName.toLowerCase().contains('borrow');

                      // Check account balance if not Cash and not special category
                      if (!isSpecialCategory && selectedAccount != 'Cash') {
                        double currentAccBal = _getAccountBalance(payerPerson, selectedAccount);
                        if (currentAccBal < amt) {
                          // Show Warning Dialog with OK and Cancel
                          bool? confirmProceed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Warning: Low Balance'),
                              content: Text('Account "$selectedAccount" has insufficient balance (Available: ₹${currentAccBal.toStringAsFixed(2)}, Expense: ₹${amt.toStringAsFixed(2)}). Do you still want to proceed?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );

                          if (confirmProceed != true) {
                            return; // Cancel entry
                          }
                        }
                      }

                      String fullCategoryName = selectedSubCategory == 'General' ? selectedCategoryName : "$selectedCategoryName - $selectedSubCategory";
                      
                      setState(() {
                        if (existingItem != null) {
                          for (var p in globalPersons) {
                            p.entries.removeWhere((e) => e.id == existingItem.id);
                          }
                        }

                        String uniqueId = existingItem?.id ?? DateTime.now().toString();

                        PersonData payerTarget = globalPersons.firstWhere((p) => p.name == selectedWhoPaid);
                        payerTarget.entries.add(
                          FinanceItem(
                            id: uniqueId,
                            title: fullCategoryName,
                            amount: -amt.abs(),
                            person: selectedExpensePerson,
                            category: fullCategoryName,
                            depositAccount: selectedAccount,
                            date: dateController.text.trim(),
                            description: "Paid by $selectedWhoPaid | ${descController.text.trim()}",
                          ),
                        );
                      });
                      await _saveDataToPrefs();
                      Navigator.pop(context);
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
        if (e.category.startsWith(widget.categoryData.name) && _isDateInRange(e.date) && _isExpenseEntry(e)) {
          categoryEntries.add(e);
        }
      }
    }
    double categoryTotal = categoryEntries.fold(0.0, (sum, item) => sum + item.amount.abs());
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryData.name} Statement', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total ${widget.categoryData.name} Expense:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                    Text('₹${categoryTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final controller = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Add Sub-Category under ${widget.categoryData.name}'),
                        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Sub-Category Name', border: OutlineInputBorder())),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                            onPressed: () async {
                              if (controller.text.trim().isNotEmpty) {
                                setState(() {
                                  if (!widget.categoryData.subCategories.contains(controller.text.trim())) {
                                    widget.categoryData.subCategories.add(controller.text.trim());
                                  }
                                });
                                await _saveDataToPrefs();
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Add'),
                          )
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Sub-Category'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openEntryDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Expense'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
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
                            leading: const CircleAvatar(backgroundColor: Colors.red, radius: 18, child: Icon(Icons.shopping_cart, color: Colors.white, size: 18)),
                            title: Text('${entry.category} - ₹${entry.amount.abs().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Person: ${entry.person} | Acc: ${entry.depositAccount}\nDate: ${entry.date}${entry.description.isNotEmpty ? ' | Note: ${entry.description}' : ''}', style: const TextStyle(fontSize: 12)),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(onTap: () => _openEntryDialog(existingItem: entry), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: Colors.blue))),
                                InkWell(
                                  onTap: () async {
                                    setState(() {
                                      for (var p in globalPersons) {
                                        p.entries.removeWhere((e) => e.id == entry.id);
                                      }
                                    });
                                    await _saveDataToPrefs();
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

class ExpensePersonDetailScreen extends StatefulWidget {
  final PersonData person;
  final String? fromDateStr;
  final String? toDateStr;
  const ExpensePersonDetailScreen({super.key, required this.person, this.fromDateStr, this.toDateStr});
  @override
  State<ExpensePersonDetailScreen> createState() => _ExpensePersonDetailScreenState();
}

class _ExpensePersonDetailScreenState extends State<ExpensePersonDetailScreen> {
  Future<void> _saveDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    var personsData = globalPersons.map((p) => {
      'id': p.id,
      'name': p.name,
      'bankAccounts': p.bankAccounts,
      'entries': p.entries.map((e) => {
        'id': e.id,
        'title': e.title,
        'amount': e.amount,
        'person': e.person,
        'category': e.category,
        'depositAccount': e.depositAccount,
        'date': e.date,
        'description': e.description,
      }).toList(),
    }).toList();
    
    var categoriesData = globalExpenseCategories.map((c) => {
      'name': c.name,
      'subCategories': c.subCategories,
    }).toList();

    await prefs.setString('saved_global_persons', jsonEncode(personsData));
    await prefs.setString('saved_expense_categories', jsonEncode(categoriesData));
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

  bool _isExpenseEntry(FinanceItem entry) {
    bool isJournalOrTransfer = entry.category.toLowerCase().contains('journal') || entry.category.toLowerCase().contains('transfer');
    return entry.amount < 0 && !isJournalOrTransfer;
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  widget.person.bankAccounts.add(controller.text.trim());
                });
                await _saveDataToPrefs();
                Navigator.pop(context);
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
    List<FinanceItem> displayExpenseEntries = [];
    for (var p in globalPersons) {
      for (var e in p.entries) {
        if (_isExpenseEntry(e) && _isDateInRange(e.date) && e.person == widget.person.name) {
          displayExpenseEntries.add(e);
        }
      }
    }

    double personTotalExpense = displayExpenseEntries.fold(0.0, (sum, item) => sum + item.amount.abs());
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.person.name}\'s Expenses', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Expenses (${widget.person.name}):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                    Text('₹${personTotalExpense.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('All Expense Entries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: displayExpenseEntries.isEmpty
                  ? const Center(child: Text('No expense entries found.'))
                  : ListView.builder(
                      itemCount: displayExpenseEntries.length,
                      itemBuilder: (context, index) {
                        final entry = displayExpenseEntries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            leading: const CircleAvatar(backgroundColor: Colors.red, radius: 18, child: Icon(Icons.shopping_cart, color: Colors.white, size: 18)),
                            title: Text('${entry.category} - ₹${entry.amount.abs().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Account: ${entry.depositAccount} | Date: ${entry.date}${entry.description.isNotEmpty ? '\nNote: ${entry.description}' : ''}', style: const TextStyle(fontSize: 12)),
                            trailing: InkWell(
                              onTap: () async {
                                setState(() {
                                  for (var p in globalPersons) {
                                    p.entries.removeWhere((e) => e.id == entry.id);
                                  }
                                });
                                await _saveDataToPrefs();
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