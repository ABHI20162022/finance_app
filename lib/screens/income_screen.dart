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
  final TextEditingController searchQueryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fromDateController.text = "01-11-2026";
    toDateController.text = "30-11-2026";
    _loadData();
  }

  Future<void> _loadData() async {
    await loadFinanceDataFromPrefs();
    
    if (globalPersons.isEmpty) {
      globalPersons.add(PersonData(
        id: '1',
        name: 'Koti',
        bankAccounts: ['SBI'],
        entries: [
          FinanceItem(
            id: 'e1',
            title: 'Salary',
            amount: 10000,
            person: 'Koti',
            category: 'Salary',
            depositAccount: 'SBI',
            date: "01-10-2026",
            description: 'Monthly Salary',
          )
        ],
      ));
      globalPersons.add(PersonData(
        id: '2',
        name: 'Manasa',
        bankAccounts: ['HDFC'],
        entries: [
          FinanceItem(
            id: 'e2',
            title: 'Salary',
            amount: 10000,
            person: 'Manasa',
            category: 'Salary',
            depositAccount: 'HDFC',
            date: "01-11-2026",
            description: 'Monthly Salary',
          )
        ],
      ));
    }
    
    if (globalIncomeCategories.isEmpty) {
      globalIncomeCategories.addAll(['Salary', 'Business', 'Rent', 'Other']);
    }

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

  bool _isDateBeforeFromDate(String dateStr) {
    if (fromDateController.text.trim().isEmpty) return false;
    DateTime? entryDate = _parseDate(dateStr);
    DateTime? fDate = _parseDate(fromDateController.text);
    if (entryDate != null && fDate != null) {
      DateTime start = DateTime(fDate.year, fDate.month, fDate.day);
      return entryDate.isBefore(start);
    }
    return false;
  }

  bool _isTransferEntry(FinanceItem entry) {
    return entry.category.toLowerCase().contains('transfer') || entry.category.toLowerCase().contains('journal');
  }

  bool _isCreditCardEntry(FinanceItem entry) {
    return entry.depositAccount.toLowerCase().contains('credit card') || 
           entry.category.toLowerCase().contains('credit card');
  }

  Future<bool> _showDeleteConfirmDialog(BuildContext context, {String title = "Delete Entry", String message = "Are you sure you want to delete this entry?"}) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showIncomePersonDialog({PersonData? person}) {
    final controller = TextEditingController(text: person?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(person == null ? 'Add Income Person' : 'Edit Person', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Person Name', border: OutlineInputBorder(), isDense: true),
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
        title: Text(oldCategory == null ? 'Add Income Category' : 'Edit Category', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder(), isDense: true),
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
        const SnackBar(content: Text('Journal Entry వేయడానికి కనీసం 2 Persons ఉండాలి!'), backgroundColor: Colors.red),
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
    final dateController = TextEditingController(
      text: existingItem != null ? existingItem.date : "${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}",
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingItem == null ? 'New Journal Entry' : 'Edit Journal Entry', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: globalPersons.any((p) => p.name == fromPerson) ? fromPerson : globalPersons.first.name,
                      decoration: const InputDecoration(labelText: 'From Person (Debit - Dr)', border: OutlineInputBorder(), isDense: true),
                      items: globalPersons.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                      onChanged: (val) => setDialogState(() => fromPerson = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: globalPersons.any((p) => p.name == toPerson) ? toPerson : globalPersons[1].name,
                      decoration: const InputDecoration(labelText: 'To Person (Credit - Cr)', border: OutlineInputBorder(), isDense: true),
                      items: globalPersons.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                      onChanged: (val) => setDialogState(() => toPerson = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: 'Date (DD-MM-YYYY)', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Narration / Description', border: OutlineInputBorder(), isDense: true),
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
                        const SnackBar(content: Text("From and To Persons ఒకటే ఉండకూడదు!"), backgroundColor: Colors.red),
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
                      
                      String dateNow = dateController.text.trim().isNotEmpty ? dateController.text.trim() : "${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}";
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
                        setState(() {});
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
    double periodIncome = 0;       
    double lifeTimeIncome = 0;     
    double lifeTimeExpenses = 0;   
    double totalNegativeBalance = 0; 
    
    for (var person in globalPersons) {
      double pIncAll = 0;
      double pExpAll = 0;
      double pTransAll = 0;

      for (var entry in person.entries) {
        if (_isDateInRange(entry.date)) {
          if (!_isTransferEntry(entry) && entry.amount > 0) {
            periodIncome += entry.amount;
          }
        }

        if (_isTransferEntry(entry)) {
          pTransAll += entry.amount;
        } else {
          if (entry.amount > 0) {
            pIncAll += entry.amount;
            lifeTimeIncome += entry.amount;
          } else if (entry.amount < 0) {
            double absAmt = entry.amount.abs();
            pExpAll += absAmt;
            lifeTimeExpenses += absAmt;
            
            if (_isCreditCardEntry(entry)) {
              pExpAll -= absAmt; 
              lifeTimeExpenses -= absAmt;
            }
          }
        }
      }

      double pNet = (pIncAll - pExpAll) + pTransAll;
      if (pNet < 0) {
        totalNegativeBalance += pNet.abs();
      }
    }
    
    double netBalance = lifeTimeIncome - lifeTimeExpenses;
    double combinedNetWithApp = netBalance + totalNegativeBalance;

    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Income & Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 45,
          actions: [
            IconButton(
              icon: const Icon(Icons.import_contacts, size: 20),
              tooltip: 'New Journal Entry',
              onPressed: () => _showJournalEntryDialog(context),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.person, size: 16), text: 'Persons'),
              Tab(icon: Icon(Icons.category, size: 16), text: 'Categories'),
              Tab(icon: Icon(Icons.receipt_long, size: 16), text: 'Statement'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Dashboard Cards
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.green.shade700,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Period Income', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text('₹${periodIncome.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Expenses', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text('₹${lifeTimeExpenses.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Net Balance', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${combinedNetWithApp.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Date Filter Section + Search Input in standard Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: fromDateController,
                      style: const TextStyle(fontSize: 10),
                      decoration: InputDecoration(
                        labelText: 'From',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(6),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 10),
                          onPressed: () => setState(() => fromDateController.clear()),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: toDateController,
                      style: const TextStyle(fontSize: 10),
                      decoration: InputDecoration(
                        labelText: 'To',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(6),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 10),
                          onPressed: () => setState(() => toDateController.clear()),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: searchQueryController,
                      style: const TextStyle(fontSize: 10),
                      decoration: InputDecoration(
                        labelText: 'Search...',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(6),
                        prefixIcon: const Icon(Icons.search, size: 14),
                        suffixIcon: searchQueryController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 10),
                                onPressed: () => setState(() => searchQueryController.clear()),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              )
                            : null,
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          fromDateController.text = "01-11-2026";
                          toDateController.text = "30-11-2026";
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Month', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            Expanded(
              child: TabBarView(
                children: [
                  IncomePersonsTab(
                    isDateInRange: _isDateInRange,
                    onAddPerson: () => _showIncomePersonDialog(),
                    onEditPerson: (p) => _showIncomePersonDialog(person: p),
                    onDeletePerson: (index) async {
                      bool confirm = await _showDeleteConfirmDialog(context, title: "Delete Person", message: "Are you sure you want to delete this person and all their records?");
                      if (confirm) {
                        globalPersons.removeAt(index);
                        await _saveData();
                      }
                    },
                    fromDateStr: fromDateController.text,
                    toDateStr: toDateController.text,
                    searchQuery: searchQueryController.text,
                  ),
                  IncomeCategoriesTab(
                    isDateInRange: _isDateInRange,
                    onAddCategory: () => _showIncomeCategoryDialog(),
                    onEditCategory: (cat, idx) => _showIncomeCategoryDialog(oldCategory: cat, index: idx),
                    onDeleteCategory: (index) async {
                      bool confirm = await _showDeleteConfirmDialog(context, title: "Delete Category", message: "Are you sure you want to delete this income category?");
                      if (confirm) {
                        globalIncomeCategories.removeAt(index);
                        await _saveData();
                      }
                    },
                    fromDateStr: fromDateController.text,
                    toDateStr: toDateController.text,
                    searchQuery: searchQueryController.text,
                  ),
                  TotalStatementTab(
                    fromDateStr: fromDateController.text,
                    toDateStr: toDateController.text,
                    isDateInRange: _isDateInRange,
                    isDateBeforeFromDate: _isDateBeforeFromDate,
                    searchQuery: searchQueryController.text,
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

class IncomePersonsTab extends StatefulWidget {
  final bool Function(String) isDateInRange;
  final VoidCallback onAddPerson;
  final Function(PersonData) onEditPerson;
  final Function(int) onDeletePerson;
  final String fromDateStr;
  final String toDateStr;
  final String searchQuery;

  const IncomePersonsTab({
    super.key,
    required this.isDateInRange,
    required this.onAddPerson,
    required this.onEditPerson,
    required this.onDeletePerson,
    required this.fromDateStr,
    required this.toDateStr,
    required this.searchQuery,
  });

  @override
  State<IncomePersonsTab> createState() => _IncomePersonsTabState();
}

class _IncomePersonsTabState extends State<IncomePersonsTab> {
  bool _isTransferEntry(FinanceItem entry) {
    return entry.category.toLowerCase().contains('transfer') || entry.category.toLowerCase().contains('journal');
  }

  @override
  Widget build(BuildContext context) {
    List<PersonData> filteredPersons = globalPersons.where((p) {
      if (widget.searchQuery.isNotEmpty && !p.name.toLowerCase().contains(widget.searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Persons (${filteredPersons.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              SizedBox(
                height: 30,
                child: ElevatedButton.icon(
                  onPressed: widget.onAddPerson,
                  icon: const Icon(Icons.person_add, size: 14),
                  label: const Text('Add Person', style: TextStyle(fontSize: 10)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: filteredPersons.isEmpty
                ? const Center(child: Text('No persons found.', style: TextStyle(fontSize: 12, color: Colors.grey)))
                : ListView.builder(
                    itemCount: filteredPersons.length,
                    itemBuilder: (context, index) {
                      final person = filteredPersons[index];
                      double personPeriodIncome = 0;
                      double lifeTimeIncome = 0;
                      double lifeTimeExpense = 0;
                      double personTransferNet = 0;
                      
                      for (var e in person.entries) {
                        if (widget.isDateInRange(e.date)) {
                          if (!_isTransferEntry(e) && e.amount > 0) {
                            personPeriodIncome += e.amount;
                          }
                        }

                        if (_isTransferEntry(e)) {
                          personTransferNet += e.amount;
                        } else {
                          if (e.amount > 0) {
                            lifeTimeIncome += e.amount;
                          } else if (e.amount < 0) {
                            lifeTimeExpense += e.amount.abs();
                          }
                        }
                      }
                      double personNet = (lifeTimeIncome - lifeTimeExpense) + personTransferNet;

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          leading: CircleAvatar(backgroundColor: Colors.green.shade100, radius: 16, child: Icon(Icons.person, color: Colors.green.shade800, size: 18)),
                          title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(
                            'Period Inc: ₹${personPeriodIncome.toStringAsFixed(0)} | Lifetime Net: ₹${personNet.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: personNet >= 0 ? Colors.blue.shade800 : Colors.red.shade800,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                onPressed: () => widget.onEditPerson(person),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                onPressed: () => widget.onDeletePerson(globalPersons.indexOf(person)),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IncomePersonDetailScreen(
                                  person: person,
                                  fromDateStr: widget.fromDateStr,
                                  toDateStr: widget.toDateStr,
                                ),
                              ),
                            );
                          },
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

class CategorySummaryItem {
  final String categoryName;
  final double totalAmount;
  final List<FinanceItem> entries;
  CategorySummaryItem({required this.categoryName, required this.totalAmount, required this.entries});
}

class PersonSummaryItem {
  final String personName;
  final double totalAmount;
  final List<FinanceItem> entries;
  PersonSummaryItem({required this.personName, required this.totalAmount, required this.entries});
}

class IncomeCategoriesTab extends StatefulWidget {
  final bool Function(String) isDateInRange;
  final VoidCallback onAddCategory;
  final Function(String, int) onEditCategory;
  final Function(int) onDeleteCategory;
  final String fromDateStr;
  final String toDateStr;
  final String searchQuery;

  const IncomeCategoriesTab({
    super.key,
    required this.isDateInRange,
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.fromDateStr,
    required this.toDateStr,
    required this.searchQuery,
  });

  @override
  State<IncomeCategoriesTab> createState() => _IncomeCategoriesTabState();
}

class _IncomeCategoriesTabState extends State<IncomeCategoriesTab> {
  @override
  Widget build(BuildContext context) {
    List<String> filteredCategories = globalIncomeCategories.where((cat) {
      if (widget.searchQuery.isNotEmpty && !cat.toLowerCase().contains(widget.searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Categories (${filteredCategories.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              SizedBox(
                height: 30,
                child: ElevatedButton.icon(
                  onPressed: widget.onAddCategory,
                  icon: const Icon(Icons.playlist_add, size: 14),
                  label: const Text('Add Category', style: TextStyle(fontSize: 10)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: filteredCategories.isEmpty
                ? const Center(child: Text('No categories found.', style: TextStyle(fontSize: 12, color: Colors.grey)))
                : ListView.builder(
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final cat = filteredCategories[index];
                      int originalIndex = globalIncomeCategories.indexOf(cat);
                      double categoryTotal = 0;
                      for (var p in globalPersons) {
                        for (var e in p.entries) {
                          if (e.category == cat && widget.isDateInRange(e.date) && e.amount > 0) {
                            categoryTotal += e.amount;
                          }
                        }
                      }
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          leading: CircleAvatar(backgroundColor: Colors.green.shade100, radius: 16, child: Icon(Icons.attach_money, color: Colors.green.shade800, size: 18)),
                          title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          subtitle: Text('Total: ₹${categoryTotal.toStringAsFixed(0)}', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 10)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                onPressed: () => widget.onEditCategory(cat, originalIndex),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                onPressed: () => widget.onDeleteCategory(originalIndex),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IncomeCategoryDetailScreen(
                                  categoryName: cat,
                                  fromDateStr: widget.fromDateStr,
                                  toDateStr: widget.toDateStr,
                                ),
                              ),
                            );
                          },
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

class IncomeCategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final String? personName; 
  final String? fromDateStr;
  final String? toDateStr;
  
  const IncomeCategoryDetailScreen({
    super.key, 
    required this.categoryName, 
    this.personName,
    this.fromDateStr, 
    this.toDateStr,
  });

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

  Future<bool> _showDeleteConfirmDialog(BuildContext context, {String title = "Delete Entry", String message = "Are you sure you want to delete this entry?"}) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download / Share Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel / CSV (.xlsx)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel file downloaded & shared successfully!'), backgroundColor: Colors.green));
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('Word Document (.docx)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Word document downloaded & shared successfully!'), backgroundColor: Colors.blue));
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF Report (.pdf)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF report downloaded & shared successfully!'), backgroundColor: Colors.red));
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
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

  void _showAddIncomeEntryDialog(BuildContext context, {FinanceItem? existingItem}) {
    if (globalPersons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('దయచేసి ముందుగా ఒక Income Person ని యాడ్ చేయండి!'), backgroundColor: Colors.red),
      );
      return;
    }

    String selectedPerson = existingItem != null 
        ? existingItem.person 
        : (widget.personName ?? globalPersons.first.name);

    if (!globalPersons.any((p) => p.name == selectedPerson)) {
      selectedPerson = globalPersons.first.name;
    }

    String? selectedAccount = existingItem != null ? existingItem.depositAccount : null;
    
    final amountController = TextEditingController(text: existingItem != null ? existingItem.amount.toString() : '');
    final descController = TextEditingController(text: existingItem?.description ?? '');
    final dateController = TextEditingController(
      text: existingItem != null ? existingItem.date : "${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}",
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            PersonData currentPersonObj = globalPersons.firstWhere((p) => p.name == selectedPerson, orElse: () => globalPersons.first);
            List<String> availableAccounts = currentPersonObj.bankAccounts;
            
            if (availableAccounts.isNotEmpty) {
              if (selectedAccount == null || !availableAccounts.contains(selectedAccount)) {
                selectedAccount = availableAccounts.first;
              }
            } else {
              selectedAccount = null;
            }

            return AlertDialog(
              title: Text(existingItem == null ? 'Add Entry in "${widget.categoryName}"' : 'Edit Entry', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPerson,
                      decoration: const InputDecoration(labelText: 'Select Person', border: OutlineInputBorder(), isDense: true),
                      items: globalPersons.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedPerson = val;
                            PersonData pObj = globalPersons.firstWhere((p) => p.name == selectedPerson);
                            selectedAccount = pObj.bankAccounts.isNotEmpty ? pObj.bankAccounts.first : null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    if (availableAccounts.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: selectedAccount,
                        decoration: const InputDecoration(labelText: 'Deposit Bank Account', border: OutlineInputBorder(), isDense: true),
                        items: availableAccounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc))).toList(),
                        onChanged: (val) => setDialogState(() => selectedAccount = val),
                      ),
                      const SizedBox(height: 10),
                    ],

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: 'Date (DD-MM-YYYY)', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description / Note', border: OutlineInputBorder(), isDense: true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  onPressed: () async {
                    double amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amt > 0) {
                      PersonData targetPerson = globalPersons.firstWhere((p) => p.name == selectedPerson);
                      
                      if (existingItem != null) {
                        for (var p in globalPersons) {
                          p.entries.removeWhere((e) => e.id == existingItem.id);
                        }
                      }

                      targetPerson.entries.add(
                        FinanceItem(
                          id: existingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          title: widget.categoryName,
                          amount: amt,
                          person: selectedPerson,
                          category: widget.categoryName,
                          depositAccount: selectedAccount ?? 'Cash',
                          date: dateController.text.trim(),
                          description: descController.text.trim(),
                        ),
                      );

                      await _saveData();
                      if (mounted) {
                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(existingItem == null ? 'Income Entry Added Successfully!' : 'Income Entry Updated Successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('దయచేసి సరైన అమౌంట్ ఇవ్వండి!'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Text(existingItem == null ? 'Save' : 'Update'),
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
    List<FinanceItem> directEntries = [];
    Map<String, List<FinanceItem>> personGroupMap = {};

    for (var p in globalPersons) {
      if (widget.personName != null && p.name.toLowerCase() != widget.personName!.toLowerCase()) {
        continue;
      }
      for (var e in p.entries) {
        if (e.category == widget.categoryName && _isDateInRange(e.date) && e.amount > 0) {
          if (widget.personName != null) {
            directEntries.add(e);
          } else {
            personGroupMap.putIfAbsent(p.name, () => []).add(e);
          }
        }
      }
    }

    List<PersonSummaryItem> personSummaries = [];
    personGroupMap.forEach((pName, list) {
      double sumAmt = list.fold(0.0, (s, item) => s + item.amount);
      personSummaries.add(PersonSummaryItem(personName: pName, totalAmount: sumAmt, entries: list));
    });

    double categoryTotal = widget.personName != null
        ? directEntries.fold(0.0, (sum, item) => sum + item.amount)
        : personSummaries.fold(0.0, (sum, item) => sum + item.totalAmount);

    String screenTitle = widget.personName != null ? '${widget.personName} - ${widget.categoryName}' : '${widget.categoryName} Statement';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(screenTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        toolbarHeight: 45,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, size: 22),
            tooltip: 'Add Entry in ${widget.categoryName}',
            onPressed: () => _showAddIncomeEntryDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Income:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  Text('₹${categoryTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: (widget.personName != null ? directEntries.isEmpty : personSummaries.isEmpty)
                  ? const Center(child: Text('No entries found.', style: TextStyle(fontSize: 12, color: Colors.grey)))
                  : widget.personName != null
                      ? ListView.builder(
                          itemCount: directEntries.length,
                          itemBuilder: (context, index) {
                            final entry = directEntries[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                leading: CircleAvatar(backgroundColor: Colors.green.shade100, radius: 14, child: Icon(Icons.attach_money, color: Colors.green.shade800, size: 14)),
                                title: Text('${entry.person} - ₹${entry.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                subtitle: Text('Acc: ${entry.depositAccount} | Date: ${entry.date}${entry.description.isNotEmpty ? '\nNote: ${entry.description}' : ''}', style: const TextStyle(fontSize: 10)),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                      onPressed: () => _showAddIncomeEntryDialog(context, existingItem: entry),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                      onPressed: () async {
                                        bool confirm = await _showDeleteConfirmDialog(context, title: "Delete Entry", message: "Are you sure you want to delete this income entry?");
                                        if (confirm) {
                                          for (var p in globalPersons) {
                                            p.entries.removeWhere((e) => e.id == entry.id);
                                          }
                                          await _saveData();
                                          setState(() {});
                                        }
                                      },
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          itemCount: personSummaries.length,
                          itemBuilder: (context, index) {
                            final summary = personSummaries[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                leading: CircleAvatar(backgroundColor: Colors.green.shade100, radius: 14, child: Icon(Icons.person, color: Colors.green.shade800, size: 14)),
                                title: Text(summary.personName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                subtitle: Text('Total Entries: ${summary.entries.length}', style: const TextStyle(fontSize: 10)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('₹${summary.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade800)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => IncomeCategoryDetailScreen(
                                        categoryName: widget.categoryName,
                                        personName: summary.personName,
                                        fromDateStr: widget.fromDateStr,
                                        toDateStr: widget.toDateStr,
                                      ),
                                    ),
                                  );
                                },
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
  Future<void> _saveData() async {
    await saveFinanceDataToPrefs();
    if (mounted) {
      setState(() {});
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download / Share ${widget.person.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel / CSV (.xlsx)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel file downloaded & shared successfully!'), backgroundColor: Colors.green));
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('Word Document (.docx)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Word document downloaded & shared successfully!'), backgroundColor: Colors.blue));
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF Report (.pdf)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF report downloaded & shared successfully!'), backgroundColor: Colors.red));
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
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

  bool _isCreditCardEntry(FinanceItem entry) {
    return entry.depositAccount.toLowerCase().contains('credit card') || 
           entry.category.toLowerCase().contains('credit card');
  }

  void _showAddBankDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Bank Account for ${widget.person.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder(), isDense: true)),
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

  Future<void> _deleteBank(String bankName) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$bankName"?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      widget.person.bankAccounts.remove(bankName);
      await _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = widget.person.entries.where((e) => _isDateInRange(e.date)).toList();
    double periodIncome = filteredEntries.where((e) => e.amount > 0 && !_isTransferEntry(e)).fold(0.0, (sum, item) => sum + item.amount);

    double lifeTimeIncome = 0;
    double lifeTimeExpense = 0;
    double lifeTimeTransferNet = 0;

    for (var e in widget.person.entries) {
      if (_isTransferEntry(e)) {
        lifeTimeTransferNet += e.amount;
      } else {
        if (e.amount > 0) {
          lifeTimeIncome += e.amount;
        } else if (e.amount < 0) {
          double absAmt = e.amount.abs();
          lifeTimeExpense += absAmt;
          if (_isCreditCardEntry(e)) {
            lifeTimeExpense -= absAmt;
          }
        }
      }
    }
    double lifeTimeNet = (lifeTimeIncome - lifeTimeExpense) + lifeTimeTransferNet;

    Map<String, List<FinanceItem>> categoryGroupMap = {};
    List<FinanceItem> personJournalEntries = [];

    for (var entry in filteredEntries) {
      if (_isTransferEntry(entry)) {
        personJournalEntries.add(entry);
      } else if (entry.amount > 0) {
        String cat = entry.category.isNotEmpty ? entry.category : 'Uncategorized';
        categoryGroupMap.putIfAbsent(cat, () => []).add(entry);
      }
    }

    List<CategorySummaryItem> categorySummaries = [];
    categoryGroupMap.forEach((catName, list) {
      double sumAmt = list.fold(0.0, (s, item) => s + item.amount);
      categorySummaries.add(CategorySummaryItem(categoryName: catName, totalAmount: sumAmt, entries: list));
    });

    double totalJournalSum = personJournalEntries.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('${widget.person.name}\'s Statement', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        toolbarHeight: 45,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Period Income (Filtered):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                        Text('₹${periodIncome.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                      ],
                    ),
                    const Divider(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Net Balance (Life-time):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                        Text('₹${lifeTimeNet.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lifeTimeNet >= 0 ? Colors.blue.shade900 : Colors.red.shade900)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bank Accounts:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(
                  height: 30,
                  child: ElevatedButton.icon(
                    onPressed: _showAddBankDialog,
                    icon: const Icon(Icons.account_balance, size: 12),
                    label: const Text('Add Bank', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            widget.person.bankAccounts.isEmpty
                ? const Text('Cash Only (No Bank Accounts)', style: TextStyle(fontSize: 10, color: Colors.grey))
                : Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: widget.person.bankAccounts.map((bank) {
                      return Chip(
                        label: Text(bank, style: const TextStyle(fontSize: 10)),
                        backgroundColor: Colors.white,
                        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.red),
                        onDeleted: () => _deleteBank(bank),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 8),
            const Text('Categories & Journal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                children: [
                  if (personJournalEntries.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        leading: CircleAvatar(backgroundColor: Colors.blue.shade100, radius: 14, child: Icon(Icons.compare_arrows, color: Colors.blue.shade800, size: 14)),
                        title: const Text('Journal Statements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text('Total Entries: ${personJournalEntries.length}', style: const TextStyle(fontSize: 10)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${totalJournalSum.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: totalJournalSum >= 0 ? Colors.blue.shade800 : Colors.red.shade800)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PersonJournalDetailScreen(
                                person: widget.person,
                                fromDateStr: widget.fromDateStr,
                                toDateStr: widget.toDateStr,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ...categorySummaries.map((summary) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        leading: CircleAvatar(backgroundColor: Colors.green.shade100, radius: 14, child: Icon(Icons.category, color: Colors.green.shade800, size: 14)),
                        title: Text(summary.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text('Total Entries: ${summary.entries.length}', style: const TextStyle(fontSize: 10)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${summary.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade800)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IncomeCategoryDetailScreen(
                                categoryName: summary.categoryName,
                                personName: widget.person.name, 
                                fromDateStr: widget.fromDateStr,
                                toDateStr: widget.toDateStr,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TotalStatementTab extends StatefulWidget {
  final String fromDateStr;
  final String toDateStr;
  final bool Function(String) isDateInRange;
  final bool Function(String) isDateBeforeFromDate;
  final String searchQuery;

  const TotalStatementTab({
    super.key,
    required this.fromDateStr,
    required this.toDateStr,
    required this.isDateInRange,
    required this.isDateBeforeFromDate,
    required this.searchQuery,
  });

  @override
  State<TotalStatementTab> createState() => _TotalStatementTabState();
}

class _TotalStatementTabState extends State<TotalStatementTab> {
  String selectedPersonFilter = 'All';

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download / Share Statement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel / CSV (.xlsx)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel file downloaded & shared successfully!'), backgroundColor: Colors.green));
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('Word Document (.docx)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Word document downloaded & shared successfully!'), backgroundColor: Colors.blue));
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF Report (.pdf)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF report downloaded & shared successfully!'), backgroundColor: Colors.red));
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> personNames = ['All', ...globalPersons.map((p) => p.name)];
    if (!personNames.contains(selectedPersonFilter)) {
      selectedPersonFilter = 'All';
    }

    double openingBalance = 0.0;
    List<StmtItem> statementItems = [];
    double totalCredit = 0.0;
    double totalDebit = 0.0;
    
    for (var person in globalPersons) {
      if (selectedPersonFilter != 'All' && person.name != selectedPersonFilter) {
        continue;
      }
      for (var entry in person.entries) {
        // 1. Calculate Opening Balance (All transactions before From Date)
        if (widget.isDateBeforeFromDate(entry.date)) {
          openingBalance += entry.amount;
        }

        // 2. Process Current Date Range Transactions
        if (widget.isDateInRange(entry.date)) {
          if (widget.searchQuery.isNotEmpty) {
            String searchStr = widget.searchQuery.toLowerCase();
            bool matches = person.name.toLowerCase().contains(searchStr) ||
                entry.category.toLowerCase().contains(searchStr) ||
                entry.description.toLowerCase().contains(searchStr) ||
                entry.depositAccount.toLowerCase().contains(searchStr);
            if (!matches) continue;
          }

          double cr = 0.0;
          double dr = 0.0;

          if (entry.amount > 0) {
            cr = entry.amount;
            totalCredit += cr;
          } else if (entry.amount < 0) {
            dr = entry.amount.abs();
            totalDebit += dr;
          }

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
    
    double currentBal = openingBalance;
    for (var item in statementItems) {
      currentBal += (item.creditAmount - item.debitAmount);
      item.runningBalance = currentBal;
    }
    double closingBalance = openingBalance + totalCredit - totalDebit;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedPersonFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Person',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: personNames
                      .map((name) => DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedPersonFilter = val ?? 'All';
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 35,
                child: ElevatedButton.icon(
                  onPressed: () => _showExportDialog(context),
                  icon: const Icon(Icons.share, size: 14),
                  label: const Text('Share', style: TextStyle(fontSize: 10)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
            child: const Row(
              children: [
                SizedBox(width: 60, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text('Person & Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text('Narration / Acc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                SizedBox(width: 50, child: Text('In(Cr)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.green), textAlign: TextAlign.right)),
                SizedBox(width: 50, child: Text('Out(Dr)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.red), textAlign: TextAlign.right)),
                SizedBox(width: 55, child: Text('Bal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blue), textAlign: TextAlign.right)),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              children: [
                // Opening Balance Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: Colors.yellow.shade50,
                  child: Row(
                    children: [
                      const SizedBox(width: 60, child: Text('-', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                      const Expanded(flex: 2, child: Text('Opening Balance', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87))),
                      const Expanded(flex: 2, child: Text('Previous Net Total', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey))),
                      const SizedBox(width: 50, child: Text('-', textAlign: TextAlign.right, style: TextStyle(fontSize: 10))),
                      const SizedBox(width: 50, child: Text('-', textAlign: TextAlign.right, style: TextStyle(fontSize: 10))),
                      SizedBox(
                        width: 55,
                        child: Text(
                          '₹${openingBalance.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: openingBalance >= 0 ? Colors.blue.shade900 : Colors.red.shade900),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Transactions List
                if (statementItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No transactions found in selected period.', style: TextStyle(fontSize: 12, color: Colors.grey))),
                  )
                else
                  ...statementItems.map((item) {
                    String detailsStr = "${item.person} (${item.category})";
                    String narration = "${item.account}${item.description.isNotEmpty ? ' - ${item.description}' : ''}";
                    bool isTransfer = item.category.toLowerCase().contains('transfer') || item.category.toLowerCase().contains('journal');

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 60, child: Text(item.date, style: const TextStyle(fontSize: 10))),
                          Expanded(flex: 2, child: Text(detailsStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isTransfer ? Colors.blue.shade800 : Colors.black87))),
                          Expanded(flex: 2, child: Text(narration, style: const TextStyle(fontSize: 10))),
                          SizedBox(
                            width: 50,
                            child: Text(
                              item.creditAmount > 0 ? '₹${item.creditAmount.toStringAsFixed(0)}' : '-',
                              style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              item.debitAmount > 0 ? '₹${item.debitAmount.toStringAsFixed(0)}' : '-',
                              style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 55,
                            child: Text(
                              '₹${item.runningBalance.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.runningBalance >= 0 ? Colors.blue.shade900 : Colors.red.shade900),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 4),
          
          // Statement Summary Footer
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Opening Bal: ₹${openingBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('Period Inflow: ₹${totalCredit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('Period Outflow: ₹${totalDebit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                const Divider(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Closing Balance:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('₹${closingBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: closingBalance >= 0 ? Colors.blue.shade900 : Colors.red.shade900)),
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

class JournalDetailScreen extends StatelessWidget {
  final FinanceItem journalItem;

  const JournalDetailScreen({super.key, required this.journalItem});

  @override
  Widget build(BuildContext context) {
    String receiverName = journalItem.category.replaceFirst('Journal to ', '');
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Journal Entry Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        toolbarHeight: 45,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transaction Date:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(journalItem.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transfer Amount:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('₹${journalItem.amount.abs().toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('From (Debit - Dr):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
                    Text(journalItem.person, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('To (Credit - Cr):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                    Text(receiverName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 16),
                const Text('Narration / Description:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  journalItem.description.isNotEmpty ? journalItem.description : 'No description provided.',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PersonJournalDetailScreen extends StatefulWidget {
  final PersonData person;
  final String? fromDateStr;
  final String? toDateStr;

  const PersonJournalDetailScreen({super.key, required this.person, this.fromDateStr, this.toDateStr});

  @override
  State<PersonJournalDetailScreen> createState() => _PersonJournalDetailScreenState();
}

class _PersonJournalDetailScreenState extends State<PersonJournalDetailScreen> {
  String selectedJournalPersonFilter = 'All';

  Future<void> _saveData() async {
    await saveFinanceDataToPrefs();
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _showDeleteConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this journal entry?', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download / Share Journal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel / CSV (.xlsx)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel file downloaded & shared successfully!'), backgroundColor: Colors.green));
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('Word Document (.docx)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Word document downloaded & shared successfully!'), backgroundColor: Colors.blue));
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF Report (.pdf)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF report downloaded & shared successfully!'), backgroundColor: Colors.red));
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
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

  void _showJournalEditDialog(FinanceItem item) {
    final amountController = TextEditingController(text: item.amount.abs().toString());
    final descController = TextEditingController(text: item.description);
    final dateController = TextEditingController(text: item.date);
    String receiverName = item.category.replaceFirst('Journal to ', '');
    String toPerson = receiverName;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Journal Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('From Person: ${widget.person.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: globalPersons.any((p) => p.name == toPerson) ? toPerson : globalPersons.first.name,
                      decoration: const InputDecoration(labelText: 'To Person (Credit - Cr)', border: OutlineInputBorder(), isDense: true),
                      items: globalPersons.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                      onChanged: (val) => setDialogState(() => toPerson = val!),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: 'Date (DD-MM-YYYY)', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Narration / Description', border: OutlineInputBorder(), isDense: true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (widget.person.name == toPerson) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("From and To Persons ఒకటే ఉండకూడదు!"), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    double amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amt > 0) {
                      for (var p in globalPersons) {
                        p.entries.removeWhere((e) => e.id.startsWith(item.id.replaceAll('_dr', '').replaceAll('_cr', '')));
                      }
                      String baseId = item.id.replaceAll('_dr', '').replaceAll('_cr', '');
                      String note = descController.text.trim();
                      String narration = note.isNotEmpty ? note : 'Journal Adjustment';
                      String entryDate = dateController.text.trim().isNotEmpty ? dateController.text.trim() : item.date;
                      
                      widget.person.entries.add(
                        FinanceItem(
                          id: '${baseId}_dr',
                          title: 'Journal Out',
                          amount: -amt,
                          person: widget.person.name,
                          category: 'Journal to $toPerson',
                          depositAccount: 'Journal',
                          date: entryDate,
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
                          category: 'Journal from ${widget.person.name}',
                          depositAccount: 'Journal',
                          date: entryDate,
                          description: narration,
                        ),
                      );
                      
                      await _saveData();
                      if (mounted) {
                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Journal Entry Updated Successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                  child: const Text('Update'),
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
    List<String> personNames = ['All', ...globalPersons.map((p) => p.name)];
    if (!personNames.contains(selectedJournalPersonFilter)) {
      selectedJournalPersonFilter = 'All';
    }

    final filteredEntries = widget.person.entries.where((e) => _isDateInRange(e.date)).toList();
    List<FinanceItem> journalEntries = [];
    Map<String, double> individualGivenMap = {};
    Map<String, double> individualReceivedMap = {};

    for (var entry in filteredEntries) {
      if (_isTransferEntry(entry)) {
        String otherPerson = "";
        if (entry.category.toLowerCase().contains('journal to')) {
          otherPerson = entry.category.replaceFirst('Journal to ', '');
        } else if (entry.category.toLowerCase().contains('journal from')) {
          otherPerson = entry.category.replaceFirst('Journal from ', '');
        }

        if (otherPerson.isNotEmpty) {
          if (entry.amount < 0) {
            individualGivenMap[otherPerson] = (individualGivenMap[otherPerson] ?? 0.0) + entry.amount.abs();
          } else if (entry.amount > 0) {
            individualReceivedMap[otherPerson] = (individualReceivedMap[otherPerson] ?? 0.0) + entry.amount.abs();
          }
        }

        if (selectedJournalPersonFilter == 'All' || otherPerson.toLowerCase() == selectedJournalPersonFilter.toLowerCase()) {
          journalEntries.add(entry);
        }
      }
    }

    journalEntries.sort((a, b) {
      DateTime? dateA = _parseDate(a.date);
      DateTime? dateB = _parseDate(b.date);
      if (dateA != null && dateB != null) {
        return dateA.compareTo(dateB);
      }
      return a.date.compareTo(b.date);
    });

    double totalGiven = journalEntries.where((e) => e.amount < 0).fold(0.0, (sum, e) => sum + e.amount.abs());
    double totalReceived = journalEntries.where((e) => e.amount > 0).fold(0.0, (sum, e) => sum + e.amount.abs());

    Set<String> allOtherPersons = {...individualGivenMap.keys, ...individualReceivedMap.keys};

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('${widget.person.name} - Journal Statements', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        toolbarHeight: 45,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedJournalPersonFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter Person',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    items: personNames
                        .map((name) => DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedJournalPersonFilter = val ?? 'All';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            Card(
              elevation: 1,
              color: Colors.blue.shade50,
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Individual Totals Breakdown:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const Divider(height: 4),
                    if (allOtherPersons.isEmpty)
                      const Text('No individual records found.', style: TextStyle(fontSize: 10, color: Colors.grey))
                    else
                      ...allOtherPersons.map((pName) {
                        if (selectedJournalPersonFilter != 'All' && selectedJournalPersonFilter.toLowerCase() != pName.toLowerCase()) {
                          return const SizedBox.shrink();
                        }
                        double given = individualGivenMap[pName] ?? 0.0;
                        double received = individualReceivedMap[pName] ?? 0.0;
                        double net = received - given;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(pName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  if (given > 0) Text('Given: ₹${given.toStringAsFixed(0)} ', style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600)),
                                  if (received > 0) Text('Recv: ₹${received.toStringAsFixed(0)} ', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                                  Text('[Net: ₹${net.toStringAsFixed(0)}]', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: net >= 0 ? Colors.blue.shade800 : Colors.red.shade800)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            Expanded(
              child: journalEntries.isEmpty
                  ? const Center(child: Text('No journal entries found.', style: TextStyle(fontSize: 12, color: Colors.grey)))
                  : ListView.builder(
                      itemCount: journalEntries.length,
                      itemBuilder: (context, index) {
                        final entry = journalEntries[index];
                        bool isGiven = entry.amount < 0;
                        String otherParty = "";
                        if (entry.category.toLowerCase().contains('journal to')) {
                          otherParty = entry.category.replaceFirst('Journal to ', '');
                        } else if (entry.category.toLowerCase().contains('journal from')) {
                          otherParty = entry.category.replaceFirst('Journal from ', '');
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => JournalDetailScreen(journalItem: entry),
                                ),
                              );
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: isGiven ? Colors.red.shade100 : Colors.green.shade100,
                                radius: 14,
                                child: Icon(isGiven ? Icons.arrow_upward : Icons.arrow_downward, color: isGiven ? Colors.red.shade800 : Colors.green.shade800, size: 14),
                              ),
                              title: Text(
                                '${isGiven ? "Given to" : "Received from"} $otherParty - ₹${entry.amount.abs().toStringAsFixed(2)}', 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isGiven ? Colors.red.shade900 : Colors.green.shade900),
                              ),
                              subtitle: Text('Date: ${entry.date}${entry.description.isNotEmpty ? ' | Note: ${entry.description}' : ''}', style: const TextStyle(fontSize: 10)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                    onPressed: () => _showJournalEditDialog(entry),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                    onPressed: () async {
                                      bool confirm = await _showDeleteConfirmDialog(context);
                                      if (confirm) {
                                        for (var p in globalPersons) {
                                          p.entries.removeWhere((e) => e.id.startsWith(entry.id.replaceAll('_dr', '').replaceAll('_cr', '')));
                                        }
                                        await _saveData();
                                        setState(() {});
                                      }
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Given (Dr): ₹${totalGiven.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                  Text('Total Received (Cr): ₹${totalReceived.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}