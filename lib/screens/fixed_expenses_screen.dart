import 'package:flutter/material.dart';

// --- Payment History Model ---
class PaymentRecord {
  String id;
  double amountPaid;
  String paymentDate; // dd-mm-yyyy
  String note;

  PaymentRecord({
    required this.id,
    required this.amountPaid,
    required this.paymentDate,
    this.note = '',
  });
}

// --- Specific Fee / Expense / Chitti Item Model ---
class FeeItem {
  String id;
  String feeTitle; // e.g., School Fee, Chitti (20 Months)
  double totalAmount; // 0 పెట్టవచ్చు లేదా టోటల్ ఎంచనా వేయవచ్చు
  List<PaymentRecord> paymentHistory;

  FeeItem({
    required this.id,
    required this.feeTitle,
    required this.totalAmount,
    List<PaymentRecord>? paymentHistory,
  }) : paymentHistory = paymentHistory ?? [];

  double get totalPaid {
    return paymentHistory.fold(0.0, (sum, item) => sum + item.amountPaid);
  }

  double get remainingAmount {
    if (totalAmount <= 0) return 0; // టోటల్ లేకపోతే రిమైనింగ్ అవసరం లేదు
    double rem = totalAmount - totalPaid;
    return rem < 0 ? 0 : rem;
  }
}

// --- Person / Child / Scheme Profile Model ---
class PersonProfile {
  String id;
  String personName; // e.g., Rahul / My Chitti Scheme
  List<FeeItem> feeList;

  PersonProfile({
    required this.id,
    required this.personName,
    List<FeeItem>? feeList,
  }) : feeList = feeList ?? [];

  double get totalAmount {
    return feeList.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  double get totalPaid {
    return feeList.fold(0.0, (sum, item) => sum + item.totalPaid);
  }

  double get remainingAmount {
    return feeList.fold(0.0, (sum, item) => sum + item.remainingAmount);
  }
}

class FixedExpensesScreen extends StatefulWidget {
  const FixedExpensesScreen({super.key});

  @override
  State<FixedExpensesScreen> createState() => _FixedExpensesScreenState();
}

class _FixedExpensesScreenState extends State<FixedExpensesScreen> {
  List<PersonProfile> personsList = [];

