import 'package:flutter/material.dart';
import '../database/expense_repository.dart';
import 'expense_provider.dart';

class BudgetProvider extends ChangeNotifier {
  final ExpenseProvider _expenseProvider;
  double _monthlyLimit = 0.0;
  final ExpenseRepository _repository = ExpenseRepository();

  BudgetProvider(this._expenseProvider) {
    loadBudget(DateTime.now());
  }

  // Getters
  double get monthlyLimit => _monthlyLimit;

  double get usedAmount => _expenseProvider.totalExpenses;

  double get remainingAmount => (_monthlyLimit - usedAmount).clamp(0, double.infinity);

  double get usedPercentage =>
      _monthlyLimit > 0 ? (usedAmount / _monthlyLimit * 100).clamp(0, 100) : 0;

  bool get isOverBudget => usedAmount > _monthlyLimit && _monthlyLimit > 0;

  bool get isNearLimit => usedPercentage >= 80 && !isOverBudget;

  bool get hasBudget => _monthlyLimit > 0;

  Color get statusColor {
    if (usedPercentage < 60) return const Color(0xFF10B981); // green
    if (usedPercentage < 80) return const Color(0xFFF59E0B); // yellow
    return const Color(0xFFFF6B6B); // red
  }

  // Methods
  Future<void> loadBudget(DateTime month) async {
    try {
      final result = await _repository.getMonthlyBudget(month);
      if (result != null) {
        _monthlyLimit = result;
      } else {
        _monthlyLimit = 0.0;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading budget: $e');
    }
  }

  Future<void> setBudget(double amount, DateTime month) async {
    try {
      await _repository.setMonthlyBudget(amount, month);
      _monthlyLimit = amount;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting budget: $e');
    }
  }

  void update(ExpenseProvider expenseProvider) {
    // This is called by ProxyProvider when ExpenseProvider updates
    notifyListeners();
  }
}
