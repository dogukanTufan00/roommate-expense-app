import 'package:intl/intl.dart';
import 'package:roommate_expense_app/api/api_client.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/session.dart';

// The API uses LocalDateTime, so dates are sent without a timezone,
// for example "2026-11-10T12:00:00".
final DateFormat _apiDateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

// Rounds money to 2 decimals, for example 12.345 -> 12.35.
double _round2(double value) => (value * 100).round() / 100;

// The data needed to create or update an expense.
class ExpenseInput {
  final int paidByUserId;
  final double amount;
  // One of: RENT, UTILITIES, GROCERIES, OTHER
  final String category;
  final String? description;
  final bool recurring;
  final DateTime expenseDate;

  ExpenseInput({
    required this.paidByUserId,
    required this.amount,
    required this.category,
    required this.description,
    required this.recurring,
    required this.expenseDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'paidByUserId': paidByUserId,
      'amount': _round2(amount),
      'category': category,
      'description': description,
      'recurring': recurring,
      'expenseDate': _apiDateFormat.format(expenseDate),
    };
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

  static Future<Member> addMember(int householdId, String email) async {
    final data = await ApiClient.post(
      '/api/households/$householdId/members',
      {'email': email},
    );
    return Member.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> removeMember(int householdId, int userId) async {
    await ApiClient.delete('/api/households/$householdId/members/$userId');
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

  static Future<Payment> createPayment(
    int householdId,
    int fromUserId,
    int toUserId,
    double amount,
  ) async {
    final data = await ApiClient.post(
      '/api/households/$householdId/payments',
      {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': _round2(amount),
      },
    );
    return Payment.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deletePayment(int householdId, int paymentId) async {
    await ApiClient.delete('/api/households/$householdId/payments/$paymentId');
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
