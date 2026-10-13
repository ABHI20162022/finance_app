import 'package:flutter/material.dart';

void main() {
  runApp(const PersonalFinanceApp());
}

class PersonalFinanceApp extends StatelessWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Family Finance Tracker',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      home: const DashboardScreen(),
    );
  }
}

// --- MODELS & GLOBAL DATA ---

List<String> kFamilyMembers = ['Self', 'Spouse'];

class FinanceItem {
  String title; // Description / Name
  double amount;
  String person; // Expense Person (who incurred the expense)
  String paidBy; // Paid By Person or Income Account (who paid the amount)
  String date; // DD-MM-YYYY format

  FinanceItem({
    required this.title,
    required this.amount,
    required this.person,
    required this.paidBy,
    required this.date,
  });
}

class SubCategoryData {
  final String name;
  final List<SubCategoryData> subCategories; 
  final List<FinanceItem> items; 

  SubCategoryData({
    required this.name,
    required this.subCategories,
    required this.items,
  });

  double get totalAmount {
    double sum = 0.0;
    for (var sub in subCategories) {
      sum += sub.totalAmount;
    }
    for (var item in items) {
      sum += item.amount;
    }
    return sum;
  }
}

class MainHeadingData {
  String headingName;
  List<SubCategoryData> subCategories;

  MainHeadingData({required this.headingName, required this.subCategories});

  double get totalAmount {
    double sum = 0.0;
    for (var sub in subCategories) {
      sum += sub.totalAmount;
    }
    return sum;
  }
}

List<MainHeadingData> kMainHeadings = [
  MainHeadingData(
    headingName: 'Expenses',
    subCategories: [
      SubCategoryData(
        name: 'Education',
        subCategories: [
          SubCategoryData(name: 'School Fee', subCategories: [], items: []),
          SubCategoryData(name: 'Uniform', subCategories: [], items: []),
        ],
        items: [],
      ),
      SubCategoryData(
        name: 'Snacks',
        subCategories: [],
        items: [],
      ),
    ],
  ),
  MainHeadingData(
    headingName: 'Incomes',
    subCategories: [
      SubCategoryData(name: 'Salary', subCategories: [], items: []),
    ],
  ),
  MainHeadingData(
    headingName: 'Reports',
    subCategories: [],
  ),
];

// Helper to extract ONLY top-level Income Headings + Family Members for Paid By dropdown
List<String> getAvailablePaidBySources() {
  Set<String> sources = {};
  sources.addAll(kFamilyMembers);

  MainHeadingData? incomeHeading = kMainHeadings.where((h) => h.headingName == 'Incomes').firstOrNull;
  if (incomeHeading != null) {
    for (var sub in incomeHeading.subCategories) {
      sources.add(sub.name);
    }
  }
  return sources.toList();
}

