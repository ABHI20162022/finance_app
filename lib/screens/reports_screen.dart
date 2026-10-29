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
    double totalLoanAmount = 0;

    for (var person in globalPersons) {
      for (var entry in person.entries) {
        if (_isDateInRange(entry.date)) {
          if (entry.amount > 0) {
            totalIncome += entry.amount;
            if (entry.category.toLowerCase().contains('loan') || entry.title.toLowerCase().contains('loan')) {
              totalLoanAmount += entry.amount;
            }
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
          // డేట్ ఫిల్టర్
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

          // ఓవరాల్ సమ్మరీ కార్డ్స్
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
                        Text('Net Balance: ₹${netBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        if (totalLoanAmount > 0)
                          Text('(అప్పు: ₹${totalLoanAmount.toStringAsFixed(0)})', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // మెయిನ್ రిపోర్ట్ & స్టేట్‌మెంట్ నావిగేషన్ కార్డ్స్
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // 1. Income Breakdown
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
                    subtitle: const Text('Category-wise, Person-wise & Net Total', style: TextStyle(fontSize: 13, color: Colors.grey)),
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

                // 2. Expenses Breakdown
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
                    subtitle: const Text('Category-wise, Person-wise & Net Total', style: TextStyle(fontSize: 13, color: Colors.grey)),
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

                // 3. Income Statement
                Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      radius: 24,
                      child: const Icon(Icons.receipt_long, color: Colors.teal, size: 28),
                    ),
                    title: const Text('Income Statement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Date-wise detailed income list with person & category', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatementListScreen(
                            isIncome: true,
                            fromDateStr: fromDateController.text,
                            toDateStr: toDateController.text,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 4. Expenses Statement
                Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      radius: 24,
                      child: Icon(Icons.list_alt, color: Colors.orange.shade800, size: 28),
                    ),
                    title: const Text('Expenses Statement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Date-wise detailed expense list with person & category', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatementListScreen(
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

// -------------------------------------------------------------
// 1. Income & Expenses Statement Screen
// -------------------------------------------------------------
class StatementListScreen extends StatelessWidget {
  final bool isIncome;
  final String? fromDateStr;
  final String? toDateStr;

  const StatementListScreen({
    super.key,
    required this.isIncome,
    this.fromDateStr,
    this.toDateStr,
  });

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
    if ((fromDateStr == null || fromDateStr!.trim().isEmpty) && (toDateStr == null || toDateStr!.trim().isEmpty)) {
      return true;
    }
    DateTime? entryDate = _parseDate(dateStr);
    if (entryDate == null) return true;
    DateTime? fDate = _parseDate(fromDateStr ?? '');
    DateTime? tDate = _parseDate(toDateStr ?? '');
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
    List<FinanceItem> statementEntries = [];

    for (var person in globalPersons) {
      for (var entry in person.entries) {
        if (_isDateInRange(entry.date)) {
          bool condition = isIncome ? (entry.amount > 0) : (entry.amount < 0);
          if (condition) {
            statementEntries.add(entry);
          }
        }
      }
    }

    double totalAmount = statementEntries.fold(0.0, (sum, e) => sum + e.amount.abs());
    Color themeColor = isIncome ? Colors.teal.shade700 : Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(
        title: Text(isIncome ? 'Income Statement' : 'Expenses Statement'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: isIncome ? Colors.teal.shade50 : Colors.orange.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isIncome ? 'Total Income Statement:' : 'Total Expenses Statement:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeColor),
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: statementEntries.isEmpty
                ? Center(child: Text(isIncome ? 'No income statement records found.' : 'No expense statement records found.'))
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
                                      Text(
                                        item.date,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.category.isNotEmpty ? item.category : 'General',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
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
                                      color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '👤 ${item.person}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
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
    );
  }
}

// -------------------------------------------------------------
// 2. Detailed Report Tabs Screen
// -------------------------------------------------------------
class DetailedReportTabsScreen extends StatelessWidget {
  final bool isIncome;
  final String? fromDateStr;
  final String? toDateStr;

  const DetailedReportTabsScreen({
    super.key,
    required this.isIncome,
    this.fromDateStr,
    this.toDateStr,
  });

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
    if ((fromDateStr == null || fromDateStr!.trim().isEmpty) && (toDateStr == null || toDateStr!.trim().isEmpty)) {
      return true;
    }
    DateTime? entryDate = _parseDate(dateStr);
    if (entryDate == null) return true;
    DateTime? fDate = _parseDate(fromDateStr ?? '');
    DateTime? tDate = _parseDate(toDateStr ?? '');
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
    Map<String, double> categoryTotals = {};
    Map<String, List<FinanceItem>> categoryEntries = {};

    Map<String, double> personTotals = {};
    Map<String, List<FinanceItem>> personEntries = {};

    List<FinanceItem> allFilteredEntries = [];

    for (var person in globalPersons) {
      for (var entry in person.entries) {
        if (_isDateInRange(entry.date)) {
          bool condition = isIncome ? (entry.amount > 0) : (entry.amount < 0);
          if (condition) {
            double amt = entry.amount.abs();
            String cat = entry.category.isNotEmpty ? entry.category : 'General';
            String pName = person.name;

            categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amt;
            categoryEntries.putIfAbsent(cat, () => []).add(entry);

            personTotals[pName] = (personTotals[pName] ?? 0) + amt;
            personEntries.putIfAbsent(pName, () => []).add(entry);

            allFilteredEntries.add(entry);
          }
        }
      }
    }

    double netTotal = allFilteredEntries.fold(0.0, (sum, e) => sum + e.amount.abs());
    Color themeColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isIncome ? 'Income Breakdown' : 'Expenses Breakdown'),
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.category), text: 'Category-wise'),
              Tab(icon: Icon(Icons.person), text: 'Person-wise'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Net Total'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGroupedListView(categoryTotals, categoryEntries, isIncome, 'No categories found.'),
            _buildGroupedListView(personTotals, personEntries, isIncome, 'No persons found.'),
            _buildNetTotalView(netTotal, allFilteredEntries, isIncome),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedListView(
    Map<String, double> totalsMap,
    Map<String, List<FinanceItem>> entriesMap,
    bool isInc,
    String emptyMessage,
  ) {
    if (totalsMap.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: totalsMap.length,
      itemBuilder: (context, index) {
        String keyName = totalsMap.keys.elementAt(index);
        double totalAmt = totalsMap[keyName]!;
        List<FinanceItem> entries = entriesMap[keyName]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          child: ExpansionTile(
            title: Text(keyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            trailing: Text(
              '₹${totalAmt.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isInc ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            children: [
              const Divider(height: 1),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, itemIndex) {
                  final item = entries[itemIndex];
                  return ListTile(
                    dense: true,
                    title: Text('📅 ${item.date}  |  👤 ${item.person}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('₹${item.amount.abs().toStringAsFixed(2)}${item.description.isNotEmpty ? ' | 📝 ${item.description}' : ''}'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNetTotalView(double netTotal, List<FinanceItem> entries, bool isInc) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Card(
            color: isInc ? Colors.green.shade50 : Colors.red.shade50,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isInc ? 'Net Total Income:' : 'Net Total Expenses:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isInc ? Colors.green.shade800 : Colors.red.shade800),
                  ),
                  Text(
                    '₹${netTotal.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isInc ? Colors.green.shade800 : Colors.red.shade800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'All Transaction Entries (${entries.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No entries found.'))
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final item = entries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('📅 ${item.date} | 📂 ${item.category}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('👤 ${item.person}${item.description.isNotEmpty ? ' | 📝 ${item.description}' : ''}'),
                          trailing: Text(
                            '₹${item.amount.abs().toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isInc ? Colors.green.shade700 : Colors.red.shade700),
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