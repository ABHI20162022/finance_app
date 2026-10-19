import 'package:flutter/material.dart';
import 'models.dart';
import 'income_screen.dart';

List<String> globalExpenseCategories = [];
List<String> globalExpensePersons = [];
Map<String, List<String>> globalExpenseSubCategories = {};

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController _mainFromDateController = TextEditingController();
  final TextEditingController _mainToDateController = TextEditingController();

  void _showAddDialog(String title, List<String> targetList, Function(String) onAdded) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: 'Enter $title name'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              String name = controller.text.trim();
              if (name.isNotEmpty && !targetList.contains(name)) {
                setState(() {
                  targetList.add(name);
                  onAdded(name);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _refreshScreen() => setState(() {});

  DateTime? _parseCustomDate(String dateStr) {
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

  @override
  Widget build(BuildContext context) {
    List<FinanceEntry> allExpenseList = globalEntries.where((e) => e.type == 'EXPENSE').toList();

    String fromStr = _mainFromDateController.text.trim();
    String toStr = _mainToDateController.text.trim();

    List<FinanceEntry> filteredExpenseList = allExpenseList;
    if (fromStr.isNotEmpty && toStr.isNotEmpty) {
      DateTime? fromDate = _parseCustomDate(fromStr);
      DateTime? toDate = _parseCustomDate(toStr);

      if (fromDate != null && toDate != null) {
        filteredExpenseList = allExpenseList.where((e) {
          DateTime? entryDate = _parseCustomDate(e.date);
          if (entryDate == null) return false;
          return (entryDate.isAtSameMomentAs(fromDate) || entryDate.isAfter(fromDate)) &&
                 (entryDate.isAtSameMomentAs(toDate) || entryDate.isBefore(toDate));
        }).toList();
      }
    }

    double totalExpense = filteredExpenseList.fold(0, (sum, item) => sum + item.amount);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expense Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Text('₹$totalExpense', style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          backgroundColor: Colors.red[800],
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.category), text: "Expense Category"),
              Tab(icon: Icon(Icons.person), text: "Expense Person"),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.red[50],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mainFromDateController,
                      onChanged: (val) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'From Date (DD-MM-YYYY)',
                        hintText: '01-10-2026',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _mainToDateController,
                      onChanged: (val) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'To Date (DD-MM-YYYY)',
                        hintText: '31-10-2026',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _mainFromDateController.clear();
                        _mainToDateController.clear();
                      });
                    },
                    tooltip: 'Clear Filter',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // TAB 1: CATEGORY
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                            onPressed: () => _showAddDialog('Expense Category', globalExpenseCategories, (val) {
                              globalExpenseSubCategories[val] = [];
                            }),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Expense Category'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: globalExpenseCategories.isEmpty
                              ? const Center(child: Text('No categories added yet.'))
                              : ListView.builder(
                                  itemCount: globalExpenseCategories.length,
                                  itemBuilder: (context, index) {
                                    String category = globalExpenseCategories[index];
                                    double catTotal = filteredExpenseList.where((e) => e.heading1 == category).fold(0, (sum, item) => sum + item.amount);

                                    return Card(
                                      child: ListTile(
                                        leading: const Icon(Icons.folder_special, color: Colors.red),
                                        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('₹$catTotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                                            const SizedBox(width: 10),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.grey),
                                              onPressed: () => setState(() {
                                                globalExpenseCategories.removeAt(index);
                                                globalExpenseSubCategories.remove(category);
                                              }),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => ExpenseCategoryDetailScreen(categoryName: category)),
                                          ).then((_) => _refreshScreen());
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  // TAB 2: PERSON
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                            onPressed: () => _showAddDialog('Expense Person', globalExpensePersons, (val) {}),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Expense Person'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: globalExpensePersons.isEmpty
                              ? const Center(child: Text('No expense persons added yet.'))
                              : ListView.builder(
                                  itemCount: globalExpensePersons.length,
                                  itemBuilder: (context, index) {
                                    String person = globalExpensePersons[index];
                                    return Card(
                                      child: ListTile(
                                        leading: const Icon(Icons.person, color: Colors.red),
                                        title: Text(person, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.grey),
                                          onPressed: () => setState(() {
                                            globalExpensePersons.removeAt(index);
                                          }),
                                        ),
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
  final String categoryName;
  const ExpenseCategoryDetailScreen({super.key, required this.categoryName});

  @override
  State<ExpenseCategoryDetailScreen> createState() => _ExpenseCategoryDetailScreenState();
}

class _ExpenseCategoryDetailScreenState extends State<ExpenseCategoryDetailScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedExpensePerson;
  String? _selectedIncomePerson;
  String? _selectedAccount;
  String? _editingEntryId;

  @override
  void initState() {
    super.initState();
    _setDefaultDate();
  }

  void _setDefaultDate() {
    final now = DateTime.now();
    _dateController.text = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  void _showAddOptionDialog(String title, List<String> targetList, Function(String) onAdded) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: 'Enter $title name'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              String name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  if (!targetList.contains(name)) targetList.add(name);
                  onAdded(name);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedExpensePerson = null;
      _selectedIncomePerson = null;
      _selectedAccount = null;
      _amountController.clear();
      _descController.clear();
      _setDefaultDate();
      _editingEntryId = null;
    });
  }

  double _calculateCurrentAccountBalance(String? person, String? account) {
    if (person == null || account == null) return 0.0;

    double inc = globalEntries
        .where((e) => e.type == 'INCOME' && e.heading2 == person && e.heading3 == account)
        .fold(0.0, (sum, item) => sum + item.amount);

    double exp = globalEntries
        .where((e) => e.type == 'EXPENSE' && e.heading3 == account)
        .fold(0.0, (sum, item) => sum + item.amount);

    return inc - exp;
  }

  void _saveExpense(TabController tabController) {
    String rawAmount = _amountController.text.trim();
    double? amount = double.tryParse(rawAmount);

    if (rawAmount.isEmpty || amount == null || amount <= 0) {
      _showAlert('Invalid Amount', 'Please enter a valid amount.');
      return;
    }

    if (_selectedExpensePerson == null || _selectedIncomePerson == null || _selectedAccount == null) {
      _showAlert('Missing Fields', 'Please select Expense Person, Paid From, and Account.');
      return;
    }

    String fullPersonDetails = "$_selectedExpensePerson (Paid by: $_selectedIncomePerson)";

    bool isDuplicate = globalEntries.any((e) =>
        e.type == 'EXPENSE' &&
        (e.heading1 == widget.categoryName || e.heading2 == fullPersonDetails) &&
        e.id != _editingEntryId);

    if (isDuplicate) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplicate Entry Warning', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          content: const Text('ఈ కేటగిరీ లేదా పర్సన్ పేరుతో ఇప్పటికే ఒక ఎంట్రీ ఉంది! అయినా సరే సేవ్ చేయాలనుకుంటున్నారా?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _checkBalanceAndSave(amount, fullPersonDetails, tabController);
              },
              child: const Text('Yes, Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      _checkBalanceAndSave(amount, fullPersonDetails, tabController);
    }
  }

  void _checkBalanceAndSave(double amount, String fullPersonDetails, TabController tabController) {
    double currentBalance = _calculateCurrentAccountBalance(_selectedIncomePerson, _selectedAccount);

    if (currentBalance < amount) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Insufficient Balance', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          content: Text(
            'మొత్తం బ్యాలెన్స్ సరిపోదు!\nCurrent Balance: ₹$currentBalance\nExpense Amount: ₹$amount\n\nనెగటివ్ బ్యాలెన్స్‌తో ప్రొసీడ్ అవ్వాలా?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _performSave(amount, fullPersonDetails, tabController);
              },
              child: const Text('Proceed', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      _performSave(amount, fullPersonDetails, tabController);
    }
  }

  void _performSave(double amount, String fullPersonDetails, TabController tabController) {
    setState(() {
      if (_editingEntryId != null) {
        int index = globalEntries.indexWhere((e) => e.id == _editingEntryId);
        if (index != -1) {
          globalEntries[index] = FinanceEntry(
            id: _editingEntryId!,
            type: 'EXPENSE',
            heading1: widget.categoryName,
            heading2: fullPersonDetails,
            heading3: _selectedAccount ?? 'None',
            description: _descController.text.trim(),
            date: _dateController.text.trim(),
            amount: amount,
          );
        }
        _editingEntryId = null;
      } else {
        globalEntries.add(FinanceEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'EXPENSE',
          heading1: widget.categoryName,
          heading2: fullPersonDetails,
          heading3: _selectedAccount ?? 'None',
          description: _descController.text.trim(),
          date: _dateController.text.trim(),
          amount: amount,
        ));
      }
      _resetForm();
    });
    tabController.animateTo(2);
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final TabController tabController = DefaultTabController.of(context);
          List<FinanceEntry> categoryEntries = globalEntries.where((e) => e.type == 'EXPENSE' && e.heading1 == widget.categoryName).toList();
          double categoryTotal = categoryEntries.fold(0, (sum, item) => sum + item.amount);
          List<String> subCategories = globalExpenseSubCategories[widget.categoryName] ?? [];

          List<String> availableAccounts = _selectedIncomePerson != null && globalPersonAccounts.containsKey(_selectedIncomePerson)
              ? globalPersonAccounts[_selectedIncomePerson]!
              : [];

          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.categoryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Text('₹$categoryTotal', style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              backgroundColor: Colors.red[800],
              bottom: const TabBar(
                indicatorColor: Colors.amber,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(icon: Icon(Icons.category), text: "Sub Category"),
                  Tab(icon: Icon(Icons.add_card), text: "New Entry"),
                  Tab(icon: Icon(Icons.receipt_long), text: "Statements"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // TAB 1: SUB CATEGORY
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                          onPressed: () => _showAddOptionDialog('Sub Category', globalExpenseSubCategories[widget.categoryName]!, (_) => setState(() {})),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Sub Category'),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: ListView.builder(
                          itemCount: subCategories.length,
                          itemBuilder: (context, index) => Card(
                            child: ListTile(
                              title: Text(subCategories[index]),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () => setState(() => subCategories.removeAt(index)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // TAB 2: NEW ENTRY
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Selected Category: ${widget.categoryName}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800])),
                      ),
                      const SizedBox(height: 15),

                      // 1. WHO SPENT
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedExpensePerson,
                              decoration: const InputDecoration(labelText: "Who Spent (Expense Person) *", border: OutlineInputBorder()),
                              items: globalExpensePersons.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (val) => setState(() => _selectedExpensePerson = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.red, size: 36),
                            onPressed: () => _showAddOptionDialog('Expense Person', globalExpensePersons, (val) {
                              setState(() => _selectedExpensePerson = val);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 2. PAID FROM
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedIncomePerson,
                              decoration: const InputDecoration(labelText: "Paid From (Income Person) *", border: OutlineInputBorder()),
                              items: globalIncomePersons.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (val) => setState(() { _selectedIncomePerson = val; _selectedAccount = null; }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.red, size: 36),
                            onPressed: () => _showAddOptionDialog('Income Person', globalIncomePersons, (val) {
                              if (!globalPersonAccounts.containsKey(val)) globalPersonAccounts[val] = [];
                              setState(() => _selectedIncomePerson = val);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 3. WHICH ACCOUNT
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAccount,
                              decoration: const InputDecoration(labelText: 'Which Account *', border: OutlineInputBorder()),
                              items: availableAccounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc))).toList(),
                              onChanged: (val) => setState(() => _selectedAccount = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.red, size: 36),
                            onPressed: () {
                              if (_selectedIncomePerson == null) return;
                              if (!globalPersonAccounts.containsKey(_selectedIncomePerson)) globalPersonAccounts[_selectedIncomePerson!] = [];
                              _showAddOptionDialog('Income Account', globalPersonAccounts[_selectedIncomePerson!]!, (val) => setState(() => _selectedAccount = val));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      
                      // MANUAL DATE INPUT
                      TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Date (DD-MM-YYYY) *',
                          hintText: 'e.g. 18-10-2026',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹) *', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      
                      // SAVE, RESET, CANCEL
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                              onPressed: () => _saveExpense(tabController),
                              child: Text(_editingEntryId == null ? 'Save' : 'Update'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                              onPressed: _resetForm,
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => tabController.animateTo(2),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // TAB 3: STATEMENTS
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: categoryEntries.length,
                    itemBuilder: (context, index) {
                      final item = categoryEntries[index];
                      return Card(
                        child: ListTile(
                          title: Text('₹${item.amount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          subtitle: Text('Spent By: ${item.heading2}\nAccount: ${item.heading3} | Date: ${item.date}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  setState(() {
                                    _editingEntryId = item.id;
                                    _selectedExpensePerson = item.heading2.split(" (Paid by:").first;
                                    _amountController.text = item.amount.toString();
                                    _descController.text = item.description;
                                    _dateController.text = item.date;
                                  });
                                  tabController.animateTo(1);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () => setState(() => globalEntries.remove(item)),
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
        },
      ),
    );
  }
}