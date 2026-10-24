import 'package:flutter/material.dart';
import 'models/finance_model.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

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

  bool _isIncomeEntry(FinanceItem entry) {
    return entry.amount > 0;
  }

  bool _isExpenseEntry(FinanceItem entry) {
    return entry.amount < 0;
  }

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
            onPressed: () {
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
                Navigator.pop(context);
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
            onPressed: () {
              String name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  if (oldCategory == null) {
                    if (!globalIncomeCategories.contains(name)) {
                      globalIncomeCategories.add(name);
                    }
                  } else if (index != null) {
                    globalIncomeCategories[index] = name;
                  }
                });
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Income & Balance', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Income Persons'),
              Tab(icon: Icon(Icons.category), text: 'Income Categories'),
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
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Income', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('₹${totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      color: netBalance >= 0 ? Colors.blue.shade700 : Colors.red.shade700,
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
                  if (fromDateController.text.isNotEmpty || toDateController.text.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.green, size: 20),
                      onPressed: () {
                        setState(() {
                          fromDateController.clear();
                          toDateController.clear();
                        });
                      },
                    )
                  ]
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
                                    double personIncome = person.entries.where((e) => _isIncomeEntry(e) && _isDateInRange(e.date)).fold(0.0, (sum, e) => sum + e.amount);

                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        leading: const CircleAvatar(backgroundColor: Colors.green, radius: 18, child: Icon(Icons.person, color: Colors.white, size: 20)),
                                        title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        subtitle: Text('Total Inc: ₹${personIncome.toStringAsFixed(2)}\nAccounts: ${person.bankAccounts.isEmpty ? "Cash" : person.bankAccounts.join(", ")}', style: const TextStyle(fontSize: 12)),
                                        isThreeLine: true,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(onTap: () => _showIncomePersonDialog(person: person), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: Colors.blue))),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  globalPersons.removeAt(index);
                                                });
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
                                          ).then((_) => setState(() {}));
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
                                              onTap: () {
                                                setState(() {
                                                  globalIncomeCategories.removeAt(index);
                                                });
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
                                          ).then((_) => setState(() {}));
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
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

class IncomeCategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final String? fromDateStr;
  final String? toDateStr;

  const IncomeCategoryDetailScreen({super.key, required this.categoryName, this.fromDateStr, this.toDateStr});

  @override
  State<IncomeCategoryDetailScreen> createState() => _IncomeCategoryDetailScreenState();
}

class _IncomeCategoryDetailScreenState extends State<IncomeCategoryDetailScreen> {
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
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                String name = controller.text.trim();
                setState(() {
                  globalPersons.add(PersonData(id: DateTime.now().toString(), name: name, bankAccounts: [], entries: []));
                });
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                String bankName = controller.text.trim();
                setState(() {
                  targetPerson.bankAccounts.add(bankName);
                });
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
    String selectedPerson = existingItem?.person ?? (globalPersons.isNotEmpty ? globalPersons.first.name : '');
    String selectedAccount = existingItem?.depositAccount ?? 'Cash';
    String selectedCategory = existingItem?.category ?? widget.categoryName;

    final dateController = TextEditingController(
      text: existingItem?.date ?? "${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}",
    );
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
                    // Income Person Row
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
                    
                    // Deposit Account Row
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

                    // Income Category Row (పక్కనే + బటన్‌తో)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: globalIncomeCategories.contains(selectedCategory) ? selectedCategory : (globalIncomeCategories.isNotEmpty ? globalIncomeCategories.first : null),
                            decoration: const InputDecoration(labelText: 'Income Category', border: OutlineInputBorder()),
                            items: globalIncomeCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => setDialogState(() => selectedCategory = val!),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () {
                            final catController = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: const Text('Add Income Category'),
                                  content: TextField(
                                    controller: catController,
                                    decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                                      onPressed: () {
                                        String newCat = catController.text.trim();
                                        if (newCat.isNotEmpty) {
                                          setState(() {
                                            if (!globalIncomeCategories.contains(newCat)) {
                                              globalIncomeCategories.add(newCat);
                                            }
                                          });
                                          setDialogState(() {
                                            selectedCategory = newCat;
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

                    TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (dd-mm-yyyy)', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder())),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  onPressed: () {
                    if (amountController.text.trim().isNotEmpty && selectedPerson.isNotEmpty && selectedCategory.isNotEmpty) {
                      double amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                      setState(() {
                        PersonData target = globalPersons.firstWhere((p) => p.name == selectedPerson);
                        if (existingItem == null) {
                          target.entries.add(
                            FinanceItem(
                              id: DateTime.now().toString(),
                              title: selectedCategory,
                              amount: amt.abs(),
                              person: selectedPerson,
                              category: selectedCategory,
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
                              title: selectedCategory,
                              amount: amt.abs(),
                              person: selectedPerson,
                              category: selectedCategory,
                              depositAccount: selectedAccount,
                              date: dateController.text.trim(),
                              description: descController.text.trim(),
                            ),
                          );
                        }
                      });
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
                                  onTap: () {
                                    setState(() {
                                      for (var p in globalPersons) {
                                        p.entries.removeWhere((e) => e.id == entry.id);
                                      }
                                    });
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

class IncomePersonDetailScreen extends StatefulWidget {
  final PersonData person;
  final String? fromDateStr;
  final String? toDateStr;

  const IncomePersonDetailScreen({super.key, required this.person, this.fromDateStr, this.toDateStr});

  @override
  State<IncomePersonDetailScreen> createState() => _IncomePersonDetailScreenState();
}

class _IncomePersonDetailScreenState extends State<IncomePersonDetailScreen> {
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
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  widget.person.bankAccounts.add(controller.text.trim());
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

  @override
  Widget build(BuildContext context) {
    final displayIncomeEntries = widget.person.entries.where((e) => e.amount > 0 && _isDateInRange(e.date)).toList();
    double personTotalIncome = displayIncomeEntries.fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.person.name}\'s Income', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Income (${widget.person.name}):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    Text('₹${personTotalIncome.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
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
            const Text('All Income Entries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: displayIncomeEntries.isEmpty
                  ? const Center(child: Text('No income entries found.'))
                  : ListView.builder(
                      itemCount: displayIncomeEntries.length,
                      itemBuilder: (context, index) {
                        final entry = displayIncomeEntries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            leading: const CircleAvatar(backgroundColor: Colors.green, radius: 18, child: Icon(Icons.attach_money, color: Colors.white, size: 18)),
                            title: Text('${entry.category} - ₹${entry.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Account: ${entry.depositAccount} | Date: ${entry.date}${entry.description.isNotEmpty ? '\nNote: ${entry.description}' : ''}', style: const TextStyle(fontSize: 12)),
                            trailing: InkWell(
                              onTap: () {
                                setState(() {
                                  widget.person.entries.removeWhere((e) => e.id == entry.id);
                                });
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