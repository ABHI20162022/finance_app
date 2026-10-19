class FinanceEntry {
  final String id;
  final String type; // 'INCOME' లేదా 'EXPENSE'
  final String heading1; // Category పేరు
  final String heading2; // Person పేరు
  final String heading3; // Account పేరు
  final String description;
  final String date;
  final double amount;

  FinanceEntry({
    required this.id,
    required this.type,
    required this.heading1,
    required this.heading2,
    required this.heading3,
    required this.description,
    required this.date,
    required this.amount,
  });
}

// గ్లోబల్ ఎంట్రీస్ లిస్ట్
List<FinanceEntry> globalEntries = [];