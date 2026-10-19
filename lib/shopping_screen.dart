import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TotalItemModel {
  String id;
  String name;
  bool isPacket;

  TotalItemModel({required this.id, required this.name, required this.isPacket});
}

class SavedShoppingFile {
  String id;
  String date;
  String shopName;
  List<Map<String, dynamic>> items;
  double grandTotal;

  SavedShoppingFile({
    required this.id,
    required this.date,
    required this.shopName,
    required this.items,
    required this.grandTotal,
  });
}

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  List<TotalItemModel> _totalItemsList = [
    TotalItemModel(id: '1', name: 'బియ్యం (Rice)', isPacket: false),
    TotalItemModel(id: '2', name: 'బెల్లం (Jaggery)', isPacket: true),
    TotalItemModel(id: '3', name: 'ఆవాలు (Avalu)', isPacket: true),
    TotalItemModel(id: '4', name: 'వాము (Vamu)', isPacket: true),
    TotalItemModel(id: '5', name: 'కందిపప్పు (Toor Dal)', isPacket: false),
    TotalItemModel(id: '6', name: 'పాలు (Milk)', isPacket: false),
    TotalItemModel(id: '7', name: 'నూనె (Oil)', isPacket: false),
    TotalItemModel(id: '8', name: 'పసుపు (Turmeric)', isPacket: true),
  ];

  List<String> _shopNamesList = ['సూపర్ మార్కెట్', 'కిరాణా షాప్', 'రైతు బజార్'];
  String? _selectedShop;

  Map<String, bool> _selectedItemsMap = {};
  Map<String, TextEditingController> _qtyControllers = {};
  Map<String, TextEditingController> _rateControllers = {};
  Map<String, bool> _requiredItemTypeOverride = {};

  List<SavedShoppingFile> _savedFilesList = [];
  String? _editingFileId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initRequiredInputs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (var controller in _rateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initRequiredInputs() {
    for (var itemModel in _totalItemsList) {
      _selectedItemsMap[itemModel.name] = false;
      _qtyControllers[itemModel.name] = TextEditingController();
      _rateControllers[itemModel.name] = TextEditingController();
      _requiredItemTypeOverride[itemModel.name] = itemModel.isPacket;
    }
  }

  bool _getItemType(TotalItemModel itemModel) {
    return _requiredItemTypeOverride[itemModel.name] ?? itemModel.isPacket;
  }

  // 🧮 ఐటమ్ టోటల్ (ఇక్కడ రౌండ్ ఆఫ్ చేయకుండా పాయింట్స్‌తో సహా ఖచ్చితమైన వాల్యూ ఇవ్వబడుతుంది)
  double _calculateItemTotal(TotalItemModel itemModel, double inputRate) {
    String qtyText = (_qtyControllers[itemModel.name]?.text ?? '').toLowerCase().trim();
    if (qtyText.isEmpty || inputRate <= 0) return 0.0;

    bool currentIsPacket = _getItemType(itemModel);

    if (currentIsPacket) {
      double count = 1.0;
      if (qtyText.contains('pkt') || qtyText.contains('packet') || qtyText.contains('bag') || qtyText.contains('*') || qtyText.contains('x')) {
        String cleanedNum = qtyText.replaceAll(RegExp(r'[^0-9.]'), '');
        count = cleanedNum.isEmpty ? 1.0 : (double.tryParse(cleanedNum) ?? 1.0);
      } else if (qtyText.contains('gm') || qtyText.contains('gram') || qtyText.contains('kg') || qtyText.contains('ltr') || qtyText.contains('ml')) {
        count = 1.0;
      } else {
        String cleanedNum = qtyText.replaceAll(RegExp(r'[^0-9.]'), '');
        count = cleanedNum.isEmpty ? 1.0 : (double.tryParse(cleanedNum) ?? 1.0);
      }
      return count * inputRate;
    }

    // Weight Mode
    if (qtyText.contains('packet') || qtyText.contains('pkt')) {
      String cleanedNum = qtyText.replaceAll(RegExp(r'[^0-9.]'), '');
      double count = cleanedNum.isEmpty ? 1.0 : (double.tryParse(cleanedNum) ?? 1.0);
      return count * inputRate;
    }

    if (qtyText.contains('gm') || qtyText.contains('gram')) {
      String cleanedNum = qtyText.replaceAll(RegExp(r'[^0-9.]'), '');
      double gmVal = double.tryParse(cleanedNum) ?? 0.0;
      return (inputRate / 1000.0) * gmVal; 
    } else if (qtyText.contains('ml')) {
      String cleanedNum = qtyText.replaceAll(RegExp(r'[^0-9.]'), '');
      double mlVal = double.tryParse(cleanedNum) ?? 0.0;
      return (inputRate / 1000.0) * mlVal;
    }

    double multiplier = 1.0;
    if (qtyText.contains('1/2') || qtyText.contains('0.5')) {
      multiplier = 0.5;
    } else if (qtyText.contains('1/4') || qtyText.contains('0.25')) {
      multiplier = 0.25;
    } else if (qtyText.contains('3/4') || qtyText.contains('0.75')) {
      multiplier = 0.75;
    } else {
      String cleanedNum = qtyText.replaceAll(RegExp(r'[^0-9.]'), '');
      multiplier = cleanedNum.isEmpty ? 1.0 : (double.tryParse(cleanedNum) ?? 1.0);
    }

    return multiplier * inputRate;
  }

  // 💰 గ్రాండ్ టోటల్ వద్ద మాత్రమే రౌండ్ ఆఫ్ (అవసరమైతే) లేదా పాయింట్స్
  double _calculateGrandTotal() {
    double grandTotal = 0.0;
    for (var itemModel in _totalItemsList) {
      if (_selectedItemsMap[itemModel.name] == true) {
        double rate = double.tryParse(_rateControllers[itemModel.name]?.text ?? '0') ?? 0.0;
        grandTotal += _calculateItemTotal(itemModel, rate);
      }
    }
    return grandTotal; // కావాలంటే దీనిని .roundToDouble() లేదా అలాగే ఉంచవచ్చు
  }

  void _showAddOrEditItemDialog({TotalItemModel? editItem}) {
    TextEditingController itemController = TextEditingController(text: editItem?.name ?? '');
    bool isPacketSelected = editItem?.isPacket ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(editItem == null ? 'Add Total Item' : 'Edit Total Item', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: itemController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      hintText: 'సరుకు పేరు టైప్ చేయండి',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Is Packet / Unit Item?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('ప్యాకెట్ ఐటమ్ అయితే ఆన్ చేయండి', style: TextStyle(fontSize: 11)),
                    value: isPacketSelected,
                    onChanged: (val) {
                      setDialogState(() {
                        isPacketSelected = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
                  onPressed: () {
                    String text = itemController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        if (editItem == null) {
                          if (!_totalItemsList.any((i) => i.name == text)) {
                            String newId = DateTime.now().millisecondsSinceEpoch.toString();
                            _totalItemsList.add(TotalItemModel(id: newId, name: text, isPacket: isPacketSelected));
                            _selectedItemsMap[text] = false;
                            _qtyControllers[text] = TextEditingController();
                            _rateControllers[text] = TextEditingController();
                            _requiredItemTypeOverride[text] = isPacketSelected;
                          }
                        } else {
                          editItem.name = text;
                          editItem.isPacket = isPacketSelected;
                          _initRequiredInputs();
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(editItem == null ? 'Save Item' : 'Update Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddShopDialog() {
    TextEditingController shopController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Shop Name', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: shopController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Shop Name',
              hintText: 'షాప్ పేరు ఎంటర్ చేయండి',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
              onPressed: () {
                String text = shopController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    if (!_shopNamesList.contains(text)) {
                      _shopNamesList.add(text);
                    }
                    _selectedShop = text;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Shop'),
            ),
          ],
        );
      },
    );
  }

  void _processSaveOrUpdate() {
    List<Map<String, dynamic>> activeItems = [];
    for (var itemModel in _totalItemsList) {
      // సెలెక్ట్ చేసి ఉండి, Qty ఇచ్చినవి మాత్రమే సేవ్ అవుతాయి (లేదా Qty ఇవ్వకపోయినా ఒకవేళ సేవ్ చేయాలంటే ఇక్కడ కండిషన్ మార్చుకోవచ్చు)
      if (_selectedItemsMap[itemModel.name] == true) {
        String qty = _qtyControllers[itemModel.name]?.text.trim() ?? '';
        double rate = double.tryParse(_rateControllers[itemModel.name]?.text ?? '0') ?? 0.0;
        double itemTotal = _calculateItemTotal(itemModel, rate);

        if (qty.isNotEmpty) {
          activeItems.add({
            'name': itemModel.name,
            'qty': qty,
            'rate': rate,
            'total': itemTotal,
            'isPacket': _getItemType(itemModel),
          });
        }
      }
    }

    if (activeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('దయచేసి కనీసం ఒక సరుకును సెలెక్ట్ చేసి Qty ఇవ్వండి!')),
      );
      return;
    }

    if (_selectedShop == null || _selectedShop!.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('షాప్ పేరు ఇవ్వలేదు'),
            ],
          ),
          content: const Text('మీరు షాప్ పేరు ఎంచుకోలేదు. షాప్ పేరు లేకుండానే సేవ్ చేయాలా?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('షాప్ ఇస్తాను'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                _executeSave(activeItems);
              },
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
    } else {
      _executeSave(activeItems);
    }
  }

  void _executeSave(List<Map<String, dynamic>> activeItems) {
    String formattedDate = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
    double grandTotal = _calculateGrandTotal();

    setState(() {
      if (_editingFileId != null) {
        int index = _savedFilesList.indexWhere((f) => f.id == _editingFileId);
        if (index != -1) {
          _savedFilesList[index] = SavedShoppingFile(
            id: _editingFileId!,
            date: formattedDate,
            shopName: _selectedShop ?? '',
            items: activeItems,
            grandTotal: grandTotal,
          );
        }
        _editingFileId = null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ఫైల్ విజయవంతంగా అప్‌డేట్ అయింది!')));
      } else {
        _savedFilesList.add(SavedShoppingFile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: formattedDate,
          shopName: _selectedShop ?? '',
          items: activeItems,
          grandTotal: grandTotal,
        ));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ఫైల్ విజయవంతంగా సేవ్ అయింది!')));
      }

      _initRequiredInputs();
      _selectedShop = null;
    });
  }

  String _generateShareText(SavedShoppingFile file) {
    String text = "🛒 *Shopping List*\n";
    text += "📅 Date: ${file.date}\n";
    if (file.shopName.isNotEmpty) {
      text += "🏪 Shop: ${file.shopName}\n";
    }
    text += "----------------------------------------\n";

    for (int i = 0; i < file.items.length; i++) {
      var it = file.items[i];
      text += "${i + 1}. ${it['name']} - Qty: ${it['qty']}";
      if ((it['total'] ?? 0) > 0) {
        text += " (₹${it['total'].toStringAsFixed(2)})";
      }
      text += "\n";
    }
    text += "----------------------------------------\n";
    if (file.grandTotal > 0) {
      text += "💰 Grand Total: ₹${file.grandTotal.toStringAsFixed(2)}";
    }
    return text;
  }

  void _shareFileModal(SavedShoppingFile file) {
    String shareText = _generateShareText(file);
    Clipboard.setData(ClipboardData(text: shareText));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Shopping List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('లిస్ట్ కాపీ అయింది! మీరు దీన్ని WhatsApp లేదా ఇతర యాప్స్‌లో పేస్ట్ చేయవచ్చు.'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Text(shareText, maxLines: 6, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('క్లిప్‌బోర్డ్‌కి కాపీ అయింది!')),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _downloadAsWordFile(SavedShoppingFile file) {
    String text = _generateShareText(file);
    Clipboard.setData(ClipboardData(text: text));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download_done, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Downloaded / Copied'),
          ],
        ),
        content: const Text('మీ షాపింగ్ లిస్ట్ కాపీ అయింది. వర్డ్ లేదా నోట్‌ప్యాడ్‌లో పేస్ట్ చేసుకోండి.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ✏️ ఎడిట్ మోడ్: కేవలం సేవ్ చేసిన ఆ ఫైల్‌లోని ఐటమ్స్ మాత్రమే ఆన్ అవుతాయి, మిగతావి క్లియర్ అవుతాయి
  void _loadFileForEditing(SavedShoppingFile file) {
    setState(() {
      _editingFileId = file.id;
      _selectedShop = file.shopName.isNotEmpty ? file.shopName : null;
      _initRequiredInputs(); // ముందు అన్నీ క్లియర్ చేస్తాం

      for (var savedItem in file.items) {
        String name = savedItem['name'];
        if (_totalItemsList.any((i) => i.name == name)) {
          _selectedItemsMap[name] = true;
          _qtyControllers[name]?.text = savedItem['qty'] ?? '';
          if ((savedItem['rate'] ?? 0) > 0) {
            _rateControllers[name]?.text = savedItem['rate'].toString();
          }
          if (savedItem['isPacket'] != null) {
            _requiredItemTypeOverride[name] = savedItem['isPacket'];
          }
        }
      }
    });

    _tabController.animateTo(2);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✏️ ఎడిటింగ్ మోడ్ ఓపెన్ అయింది. మార్పులు చేసి UPDATE కొట్టండి!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteFile(String id) {
    setState(() {
      _savedFilesList.removeWhere((f) => f.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ ఫైల్ తొలగించబడింది!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo[900],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Total Items"),
            Tab(text: "Shop Name"),
            Tab(text: "Required Items"),
            Tab(text: "Comparison"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Items List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
                      onPressed: () => _showAddOrEditItemDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _totalItemsList.length,
                    itemBuilder: (context, index) {
                      TotalItemModel itemModel = _totalItemsList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Text('${index + 1}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(itemModel.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            itemModel.isPacket ? "Default: Packet" : "Default: Weight (Kg)",
                            style: TextStyle(fontSize: 11, color: itemModel.isPacket ? Colors.purple : Colors.indigo),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showAddOrEditItemDialog(editItem: itemModel),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _totalItemsList.removeAt(index);
                                    _initRequiredInputs();
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
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saved Shops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
                      onPressed: _showAddShopDialog,
                      icon: const Icon(Icons.store),
                      label: const Text('Add Shop'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _shopNamesList.length,
                    itemBuilder: (context, index) {
                      String shop = _shopNamesList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.storefront, color: Colors.indigo),
                          title: Text(shop, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _shopNamesList.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Card(
                  color: Colors.indigo[50],
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.indigo, size: 20),
                                const SizedBox(width: 8),
                                Text("Date: $formattedDate", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            TextButton(
                              onPressed: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) setState(() => _selectedDate = picked);
                              },
                              child: const Text('Change Date'),
                            ),
                          ],
                        ),
                        const Divider(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.store, color: Colors.indigo, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  hint: const Text('Select Shop Name (Optional)'),
                                  value: _selectedShop,
                                  isExpanded: true,
                                  items: _shopNamesList.map((String shop) {
                                    return DropdownMenuItem<String>(
                                      value: shop,
                                      child: Text(shop, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedShop = val),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 28),
                              onPressed: _showAddShopDialog,
                              tooltip: 'Add Shop',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(color: Colors.indigo[900], borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    children: [
                      SizedBox(width: 30),
                      Expanded(flex: 2, child: Text('Item Name & Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Qty', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Rate', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView(
                    children: [
                      ..._totalItemsList.map((itemModel) {
                        bool isChecked = _selectedItemsMap[itemModel.name] ?? false;
                        double rate = double.tryParse(_rateControllers[itemModel.name]?.text ?? '0') ?? 0.0;
                        bool currentIsPacket = _getItemType(itemModel);
                        double total = _calculateItemTotal(itemModel, rate);

                        return Card(
                          color: isChecked ? Colors.green[50] : Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isChecked,
                                  onChanged: (val) => setState(() => _selectedItemsMap[itemModel.name] = val!),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _requiredItemTypeOverride[itemModel.name] = !currentIsPacket;
                                      });
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(itemModel.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Row(
                                          children: [
                                            Text(
                                              currentIsPacket ? "📦 Packet" : "⚖️ Weight",
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: currentIsPacket ? Colors.purple : Colors.indigo),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.swap_horiz, size: 12, color: Colors.grey),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 36,
                                    child: TextField(
                                      controller: _qtyControllers[itemModel.name],
                                      decoration: const InputDecoration(
                                        hintText: '500gm / 2pkt',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      ),
                                      onChanged: (val) => setState(() {}),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 36,
                                    child: TextField(
                                      controller: _rateControllers[itemModel.name],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'Rate',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      ),
                                      onChanged: (val) => setState(() {}),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    total > 0 ? "₹${total.toStringAsFixed(2)}" : "-", // పాయింట్స్ తో సహా ఖచ్చితమైన టోటల్ చూపుతుంది
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      // ➕ రిక్వైర్డ్ లిస్ట్ చివర్లో కొత్త ఐటమ్ యాడ్ చేయడానికి బటన్
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo[900],
                          side: BorderSide(color: Colors.indigo.shade900),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _showAddOrEditItemDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Item to List', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _editingFileId != null ? Colors.orange[800] : Colors.green[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _processSaveOrUpdate,
                        icon: Icon(_editingFileId != null ? Icons.update : Icons.save),
                        label: Text(_editingFileId != null ? 'UPDATE FILE' : 'SAVE FILE', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 15),
                      if (_savedFilesList.isNotEmpty) ...[
                        const Text('Saved Lists / Files:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        ..._savedFilesList.map((file) {
                          return Card(
                            color: Colors.amber[50],
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("📅 Date: ${file.date}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        if (file.shopName.isNotEmpty)
                                          Text("🏪 Shop: ${file.shopName}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text("💰 Total: ₹${file.grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _loadFileForEditing(file),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: Icon(Icons.edit, color: Colors.blue, size: 22),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _shareFileModal(file),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: Icon(Icons.share, color: Colors.green, size: 22),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _downloadAsWordFile(file),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: Icon(Icons.download, color: Colors.indigo, size: 22),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _deleteFile(file.id),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: Icon(Icons.delete, color: Colors.red, size: 22),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Center(
            child: Text('Comparison Tab (త్వరలో వస్తుంది)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}