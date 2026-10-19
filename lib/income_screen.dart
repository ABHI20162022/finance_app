import 'package:flutter/material.dart';
import 'models.dart';

List<String> globalIncomeCategories = [];
List<String> globalIncomePersons = [];
Map<String, List<String>> globalPersonAccounts = {};
Map<String, List<String>> globalIncomeSubCategories = {};

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  // మెయిన్ స్క్రీన్ కోసం From Date మరియు To Date కంట్రోలర్స్
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

  double _calculatePersonNetBalance(String personName, List<FinanceEntry> filteredEntries) {
    double totalInc = filteredEntries
        .where((e) => e.type == 'INCOME' && e.heading2 == personName)
        .fold(0.0, (sum, item) => sum + item.amount);

    double totalExp = filteredEntries
        .where((e) => e.type == 'EXPENSE' && (e.heading2 == personName || e.heading2.contains('Paid by: $personName')))
        .fold(0.0, (sum, item) => sum + item.amount);

    return totalInc - totalExp;
  }

  @override
  Widget build(BuildContext context) {
    List<FinanceEntry> allEntriesList = globalEntries;

    // మెయిన్ స్క్రీన్ డేట్ ఫిల్టర్ అప్లై చేయడం
    String fromStr = _mainFromDateController.text.trim();
    String toStr = _mainToDateController.text.trim();

    List<FinanceEntry> filteredEntries = allEntriesList;
    if (fromStr.isNotEmpty && toStr.isNotEmpty) {
      DateTime? fromDate = _parseCustomDate(fromStr);
      DateTime? toDate = _parseCustomDate(toStr);

      if (fromDate != null && toDate != null) {
        filteredEntries = allEntriesList.where((e) {
          DateTime? entryDate = _parseCustomDate(e.date);
          if (entryDate == null) return false;
          return (entryDate.isAtSameMomentAs(fromDate) || entryDate.isAfter(fromDate)) &&
                 (entryDate.isAtSameMomentAs(toDate) || entryDate.isBefore(toDate));
        }).toList();
      }
    }

    double totalIncomeAmount = filteredEntries.where((e) => e.type == 'INCOME').fold(0.0, (sum, item) => sum + item.amount);
    double totalExpenseAmount = filteredEntries.where((e) => e.type == 'EXPENSE').fold(0.0, (sum, item) => sum + item.amount);
    double netTotalBalance = totalIncomeAmount - totalExpenseAmount;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Income Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  'Net: ₹${netTotalBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: netTotalBalance < 0 ? Colors.red[900] : Colors.green[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.teal[800],
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.category), text: "Income Category"),
              Tab(icon: Icon(Icons.person), text: "Income Person"),
            ],
          ),
        ),
        body: Column(
          children: [
            // స్పష్టమైన డేట్ ఫిల్టర్ హెడర్
            Card(
              margin: const EdgeInsets.all(8.0),
              elevation: 3,
              color: Colors.teal[50],
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mainFromDateController,
                        onChanged: (val) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'From (DD-MM-YYYY)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _mainToDateController,
                        onChanged: (val) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'To (DD-MM-YYYY)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.teal),
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
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
                            onPressed: () => _showAddDialog('Income Category', globalIncomeCategories, (val) {
                              globalIncomeSubCategories[val] = [];
                            }),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Income Category'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: globalIncomeCategories.isEmpty
                              ? const Center(child: Text('No categories added yet.'))
                              : ListView.builder(
                                  itemCount: globalIncomeCategories.length,
                                  itemBuilder: (context, index) {
                                    String category = globalIncomeCategories[index];
                                    double catTotal = filteredEntries
                                        .where((e) => e.type == 'INCOME' && e.heading1 == category)
                                        .fold(0.0, (sum, item) => sum + item.amount);

                                    return Card(
                                      child: ListTile(
                                        leading: const Icon(Icons.folder, color: Colors.teal),
                                        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('₹$catTotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                                            const SizedBox(width: 10),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.grey),
                                              onPressed: () => setState(() {
                                                globalIncomeCategories.removeAt(index);
                                                globalIncomeSubCategories.remove(category);
                                              }),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => IncomeCategoryDetailScreen(categoryName: category)),
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
                  // TAB 2: PERSON & NET BALANCE
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
                            onPressed: () => _showAddDialog('Income Person', globalIncomePersons, (val) {
                              globalPersonAccounts[val] = [];
                            }),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Person'),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Expanded(
                          child: globalIncomePersons.isEmpty
                              ? const Center(child: Text('No persons added yet.'))
                              : ListView.builder(
                                  itemCount: globalIncomePersons.length,
                                  itemBuilder: (context, index) {
                                    String person = globalIncomePersons[index];
                                    List<String> accounts = globalPersonAccounts[person] ?? [];
                                    double netBal = _calculatePersonNetBalance(person, filteredEntries);

                                    return Card(
                                      child: ListTile(
                                        leading: Icon(Icons.person, color: netBal < 0 ? Colors.red : Colors.green),
                                        title: Text(person, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('Accounts: ${accounts.isEmpty ? "None" : accounts.join(", ")}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '₹${netBal.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: netBal < 0 ? Colors.red : Colors.green[800],
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.grey),
                                              onPressed: () => setState(() {
                                                globalIncomePersons.removeAt(index);
                                                globalPersonAccounts.remove(person);
                                              }),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => IncomePersonAccountsScreen(personName: person)),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IncomePersonAccountsScreen extends StatefulWidget {
  final String personName;
  const IncomePersonAccountsScreen({super.key, required this.personName});

  @override
  State<IncomePersonAccountsScreen> createState() => _IncomePersonAccountsScreenState();
}

class _IncomePersonAccountsScreenState extends State<IncomePersonAccountsScreen> {
  void _addAccountDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Account for ${widget.personName}'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. SBI Bank'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              String name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  if (!globalPersonAccounts.containsKey(widget.personName)) globalPersonAccounts[widget.personName] = [];
                  globalPersonAccounts[widget.personName]!.add(name);
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

  double _calculateAccountNetBalance(String accountName) {
    double inc = globalEntries
        .where((e) => e.type == 'INCOME' && e.heading2 == widget.personName && e.heading3 == accountName)
        .fold(0.0, (sum, item) => sum + item.amount);

    double exp = globalEntries
        .where((e) => e.type == 'EXPENSE' && e.heading3 == accountName && (e.heading2 == widget.personName || e.heading2.contains('Paid by: ${widget.personName}')))
        .fold(0.0, (sum, item) => sum + item.amount);

    return inc - exp;
  }

  @override
  Widget build(BuildContext context) {
    List<String> accountsList = globalPersonAccounts[widget.personName] ?? [];
    return Scaffold(
      appBar: AppBar(title: Text('${widget.personName} Accounts', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.teal[800]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
                onPressed: _addAccountDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Account'),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: accountsList.length,
                itemBuilder: (context, index) {
                  String account = accountsList[index];
                  double accBal = _calculateAccountNetBalance(account);

                  return Card(
                    child: ListTile(
                      title: Text(account, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Balance: ₹${accBal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: accBal < 0 ? Colors.red : Colors.green[800],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => setState(() => accountsList.removeAt(index)),
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

class IncomeCategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  const IncomeCategoryDetailScreen({super.key, required this.categoryName});

  @override
  State<IncomeCategoryDetailScreen> createState() => _IncomeCategoryDetailScreenState();
}

class _IncomeCategoryDetailScreenState extends State<IncomeCategoryDetailScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedPerson;
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
      _selectedPerson = null;
      _selectedAccount = null;
      _amountController.clear();
      _descController.clear();
      _setDefaultDate();
      _editingEntryId = null;
    });
  }

  void _saveIncome(TabController tabController) {
    if (_amountController.text.trim().isEmpty) return;
    double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() {
      if (_editingEntryId != null) {
        int index = globalEntries.indexWhere((e) => e.id == _editingEntryId);
        if (index != -1) {
          globalEntries[index] = FinanceEntry(
            id: _editingEntryId!,
            type: 'INCOME',
            heading1: widget.categoryName,
            heading2: _selectedPerson ?? 'None',
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
          type: 'INCOME',
          heading1: widget.categoryName,
          heading2: _selectedPerson ?? 'None',
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final TabController tabController = DefaultTabController.of(context);
          List<FinanceEntry> categoryEntries = globalEntries.where((e) => e.type == 'INCOME' && e.heading1 == widget.categoryName).toList();
          double categoryTotal = categoryEntries.fold(0.0, (sum, item) => sum + item.amount);
          List<String> subCategories = globalIncomeSubCategories[widget.categoryName] ?? [];
          List<String> availableAccounts = _selectedPerson != null && globalPersonAccounts.containsKey(_selectedPerson) ? globalPersonAccounts[_selectedPerson]! : [];

          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.categoryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Text('₹$categoryTotal', style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              backgroundColor: Colors.teal[800],
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
                // TAB 1
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
                          onPressed: () => _showAddOptionDialog('Sub Category', globalIncomeSubCategories[widget.categoryName]!, (_) => setState(() {})),
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
                // TAB 2
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.teal[50], border: Border.all(color: Colors.teal.shade300), borderRadius: BorderRadius.circular(8)),
                        child: Text('Selected Category: ${widget.categoryName}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPerson,
                              decoration: const InputDecoration(labelText: "Person Name *", border: OutlineInputBorder()),
                              items: globalIncomePersons.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (val) => setState(() { _selectedPerson = val; _selectedAccount = null; }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.teal, size: 36),
                            onPressed: () => _showAddOptionDialog('Person', globalIncomePersons, (val) {
                              if (!globalPersonAccounts.containsKey(val)) globalPersonAccounts[val] = [];
                              setState(() => _selectedPerson = val);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAccount,
                              decoration: const InputDecoration(labelText: 'Deposited Account *', border: OutlineInputBorder()),
                              items: availableAccounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc))).toList(),
                              onChanged: (val) => setState(() => _selectedAccount = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.teal, size: 36),
                            onPressed: () {
                              if (_selectedPerson == null) return;
                              if (!globalPersonAccounts.containsKey(_selectedPerson)) globalPersonAccounts[_selectedPerson!] = [];
                              _showAddOptionDialog('Account', globalPersonAccounts[_selectedPerson!]!, (val) => setState(() => _selectedAccount = val));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
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
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
                        onPressed: () => _saveIncome(tabController),
                        child: Text(_editingEntryId == null ? 'Save' : 'Update'),
                      ),
                    ],
                  ),
                ),
                // TAB 3
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: categoryEntries.length,
                    itemBuilder: (context, index) {
                      final item = categoryEntries[index];
                      return Card(
                        child: ListTile(
                          title: Text('₹${item.amount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          subtitle: Text('Person: ${item.heading2} | Account: ${item.heading3}\nDate: ${item.date}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  setState(() {
                                    _editingEntryId = item.id;
                                    _selectedPerson = item.heading2;
                                    _selectedAccount = item.heading3;
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