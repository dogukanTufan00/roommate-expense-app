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

// An invitation to join a home. The invitee must accept it before joining.
class Invitation {
  final int id;
  final int householdId;
  final String householdName;
  final int invitedUserId;
  final String invitedUserName;
  final String invitedUserEmail;
  final int invitedById;
  final String invitedByName;
  // The API sends PENDING for open invitations.
  final String status;
  final DateTime createdAt;

  Invitation({
    required this.id,
    required this.householdId,
    required this.householdName,
    required this.invitedUserId,
    required this.invitedUserName,
    required this.invitedUserEmail,
    required this.invitedById,
    required this.invitedByName,
    required this.status,
    required this.createdAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as int,
      householdId: json['householdId'] as int,
      householdName: json['householdName'] as String,
      invitedUserId: json['invitedUserId'] as int,
      invitedUserName: json['invitedUserName'] as String,
      invitedUserEmail: json['invitedUserEmail'] as String,
      invitedById: json['invitedById'] as int,
      invitedByName: json['invitedByName'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// One person's part of an expense, as returned by the API.
class ExpenseShare {
  final int userId;
  final String name;
  final double owedAmount;
  // Only set when the expense split is PERCENT. Otherwise null.
  final double? percent;

  ExpenseShare({
    required this.userId,
    required this.name,
    required this.owedAmount,
    required this.percent,
  });

  factory ExpenseShare.fromJson(Map<String, dynamic> json) {
    return ExpenseShare(
      userId: json['userId'] as int,
      name: json['name'] as String,
      owedAmount: (json['owedAmount'] as num).toDouble(),
      percent: (json['percent'] as num?)?.toDouble(),
    );
  }
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
  // One of: EQUAL, PERCENT, AMOUNT. Old responses without it count as EQUAL.
  final String splitType;
  // Who shares the expense and how much each person owes. Empty if the API sent none.
  final List<ExpenseShare> shares;

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
    this.splitType = 'EQUAL',
    this.shares = const [],
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final rawShares = json['shares'] as List<dynamic>? ?? const [];
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
      splitType: json['splitType'] as String? ?? 'EQUAL',
      shares: [
        for (final item in rawShares)
          ExpenseShare.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

// One person's percent in a category's default split.
class CategorySplitShare {
  final int userId;
  final String name;
  final double percent;

  CategorySplitShare({
    required this.userId,
    required this.name,
    required this.percent,
  });

  factory CategorySplitShare.fromJson(Map<String, dynamic> json) {
    return CategorySplitShare(
      userId: json['userId'] as int,
      name: json['name'] as String,
      percent: (json['percent'] as num).toDouble(),
    );
  }
}

// The household's default ratio for one category, for example RENT.
class CategorySplitDefault {
  final String category;
  final List<CategorySplitShare> shares;

  CategorySplitDefault({required this.category, required this.shares});

  factory CategorySplitDefault.fromJson(Map<String, dynamic> json) {
    final rawShares = json['shares'] as List<dynamic>? ?? const [];
    return CategorySplitDefault(
      category: json['category'] as String,
      shares: [
        for (final item in rawShares)
          CategorySplitShare.fromJson(item as Map<String, dynamic>),
      ],
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
