// All data models used by the app. Each model has a fromJson factory that
// reads the JSON sent by the API.
//
// Amounts arrive as JSON numbers, so we convert them to double.
// Dates arrive as ISO strings, so we parse them with DateTime.parse.

class Household {
  final int id;
  final String name;
  final int createdByUserId;
  final DateTime createdAt;

  Household({
    required this.id,
    required this.name,
    required this.createdByUserId,
    required this.createdAt,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] as int,
      name: json['name'] as String,
      createdByUserId: json['createdByUserId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class Member {
  final int userId;
  final String name;
  final String email;
  final String role;
  final DateTime joinedAt;

  Member({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      userId: json['userId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  // The API uses the role names ADMIN and MEMBER.
  bool get isAdmin => role == 'ADMIN';
}

class Expense {
  final int id;
  final int householdId;
  final int paidByUserId;
  final String paidByName;
  final double amount;
  // One of: RENT, UTILITIES, GROCERIES, OTHER
  final String category;
  final String? description;
  final bool recurring;
  final DateTime expenseDate;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.householdId,
    required this.paidByUserId,
    required this.paidByName,
    required this.amount,
    required this.category,
    required this.description,
    required this.recurring,
    required this.expenseDate,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int,
      householdId: json['householdId'] as int,
      paidByUserId: json['paidByUserId'] as int,
      paidByName: json['paidByName'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String?,
      recurring: json['recurring'] as bool,
      expenseDate: DateTime.parse(json['expenseDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class Balance {
  final int userId;
  final String name;
  // Positive: the household owes this person. Negative: they owe the household.
  final double netBalance;

  Balance({
    required this.userId,
    required this.name,
    required this.netBalance,
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      userId: json['userId'] as int,
      name: json['name'] as String,
      netBalance: (json['netBalance'] as num).toDouble(),
    );
  }
}

class Settlement {
  final int fromUserId;
  final String fromName;
  final int toUserId;
  final String toName;
  final double amount;

  Settlement({
    required this.fromUserId,
    required this.fromName,
    required this.toUserId,
    required this.toName,
    required this.amount,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      fromUserId: json['fromUserId'] as int,
      fromName: json['fromName'] as String,
      toUserId: json['toUserId'] as int,
      toName: json['toName'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class Payment {
  final int id;
  final int householdId;
  final int fromUserId;
  final String fromUserName;
  final int toUserId;
  final String toUserName;
  final double amount;
  final DateTime paidAt;

  Payment({
    required this.id,
    required this.householdId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
    required this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int,
      householdId: json['householdId'] as int,
      fromUserId: json['fromUserId'] as int,
      fromUserName: json['fromUserName'] as String,
      toUserId: json['toUserId'] as int,
      toUserName: json['toUserName'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidAt: DateTime.parse(json['paidAt'] as String),
    );
  }
}
