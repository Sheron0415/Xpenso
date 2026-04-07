class TransactionModel {
  int? id;
  String title;
  String category;
  double amount;
  String type; // Income or Expense
  DateTime date;

  TransactionModel({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      amount: map['amount'],
      type: map['type'],
      date: DateTime.parse(map['date']),
    );
  }
}