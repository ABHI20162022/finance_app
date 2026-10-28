import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Data Models ---
class ShoppingItem {
  String id;
  String name;
  String unitType; // Cycles: 'Weight (Kg/g)' -> 'Pocket' -> 'Number (No)'
  bool isSelected;
  String qtyText;
  double rate;
  double amount;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.unitType,
    this.isSelected = false,
    this.qtyText = '',
    this.rate = 0.0,
    this.amount = 0.0,
  });

  void toggleUnitType() {
    if (unitType == 'Weight (Kg/g)') {
      unitType = 'Pocket';
    } else if (unitType == 'Pocket') {
      unitType = 'Number (No)';
    } else {
      unitType = 'Weight (Kg/g)';
    }
  }

  void calculateAmount() {
    double qtyVal = _parseQty(qtyText, unitType);
    amount = qtyVal * rate;
  }

  // Universal Smart Parser Logic for Weight, Pocket, and Number
  double _parseQty(String text, String type) {
    text = text.trim().toLowerCase();
    if (text.isEmpty) return 0.0;
    if (type == 'Pocket' || type == 'Number (No)') {
      if (text.contains('*') || text.contains('x')) {
        List<String> parts = text.split(RegExp(r'[*x]'));
        return double.tryParse(parts[0].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.0;
      }
      String cleanNumStr = text.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanNumStr) ?? 0.0;
    }
    if (text.contains('*') || text.contains('x')) {
      List<String> parts = text.split(RegExp(r'[*x]'));
      if (parts.length == 2) {
        double count = double.tryParse(parts[0].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.0;
        double subQty = _parseSingleWeightQty(parts[1]);
        return count * subQty;
      }
    }
    return _parseSingleWeightQty(text);
  }

  double _parseSingleWeightQty(String text) {
    text = text.trim().toLowerCase();
    if (text.isEmpty) return 0.0;
    if (text == '1/2' || text == 'half') return 0.5;
    if (text == '1/4') return 0.25;
    if (text == '3/4') return 0.75;
    if (text.contains('kg')) {
      String numStr = text.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(numStr) ?? 0.0;
    }
    if (text.contains('gm') || text.contains('g')) {
      String numStr = text.replaceAll(RegExp(r'[^0-9.]'), '');
      double grams = double.tryParse(numStr) ?? 0.0;
      return grams / 1000.0;
    }
    String cleanNumStr = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanNumStr) ?? 0.0;
  }
}

class CategoryModel {
  String id;
  String name;
  List<ShoppingItem> items;
  CategoryModel({required this.id, required this.name, required this.items});
}

class ShopModel {
  String id;
  String name;
  ShopModel({required this.id, required this.name});
}

class RequiredListEntry {
  String id;
  String date;
  String? shopName;
  String? categoryName;
  List<ShoppingItem> selectedItems;
  double grandTotal;
  RequiredListEntry({
    required this.id,
    required this.date,
    this.shopName,
    this.categoryName,
    required this.selectedItems,
    required this.grandTotal,
  });
}

// Global shared lists
List<CategoryModel> globalCategories = [
  CategoryModel(
    id: '1',
    name: 'Groceries (కిరాణా)',
    items: [
      ShoppingItem(id: '101', name: 'Rice', unitType: 'Weight (Kg/g)'),
      ShoppingItem(id: '102', name: 'Dal', unitType: 'Weight (Kg/g)'),
    ],
  ),
  CategoryModel(
    id: '2',
    name: 'Vegetables (కూరగాయలు)',
    items: [
      ShoppingItem(id: '201', name: 'Tomato', unitType: 'Weight (Kg/g)'),
    ],
  ),
];

List<ShopModel> globalShops = [
  ShopModel(id: '1', name: 'Reliance Fresh'),
  ShopModel(id: '2', name: 'D-Mart'),
  ShopModel(id: '3', name: 'Local Rythu Bazar'),
];

List<RequiredListEntry> globalRequiredLists = [];

