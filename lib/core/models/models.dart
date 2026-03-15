import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Expense Category ───────────────────────────────────────────────────────

enum ExpenseCategory {
  food,
  transport,
  shopping,
  leisure,
  health,
  rent,
  entertainment,
  other,
}

extension ExpenseCategoryExt on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food: return 'Food';
      case ExpenseCategory.transport: return 'Transport';
      case ExpenseCategory.shopping: return 'Shopping';
      case ExpenseCategory.leisure: return 'Leisure';
      case ExpenseCategory.health: return 'Health';
      case ExpenseCategory.rent: return 'Rent';
      case ExpenseCategory.entertainment: return 'Entertainment';
      case ExpenseCategory.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food: return Icons.restaurant;
      case ExpenseCategory.transport: return Icons.directions_car;
      case ExpenseCategory.shopping: return Icons.shopping_bag;
      case ExpenseCategory.leisure: return Icons.movie;
      case ExpenseCategory.health: return Icons.medication;
      case ExpenseCategory.rent: return Icons.home;
      case ExpenseCategory.entertainment: return Icons.subscriptions;
      case ExpenseCategory.other: return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food: return AppColors.categoryFood;
      case ExpenseCategory.transport: return AppColors.blue500;
      case ExpenseCategory.shopping: return AppColors.categoryShopping;
      case ExpenseCategory.leisure: return AppColors.purple500;
      case ExpenseCategory.health: return AppColors.categoryHealth;
      case ExpenseCategory.rent: return AppColors.categoryRent;
      case ExpenseCategory.entertainment: return AppColors.categoryEntertainment;
      case ExpenseCategory.other: return AppColors.neutral;
    }
  }

  Color get bgColor {
    switch (this) {
      case ExpenseCategory.food: return AppColors.orange100;
      case ExpenseCategory.transport: return AppColors.blue100;
      case ExpenseCategory.shopping: return AppColors.blue100;
      case ExpenseCategory.leisure: return AppColors.purple100;
      case ExpenseCategory.health: return const Color(0xFFFEF9C3);
      case ExpenseCategory.rent: return AppColors.emerald100;
      case ExpenseCategory.entertainment: return AppColors.emerald100;
      case ExpenseCategory.other: return const Color(0xFFF1F5F9);
    }
  }
}

// ─── Transaction Model ───────────────────────────────────────────────────────

class Transaction {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final bool isIncome;
  final String? note;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.isIncome = false,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'is_income': isIncome ? 1 : 0,
      'note': note ?? '',
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      category: ExpenseCategory.values.byName(map['category']),
      date: DateTime.parse(map['date']),
      isIncome: map['is_income'] == 1,
      note: map['note'],
    );
  }
}

// ─── Insight Model ───────────────────────────────────────────────────────────

class SpendingInsight {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color badgeBgColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const SpendingInsight({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.badgeBgColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

// ─── Recommendation Model ────────────────────────────────────────────────────

class Recommendation {
  final int number;
  final String title;
  final String description;
  final String savingsLabel;

  const Recommendation({
    required this.number,
    required this.title,
    required this.description,
    required this.savingsLabel,
  });
}

// ─── Profile Menu Item ───────────────────────────────────────────────────────

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// ─── Sample Data ─────────────────────────────────────────────────────────────

class SampleData {
  static List<Transaction> get transactions => [
    Transaction(
      id: '1',
      title: 'Starbucks Coffee',
      amount: 12.50,
      category: ExpenseCategory.food,
      date: DateTime.now(),
    ),
    Transaction(
      id: '2',
      title: 'Monthly Salary',
      amount: 4500.00,
      category: ExpenseCategory.other,
      date: DateTime.now(),
      isIncome: true,
    ),
    Transaction(
      id: '3',
      title: 'Uber Trip',
      amount: 24.30,
      category: ExpenseCategory.transport,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: '4',
      title: 'Burger King',
      amount: 15.80,
      category: ExpenseCategory.food,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: '5',
      title: 'Netflix Subscription',
      amount: 19.99,
      category: ExpenseCategory.leisure,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static List<SpendingInsight> get insights => [
    SpendingInsight(
      title: 'Dining Out',
      subtitle: '15% higher than last month',
      badge: '+12%',
      badgeColor: AppColors.primary,
      badgeBgColor: AppColors.primaryLight,
      icon: Icons.restaurant,
      iconColor: AppColors.orange500,
      iconBgColor: AppColors.orange100,
    ),
    SpendingInsight(
      title: 'Subscribed Services',
      subtitle: '3 unused trials expiring soon',
      badge: 'Optimized',
      badgeColor: AppColors.emerald500,
      badgeBgColor: AppColors.emerald100,
      icon: Icons.subscriptions,
      iconColor: AppColors.emerald500,
      iconBgColor: AppColors.emerald100,
    ),
    SpendingInsight(
      title: 'Shopping Trends',
      subtitle: 'Consistent with seasonal norms',
      badge: 'Neutral',
      badgeColor: AppColors.neutral,
      badgeBgColor: const Color(0xFFF1F5F9),
      icon: Icons.shopping_bag,
      iconColor: AppColors.blue500,
      iconBgColor: AppColors.blue100,
    ),
  ];

  static List<Recommendation> get recommendations => [
    Recommendation(
      number: 1,
      title: 'Switch Internet Provider',
      description: 'Found a better plan for your area with higher speeds.',
      savingsLabel: 'Save \$15/mo',
    ),
    Recommendation(
      number: 2,
      title: 'Consolidate Debt',
      description: 'Your high-interest card balance can be transferred.',
      savingsLabel: 'Save \$42/mo',
    ),
  ];

  static List<ProfileMenuItem> get profileMenuItems => [
    ProfileMenuItem(icon: Icons.person, title: 'User Profile', subtitle: 'Manage your personal information'),
    ProfileMenuItem(icon: Icons.star, title: 'Premium Plans', subtitle: 'View your subscription details'),
    ProfileMenuItem(icon: Icons.account_balance, title: 'Accounts', subtitle: 'Link and manage bank accounts'),
    ProfileMenuItem(icon: Icons.payments, title: 'Currencies', subtitle: 'Set default trading currencies'),
    ProfileMenuItem(icon: Icons.category, title: 'Categories', subtitle: 'Organize your transaction types'),
    ProfileMenuItem(icon: Icons.shield, title: 'Security', subtitle: 'Password and authentication'),
  ];
}
