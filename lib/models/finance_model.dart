import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// --- Storage Keys ---
const String kSavedGlobalPersonsKey = 'saved_global_persons';
const String kSavedIncomeCategoriesKey = 'saved_income_categories';
const String kSavedExpenseCategoriesKey = 'saved_expense_categories';

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
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        person: json['person']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        depositAccount: json['depositAccount']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
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
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        bankAccounts: List<String>.from(json['bankAccounts'] ?? const []),
        entries: (json['entries'] as List? ?? const [])
            .map((e) =>
                FinanceItem.fromJson(Map<String, dynamic>.from(e as Map)))
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

  factory ExpenseCategoryData.fromJson(Map<String, dynamic> json) =>
      ExpenseCategoryData(
        name: json['name']?.toString() ?? '',
        subCategories: List<String>.from(json['subCategories'] ?? const []),
      );
}

// Global Lists
List<PersonData> globalPersons = [];
List<String> globalIncomeCategories = [];
List<ExpenseCategoryData> globalExpenseCategories = [];

// --- Global Storage Helpers ---
Future<void> saveFinanceDataToPrefs() async {
  final prefs = await SharedPreferences.getInstance();

  final personsJson = globalPersons.map((p) => p.toJson()).toList();
  await prefs.setString(kSavedGlobalPersonsKey, jsonEncode(personsJson));

  await prefs.setStringList(
    kSavedIncomeCategoriesKey,
    List<String>.from(globalIncomeCategories),
  );

  final expCatsJson = globalExpenseCategories.map((c) => c.toJson()).toList();
  await prefs.setString(kSavedExpenseCategoriesKey, jsonEncode(expCatsJson));
}

Future<void> loadFinanceDataFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();

  final personsStr = prefs.getString(kSavedGlobalPersonsKey);
  if (personsStr != null && personsStr.isNotEmpty) {
    final decoded = jsonDecode(personsStr);
    if (decoded is List) {
      globalPersons = decoded
          .map((p) => PersonData.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
    } else {
      globalPersons = [];
    }
  } else {
    globalPersons = [];
  }

  globalIncomeCategories = List<String>.from(
      prefs.getStringList(kSavedIncomeCategoriesKey) ?? const []);

  final expCatsStr = prefs.getString(kSavedExpenseCategoriesKey);
  if (expCatsStr != null && expCatsStr.isNotEmpty) {
    final decodedExp = jsonDecode(expCatsStr);
    if (decodedExp is List) {
      globalExpenseCategories = decodedExp
          .map((c) =>
              ExpenseCategoryData.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
    } else {
      globalExpenseCategories = [];
    }
  } else {
    globalExpenseCategories = [];
  }
}

Future<void> clearFinanceDataPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(kSavedGlobalPersonsKey);
  await prefs.remove(kSavedIncomeCategoriesKey);
  await prefs.remove(kSavedExpenseCategoriesKey);
  globalPersons = [];
  globalIncomeCategories = [];
  globalExpenseCategories = [];
}