// --- DASHBOARD SCREEN ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Family Finance', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _DashboardMainCard(
                    title: 'Family Members',
                    icon: Icons.people,
                    color: Colors.deepOrange,
                    countText: '${kFamilyMembers.length} Members',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FamilyMembersScreen()),
                      );
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DashboardMainCard(
                    title: 'Headings List',
                    icon: Icons.list_alt,
                    color: Colors.teal,
                    countText: '${kMainHeadings.where((h) => h.headingName != 'Reports').length} Headings',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HeadingsListScreen()),
                      );
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Financial Modules',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: kMainHeadings.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final heading = kMainHeadings[index];
                  
                  if (heading.headingName == 'Reports') {
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReportsMainScreen()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Icon(Icons.bar_chart, color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                heading.headingName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'View Analytics',
                                style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        if (heading.headingName == 'Incomes') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IncomeCategoryScreen(
                                title: heading.headingName,
                                subCategories: heading.subCategories,
                              ),
                            ),
                          );
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DynamicCategoryScreen(
                                title: heading.headingName,
                                subCategories: heading.subCategories,
                              ),
                            ),
                          );
                        }
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: heading.headingName == 'Incomes' ? Colors.green : Colors.indigoAccent,
                              child: Icon(heading.headingName == 'Incomes' ? Icons.account_balance_wallet : Icons.folder, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              heading.headingName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${heading.totalAmount}',
                              style: TextStyle(color: heading.headingName == 'Incomes' ? Colors.green : Colors.indigo, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
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

class _DashboardMainCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String countText;
  final VoidCallback onTap;

  const _DashboardMainCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.countText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(countText, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- FAMILY MEMBERS SCREEN ---
class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  void _addMemberDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Family Member'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter name (e.g., Harika)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  kFamilyMembers.add(controller.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Family Members'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: kFamilyMembers.isEmpty
          ? const Center(child: Text('No family members found.'))
          : ListView.builder(
              itemCount: kFamilyMembers.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.deepOrange,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(kFamilyMembers[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          kFamilyMembers.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMemberDialog,
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('+ Add Member', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// --- HEADINGS LIST SCREEN ---
class HeadingsListScreen extends StatefulWidget {
  const HeadingsListScreen({super.key});

  @override
  State<HeadingsListScreen> createState() => _HeadingsListScreenState();
}

class _HeadingsListScreenState extends State<HeadingsListScreen> {
  void _addHeadingDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Heading'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter title (e.g., Medical)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  int reportIndex = kMainHeadings.indexWhere((h) => h.headingName == 'Reports');
                  if (reportIndex != -1) {
                    kMainHeadings.insert(reportIndex, MainHeadingData(headingName: controller.text, subCategories: []));
                  } else {
                    kMainHeadings.add(MainHeadingData(headingName: controller.text, subCategories: []));
                  }
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

  @override
  Widget build(BuildContext context) {
    final listHeadings = kMainHeadings.where((h) => h.headingName != 'Reports').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Headings'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: listHeadings.length,
        itemBuilder: (context, index) {
          final heading = listHeadings[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: heading.headingName == 'Incomes' ? Colors.green : Colors.teal,
                child: Icon(heading.headingName == 'Incomes' ? Icons.account_balance_wallet : Icons.folder, color: Colors.white),
              ),
              title: Text(heading.headingName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('${heading.subCategories.length} Sub-categories'),
              trailing: heading.headingName == 'Incomes' || heading.headingName == 'Expenses'
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          kMainHeadings.remove(heading);
                        });
                      },
                    ),
              onTap: () async {
                if (heading.headingName == 'Incomes') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IncomeCategoryScreen(
                        title: heading.headingName,
                        subCategories: heading.subCategories,
                      ),
                    ),
                  );
                } else {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DynamicCategoryScreen(
                        title: heading.headingName,
                        subCategories: heading.subCategories,
                      ),
                    ),
                  );
                }
                setState(() {});
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHeadingDialog,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('+ Add Heading', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// --- INCOME CATEGORY SCREEN ---
class IncomeCategoryScreen extends StatefulWidget {
  final String title;
  final List<SubCategoryData> subCategories;

  const IncomeCategoryScreen({
    super.key,
    required this.title,
    required this.subCategories,
  });

  @override
  State<IncomeCategoryScreen> createState() => _IncomeCategoryScreenState();
}

class _IncomeCategoryScreenState extends State<IncomeCategoryScreen> {
  void _addSubCategoryDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Income Type (e.g., Salary, Rental)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter income type name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.subCategories.add(
                    SubCategoryData(name: controller.text, subCategories: [], items: []),
                  );
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

  @override
  Widget build(BuildContext context) {
    double totalSum = widget.subCategories.fold(0.0, (sum, sub) => sum + sub.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Total: ₹$totalSum',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.yellowAccent),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _addSubCategoryDialog,
                icon: const Icon(Icons.add),
                label: const Text('+ Add Sub-category'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: widget.subCategories.isEmpty
                ? const Center(
                    child: Text(
                      'No income types found.\nClick "+ Add Sub-category" above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.subCategories.length,
                    itemBuilder: (context, index) {
                      final sub = widget.subCategories[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.account_balance_wallet, color: Colors.white),
                          ),
                          title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Total: ₹${sub.totalAmount}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    widget.subCategories.removeAt(index);
                                  });
                                },
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IncomeDetailScreen(categoryData: sub),
                              ),
                            );
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubCategoryDialog,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('+ Add', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// --- INCOME DETAIL SCREEN ---
class IncomeDetailScreen extends StatefulWidget {
  final SubCategoryData categoryData;

  const IncomeDetailScreen({super.key, required this.categoryData});

  @override
  State<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends State<IncomeDetailScreen> {
  void _showAddEntryDialog() {
    List<String> sources = getAvailablePaidBySources();
    String selectedSource = sources.isNotEmpty ? sources[0] : 'Self';
    TextEditingController descController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    DateTime now = DateTime.now();
    String currentDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    TextEditingController dateController = TextEditingController(text: currentDate);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Add Income under ${widget.categoryData.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: sources.contains(selectedSource) ? selectedSource : sources[0],
                    decoration: const InputDecoration(labelText: 'Paid By / Source', border: OutlineInputBorder()),
                    items: sources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedSource = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description / Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Date (DD-MM-YYYY)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (descController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    double? parsedAmount = double.tryParse(amountController.text);
                    if (parsedAmount != null) {
                      setState(() {
                        widget.categoryData.items.add(
                          FinanceItem(
                            title: descController.text,
                            amount: parsedAmount,
                            person: selectedSource,
                            paidBy: selectedSource,
                            date: dateController.text,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditEntryDialog(FinanceItem item) {
    List<String> sources = getAvailablePaidBySources();
    String selectedSource = sources.contains(item.paidBy) ? item.paidBy : (sources.isNotEmpty ? sources[0] : 'Self');

    TextEditingController descController = TextEditingController(text: item.title);
    TextEditingController amountController = TextEditingController(text: item.amount.toString());
    TextEditingController dateController = TextEditingController(text: item.date);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Income Entry'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedSource,
                    decoration: const InputDecoration(labelText: 'Paid By / Source', border: OutlineInputBorder()),
                    items: sources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedSource = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description / Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Date (DD-MM-YYYY)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (descController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    double? parsedAmount = double.tryParse(amountController.text);
                    if (parsedAmount != null) {
                      setState(() {
                        item.title = descController.text;
                        item.amount = parsedAmount;
                        item.person = selectedSource;
                        item.paidBy = selectedSource;
                        item.date = dateController.text;
                      });
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasItems = widget.categoryData.items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryData.name),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Total: ₹${widget.categoryData.totalAmount}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.yellowAccent),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: !hasItems
                ? Center(
                    child: Text(
                      'No income entries under ${widget.categoryData.name}.\nClick "+ Add" below.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.categoryData.items.length,
                    itemBuilder: (context, index) {
                      FinanceItem item = widget.categoryData.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.currency_rupee, color: Colors.white),
                          ),
                          title: Text('Date: ${item.date}  |  By: ${item.paidBy}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Name: ${item.title}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('₹${item.amount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _showEditEntryDialog(item);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    widget.categoryData.items.removeAt(index);
                                  });
                                },
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntryDialog,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('+ Add', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// --- DYNAMIC CATEGORY SCREEN (For Custom Headings & Expenses) ---
class DynamicCategoryScreen extends StatefulWidget {
  final String title;
  final List<SubCategoryData> subCategories;

  const DynamicCategoryScreen({
    super.key,
    required this.title,
    required this.subCategories,
  });

  @override
  State<DynamicCategoryScreen> createState() => _DynamicCategoryScreenState();
}

class _DynamicCategoryScreenState extends State<DynamicCategoryScreen> {
  void _addSubCategoryDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Sub-Category under ${widget.title}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.subCategories.add(
                    SubCategoryData(name: controller.text, subCategories: [], items: []),
                  );
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

  @override
  Widget build(BuildContext context) {
    double totalSum = widget.subCategories.fold(0.0, (sum, sub) => sum + sub.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Total: ₹$totalSum',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.yellowAccent),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _addSubCategoryDialog,
                icon: const Icon(Icons.add),
                label: const Text('+ Sub-category'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: widget.subCategories.isEmpty
                ? const Center(child: Text('No sub-categories found.'))
                : ListView.builder(
                    itemCount: widget.subCategories.length,
                    itemBuilder: (context, index) {
                      final sub = widget.subCategories[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Total: ₹${sub.totalAmount}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    widget.subCategories.removeAt(index);
                                  });
                                },
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubCategoryDetailScreen(categoryData: sub),
                              ),
                            );
                            setState(() {});
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

// --- SUB-CATEGORY DETAIL SCREEN ---
class SubCategoryDetailScreen extends StatefulWidget {
  final SubCategoryData categoryData;

  const SubCategoryDetailScreen({super.key, required this.categoryData});

  @override
  State<SubCategoryDetailScreen> createState() => _SubCategoryDetailScreenState();
}

class _SubCategoryDetailScreenState extends State<SubCategoryDetailScreen> {
  void _addSubCategoryDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Sub-Category under ${widget.categoryData.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.categoryData.subCategories.add(
                    SubCategoryData(name: controller.text, subCategories: [], items: []),
                  );
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

  void _showAddEntryDialog() {
    String selectedMember = kFamilyMembers.isNotEmpty ? kFamilyMembers[0] : 'Self';
    List<String> paidBySources = getAvailablePaidBySources();
    String selectedPaidBy = paidBySources.contains(selectedMember) ? selectedMember : (paidBySources.isNotEmpty ? paidBySources[0] : 'Self');

    TextEditingController descController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    DateTime now = DateTime.now();
    String currentDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    TextEditingController dateController = TextEditingController(text: currentDate);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Add Entry under ${widget.categoryData.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: kFamilyMembers.contains(selectedMember) ? selectedMember : (kFamilyMembers.isNotEmpty ? kFamilyMembers[0] : 'Self'),
                    decoration: const InputDecoration(labelText: 'Family Member', border: OutlineInputBorder()),
                    items: kFamilyMembers.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedMember = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Name / Description', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (DD-MM-YYYY)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: paidBySources.contains(selectedPaidBy) ? selectedPaidBy : paidBySources[0],
                    decoration: const InputDecoration(labelText: 'Paid By (Account / Source)', border: OutlineInputBorder()),
                    items: paidBySources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedPaidBy = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (descController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    double? amt = double.tryParse(amountController.text);
                    if (amt != null) {
                      setState(() {
                        widget.categoryData.items.add(FinanceItem(
                          title: descController.text,
                          amount: amt,
                          person: selectedMember,
                          paidBy: selectedPaidBy,
                          date: dateController.text,
                        ));
                      });
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditEntryDialog(FinanceItem item) {
    String selectedMember = kFamilyMembers.contains(item.person) ? item.person : (kFamilyMembers.isNotEmpty ? kFamilyMembers[0] : 'Self');
    List<String> paidBySources = getAvailablePaidBySources();
    String selectedPaidBy = paidBySources.contains(item.paidBy) ? item.paidBy : (paidBySources.isNotEmpty ? paidBySources[0] : 'Self');

    TextEditingController descController = TextEditingController(text: item.title);
    TextEditingController amountController = TextEditingController(text: item.amount.toString());
    TextEditingController dateController = TextEditingController(text: item.date);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Entry'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedMember,
                    decoration: const InputDecoration(labelText: 'Family Member', border: OutlineInputBorder()),
                    items: kFamilyMembers.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedMember = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Name / Description', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (DD-MM-YYYY)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPaidBy,
                    decoration: const InputDecoration(labelText: 'Paid By (Account / Source)', border: OutlineInputBorder()),
                    items: paidBySources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedPaidBy = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (descController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    double? amt = double.tryParse(amountController.text);
                    if (amt != null) {
                      setState(() {
                        item.title = descController.text;
                        item.amount = amt;
                        item.person = selectedMember;
                        item.paidBy = selectedPaidBy;
                        item.date = dateController.text;
                      });
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryData.name), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: _addSubCategoryDialog, icon: const Icon(Icons.add), label: const Text('+ Sub-category'), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton.icon(onPressed: _showAddEntryDialog, icon: const Icon(Icons.add), label: const Text('+ Entry'), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ...widget.categoryData.subCategories.asMap().entries.map((e) => Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Total: ₹${e.value.totalAmount}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => SubCategoryDetailScreen(categoryData: e.value)));
                      setState(() {});
                    },
                  ),
                )),
                ...widget.categoryData.items.asMap().entries.map((e) {
                  FinanceItem item = e.value;
                  String titleText = 'Date: ${item.date}  |  ${item.person}';
                  if (item.person != item.paidBy) {
                    titleText += '  |  By: ${item.paidBy}';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
                      subtitle: Text('Name: ${item.title}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${item.amount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16)),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showEditEntryDialog(item)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => widget.categoryData.items.removeAt(e.key))),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- REPORTS MAIN SCREEN ---
class ReportsMainScreen extends StatelessWidget {
  const ReportsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportableHeadings = kMainHeadings.where((h) => h.headingName != 'Reports').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: reportableHeadings.length,
        itemBuilder: (context, index) {
          final heading = reportableHeadings[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: heading.headingName == 'Incomes' ? Colors.green : Colors.indigoAccent,
                child: Icon(heading.headingName == 'Incomes' ? Icons.account_balance_wallet : Icons.folder, color: Colors.white),
              ),
              title: Text(heading.headingName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('Total: ₹${heading.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HeadingReportDetailScreen(headingData: heading),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- HEADING REPORT DETAIL SCREEN ---
class HeadingReportDetailScreen extends StatefulWidget {
  final MainHeadingData headingData;

  const HeadingReportDetailScreen({super.key, required this.headingData});

  @override
  State<HeadingReportDetailScreen> createState() => _HeadingReportDetailScreenState();
}

class _HeadingReportDetailScreenState extends State<HeadingReportDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String? fromDateStr;
  String? toDateStr;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  DateTime? _parseDate(String dateStr) {
    try {
      List<String> parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}
    return null;
  }

  bool _isDateInRange(String itemDateStr) {
    if (fromDateStr == null && toDateStr == null) return true;
    DateTime? itemDate = _parseDate(itemDateStr);
    if (itemDate == null) return true;

    if (fromDateStr != null && fromDateStr!.isNotEmpty) {
      DateTime? fromDate = _parseDate(fromDateStr!);
      if (fromDate != null && itemDate.isBefore(fromDate)) return false;
    }

    if (toDateStr != null && toDateStr!.isNotEmpty) {
      DateTime? toDate = _parseDate(toDateStr!);
      if (toDate != null && itemDate.isAfter(toDate)) return false;
    }

    return true;
  }

  List<FinanceItem> _getAllItems(List<SubCategoryData> subs) {
    List<FinanceItem> list = [];
    for (var sub in subs) {
      for (var item in sub.items) {
        if (_isDateInRange(item.date)) {
          list.add(item);
        }
      }
      list.addAll(_getAllItems(sub.subCategories));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    List<FinanceItem> filteredItems = _getAllItems(widget.headingData.subCategories);
    double filteredTotalAmount = filteredItems.fold(0.0, (sum, item) => sum + item.amount);

    // For Member Wise tab, we want all Family Members as primary filters, plus any other paidBy sources if needed
    List<String> allMembers = List.from(kFamilyMembers);
    List<String> allSources = getAvailablePaidBySources();
    for (var src in allSources) {
      if (!allMembers.contains(src)) {
        allMembers.add(src);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.headingData.headingName} Reports'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.yellowAccent,
          labelColor: Colors.yellowAccent,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Item Wise'),
            Tab(text: 'Member Wise'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.indigo.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total ${widget.headingData.headingName}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('₹$filteredTotalAmount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'From (DD-MM-YYYY)', border: OutlineInputBorder(), isDense: true),
                    controller: TextEditingController(text: fromDateStr),
                    onChanged: (val) => setState(() => fromDateStr = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'To (DD-MM-YYYY)', border: OutlineInputBorder(), isDense: true),
                    controller: TextEditingController(text: toDateStr),
                    onChanged: (val) => setState(() => toDateStr = val),
                  ),
                ),
                if ((fromDateStr != null && fromDateStr!.isNotEmpty) || (toDateStr != null && toDateStr!.isNotEmpty))
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () => setState(() {
                      fromDateStr = null;
                      toDateStr = null;
                    }),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. ITEM WISE
                widget.headingData.subCategories.isEmpty
                    ? const Center(child: Text('No categories found.'))
                    : ListView.builder(
                        itemCount: widget.headingData.subCategories.length,
                        itemBuilder: (context, index) {
                          SubCategoryData subCat = widget.headingData.subCategories[index];
                          return _ReportSubCategoryTile(subCategory: subCat, dateChecker: _isDateInRange);
                        },
                      ),

                // 2. MEMBER WISE (Grouped by Expense Person 'person' for display, but tracked against 'paidBy' for deduction)
                allMembers.isEmpty
                    ? const Center(child: Text('No members found.'))
                    : ListView.builder(
                        itemCount: allMembers.length,
                        itemBuilder: (context, index) {
                          String memberName = allMembers[index];
                          
                          List<Widget> subCategoryWidgets = [];
                          double memberTotal = 0.0;

                          for (var subCat in widget.headingData.subCategories) {
                            Widget? renderedSub = _buildMemberSubCategoryTree(subCat, memberName, _isDateInRange);
                            if (renderedSub != null) {
                              subCategoryWidgets.add(renderedSub);
                              memberTotal += _calculateMemberSubTotal(subCat, memberName, _isDateInRange);
                            }
                          }

                          if (memberTotal == 0) return const SizedBox.shrink();

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ExpansionTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.deepOrange,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Text('Total: ₹$memberTotal (Deducted from Paid By)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12)),
                              children: subCategoryWidgets,
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMemberSubTotal(SubCategoryData sub, String memberName, bool Function(String) checker) {
    // Member wise report groups by 'person' (who incurred the expense)
    double sum = sub.items.where((i) => i.person == memberName && checker(i.date)).fold(0.0, (s, i) => s + i.amount);
    for (var n in sub.subCategories) {
      sum += _calculateMemberSubTotal(n, memberName, checker);
    }
    return sum;
  }

  Widget? _buildMemberSubCategoryTree(SubCategoryData sub, String memberName, bool Function(String) checker) {
    List<FinanceItem> filteredItems = sub.items.where((i) => i.person == memberName && checker(i.date)).toList();
    List<Widget> nestedWidgets = [];
    double nestedTotal = 0.0;

    for (var nSub in sub.subCategories) {
      Widget? builtNested = _buildMemberSubCategoryTree(nSub, memberName, checker);
      if (builtNested != null) {
        nestedWidgets.add(builtNested);
        nestedTotal += _calculateMemberSubTotal(nSub, memberName, checker);
      }
    }

    double itemsTotal = filteredItems.fold(0.0, (sum, i) => sum + i.amount);
    double totalAmt = itemsTotal + nestedTotal;

    if (totalAmt == 0) return null;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4.0),
      child: ExpansionTile(
        leading: const Icon(Icons.folder_open, color: Colors.indigo, size: 20),
        title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: Text('₹$totalAmt', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        children: [
          ...nestedWidgets,
          ...filteredItems.map((item) {
            String titleText = 'Date: ${item.date}  |  ${item.person}';
            if (item.person != item.paidBy) {
              titleText += '  |  By: ${item.paidBy}';
            }

            return ListTile(
              dense: true,
              title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
              subtitle: Text('Name: ${item.title}'),
              trailing: Text('₹${item.amount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            );
          }),
        ],
      ),
    );
  }
}

// Helper widget to recursively render Sub-Categories and HIDE if total amount in date range is 0
class _ReportSubCategoryTile extends StatelessWidget {
  final SubCategoryData subCategory;
  final bool Function(String) dateChecker;

  const _ReportSubCategoryTile({required this.subCategory, required this.dateChecker});

  double _calculateSubTotal(SubCategoryData sub, bool Function(String) checker) {
    double sum = sub.items.where((i) => checker(i.date)).fold(0.0, (s, i) => s + i.amount);
    for (var n in sub.subCategories) {
      sum += _calculateSubTotal(n, checker);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    List<FinanceItem> filteredItems = subCategory.items.where((i) => dateChecker(i.date)).toList();

    List<Widget> nestedWidgets = [];
    double nestedTotal = 0.0;

    for (var nestedSub in subCategory.subCategories) {
      double calculatedSubTotal = _calculateSubTotal(nestedSub, dateChecker);
      if (calculatedSubTotal > 0) {
        nestedTotal += calculatedSubTotal;
        nestedWidgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: _ReportSubCategoryTile(subCategory: nestedSub, dateChecker: dateChecker),
          ),
        );
      }
    }

    double itemsTotal = filteredItems.fold(0.0, (sum, i) => sum + i.amount);
    double totalSubCategoryAmount = itemsTotal + nestedTotal;

    if (totalSubCategoryAmount == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        leading: const Icon(Icons.folder, color: Colors.indigo),
        title: Text(subCategory.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: Text('₹$totalSubCategoryAmount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16)),
        children: [
          ...nestedWidgets,
          ...filteredItems.map((item) {
            String titleText = 'Date: ${item.date}  |  ${item.person}';
            if (item.person != item.paidBy) {
              titleText += '  |  By: ${item.paidBy}';
            }

            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
              subtitle: Text('Name: ${item.title}'),
              trailing: Text('₹${item.amount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            );
          }),
        ],
      ),
    );
  }
}
