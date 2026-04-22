class TransactionModel {
  int? id;
  String title;
  String category;
  double amount;
  String type;
  DateTime date;

  TransactionModel({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
  });

  // ================= TO MAP =================

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

  // ================= FROM MAP =================

  factory TransactionModel.fromMap(
      Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      amount: map['amount'] is int
          ? (map['amount'] as int).toDouble()
          : map['amount'],
      type: map['type'],
      date: DateTime.parse(map['date']),
    );
  }

  // ================= COPY FOR EDIT =================

  TransactionModel copyWith({
    int? id,
    String? title,
    String? category,
    double? amount,
    String? type,
    DateTime? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
    );
  }
}