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
  // The member's saved IBAN, or null. Shown and copied in the members list.
  final String? iban;
  // True for the user who created the home, or who was given ownership.
  final bool founder;

  Member({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.iban,
    this.founder = false,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      userId: json['userId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      iban: _optionalText(json['iban']),
      founder: json['founder'] as bool? ?? false,
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
  // How many receipts or documents are attached. 0 when the API does not send it.
  final int attachmentCount;
  // Set on copies the server made automatically: the id of the expense they came from. Null otherwise.
  final int? generatedFromId;
  // The day of the month this recurring chain repeats on. Null when the API does not send it.
  final int? recurrenceDay;

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
    this.attachmentCount = 0,
    this.generatedFromId,
    this.recurrenceDay,
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
      attachmentCount: _countValue(json['attachmentCount']),
      generatedFromId: json['generatedFromId'] as int?,
      recurrenceDay: json['recurrenceDay'] as int?,
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
  // The receiver's IBAN, or null if they have not added one.
  final String? toIban;

  Settlement({
    required this.fromUserId,
    required this.fromName,
    required this.toUserId,
    required this.toName,
    required this.amount,
    this.toIban,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      fromUserId: json['fromUserId'] as int,
      fromName: json['fromName'] as String,
      toUserId: json['toUserId'] as int,
      toName: json['toName'] as String,
      amount: (json['amount'] as num).toDouble(),
      toIban: _optionalText(json['toIban']),
    );
  }
}

// A reminder I sent in this home in the last 24 hours. I cannot remind this person again before
// nextAllowedAt. The POST answer has the same two fields, so it is read the same way.
class ReminderCooldown {
  final int debtorUserId;
  // Converted to the phone's time zone.
  final DateTime nextAllowedAt;

  ReminderCooldown({required this.debtorUserId, required this.nextAllowedAt});

  factory ReminderCooldown.fromJson(Map<String, dynamic> json) {
    return ReminderCooldown(
      debtorUserId: json['debtorUserId'] as int,
      nextAllowedAt: DateTime.parse(json['nextAllowedAt'] as String).toLocal(),
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
  // Optional note, up to 200 characters. Null when there is none.
  final String? note;
  // How many receipts (dekont) are attached. 0 when the API does not send it.
  final int attachmentCount;

  Payment({
    required this.id,
    required this.householdId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
    required this.paidAt,
    this.note,
    this.attachmentCount = 0,
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
      note: _optionalText(json['note']),
      attachmentCount: _countValue(json['attachmentCount']),
    );
  }
}

// A receipt or document attached to an expense or a payment.
class Attachment {
  final int id;
  final int? expenseId;
  final int? paymentId;
  final String originalFilename;
  // The file type, for example "image/jpeg" or "application/pdf".
  final String contentType;
  final int sizeBytes;
  final int uploadedById;
  final String uploadedByName;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.expenseId,
    required this.paymentId,
    required this.originalFilename,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedById,
    required this.uploadedByName,
    required this.createdAt,
  });

  bool get isImage => contentType.startsWith('image/');
  bool get isPdf => contentType == 'application/pdf';

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as int,
      expenseId: json['expenseId'] as int?,
      paymentId: json['paymentId'] as int?,
      originalFilename: json['originalFilename'] as String,
      contentType: json['contentType'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      uploadedById: json['uploadedById'] as int,
      uploadedByName: json['uploadedByName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// One monthly chain from GET /api/households/{id}/expenses/recurring. expenseId is the
// latest expense of the chain, the one that carries the recurring flag.
class RecurringExpense {
  final int expenseId;
  final String? description;
  final String category;
  final double amount;
  final int paidByUserId;
  final String paidByName;
  // The day of the month the chain repeats on.
  final int recurrenceDay;
  final DateTime? lastDate;
  final DateTime? nextDate;

  RecurringExpense({
    required this.expenseId,
    required this.description,
    required this.category,
    required this.amount,
    required this.paidByUserId,
    required this.paidByName,
    required this.recurrenceDay,
    required this.lastDate,
    required this.nextDate,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      expenseId: json['expenseId'] as int,
      description: _optionalText(json['description']),
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidByUserId: json['paidByUserId'] as int,
      paidByName: json['paidByName'] as String,
      recurrenceDay: (json['recurrenceDay'] as num).toInt(),
      lastDate: _optionalDate(json['lastDate']),
      nextDate: _optionalDate(json['nextDate']),
    );
  }
}

// ---- Statement (GET /api/households/{id}/statement) ----

// One member's numbers for the statement period.
class StatementMember {
  final int userId;
  final String name;
  // False when the person has left the home since.
  final bool active;
  // What they paid for expenses.
  final double paid;
  // What they owe for their part of the expenses.
  final double share;
  // paid minus share. Positive: the home owes them. Negative: they owe the home.
  final double net;
  final double paymentsSent;
  final double paymentsReceived;
  // Their part of all money paid in the period, from 0 to 100.
  final double paidPercent;

  StatementMember({
    required this.userId,
    required this.name,
    required this.active,
    required this.paid,
    required this.share,
    required this.net,
    required this.paymentsSent,
    required this.paymentsReceived,
    required this.paidPercent,
  });

  factory StatementMember.fromJson(Map<String, dynamic> json) {
    return StatementMember(
      userId: json['userId'] as int,
      name: json['name'] as String,
      active: json['active'] as bool? ?? true,
      paid: _numValue(json['paid']),
      share: _numValue(json['share']),
      net: _numValue(json['net']),
      paymentsSent: _numValue(json['paymentsSent']),
      paymentsReceived: _numValue(json['paymentsReceived']),
      paidPercent: _numValue(json['paidPercent']),
    );
  }
}

// The member who paid the most in the period. Null when nothing was paid.
class DominantPayer {
  final int userId;
  final String name;
  final double paidPercent;

  DominantPayer({
    required this.userId,
    required this.name,
    required this.paidPercent,
  });

  factory DominantPayer.fromJson(Map<String, dynamic> json) {
    return DominantPayer(
      userId: json['userId'] as int,
      name: json['name'] as String,
      paidPercent: _numValue(json['paidPercent']),
    );
  }
}

// The total of one category in the period.
class StatementCategory {
  // One of: RENT, UTILITIES, GROCERIES, OTHER
  final String category;
  final double total;
  final int count;
  // From 0 to 100.
  final double percent;

  StatementCategory({
    required this.category,
    required this.total,
    required this.count,
    required this.percent,
  });

  factory StatementCategory.fromJson(Map<String, dynamic> json) {
    return StatementCategory(
      category: json['category'] as String,
      total: _numValue(json['total']),
      count: _countValue(json['count']),
      percent: _numValue(json['percent']),
    );
  }
}

// How much one member paid in one month of the trend.
class TrendMemberPaid {
  final int userId;
  final String name;
  final double paid;

  TrendMemberPaid({required this.userId, required this.name, required this.paid});

  factory TrendMemberPaid.fromJson(Map<String, dynamic> json) {
    return TrendMemberPaid(
      userId: json['userId'] as int,
      name: json['name'] as String,
      paid: _numValue(json['paid']),
    );
  }
}

// One month of the 6 month trend. month is the first day of that month.
class TrendMonth {
  final DateTime month;
  final double total;
  final List<TrendMemberPaid> perMember;

  TrendMonth({required this.month, required this.total, required this.perMember});

  factory TrendMonth.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['perMember'] as List<dynamic>? ?? const [];
    return TrendMonth(
      month: DateTime.parse(json['month'] as String),
      total: _numValue(json['total']),
      perMember: [
        for (final item in rawMembers)
          TrendMemberPaid.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

// One person's owed part of a statement expense.
class StatementShare {
  final String name;
  final double owedAmount;

  StatementShare({required this.name, required this.owedAmount});

  factory StatementShare.fromJson(Map<String, dynamic> json) {
    return StatementShare(
      name: json['name'] as String,
      owedAmount: _numValue(json['owedAmount']),
    );
  }
}

// An expense listed in the statement.
class StatementExpense {
  final int id;
  final DateTime date;
  final String? description;
  // One of: RENT, UTILITIES, GROCERIES, OTHER
  final String category;
  final double amount;
  final String paidByName;
  // One of: EQUAL, PERCENT, AMOUNT
  final String splitType;
  final List<StatementShare> shares;

  StatementExpense({
    required this.id,
    required this.date,
    required this.description,
    required this.category,
    required this.amount,
    required this.paidByName,
    required this.splitType,
    required this.shares,
  });

  factory StatementExpense.fromJson(Map<String, dynamic> json) {
    final rawShares = json['shares'] as List<dynamic>? ?? const [];
    return StatementExpense(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      description: _optionalText(json['description']),
      category: json['category'] as String,
      amount: _numValue(json['amount']),
      paidByName: json['paidByName'] as String,
      splitType: json['splitType'] as String? ?? 'EQUAL',
      shares: [
        for (final item in rawShares)
          StatementShare.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

// A payment listed in the statement. paidAt is converted to the phone's time zone.
class StatementPayment {
  final int id;
  final DateTime paidAt;
  final String fromName;
  final String toName;
  final double amount;
  final String? note;

  StatementPayment({
    required this.id,
    required this.paidAt,
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.note,
  });

  factory StatementPayment.fromJson(Map<String, dynamic> json) {
    return StatementPayment(
      id: json['id'] as int,
      paidAt: DateTime.parse(json['paidAt'] as String).toLocal(),
      fromName: json['fromName'] as String,
      toName: json['toName'] as String,
      amount: _numValue(json['amount']),
      note: _optionalText(json['note']),
    );
  }
}

// The whole statement of one home for one period. from and to are both inclusive.
class Statement {
  final DateTime from;
  final DateTime to;
  final String householdName;
  final double totalExpenses;
  final int expenseCount;
  final double totalPayments;
  final int paymentCount;
  final List<StatementMember> members;
  final DominantPayer? dominantPayer;
  final List<StatementCategory> categories;
  // Six months, oldest first.
  final List<TrendMonth> trend;
  final List<StatementExpense> expenses;
  final List<StatementPayment> payments;

  Statement({
    required this.from,
    required this.to,
    required this.householdName,
    required this.totalExpenses,
    required this.expenseCount,
    required this.totalPayments,
    required this.paymentCount,
    required this.members,
    required this.dominantPayer,
    required this.categories,
    required this.trend,
    required this.expenses,
    required this.payments,
  });

  factory Statement.fromJson(Map<String, dynamic> json) {
    final dominant = json['dominantPayer'];
    return Statement(
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      householdName: json['householdName'] as String,
      totalExpenses: _numValue(json['totalExpenses']),
      expenseCount: _countValue(json['expenseCount']),
      totalPayments: _numValue(json['totalPayments']),
      paymentCount: _countValue(json['paymentCount']),
      members: [
        for (final item in _list(json['members']))
          StatementMember.fromJson(item),
      ],
      dominantPayer: dominant is Map<String, dynamic>
          ? DominantPayer.fromJson(dominant)
          : null,
      categories: [
        for (final item in _list(json['categories']))
          StatementCategory.fromJson(item),
      ],
      trend: [
        for (final item in _list(json['trend'])) TrendMonth.fromJson(item),
      ],
      expenses: [
        for (final item in _list(json['expenses'])) StatementExpense.fromJson(item),
      ],
      payments: [
        for (final item in _list(json['payments'])) StatementPayment.fromJson(item),
      ],
    );
  }

  // Turns a JSON array into maps. A missing array counts as empty.
  static List<Map<String, dynamic>> _list(Object? value) {
    final items = value as List<dynamic>? ?? const [];
    return [for (final item in items) item as Map<String, dynamic>];
  }
}

// The kinds of notification the API sends. A kind the app does not know yet is unknown.
enum NotificationType {
  expenseAdded,
  paymentRecorded,
  invitationReceived,
  invitationAccepted,
  recurringExpenseAdded,
  // Someone asks me (the debtor) to pay them back.
  paymentReminder,
  // Someone edited an expense or a payment. previousAmount is set when the amount changed.
  expenseUpdated,
  paymentUpdated,
  // A chore came to my turn (sent to the person who is next). actorName did the chore.
  choreTurn,
  // Someone asks me to do my chore turn. actorName sent the reminder.
  choreReminder,
  unknown;

  static NotificationType fromApi(String value) => switch (value) {
        'EXPENSE_ADDED' => expenseAdded,
        'PAYMENT_RECORDED' => paymentRecorded,
        'INVITATION_RECEIVED' => invitationReceived,
        'INVITATION_ACCEPTED' => invitationAccepted,
        'RECURRING_EXPENSE_ADDED' => recurringExpenseAdded,
        'PAYMENT_REMINDER' => paymentReminder,
        'EXPENSE_UPDATED' => expenseUpdated,
        'PAYMENT_UPDATED' => paymentUpdated,
        'CHORE_TURN' => choreTurn,
        'CHORE_REMINDER' => choreReminder,
        _ => unknown,
      };
}

// One item from GET /api/notifications. The server sends data only, so the app
// writes the text in the current language (see utils/notification_text.dart).
class AppNotification {
  final int id;
  final NotificationType type;
  final int? householdId;
  final String householdName;
  // The person who caused it, for example who added the expense.
  final String actorName;
  // The other person, for example the receiver of a payment. Null for other types.
  final String? targetName;
  final double? amount;
  // The amount before an edit. Only set when the amount changed (EXPENSE_UPDATED, PAYMENT_UPDATED).
  final double? previousAmount;
  // For example the expense description "Market". Null when there is none.
  final String? detail;
  final int? expenseId;
  final int? paymentId;
  final int? invitationId;
  // Changed on the phone when the user reads it, so the list updates at once.
  bool read;
  // Converted to the phone's time zone.
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.householdId,
    required this.householdName,
    required this.actorName,
    required this.targetName,
    required this.amount,
    required this.previousAmount,
    required this.detail,
    required this.expenseId,
    required this.paymentId,
    required this.invitationId,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: NotificationType.fromApi(json['type'] as String? ?? ''),
      householdId: json['householdId'] as int?,
      householdName: json['householdName'] as String? ?? '',
      actorName: json['actorName'] as String? ?? '',
      targetName: _optionalText(json['targetName']),
      amount: (json['amount'] as num?)?.toDouble(),
      previousAmount: (json['previousAmount'] as num?)?.toDouble(),
      detail: _optionalText(json['detail']),
      expenseId: json['expenseId'] as int?,
      paymentId: json['paymentId'] as int?,
      invitationId: json['invitationId'] as int?,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}

// ---- Chores (GET /api/households/{id}/chores) ----

// One person in a chore's rotation.
class ChoreMember {
  final int userId;
  final String name;

  ChoreMember({required this.userId, required this.name});

  factory ChoreMember.fromJson(Map<String, dynamic> json) {
    return ChoreMember(
      userId: json['userId'] as int,
      name: json['name'] as String,
    );
  }
}

// One time a chore was marked as done.
class ChoreCompletion {
  final String userName;
  // Converted to the phone's time zone.
  final DateTime doneAt;

  ChoreCompletion({required this.userName, required this.doneAt});

  factory ChoreCompletion.fromJson(Map<String, dynamic> json) {
    return ChoreCompletion(
      userName: json['userName'] as String,
      doneAt: DateTime.parse(json['doneAt'] as String).toLocal(),
    );
  }
}

// A household chore. currentUserId is whose turn it is now (null when nobody is up).
class Chore {
  final int id;
  final String name;
  // The turn order. The turn moves to the next person after each "done".
  final List<ChoreMember> rotation;
  final int? currentUserId;
  final String? currentUserName;
  // The latest completions, newest first (at most 5).
  final List<ChoreCompletion> recentCompletions;
  // Until when nobody may remind the current person again. Null when a reminder is allowed.
  final DateTime? reminderAvailableAt;

  Chore({
    required this.id,
    required this.name,
    required this.rotation,
    required this.currentUserId,
    required this.currentUserName,
    required this.recentCompletions,
    required this.reminderAvailableAt,
  });

  factory Chore.fromJson(Map<String, dynamic> json) {
    final rawRotation = json['rotation'] as List<dynamic>? ?? const [];
    final rawCompletions = json['recentCompletions'] as List<dynamic>? ?? const [];
    return Chore(
      id: json['id'] as int,
      name: json['name'] as String,
      rotation: [
        for (final item in rawRotation)
          ChoreMember.fromJson(item as Map<String, dynamic>),
      ],
      currentUserId: json['currentUserId'] as int?,
      currentUserName: _optionalText(json['currentUserName']),
      recentCompletions: [
        for (final item in rawCompletions)
          ChoreCompletion.fromJson(item as Map<String, dynamic>),
      ],
      reminderAvailableAt: _optionalDate(json['reminderAvailableAt'])?.toLocal(),
    );
  }
}

// Reads a JSON number as a double. Missing or odd values count as 0.
double _numValue(Object? value) => value is num ? value.toDouble() : 0;

// Reads a count sent as a JSON number. Missing or odd values count as 0.
int _countValue(Object? value) => value is num ? value.toInt() : 0;

// The kinds of change in the home's history. A kind the app does not know yet is unknown.
enum ActivityType {
  householdCreated,
  householdRenamed,
  ownershipTransferred,
  memberJoined,
  memberLeft,
  memberRemoved,
  memberRoleChanged,
  expenseAdded,
  expenseUpdated,
  expenseDeleted,
  recurringExpenseGenerated,
  paymentAdded,
  paymentUpdated,
  paymentDeleted,
  choreAdded,
  choreUpdated,
  choreDeleted,
  unknown;

  static ActivityType fromApi(String value) => switch (value) {
        'HOUSEHOLD_CREATED' => householdCreated,
        'HOUSEHOLD_RENAMED' => householdRenamed,
        'OWNERSHIP_TRANSFERRED' => ownershipTransferred,
        'MEMBER_JOINED' => memberJoined,
        'MEMBER_LEFT' => memberLeft,
        'MEMBER_REMOVED' => memberRemoved,
        'MEMBER_ROLE_CHANGED' => memberRoleChanged,
        'EXPENSE_ADDED' => expenseAdded,
        'EXPENSE_UPDATED' => expenseUpdated,
        'EXPENSE_DELETED' => expenseDeleted,
        'RECURRING_EXPENSE_GENERATED' => recurringExpenseGenerated,
        'PAYMENT_ADDED' => paymentAdded,
        'PAYMENT_UPDATED' => paymentUpdated,
        'PAYMENT_DELETED' => paymentDeleted,
        'CHORE_ADDED' => choreAdded,
        'CHORE_UPDATED' => choreUpdated,
        'CHORE_DELETED' => choreDeleted,
        _ => unknown,
      };
}

// One field that changed in a history item. Values are text, as the API sends them.
class ActivityChange {
  // The API's field name, for example "amount" or "paidBy".
  final String field;
  // Null when there was no old value (or no new value).
  final String? oldValue;
  final String? newValue;
  // For "share" changes: the person whose share changed. Null for other fields.
  final int? userId;
  final String? personName;

  ActivityChange({
    required this.field,
    required this.oldValue,
    required this.newValue,
    this.userId,
    this.personName,
  });

  factory ActivityChange.fromJson(Map<String, dynamic> json) {
    return ActivityChange(
      field: json['field'] as String? ?? '',
      oldValue: json['oldValue']?.toString(),
      newValue: json['newValue']?.toString(),
      userId: json['userId'] as int?,
      personName: _optionalText(json['personName']),
    );
  }
}

// One item from GET /api/households/{id}/activity. The server sends data only, so the
// app writes the sentence in the current language (see utils/activity_text.dart).
class ActivityEntry {
  final int id;
  final ActivityType type;
  // The person who did it. Null for recurring expenses, which the app adds by itself.
  final int? actorUserId;
  final String? actorName;
  // The person the action is about, for example who joined or whose payment it was.
  final int? subjectUserId;
  final String? subjectName;
  // The other person in a payment (the receiver). Null for other types.
  final int? otherUserId;
  final String? otherName;
  final double? amount;
  // The expense description. Null when there is none.
  final String? label;
  final int? expenseId;
  final int? paymentId;
  // Empty when nothing changed in a readable way.
  final List<ActivityChange> changes;
  // Converted to the phone's time zone.
  final DateTime createdAt;

  ActivityEntry({
    required this.id,
    required this.type,
    required this.actorUserId,
    required this.actorName,
    required this.subjectUserId,
    required this.subjectName,
    required this.otherUserId,
    required this.otherName,
    required this.amount,
    required this.label,
    required this.expenseId,
    required this.paymentId,
    required this.changes,
    required this.createdAt,
  });

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    final rawChanges = json['changes'] as List<dynamic>? ?? const [];
    return ActivityEntry(
      id: json['id'] as int,
      type: ActivityType.fromApi(json['type'] as String? ?? ''),
      actorUserId: json['actorUserId'] as int?,
      actorName: _optionalText(json['actorName']),
      subjectUserId: json['subjectUserId'] as int?,
      subjectName: _optionalText(json['subjectName']),
      otherUserId: json['otherUserId'] as int?,
      otherName: _optionalText(json['otherName']),
      amount: (json['amount'] as num?)?.toDouble(),
      label: _optionalText(json['label']),
      expenseId: json['expenseId'] as int?,
      paymentId: json['paymentId'] as int?,
      changes: [
        for (final item in rawChanges)
          ActivityChange.fromJson(item as Map<String, dynamic>),
      ],
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}

// The logged in user's own profile, from GET /api/users/me.
class UserProfile {
  final int id;
  final String name;
  final String email;
  // The saved IBAN without spaces, or null if none is set.
  final String? iban;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.iban,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      iban: _optionalText(json['iban']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// A home that blocks account deletion, from GET /api/users/me/deletion-check.
// reason is FOUNDER_WITH_MEMBERS or LAST_ADMIN_WITH_MEMBERS.
class DeletionBlocker {
  final int householdId;
  final String householdName;
  final String reason;

  DeletionBlocker({
    required this.householdId,
    required this.householdName,
    required this.reason,
  });

  factory DeletionBlocker.fromJson(Map<String, dynamic> json) {
    return DeletionBlocker(
      householdId: json['householdId'] as int,
      householdName: json['householdName'] as String,
      reason: json['reason'] as String,
    );
  }
}

// The money still open in one home. net > 0: the home owes the user. net < 0: the user owes the home.
class DeletionOpenBalance {
  final int householdId;
  final String householdName;
  final double net;

  DeletionOpenBalance({
    required this.householdId,
    required this.householdName,
    required this.net,
  });

  factory DeletionOpenBalance.fromJson(Map<String, dynamic> json) {
    return DeletionOpenBalance(
      householdId: json['householdId'] as int,
      householdName: json['householdName'] as String,
      net: _numValue(json['net']),
    );
  }
}

// What deleting the account would do, from GET /api/users/me/deletion-check.
class DeletionCheck {
  final List<DeletionBlocker> blockers;
  final List<DeletionOpenBalance> openBalances;
  // Names of the homes where the user is alone. They are deleted with the account.
  final List<String> householdsToDelete;

  DeletionCheck({
    required this.blockers,
    required this.openBalances,
    required this.householdsToDelete,
  });

  factory DeletionCheck.fromJson(Map<String, dynamic> json) {
    return DeletionCheck(
      blockers: [
        for (final item in _list(json['blockers']))
          DeletionBlocker.fromJson(item),
      ],
      openBalances: [
        for (final item in _list(json['openBalances']))
          DeletionOpenBalance.fromJson(item),
      ],
      householdsToDelete: [
        for (final name in json['householdsToDelete'] as List<dynamic>? ?? const [])
          name as String,
      ],
    );
  }

  static List<Map<String, dynamic>> _list(Object? value) {
    final items = value as List<dynamic>? ?? const [];
    return [for (final item in items) item as Map<String, dynamic>];
  }
}

// Blank text from the API counts as "not set".
String? _optionalText(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value;
}

// Blank or missing dates count as "not set".
DateTime? _optionalDate(Object? value) {
  final text = _optionalText(value);
  return text == null ? null : DateTime.parse(text);
}