  void _showPersonDialog({PersonProfile? existingPerson}) {
    final TextEditingController nameController = TextEditingController(
      text: existingPerson?.personName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingPerson == null ? 'Add Profile / Scheme' : 'Edit Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name (e.g. Rahul / Chitti Committee)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    if (existingPerson == null) {
                      personsList.add(
                        PersonProfile(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          personName: nameController.text.trim(),
                        ),
                      );
                    } else {
                      existingPerson.personName = nameController.text.trim();
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(existingPerson == null ? 'Save' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixed Expenses & Chitti Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.shade50,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Add Profile / Chitti Account'),
                    onPressed: () => _showPersonDialog(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: personsList.isEmpty
                ? const Center(
                    child: Text(
                      'No profiles added yet.\nClick "Add Profile" to begin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: personsList.length,
                    itemBuilder: (context, index) {
                      final person = personsList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.indigo.shade100,
                            child: Icon(Icons.account_balance_wallet, color: Colors.indigo.shade800),
                          ),
                          title: Text(
                            person.personName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Items Count: ${person.feeList.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('Total Paid: ₹${person.totalPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _showPersonDialog(existingPerson: person),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() {
                                    personsList.removeAt(index);
                                  });
                                },
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PersonFeesDetailScreen(
                                  person: person,
                                  onStateChanged: () => setState(() {}),
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

// -------------------------------------------------------------
// Detail Screen (చిట్టీ లేదా ఫీజుల ఎంట్రీలు మరియు పేమెంట్స్)
// -------------------------------------------------------------
class PersonFeesDetailScreen extends StatefulWidget {
  final PersonProfile person;
  final VoidCallback onStateChanged;

  const PersonFeesDetailScreen({
    super.key,
    required this.person,
    required this.onStateChanged,
  });

  @override
  State<PersonFeesDetailScreen> createState() => _PersonFeesDetailScreenState();
}

class _PersonFeesDetailScreenState extends State<PersonFeesDetailScreen> {
  void _showFeeDialog({FeeItem? existingFee}) {
    final TextEditingController titleController = TextEditingController(
      text: existingFee?.feeTitle ?? '',
    );
    final TextEditingController totalAmountController = TextEditingController(
      text: existingFee?.totalAmount != null && existingFee!.totalAmount > 0 
          ? existingFee.totalAmount.toStringAsFixed(0) 
          : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingFee == null ? 'Add Item / Chitti Name' : 'Edit Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (e.g., 20 Months Chitti / School Fee)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: totalAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount (Optional / Put 0 if unknown)',
                    hintText: 'e.g. 40000 or leave 0',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  double total = double.tryParse(totalAmountController.text.trim()) ?? 0.0;
                  setState(() {
                    if (existingFee == null) {
                      widget.person.feeList.add(
                        FeeItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          feeTitle: titleController.text.trim(),
                          totalAmount: total,
                        ),
                      );
                    } else {
                      existingFee.feeTitle = titleController.text.trim();
                      existingFee.totalAmount = total;
                    }
                  });
                  widget.onStateChanged();
                  Navigator.pop(context);
                }
              },
              child: Text(existingFee == null ? 'Save' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPaymentDialog(FeeItem item) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController dateController = TextEditingController(text: _getTodayDateString());
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pay Amount - ${item.feeTitle}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid (₹)',
                    hintText: 'e.g. 2000, 2500 etc.',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date (dd-mm-yyyy)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note / Month (e.g., January Month / Installment 1)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () {
                double paidAmt = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (paidAmt > 0) {
                  setState(() {
                    item.paymentHistory.add(
                      PaymentRecord(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        amountPaid: paidAmt,
                        paymentDate: dateController.text.trim(),
                        note: noteController.text.trim(),
                      ),
                    );
                  });
                  widget.onStateChanged();
                  Navigator.pop(context);
                }
              },
              child: const Text('Pay Amount'), // బటన్ పేరు ఇక్కడ Pay Amount గా మార్చబడింది
            ),
          ],
        );
      },
    );
  }

  String _getTodayDateString() {
    DateTime now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.person.personName} - Accounts'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.shade50,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Chitti / Account'),
                    onPressed: () => _showFeeDialog(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.person.feeList.isEmpty
                ? const Center(
                    child: Text(
                      'No Chitti or items added here yet.\nClick above to create one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.person.feeList.length,
                    itemBuilder: (context, index) {
                      final item = widget.person.feeList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item.feeTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                        onPressed: () => _showFeeDialog(existingFee: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            widget.person.feeList.removeAt(index);
                                          });
                                          widget.onStateChanged();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text('Total Entries', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text('${item.paymentHistory.length} Times', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('Total Amount Paid', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text('₹${item.totalPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.history, size: 18),
                                    label: Text('History (${item.paymentHistory.length})'),
                                    onPressed: () => _showHistoryBottomSheet(item),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.payment, size: 18),
                                    label: const Text('Pay Amount'), // ఇక్కడ కూడా Pay Amount గా మార్చబడింది
                                    onPressed: () => _showAddPaymentDialog(item),
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

  void _showHistoryBottomSheet(FeeItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment History - ${item.feeTitle}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const Divider(),
                  item.paymentHistory.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: Text('No payments recorded yet.')),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: item.paymentHistory.length,
                            itemBuilder: (context, idx) {
                              final pay = item.paymentHistory[idx];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.greenAccent,
                                  child: Icon(Icons.check, color: Colors.green),
                                ),
                                title: Text('Paid: ₹${pay.amountPaid.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Date: ${pay.paymentDate} ${pay.note.isNotEmpty ? '| ${pay.note}' : ''}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      item.paymentHistory.removeAt(idx);
                                    });
                                    setSheetState(() {});
                                    widget.onStateChanged();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}