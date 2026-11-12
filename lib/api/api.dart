import 'package:intl/intl.dart';
import 'package:roommate_expense_app/api/api_client.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/session.dart';

// The API uses LocalDateTime, so dates are sent without a timezone,
// for example "2026-11-10T12:00:00".
final DateFormat _apiDateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

// Rounds money to 2 decimals, for example 12.345 -> 12.35.
double _round2(double value) => (value * 100).round() / 100;

// One participant in an expense split. value is the percent (PERCENT) or the
// amount (AMOUNT). It is null for EQUAL, where the API ignores it.
class ShareInput {
  final int userId;
  final double? value;

  ShareInput({required this.userId, required this.value});

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'value': value == null ? null : _round2(value!),
    };
  }
}

// The data needed to create or update an expense.
class ExpenseInput {
  final int paidByUserId;
  final double amount;
  // One of: RENT, UTILITIES, GROCERIES, OTHER
  final String category;
  final String? description;
  final bool recurring;
  final DateTime expenseDate;
  // One of: EQUAL, PERCENT, AMOUNT. Null on edit means "keep the stored split".
  final String? splitType;
  // The participants. Null on edit means "keep the stored split". Omitted from the JSON.
  final List<ShareInput>? shares;

  ExpenseInput({
    required this.paidByUserId,
    required this.amount,
    required this.category,
    required this.description,
    required this.recurring,
    required this.expenseDate,
    required this.splitType,
    required this.shares,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'paidByUserId': paidByUserId,
      'amount': _round2(amount),
      'category': category,
      'description': description,
      'recurring': recurring,
      'expenseDate': _apiDateFormat.format(expenseDate),
    };
    // Sending neither splitType nor shares tells the API to keep the stored split.
    if (splitType != null) json['splitType'] = splitType;
    if (shares != null) {
      json['shares'] = [for (final share in shares!) share.toJson()];
    }
    return json;
  }
}

// One static method per API call. Screens call these, never ApiClient directly.
class Api {
  // ---- Auth ----

  // Logs in and saves the token in Session.
  static Future<void> login(String email, String password) async {
    final data = await ApiClient.post(
      '/api/auth/login',
      {'email': email, 'password': password},
    ) as Map<String, dynamic>;

    await Session.saveToken(data['token'] as String);
  }

  static Future<void> register(String name, String email, String password) async {
    await ApiClient.post(
      '/api/auth/register',
      {'name': name, 'email': email, 'password': password},
    );
  }

  // ---- Households ----

  static Future<List<Household>> getHouseholds() async {
    final data = await ApiClient.get('/api/households');
    return _parseList(data, Household.fromJson);
  }

  static Future<Household> createHousehold(String name) async {
    final data = await ApiClient.post('/api/households', {'name': name});
    return Household.fromJson(data as Map<String, dynamic>);
  }

