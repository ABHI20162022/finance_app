import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// --- Models ---
class FinanceItem {
  String id;
  String title;
  double amount;
  String person;
  String category;
  String depositAccount;
  String date;
  String description;

  FinanceItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.person,
    required this.category,
    required this.depositAccount,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'person': person,
        'category': category,
        'depositAccount': depositAccount,
        'date': date,
        'description': description,
      };

  factory FinanceItem.fromJson(Map<String, dynamic> json) => FinanceItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        person: json['person'] ?? '',
        category: json['category'] ?? '',
        depositAccount: json['depositAccount'] ?? '',
        date: json['date'] ?? '',
        description: json['description'] ?? '',
      );
}

class PersonData {
  String id;
  String name;
  List<String> bankAccounts;
  List<FinanceItem> entries;

  PersonData({
    required this.id,
    required this.name,
    required this.bankAccounts,
    required this.entries,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bankAccounts': bankAccounts,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory PersonData.fromJson(Map<String, dynamic> json) => PersonData(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        bankAccounts: List<String>.from(json['bankAccounts'] ?? []),
        entries: (json['entries'] as List? ?? [])
            .map((e) => FinanceItem.fromJson(e))
            .toList(),
      );
}

class ExpenseCategoryData {
  String name;
  List<String> subCategories;

  ExpenseCategoryData({
    required this.name,
    required this.subCategories,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'subCategories': subCategories,
      };

  factory ExpenseCategoryData.fromJson(Map<String, dynamic> json) => ExpenseCategoryData(
        name: json['name'] ?? '',
        subCategories: List<String>.from(json['subCategories'] ?? []),
      );
}

// Global Lists
List<PersonData> globalPersons = [];
List<String> globalIncomeCategories = [];
List<ExpenseCategoryData> globalExpenseCategories = [];

// --- Global Storage Helpers ---
Future<void> saveFinanceDataToPrefs() async {
  final prefs = await SharedPreferences.getInstance();

  List<Map<String, dynamic>> personsJson =
      globalPersons.map((p) => p.toJson()).toList();
  await prefs.setString('saved_global_persons', jsonEncode(personsJson));
  await prefs.setStringList('saved_income_categories', globalIncomeCategories);
  
  List<Map<String, dynamic>> expCatsJson =
      globalExpenseCategories.map((c) => c.toJson()).toList();
  await prefs.setString('saved_expense_categories', jsonEncode(expCatsJson));
}

Future<void> loadFinanceDataFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();

  String? personsStr = prefs.getString('saved_global_persons');
  if (personsStr != null) {
    List<dynamic> decodedPersons = jsonDecode(personsStr);
    globalPersons = decodedPersons.map((p) => PersonData.fromJson(p)).toList();
  } else {
    globalPersons = [];
  }

  globalIncomeCategories = prefs.getStringList('saved_income_categories') ?? [];

  String? expCatsStr = prefs.getString('saved_expense_categories');
  if (expCatsStr != null) {
    List<dynamic> decodedExpCats = jsonDecode(expCatsStr);
    globalExpenseCategories =
        decodedExpCats.map((c) => ExpenseCategoryData.fromJson(c)).toList();
  } else {
    globalExpenseCategories = [];
  }
}