// Local Storage Helpers for Shopping
Future<void> saveShoppingDataToPrefs() async {
  final prefs = await SharedPreferences.getInstance();

  // 1. Categories
  List<Map<String, dynamic>> catData = globalCategories.map((c) => {
    'id': c.id,
    'name': c.name,
    'items': c.items.map((i) => {
      'id': i.id,
      'name': i.name,
      'unitType': i.unitType,
    }).toList(),
  }).toList();
  await prefs.setString('saved_shopping_categories', jsonEncode(catData));

  // 2. Shops
  List<Map<String, dynamic>> shopData = globalShops.map((s) => {
    'id': s.id,
    'name': s.name,
  }).toList();
  await prefs.setString('saved_shopping_shops', jsonEncode(shopData));

  // 3. Required Lists
  List<Map<String, dynamic>> reqData = globalRequiredLists.map((r) => {
    'id': r.id,
    'date': r.date,
    'shopName': r.shopName,
    'categoryName': r.categoryName,
    'grandTotal': r.grandTotal,
    'selectedItems': r.selectedItems.map((i) => {
      'id': i.id,
      'name': i.name,
      'unitType': i.unitType,
      'isSelected': i.isSelected,
      'qtyText': i.qtyText,
      'rate': i.rate,
      'amount': i.amount,
    }).toList(),
  }).toList();
  await prefs.setString('saved_shopping_required_lists', jsonEncode(reqData));
}

Future<void> loadShoppingDataFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();

  // 1. Categories Load
  String? catStr = prefs.getString('saved_shopping_categories');
  if (catStr != null) {
    List<dynamic> decodedCats = jsonDecode(catStr);
    globalCategories = decodedCats.map((cMap) {
      var itemsList = (cMap['items'] as List? ?? []).map((iMap) => ShoppingItem(
        id: iMap['id'],
        name: iMap['name'],
        unitType: iMap['unitType'],
      )).toList();
      return CategoryModel(id: cMap['id'], name: cMap['name'], items: itemsList);
    }).toList();
  }

  // 2. Shops Load
  String? shopStr = prefs.getString('saved_shopping_shops');
  if (shopStr != null) {
    List<dynamic> decodedShops = jsonDecode(shopStr);
    globalShops = decodedShops.map((sMap) => ShopModel(id: sMap['id'], name: sMap['name'])).toList();
  }

  // 3. Required Lists Load
  String? reqStr = prefs.getString('saved_shopping_required_lists');
  if (reqStr != null) {
    List<dynamic> decodedReqs = jsonDecode(reqStr);
    globalRequiredLists = decodedReqs.map((rMap) {
      var selItems = (rMap['selectedItems'] as List? ?? []).map((iMap) => ShoppingItem(
        id: iMap['id'],
        name: iMap['name'],
        unitType: iMap['unitType'],
        isSelected: iMap['isSelected'] ?? false,
        qtyText: iMap['qtyText'] ?? '',
        rate: (iMap['rate'] as num).toDouble(),
        amount: (iMap['amount'] as num).toDouble(),
      )).toList();
      return RequiredListEntry(
        id: rMap['id'],
        date: rMap['date'],
        shopName: rMap['shopName'],
        categoryName: rMap['categoryName'],
        grandTotal: (rMap['grandTotal'] as num).toDouble(),
        selectedItems: selItems,
      );
    }).toList();
  }
}

