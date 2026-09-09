class Expense {
  final String id;
  final String title;
  final double amount;
  final String category; // 'Food', 'Transport', 'Shopping', 'Other'
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });
}