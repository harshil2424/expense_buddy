import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/providers/expense_provider.dart';
import '../../../../core/providers/budget_provider.dart';
import '../../../../core/models/models.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/budget_bottom_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedFilter = 1; // Default to 'This month'
  final List<String> _filters = ['This week', 'This month', 'This year'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseProvider = context.watch<ExpenseProvider>();

    return Scaffold(
      body: SafeArea(
        child: expenseProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(isDark: isDark),
                    _PageTitle(),
                    if (expenseProvider.transactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: AppColors.neutral.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              const Text(
                                "No expenses yet",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Tap + to add your first expense",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _MainExpenseCard(
                          selectedFilter: _selectedFilter,
                          filters: _filters,
                          onFilterChanged: (i) => setState(() => _selectedFilter = i),
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                AppConstants.defaultUserName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://i.pravatar.cc/150?img=33',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page Title ───────────────────────────────────────────────────────────────

class _PageTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Text(
        'Manage your\nexpenses',
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          fontSize: 36,
          height: 1.15,
        ),
      ),
    );
  }
}

// ─── Main Expense Card ────────────────────────────────────────────────────────

class _MainExpenseCard extends StatelessWidget {
  final int selectedFilter;
  final List<String> filters;
  final ValueChanged<int> onFilterChanged;
  final bool isDark;

  const _MainExpenseCard({
    required this.selectedFilter,
    required this.filters,
    required this.onFilterChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final now = expenseProvider.selectedMonth;
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final dateRange = '${DateFormat('MMM d').format(firstDay)} - ${DateFormat('MMM d, yyyy').format(lastDay)}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Card header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expenses', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    dateRange,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Text(
                currencyFormat.format(expenseProvider.totalExpenses),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Donut chart + legend
          _DonutWithLegend(isDark: isDark),

          const SizedBox(height: 24),

          // Time filters
          FilterChipRow(
            filters: filters,
            selectedIndex: selectedFilter,
            onSelected: onFilterChanged,
          ),

          const SizedBox(height: 24),

          // Income / Expense progress cards
          _ProgressCards(isDark: isDark),

          const SizedBox(height: 16),

          // Bottom banner
          _StatusBanner(),
        ],
      ),
    );
  }
}

class _DonutWithLegend extends StatelessWidget {
  final bool isDark;
  const _DonutWithLegend({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final categoryTotals = expenseProvider.categoryTotals;
    final totalExpenses = expenseProvider.totalExpenses;

    List<DonutSegment> segments = [];
    if (categoryTotals.isEmpty) {
      segments = [DonutSegment(percentage: 100, color: Colors.grey.shade300)];
    } else {
      categoryTotals.forEach((cat, amount) {
        final percentage = totalExpenses > 0 ? (amount / totalExpenses * 100) : 0.0;
        segments.add(DonutSegment(percentage: percentage, color: cat.color));
      });
    }

    // Prepare legend items (top 3)
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(3).toList();

    return Row(
      children: [
        // Donut chart
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(140, 140),
                painter: DonutChartPainter(segments: segments, strokeWidth: 16),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '100%',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 24),

        // Legend
        Expanded(
          child: Column(
            children: topCategories.isEmpty
                ? [const Text("No data available")]
                : topCategories.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _LegendItem(
                        color: entry.key.color,
                        label: entry.key.label,
                        amount: NumberFormat.currency(symbol: '\$').format(entry.value),
                        isDark: isDark,
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;
  final bool isDark;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}

class _ProgressCards extends StatelessWidget {
  final bool isDark;
  const _ProgressCards({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final incomeProgress = expenseProvider.totalIncome > 0
        ? (expenseProvider.totalExpenses / expenseProvider.totalIncome).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _ProgressCard(
            label: 'Income',
            amount: currencyFormat.format(expenseProvider.totalIncome),
            progress: incomeProgress,
            color: AppColors.income,
            textColor: AppColors.income,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProgressCard(
            label: 'Expenses',
            amount: currencyFormat.format(expenseProvider.totalExpenses),
            progress: budgetProvider.usedPercentage / 100,
            color: budgetProvider.statusColor,
            textColor: budgetProvider.statusColor,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String label;
  final String amount;
  final double progress;
  final Color color;
  final Color textColor;
  final bool isDark;

  const _ProgressCard({
    required this.label,
    required this.amount,
    required this.progress,
    required this.color,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgetProvider = context.watch<BudgetProvider>();

    String message;
    String emoji;
    Color bgColor;
    Color textColor;

    if (budgetProvider.isOverBudget) {
      message = "⚠️ You have exceeded your budget!";
      emoji = "⚠️";
      bgColor = isDark ? Colors.red.withValues(alpha: 0.2) : const Color(0xFFFEF2F2);
      textColor = isDark ? Colors.red.shade200 : const Color(0xFF991B1B);
    } else if (budgetProvider.isNearLimit) {
      message = "⚡ You are nearing your budget limit";
      emoji = "⚡";
      bgColor = isDark ? Colors.orange.withValues(alpha: 0.2) : const Color(0xFFFFFBEB);
      textColor = isDark ? Colors.orange.shade200 : const Color(0xFF92400E);
    } else if (budgetProvider.hasBudget) {
      message = "👍 Great job! Spending is on track";
      emoji = "👍";
      bgColor = isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFF0FDF4);
      textColor = isDark ? Colors.green.shade200 : const Color(0xFF166534);
    } else {
      message = "💡 Set a budget to track your progress";
      emoji = "💡";
      bgColor = isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFEFF6FF);
      textColor = isDark ? Colors.blue.shade200 : const Color(0xFF1E40AF);
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const BudgetBottomSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