// --- Main Shopping Dashboard Screen ---
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await loadShoppingDataFromPrefs();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Management'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardCard(
            context,
            title: 'Item List & Categories',
            subtitle: 'Add categories, items with continuous entry, edit/delete',
            icon: Icons.list_alt,
            color: Colors.orange,
            destination: const CategoriesScreen(),
          ),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            title: 'Shop Name / Selection',
            subtitle: 'Manage shops with add, edit or delete',
            icon: Icons.store,
            color: Colors.blue,
            destination: const ShopSelectionScreen(),
          ),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            title: 'Required Items (To-Buy List)',
            subtitle: 'Create and manage your required shopping lists',
            icon: Icons.check_box,
            color: Colors.green,
            destination: const RequiredItemsScreen(),
          ),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            title: 'Rate Comparison List',
            subtitle: 'Compare item rates',
            icon: Icons.compare_arrows, // ఎర్రర్ రాకుండా ఇక్కడ మార్చబడింది
            color: Colors.purple,
            destination: const RateComparisonScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          ).then((_) => setState(() {}));
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Screen 1: Categories & Items Management ---
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  void _openCategoryDialog({CategoryModel? editingCategory}) {
    TextEditingController catController = TextEditingController(text: editingCategory?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editingCategory == null ? 'Add Category' : 'Edit Category'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (catController.text.isNotEmpty) {
                setState(() {
                  if (editingCategory != null) {
                    editingCategory.name = catController.text;
                  } else {
                    globalCategories.add(CategoryModel(
                      id: DateTime.now().toString(),
                      name: catController.text,
                      items: [],
                    ));
                  }
                });
                await saveShoppingDataToPrefs();
                Navigator.pop(context);
              }
            },
            child: Text(editingCategory == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Categories & Lists'),
        backgroundColor: Colors.orange,
      ),
      body: ListView.builder(
        itemCount: globalCategories.length,
        itemBuilder: (context, index) {
          final cat = globalCategories[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.folder, color: Colors.orange),
              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${cat.items.length} items'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _openCategoryDialog(editingCategory: cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      setState(() {
                        globalCategories.removeAt(index);
                      });
                      await saveShoppingDataToPrefs();
                    },
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryItemsDetailScreen(category: cat),
                  ),
                ).then((_) async {
                  await saveShoppingDataToPrefs();
                  setState(() {});
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryDialog(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }
}

// --- Screen 2: Items Inside Category ---
class CategoryItemsDetailScreen extends StatefulWidget {
  final CategoryModel category;
  const CategoryItemsDetailScreen({super.key, required this.category});

  @override
  State<CategoryItemsDetailScreen> createState() => _CategoryItemsDetailScreenState();
}

class _CategoryItemsDetailScreenState extends State<CategoryItemsDetailScreen> {
  void _openAddItemDialog({ShoppingItem? editingItem}) {
    final nameController = TextEditingController(text: editingItem?.name ?? '');
    String selectedUnit = editingItem?.unitType ?? 'Weight (Kg/g)';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(editingItem == null ? 'Add Item (Continuous)' : 'Edit Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Item Name'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: const InputDecoration(labelText: 'Select Unit Type'),
                      items: const [
                        DropdownMenuItem(value: 'Weight (Kg/g)', child: Text('Weight (Kg / g)')),
                        DropdownMenuItem(value: 'Pocket', child: Text('Pocket')),
                        DropdownMenuItem(value: 'Number (No)', child: Text('Number (No)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          dialogSetState(() => selectedUnit = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        if (editingItem != null) {
                          editingItem.name = nameController.text;
                          editingItem.unitType = selectedUnit;
                          Navigator.pop(context);
                        } else {
                          widget.category.items.add(ShoppingItem(
                            id: DateTime.now().toString(),
                            name: nameController.text,
                            unitType: selectedUnit,
                          ));
                          nameController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Item added! Add another or click Cancel.')),
                          );
                        }
                      });
                      await saveShoppingDataToPrefs();
                    }
                  },
                  child: Text(editingItem == null ? 'Add & Continue' : 'Save'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: Colors.orange,
      ),
      body: widget.category.items.isEmpty
          ? const Center(child: Text('No items added yet. Click + Add Item.'))
          : ListView.builder(
              itemCount: widget.category.items.length,
              itemBuilder: (context, index) {
                final item = widget.category.items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Type: ${item.unitType}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _openAddItemDialog(editingItem: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            setState(() {
                              widget.category.items.removeAt(index);
                            });
                            await saveShoppingDataToPrefs();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddItemDialog(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}

// --- Screen 3: Shop Selection Screen ---
class ShopSelectionScreen extends StatefulWidget {
  const ShopSelectionScreen({super.key});

  @override
  State<ShopSelectionScreen> createState() => _ShopSelectionScreenState();
}

class _ShopSelectionScreenState extends State<ShopSelectionScreen> {
  void _openShopDialog({ShopModel? editingShop}) {
    TextEditingController shopController = TextEditingController(text: editingShop?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editingShop == null ? 'Add Shop' : 'Edit Shop'),
        content: TextField(
          controller: shopController,
          decoration: const InputDecoration(labelText: 'Shop Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (shopController.text.isNotEmpty) {
                setState(() {
                  if (editingShop != null) {
                    editingShop.name = shopController.text;
                  } else {
                    globalShops.add(ShopModel(
                      id: DateTime.now().toString(),
                      name: shopController.text,
                    ));
                  }
                });
                await saveShoppingDataToPrefs();
                Navigator.pop(context);
              }
            },
            child: Text(editingShop == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Management'),
        backgroundColor: Colors.blue,
      ),
      body: globalShops.isEmpty
          ? const Center(child: Text('No shops added yet. Click + Add Shop.'))
          : ListView.builder(
              itemCount: globalShops.length,
              itemBuilder: (context, index) {
                final shop = globalShops[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.store, color: Colors.blue),
                    title: Text(shop.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _openShopDialog(editingShop: shop),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            setState(() {
                              globalShops.removeAt(index);
                            });
                            await saveShoppingDataToPrefs();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openShopDialog(),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Add Shop'),
      ),
    );
  }
}

// --- Screen 4: Required Items / To-Buy List Screen ---
class RequiredItemsScreen extends StatefulWidget {
  const RequiredItemsScreen({super.key});

  @override
  State<RequiredItemsScreen> createState() => _RequiredItemsScreenState();
}

class _RequiredItemsScreenState extends State<RequiredItemsScreen> {
  String _getListText(RequiredListEntry entry) {
    String text = "========================================\n";
    text += "         SHOPPING BILL REPORT         \n";
    text += "========================================\n";
    text += "Date : ${entry.date}\n";
    text += "Shop : ${entry.shopName ?? 'N/A'}\n";
    text += "----------------------------------------\n";
    text += "Item Name          Qty & Unit    Amount\n";
    text += "----------------------------------------\n";
    for (var item in entry.selectedItems) {
      String name = item.name.padRight(18, ' ');
      String qty = "${item.qtyText} (${item.unitType})".padRight(14, ' ');
      String amt = "₹${item.amount.toStringAsFixed(2)}";
      text += "$name $qty $amt\n";
    }
    text += "----------------------------------------\n";
    text += "GRAND TOTAL: ₹${entry.grandTotal.toStringAsFixed(2)}\n";
    text += "========================================\n";
    return text;
  }

  void _shareList(RequiredListEntry entry) {
    String listText = _getListText(entry);
    Clipboard.setData(ClipboardData(text: listText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('List copied! You can paste and share on WhatsApp/Messages.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _openNotepadDialog(RequiredListEntry entry) {
    String listText = _getListText(entry);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.edit_note, color: Colors.purple),
            SizedBox(width: 8),
            Text('Notepad / Bill Viewer'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            border: Border.all(color: Colors.brown.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              listText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: listText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bill text copied successfully! Ready to paste into Word/Notepad.'),
                  backgroundColor: Colors.purple,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Required Lists'),
        backgroundColor: Colors.green,
      ),
      body: globalRequiredLists.isEmpty
          ? const Center(
              child: Text(
                'No required lists created yet.\nClick "+ Enter Required List" below.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: globalRequiredLists.length,
              itemBuilder: (context, index) {
                final entry = globalRequiredLists[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    title: Text('Date: ${entry.date} | Shop: ${entry.shopName ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Total Amount: ₹${entry.grandTotal.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateRequiredListScreen(editingEntry: entry),
                              ),
                            ).then((_) async {
                              await saveShoppingDataToPrefs();
                              setState(() {});
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            setState(() {
                              globalRequiredLists.removeAt(index);
                            });
                            await saveShoppingDataToPrefs();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.green),
                          onPressed: () => _shareList(entry),
                          tooltip: 'Share List',
                        ),
                        IconButton(
                          icon: const Icon(Icons.description, color: Colors.purple),
                          onPressed: () => _openNotepadDialog(entry),
                          tooltip: 'Open Notepad / Bill Report',
                        ),
                      ],
                    ),
                    children: entry.selectedItems.map((item) {
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('Unit: ${item.unitType} | Qty: ${item.qtyText} | Rate: ₹${item.rate}'),
                        trailing: Text('₹${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRequiredListScreen(),
            ),
          ).then((_) async {
            await saveShoppingDataToPrefs();
            setState(() {});
          });
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Enter Required List'),
      ),
    );
  }
}

// --- Screen 5: Form to Create/Edit Required List ---
class CreateRequiredListScreen extends StatefulWidget {
  final RequiredListEntry? editingEntry;
  const CreateRequiredListScreen({super.key, this.editingEntry});

  @override
  State<CreateRequiredListScreen> createState() => _CreateRequiredListScreenState();
}

class _CreateRequiredListScreenState extends State<CreateRequiredListScreen> {
  late TextEditingController _dateController;
  String? _selectedShop;
  String? _selectedCategory;
  List<ShoppingItem> _formItems = [];
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _rateControllers = {};

  @override
  void initState() {
    super.initState();
    String defaultDate = widget.editingEntry?.date ??
        '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}';
    _dateController = TextEditingController(text: defaultDate);
    _selectedShop = widget.editingEntry?.shopName;
    _selectedCategory = widget.editingEntry?.categoryName;
    _loadItemsForSelection();
  }

  void _loadItemsForSelection() {
    _formItems = [];
    _qtyControllers.clear();
    _rateControllers.clear();
    for (var cat in globalCategories) {
      if (_selectedCategory == null || _selectedCategory == 'All Categories' || cat.name == _selectedCategory) {
        for (var item in cat.items) {
          bool isSel = false;
          String qText = '';
          double r = 0.0;
          String uType = item.unitType;
          if (widget.editingEntry != null) {
            var existing = widget.editingEntry!.selectedItems.firstWhere(
              (element) => element.id == item.id,
              orElse: () => ShoppingItem(id: '', name: '', unitType: ''),
            );
            if (existing.id.isNotEmpty) {
              isSel = true;
              qText = existing.qtyText;
              r = existing.rate;
              uType = existing.unitType;
            }
          }
          var newItem = ShoppingItem(
            id: item.id,
            name: item.name,
            unitType: uType,
            isSelected: isSel,
            qtyText: qText,
            rate: r,
          );
          newItem.calculateAmount();
          _formItems.add(newItem);
          _qtyControllers[item.id] = TextEditingController(text: qText);
          _rateControllers[item.id] = TextEditingController(text: r == 0 ? '' : r.toString());
        }
      }
    }
  }

  void _addNewShopDialog() {
    TextEditingController shopController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Shop'),
        content: TextField(
          controller: shopController,
          decoration: const InputDecoration(labelText: 'Shop Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (shopController.text.isNotEmpty) {
                setState(() {
                  globalShops.add(ShopModel(
                    id: DateTime.now().toString(),
                    name: shopController.text,
                  ));
                  _selectedShop = shopController.text;
                });
                await saveShoppingDataToPrefs();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addNewItemDialog() {
    TextEditingController itemController = TextEditingController();
    String selectedUnit = 'Weight (Kg/g)';
    String? targetCategory = _selectedCategory ?? (globalCategories.isNotEmpty ? globalCategories.first.name : null);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, dialogSetState) {
          return AlertDialog(
            title: const Text('Add New Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: itemController,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: targetCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: globalCategories.map((c) {
                      return DropdownMenuItem(value: c.name, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) dialogSetState(() => targetCategory = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unit Type'),
                    items: const [
                      DropdownMenuItem(value: 'Weight (Kg/g)', child: Text('Weight (Kg / g)')),
                      DropdownMenuItem(value: 'Pocket', child: Text('Pocket')),
                      DropdownMenuItem(value: 'Number (No)', child: Text('Number (No)')),
                    ],
                    onChanged: (val) {
                      if (val != null) dialogSetState(() => selectedUnit = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (itemController.text.isNotEmpty && targetCategory != null) {
                    var cat = globalCategories.firstWhere((c) => c.name == targetCategory);
                    setState(() {
                      cat.items.add(ShoppingItem(
                        id: DateTime.now().toString(),
                        name: itemController.text,
                        unitType: selectedUnit,
                      ));
                      _loadItemsForSelection();
                    });
                    await saveShoppingDataToPrefs();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  double get _grandTotal {
    double total = 0.0;
    for (var item in _formItems) {
      if (item.isSelected) {
        total += item.amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    List<String> categoryNames = ['All Categories', ...globalCategories.map((e) => e.name)];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingEntry == null ? 'Create Required List' : 'Edit Required List'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date (dd-mm-yyyy)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedShop,
                    decoration: const InputDecoration(
                      labelText: 'Shop Name (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: globalShops.map((shop) {
                      return DropdownMenuItem(
                        value: shop.name,
                        child: Text(shop.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedShop = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 36),
                  onPressed: _addNewShopDialog,
                  tooltip: 'Add Shop',
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory ?? 'All Categories',
              decoration: const InputDecoration(
                labelText: 'Item Category (Optional)',
                border: OutlineInputBorder(),
              ),
              items: categoryNames.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val == 'All Categories' ? null : val;
                  _loadItemsForSelection();
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Items, Qty & Rate:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: _addNewItemDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _formItems.length,
                itemBuilder: (context, index) {
                  final item = _formItems[index];
                  String dynamicHint = '1/2, 2*200gm, 1kg';
                  if (item.unitType == 'Pocket') {
                    dynamicHint = '1, 2*200gm, 2';
                  } else if (item.unitType == 'Number (No)') {
                    dynamicHint = '10, 2*10';
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.isSelected,
                            activeColor: Colors.green,
                            onChanged: (bool? val) {
                              setState(() {
                                item.isSelected = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      item.toggleUnitType();
                                      item.calculateAmount();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: Colors.orange),
                                    ),
                                    child: Text(
                                      item.unitType,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.deepOrange),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _qtyControllers[item.id],
                              decoration: InputDecoration(
                                labelText: 'Qty',
                                hintText: dynamicHint,
                                isDense: true,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  item.qtyText = val;
                                  item.calculateAmount();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _rateControllers[item.id],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Rate',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  item.rate = double.tryParse(val) ?? 0.0;
                                  item.calculateAmount();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey[100],
                              ),
                              child: Text(
                                '₹${item.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '₹${_grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  List<ShoppingItem> selectedList = _formItems.where((element) => element.isSelected).toList();
                  if (selectedList.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one item!')),
                    );
                    return;
                  }
                  setState(() {
                    if (widget.editingEntry != null) {
                      widget.editingEntry!.date = _dateController.text;
                      widget.editingEntry!.shopName = _selectedShop;
                      widget.editingEntry!.categoryName = _selectedCategory;
                      widget.editingEntry!.selectedItems = selectedList;
                      widget.editingEntry!.grandTotal = _grandTotal;
                    } else {
                      globalRequiredLists.add(RequiredListEntry(
                        id: DateTime.now().toString(),
                        date: _dateController.text,
                        shopName: _selectedShop,
                        categoryName: _selectedCategory,
                        selectedItems: selectedList,
                        grandTotal: _grandTotal,
                      ));
                    }
                  });
                  await saveShoppingDataToPrefs();
                  Navigator.pop(context);
                },
                child: Text(
                  widget.editingEntry == null ? 'Save Required List' : 'Update Required List',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Screen 6: Rate Comparison Screen ---
class RateComparisonScreen extends StatelessWidget {
  const RateComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Comparison List'),
        backgroundColor: Colors.purple,
      ),
      body: const Center(
        child: Text(
          'No comparison data available.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}