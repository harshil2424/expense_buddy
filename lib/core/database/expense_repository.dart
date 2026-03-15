import 'package:intl/intl.dart';
import '../models/models.dart';
import 'database_helper.dart';

class ExpenseRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> addTransaction(Transaction t) async {
    await _db.insertTransaction(t.toMap());
  }

  Future<List<Transaction>> getTransactions() async {
    final List<Map<String, dynamic>> maps = await _db.getAllTransactions();
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getTransactionsForMonth(DateTime month) async {
    final monthStr = DateFormat('yyyy-MM').format(month);
    final List<Map<String, dynamic>> maps = await _db.getTransactionsByMonth(monthStr);
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
  }

  Future<void> updateTransaction(Transaction t) async {
    await _db.updateTransaction(t.id, t.toMap());
  }

  Future<void> setMonthlyBudget(double amount, DateTime month) async {
    final monthStr = DateFormat('yyyy-MM').format(month);
    await _db.setBudget(amount, monthStr);
  }

  Future<double?> getMonthlyBudget(DateTime month) async {
    final monthStr = DateFormat('yyyy-MM').format(month);
    final map = await _db.getBudget(monthStr);
    if (map != null) {
      return map['monthly_limit'] as double;
    }
    return null;
  }
}