  static Future<Household> renameHousehold(int id, String name) async {
    final data = await ApiClient.put('/api/households/$id', {'name': name});
    return Household.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteHousehold(int id) async {
    await ApiClient.delete('/api/households/$id');
  }

  // ---- Members ----

  static Future<List<Member>> getMembers(int householdId) async {
    final data = await ApiClient.get('/api/households/$householdId/members');
    return _parseList(data, Member.fromJson);
  }

  static Future<void> removeMember(int householdId, int userId) async {
    await ApiClient.delete('/api/households/$householdId/members/$userId');
  }

  // Leaving is removing yourself. Any member may do it, but the last admin may not.
  static Future<void> leaveHousehold(int householdId, int myUserId) {
    return removeMember(householdId, myUserId);
  }

  // Admins only. role is "ADMIN" or "MEMBER". Demoting the last admin fails with 409.
  static Future<Member> changeRole(int householdId, int userId, String role) async {
    final data = await ApiClient.patch(
      '/api/households/$householdId/members/$userId',
      {'role': role},
    );
    return Member.fromJson(data as Map<String, dynamic>);
  }

  // Founder only. The new founder is made an admin if needed. The founder stays an admin.
  static Future<void> transferOwnership(int householdId, int userId) async {
    await ApiClient.post(
      '/api/households/$householdId/transfer-ownership',
      {'userId': userId},
    );
  }

  // ---- Invitations ----

  // Admins only. The invitee has to accept before joining.
  static Future<Invitation> inviteMember(int householdId, String email) async {
    final data = await ApiClient.post(
      '/api/households/$householdId/invitations',
      {'email': email},
    );
    return Invitation.fromJson(data as Map<String, dynamic>);
  }

  // Pending invitations of one home. Any member can see them.
  static Future<List<Invitation>> getHouseholdInvitations(int householdId) async {
    final data = await ApiClient.get('/api/households/$householdId/invitations');
    return _parseList(data, Invitation.fromJson);
  }

  // Admins only. Cancels a pending invitation.
  static Future<void> cancelInvitation(int householdId, int invitationId) async {
    await ApiClient.delete('/api/households/$householdId/invitations/$invitationId');
  }

  // My pending invitations, from every home.
  static Future<List<Invitation>> getMyInvitations() async {
    final data = await ApiClient.get('/api/invitations');
    return _parseList(data, Invitation.fromJson);
  }

  // Accepting joins the home. Returns the home, as GET /api/households/{id} does.
  static Future<Household> acceptInvitation(int invitationId) async {
    final data = await ApiClient.post('/api/invitations/$invitationId/accept');
    return Household.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> declineInvitation(int invitationId) async {
    await ApiClient.post('/api/invitations/$invitationId/decline');
  }

  // ---- Expenses ----

  // Newest expense date first.
  static Future<List<Expense>> getExpenses(int householdId) async {
    final data = await ApiClient.get('/api/households/$householdId/expenses');
    final expenses = _parseList(data, Expense.fromJson);
    expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return expenses;
  }

  static Future<Expense> createExpense(int householdId, ExpenseInput input) async {
    final data = await ApiClient.post(
      '/api/households/$householdId/expenses',
      input.toJson(),
    );
    return Expense.fromJson(data as Map<String, dynamic>);
  }

  static Future<Expense> updateExpense(
    int householdId,
    int expenseId,
    ExpenseInput input,
  ) async {
    final data = await ApiClient.put(
      '/api/households/$householdId/expenses/$expenseId',
      input.toJson(),
    );
    return Expense.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteExpense(int householdId, int expenseId) async {
    await ApiClient.delete('/api/households/$householdId/expenses/$expenseId');
  }

  // ---- Category split defaults ----

  // Only the categories that have a default are returned.
  static Future<List<CategorySplitDefault>> getSplitDefaults(int householdId) async {
    final data = await ApiClient.get('/api/households/$householdId/split-defaults');
    return _parseList(data, CategorySplitDefault.fromJson);
  }

  // percents maps userId to percent. Admins only. The API checks that the total is 100.
  static Future<CategorySplitDefault> saveSplitDefault(
    int householdId,
    String category,
    Map<int, double> percents,
  ) async {
    final data = await ApiClient.put(
      '/api/households/$householdId/split-defaults/$category',
      {
        'shares': [
          for (final entry in percents.entries)
            {'userId': entry.key, 'value': _round2(entry.value)},
        ],
      },
    );
    return CategorySplitDefault.fromJson(data as Map<String, dynamic>);
  }

  // Admins only.
  static Future<void> deleteSplitDefault(int householdId, String category) async {
    await ApiClient.delete('/api/households/$householdId/split-defaults/$category');
  }

  // ---- Balances and settlements ----

  static Future<List<Balance>> getBalances(int householdId) async {
    final data = await ApiClient.get('/api/households/$householdId/balances');
    return _parseList(data, Balance.fromJson);
  }

  static Future<List<Settlement>> getSettlements(int householdId) async {
    final data = await ApiClient.get('/api/households/$householdId/settlements');
    return _parseList(data, Settlement.fromJson);
  }

  // ---- Payments ----

  // Newest payment first.
  static Future<List<Payment>> getPayments(int householdId) async {
    final data = await ApiClient.get('/api/households/$householdId/payments');
    final payments = _parseList(data, Payment.fromJson);
    payments.sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return payments;
  }

  // note is optional and up to 200 characters. Null means no note.
  static Future<Payment> createPayment(
    int householdId,
    int fromUserId,
    int toUserId,
    double amount, [
    String? note,
  ]) async {
    final data = await ApiClient.post(
      '/api/households/$householdId/payments',
      {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': _round2(amount),
        'note': note,
      },
    );
    return Payment.fromJson(data as Map<String, dynamic>);
  }

  // Only the original sender or an admin may edit. A null note clears the note.
  static Future<Payment> updatePayment(
    int householdId,
    int paymentId, {
    required int fromUserId,
    required int toUserId,
    required double amount,
    required String? note,
  }) async {
    final data = await ApiClient.put(
      '/api/households/$householdId/payments/$paymentId',
      {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': _round2(amount),
        'note': note,
      },
    );
    return Payment.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deletePayment(int householdId, int paymentId) async {
    await ApiClient.delete('/api/households/$householdId/payments/$paymentId');
  }

  // ---- Profile ----

  static Future<UserProfile> getProfile() async {
    final data = await ApiClient.get('/api/users/me');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  // An empty iban removes the saved IBAN. The API stores it without spaces.
  static Future<UserProfile> updateProfile(String name, String iban) async {
    final data = await ApiClient.put('/api/users/me', {'name': name, 'iban': iban});
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> changePassword(String currentPassword, String newPassword) async {
    await ApiClient.put('/api/users/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // Turns a JSON array into a list of models.
  static List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = data as List<dynamic>;
    return items
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
