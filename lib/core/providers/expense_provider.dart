import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime.now();
  final ExpenseRepository _repository = ExpenseRepository();

  ExpenseProvider() {
    loadTransactions();
  }

  // Getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;

  double get totalExpenses {
    return _transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<ExpenseCategory, double> get categoryTotals {
    final Map<ExpenseCategory, double> totals = {};
    for (var t in _transactions) {
      if (!t.isIncome) {
        totals[t.category] = (totals[t.category] ?? 0.0) + t.amount;
      }
    }
    return totals;
  }

  List<Transaction> get recentTransactions {
    final sorted = List<Transaction>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  // Methods
  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _repository.getTransactionsForMonth(_selectedMonth);
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction t) async {
    await _repository.addTransaction(t);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    await loadTransactions();
  }

  Future<void> updateTransaction(Transaction t) async {
    await _repository.updateTransaction(t);
    await loadTransactions();
  }

  void setMonth(DateTime month) {
    _selectedMonth = month;
    loadTransactions();
  }
}
