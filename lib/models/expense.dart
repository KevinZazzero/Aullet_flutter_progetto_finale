class Expense {
  final String? id;
  final String title;
  final double amount;
  final DateTime date;
  final String categoryId;
  final String userId;
  final String? description; 

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.userId,
    this.description, 
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'user_id': userId,
      'description': description, 
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as String,
      userId: map['user_id'] as String,
      description: map['description'] as String?, 
    );
  }
}