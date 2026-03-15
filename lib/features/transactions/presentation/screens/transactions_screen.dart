import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/providers/expense_provider.dart';
import '../../../../features/add_expense/presentation/screens/add_expense_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _selectedFilter = 1; // Default to 'This month'
  final List<String> _filters = ['This week', 'This month', 'This year'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter and group transactions
  Map<String, List<Transaction>> _getGroupedTransactions(List<Transaction> all) {
    final query = _searchController.text.toLowerCase();
    
    // Filter by search and selected time range
    final filtered = all.where((t) {
      // Search filter
      final matchesSearch = t.title.toLowerCase().contains(query) || 
                          t.category.label.toLowerCase().contains(query);
      if (!matchesSearch) return false;

      // Time range filter
      final now = DateTime.now();
      switch (_selectedFilter) {
        case 0: // This week
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return t.date.isAfter(DateTime(weekStart.year, weekStart.month, weekStart.day).subtract(const Duration(seconds: 1)));
        case 1: // This month
          return t.date.year == now.year && t.date.month == now.month;
        case 2: // This year
          return t.date.year == now.year;
        default:
          return true;
      }
    }).toList();

    // Sort by date descending
    filtered.sort((a, b) => b.date.compareTo(a.date));

    // Grouping
    final Map<String, List<Transaction>> map = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final t in filtered) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      String label;
      
      if (tDate.isAtSameMomentAs(today)) {
        label = 'Today';
      } else if (tDate.isAtSameMomentAs(yesterday)) {
        label = 'Yesterday';
      } else {
        label = DateFormat('MMMM d, yyyy').format(t.date);
      }
      map.putIfAbsent(label, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseProvider = context.watch<ExpenseProvider>();
    final grouped = _getGroupedTransactions(expenseProvider.transactions);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: _SearchBar(controller: _searchController, isDark: isDark),
            ),

            // Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: FilterChipRow(
                filters: _filters,
                selectedIndex: _selectedFilter,
                onSelected: (i) => setState(() => _selectedFilter = i),
              ),
            ),

            // Transaction List
            Expanded(
              child: grouped.isEmpty 
                  ? _EmptyState(isDark: isDark)
                  : ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                children: grouped.entries.map((entry) {
                  return _TransactionGroup(
                    label: entry.key,
                    transactions: entry.value,
                    onTransactionTap: (t) => _onTransactionTap(context, t),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTransactionTap(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AddExpenseScreen(transaction: transaction),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Transactions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28)),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1) 
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.tune_rounded, size: 22),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 80,
            color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.2) : AppColors.textSecondaryLight.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const _SearchBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search transactions',
          hintStyle: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: controller.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => controller.clear(),
                ) 
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ─── Transaction Group ────────────────────────────────────────────────────────

class _TransactionGroup extends StatelessWidget {
  final String label;
  final List<Transaction> transactions;
  final Function(Transaction) onTransactionTap;

  const _TransactionGroup({
    required this.label, 
    required this.transactions,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        SectionHeader(title: label),
        const SizedBox(height: 14),
        ...transactions.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TransactionCard(
            transaction: t,
            onTap: () => onTransactionTap(t),
          ),
        )),
      ],
    );
  }
}
