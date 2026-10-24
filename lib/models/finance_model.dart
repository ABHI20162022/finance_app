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
}

class ExpenseCategoryData {
  String name;
  List<String> subCategories;

  ExpenseCategoryData({required this.name, required this.subCategories});
}

// Global lists (Started completely empty with no defaults)
List<PersonData> globalPersons = [];
List<String> globalIncomeCategories = [];
List<ExpenseCategoryData> globalExpenseCategories = [];