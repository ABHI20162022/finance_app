import 'package:flutter/material.dart';
import '../models/finance_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await loadFinanceDataFromPrefs();
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

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalExpenses = 0;

    for (var person in globalPersons) {
      for (var entry in person.entries) {
        if (_isDateInRange(entry.date)) {
          if (entry.amount > 0) {
            totalIncome += entry.amount;
          } else if (entry.amount < 0) {
            totalExpenses += entry.amount.abs();
          }
        }
      }
    }

    double netBalance = totalIncome - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports & Statements', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.green.shade50,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: fromDateController,
                    decoration: const InputDecoration(
                      labelText: 'From (dd-mm-yyyy)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: toDateController,
                    decoration: const InputDecoration(
                      labelText: 'To (dd-mm-yyyy)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.green.shade700,
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
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
                        color: Colors.red.shade700,
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
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
                  ],
                ),
                const SizedBox(height: 6),
                Card(
                  color: netBalance >= 0 ? Colors.blue.shade700 : Colors.red.shade900,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Overall Net Balance: ₹${netBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      radius: 24,
                      child: const Icon(Icons.arrow_downward, color: Colors.green, size: 28),
                    ),
                    title: const Text('Income Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Total Income & Filtered Statement Tabs', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailedReportTabsScreen(
                            isIncome: true,
                            fromDateStr: fromDateController.text,
                            toDateStr: toDateController.text,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      radius: 24,
                      child: const Icon(Icons.arrow_upward, color: Colors.red, size: 28),
                    ),
                    title: const Text('Expenses Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Total Expenses & Filtered Statement Tabs', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailedReportTabsScreen(
                            isIncome: false,
                            fromDateStr: fromDateController.text,
                            toDateStr: toDateController.text,
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
    );
  }
}

class DetailedReportTabsScreen extends StatefulWidget {
  final bool isIncome;
  final String? fromDateStr;
  final String? toDateStr;

  const DetailedReportTabsScreen({
    super.key,
    required this.isIncome,
    this.fromDateStr,
    this.toDateStr,
  });

  @override
  State<DetailedReportTabsScreen> createState() => _DetailedReportTabsScreenState();
}

class _DetailedReportTabsScreenState extends State<DetailedReportTabsScreen> {
  String selectedPerson = 'All';
  String selectedCategory = 'All';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await loadFinanceDataFromPrefs();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
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
    if ((widget.fromDateStr == null || widget.fromDateStr!.trim().isEmpty) &&
        (widget.toDateStr == null || widget.toDateStr!.trim().isEmpty)) {
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isIncome ? 'Income Report' : 'Expenses Report'),
          backgroundColor: widget.isIncome ? Colors.green.shade700 : Colors.red.shade700,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    List<FinanceItem> statementEntries = [];
    Set<String> personsSet = {'All'};
    Set<String> categoriesSet = {'All'};

    for (var personData in globalPersons) {
      for (var entry in personData.entries) {
        if (_isDateInRange(entry.date)) {
          bool condition = widget.isIncome ? (entry.amount > 0) : (entry.amount < 0);
          if (condition) {
            statementEntries.add(entry);

            if (entry.person.isNotEmpty) {
              personsSet.add(entry.person);
            } else if (personData.name.isNotEmpty) {
              personsSet.add(personData.name);
            }

            if (entry.category.isNotEmpty) {
              categoriesSet.add(entry.category);
            }
          }
        }
      }
    }

    List<String> personsList = personsSet.toList();
    List<String> categoriesList = categoriesSet.toList();

    statementEntries.sort((a, b) {
      DateTime? dtA = _parseDate(a.date);
      DateTime? dtB = _parseDate(b.date);
      if (dtA != null && dtB != null) return dtA.compareTo(dtB);
      return 0;
    });

    if (!personsList.contains(selectedPerson)) {
      selectedPerson = 'All';
    }
    if (!categoriesList.contains(selectedCategory)) {
      selectedCategory = 'All';
    }

    List<FinanceItem> filteredEntries = statementEntries.where((entry) {
      bool matchesPerson = selectedPerson == 'All' || entry.person == selectedPerson;
      bool matchesCategory = selectedCategory == 'All' || entry.category == selectedCategory;
      return matchesPerson && matchesCategory;
    }).toList();

    double totalAmountTab1 = statementEntries.fold(0.0, (sum, e) => sum + e.amount.abs());
    double totalAmountTab2 = filteredEntries.fold(0.0, (sum, e) => sum + e.amount.abs());

    // Calculate Individual Person Totals if a specific person is selected in Tab 2
    double personIncome = 0;
    double personExpense = 0;
    if (selectedPerson != 'All') {
      for (var p in globalPersons) {
        if (p.name == selectedPerson) {
          for (var e in p.entries) {
            if (_isDateInRange(e.date)) {
              if (e.amount > 0) personIncome += e.amount;
              if (e.amount < 0) personExpense += e.amount.abs();
            }
          }
        }
      }
    }
    double personNetBalance = personIncome - personExpense;

    Color themeColor = widget.isIncome ? Colors.green.shade700 : Colors.red.shade700;
    String personLabel = widget.isIncome ? 'Income Person' : 'Expense Person';
    String categoryLabel = widget.isIncome ? 'Income Category' : 'Expense Category';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isIncome ? 'Income Report' : 'Expenses Report'),
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: const Icon(Icons.list_alt), text: widget.isIncome ? 'Total Income' : 'Total Expenses'),
              const Tab(icon: Icon(Icons.filter_list), text: 'Person & Category-wise'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Expanded(
                  child: statementEntries.isEmpty
                      ? Center(child: Text(widget.isIncome ? 'No income records found.' : 'No expense records found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: statementEntries.length,
                          itemBuilder: (context, index) {
                            final item = statementEntries[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(item.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(item.category.isNotEmpty ? item.category : 'General', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        if (item.description.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text('📝 ${item.description}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${item.amount.abs().toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: widget.isIncome ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                                          child: Text('👤 ${item.person}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: widget.isIncome ? Colors.green.shade50 : Colors.red.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.isIncome ? 'Total Income Amount:' : 'Total Expenses Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeColor)),
                      Text('₹${totalAmountTab1.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  color: widget.isIncome ? Colors.green.shade50 : Colors.red.shade50,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedPerson,
                              decoration: InputDecoration(
                                labelText: personLabel,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                fillColor: Colors.white,
                                filled: true,
                                contentPadding: const EdgeInsets.all(8),
                              ),
                              items: personsList.map((String p) {
                                return DropdownMenuItem<String>(value: p, child: Text(p, style: const TextStyle(fontSize: 13)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedPerson = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              decoration: InputDecoration(
                                labelText: categoryLabel,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                fillColor: Colors.white,
                                filled: true,
                                contentPadding: const EdgeInsets.all(8),
                              ),
                              items: categoriesList.map((String c) {
                                return DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedCategory = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (selectedPerson != 'All') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text('Income: ₹${personIncome.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                              Text('Expense: ₹${personExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                              Text('Net: ₹${personNetBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: personNetBalance >= 0 ? Colors.blue : Colors.red)),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                Expanded(
                  child: filteredEntries.isEmpty
                      ? Center(child: Text(widget.isIncome ? 'No matching income records.' : 'No matching expense records.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredEntries.length,
                          itemBuilder: (context, idx) {
                            final item = filteredEntries[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(item.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(item.category.isNotEmpty ? item.category : 'General', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        if (item.description.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text('📝 ${item.description}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${item.amount.abs().toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: widget.isIncome ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                                          child: Text('👤 ${item.person}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: widget.isIncome ? Colors.green.shade50 : Colors.red.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filtered Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeColor)),
                      Text('₹${totalAmountTab2.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}