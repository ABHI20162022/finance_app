import 'package:flutter/material.dart';
import 'models/finance_model.dart';

class ExpenceScreen extends StatefulWidget {
  const ExpenceScreen({super.key});

  @override
  State<ExpenceScreen> createState() => _ExpenceScreenState();
}

class _ExpenceScreenState extends State<ExpenceScreen> {
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

  bool _isExpenseEntry(FinanceItem entry) {
    return entry.amount < 0;
  }

  bool _isIncomeEntry(FinanceItem entry) {
    return entry.amount > 0;
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
            onPressed: () {
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

    for (var person in globalPersons) {
      for (var entry in person.entries) {
        if (_isDateInRange(entry.date)) {
          if (_isExpenseEntry(entry)) {
            totalExpenses += entry.amount.abs();
          } else if (_isIncomeEntry(entry)) {
            totalIncome += entry.amount;
          }
        }
      }
    }

    double netBalance = totalIncome - totalExpenses;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expense Management & Balance', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Expense Persons'),
              Tab(icon: Icon(Icons.category), text: 'Expense Categories'),
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
                      icon: const Icon(Icons.clear, color: Colors.red, size: 20),
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
                  // Tab 1: Expense Persons
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
                              ? const Center(child: Text('No persons added yet.\nClick "+ Add Person" to start.', textAlign: TextAlign.center))
                              : ListView.builder(
                                  itemCount: globalPersons.length,
                                  itemBuilder: (context, index) {
                                    final person = globalPersons[index];
                                    double personExpense = person.entries.where((e) => _isExpenseEntry(e) && _isDateInRange(e.date)).fold(0.0, (sum, e) => sum + e.amount.abs());

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
                                              builder: (context) => ExpensePersonDetailScreen(
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

                  // Tab 2: Expense Categories
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
                              ? const Center(child: Text('No expense categories added yet.\nClick "+ Add Category" to create one.', textAlign: TextAlign.center))
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
                                              onTap: () {
                                                setState(() {
                                                  globalExpenseCategories.removeAt(index);
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
                                              builder: (context) => ExpenseCategoryDetailScreen(
                                                categoryData: cat,
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

class ExpenseCategoryDetailScreen extends StatefulWidget {
  final ExpenseCategoryData categoryData;
  final String? fromDateStr;
  final String? toDateStr;

  const ExpenseCategoryDetailScreen({super.key, required this.categoryData, this.fromDateStr, this.toDateStr});

  @override
  State<ExpenseCategoryDetailScreen> createState() => _ExpenseCategoryDetailScreenState();
}

class _ExpenseCategoryDetailScreenState extends State<ExpenseCategoryDetailScreen> {
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
        title: const Text('Add Expense Person'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Person Name', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
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
    // 1. Expense Person (Who is this expense for)
    String selectedExpensePerson = existingItem?.person ?? (globalPersons.isNotEmpty ? globalPersons.first.name : '');
    
    // 2. Expense Category (Default to current category)
    String selectedCategoryName = widget.categoryData.name;
    
    // 3. Sub-Category
    String selectedSubCategory = 'General';
    if (existingItem != null && existingItem.category.contains(' - ')) {
      selectedSubCategory = existingItem.category.split(' - ').last;
    } else if (widget.categoryData.subCategories.isNotEmpty) {
      selectedSubCategory = widget.categoryData.subCategories.first;
    }

    // 4. Who Paid (Payer)
    String selectedWhoPaid = existingItem?.person ?? (globalPersons.isNotEmpty ? globalPersons.first.name : '');
    
    // 5. Account / Bank from Who Paid
    String selectedAccount = existingItem?.depositAccount ?? 'Cash';

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
            // Get Payer object for bank accounts
            PersonData payerPerson = globalPersons.firstWhere(
              (p) => p.name == selectedWhoPaid,
              orElse: () => globalPersons.isNotEmpty ? globalPersons.first : PersonData(id: '0', name: 'Default', bankAccounts: [], entries: []),
            );

            List<String> accounts = ['Cash', ...payerPerson.bankAccounts];
            if (!accounts.contains(selectedAccount)) {
              selectedAccount = 'Cash';
            }

            // Sub-categories list for current category
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
                    // 1. Expense Person Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: globalPersons.any((p) => p.name == selectedExpensePerson) ? selectedExpensePerson : (globalPersons.isNotEmpty ? globalPersons.first.name : null),
                            decoration: const InputDecoration(labelText: 'Expense Person', border: OutlineInputBorder()),
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

                    // 2. Expense Category Row (Default category, non-editable or dropdown)
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
                                  // Update subcategories based on selected category
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
                                  content: TextField(
                                    controller: catController,
                                    decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                                      onPressed: () {
                                        String newCat = catController.text.trim();
                                        if (newCat.isNotEmpty) {
                                          setState(() {
                                            if (!globalExpenseCategories.any((c) => c.name == newCat)) {
                                              globalExpenseCategories.add(ExpenseCategoryData(name: newCat, subCategories: []));
                                            }
                                          });
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

                    // 3. Sub-Category Row (if subcategories exist)
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
                                    content: TextField(
                                      controller: subController,
                                      decoration: const InputDecoration(labelText: 'Sub-Category Name', border: OutlineInputBorder()),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                                        onPressed: () {
                                          String newSub = subController.text.trim();
                                          if (newSub.isNotEmpty) {
                                            setState(() {
                                              ExpenseCategoryData catObj = globalExpenseCategories.firstWhere((c) => c.name == selectedCategoryName, orElse: () => widget.categoryData);
                                              if (!catObj.subCategories.contains(newSub)) {
                                                catObj.subCategories.add(newSub);
                                              }
                                            });
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

                    // 4. Who Paid Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: globalPersons.any((p) => p.name == selectedWhoPaid) ? selectedWhoPaid : (globalPersons.isNotEmpty ? globalPersons.first.name : null),
                            decoration: const InputDecoration(labelText: 'Who Paid', border: OutlineInputBorder()),
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

                    // 5. Paid From Account Row (Bank linked to Who Paid)
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

                    // 6. Date, Description, Amount
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                  onPressed: () {
                    if (amountController.text.trim().isNotEmpty && selectedExpensePerson.isNotEmpty) {
                      double amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                      String fullCategoryName = selectedSubCategory == 'General' ? selectedCategoryName : "$selectedCategoryName - $selectedSubCategory";
                      
                      setState(() {
                        // Expense is saved under the selected Expense Person, amount is negative (-amt.abs()) to deduct
                        PersonData target = globalPersons.firstWhere((p) => p.name == selectedExpensePerson);
                        if (existingItem == null) {
                          target.entries.add(
                            FinanceItem(
                              id: DateTime.now().toString(),
                              title: fullCategoryName,
                              amount: -amt.abs(), // Negative value to deduct from balance
                              person: selectedExpensePerson,
                              category: fullCategoryName,
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
                              title: fullCategoryName,
                              amount: -amt.abs(),
                              person: selectedExpensePerson,
                              category: fullCategoryName,
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
        if (e.category.startsWith(widget.categoryData.name) && _isDateInRange(e.date) && e.amount < 0) {
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
                    // Add Sub Category dialog
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
                            onPressed: () {
                              if (controller.text.trim().isNotEmpty) {
                                setState(() {
                                  if (!widget.categoryData.subCategories.contains(controller.text.trim())) {
                                    widget.categoryData.subCategories.add(controller.text.trim());
                                  }
                                });
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

class ExpensePersonDetailScreen extends StatefulWidget {
  final PersonData person;
  final String? fromDateStr;
  final String? toDateStr;

  const ExpensePersonDetailScreen({super.key, required this.person, this.fromDateStr, this.toDateStr});

  @override
  State<ExpensePersonDetailScreen> createState() => _ExpensePersonDetailScreenState();
}

class _ExpensePersonDetailScreenState extends State<ExpensePersonDetailScreen> {
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
    return entry.amount < 0;
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
    final displayExpenseEntries = widget.person.entries.where((e) => _isExpenseEntry(e) && _isDateInRange(e.date)).toList();

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