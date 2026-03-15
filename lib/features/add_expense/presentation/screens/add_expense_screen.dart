import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Transaction? transaction;
  const AddExpenseScreen({super.key, this.transaction});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  final TextEditingController _amountController = TextEditingController(text: '0.00');
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  
  bool _isIncome = false;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final List<ExpenseCategory> _categories = [
    ExpenseCategory.food,
    ExpenseCategory.transport,
    ExpenseCategory.shopping,
    ExpenseCategory.leisure,
    ExpenseCategory.health,
    ExpenseCategory.rent,
    ExpenseCategory.entertainment,
    ExpenseCategory.other,
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _selectedCategory = t.category;
      _amountController.text = t.amount.toStringAsFixed(2);
      _descController.text = t.title;
      _noteController.text = t.note ?? '';
      _isIncome = t.isIncome;
      _selectedDate = t.date;
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _amountFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount card
                    _AmountCard(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Income Toggle
                    _IncomeToggle(
                      isIncome: _isIncome,
                      onChanged: (val) => setState(() => _isIncome = val),
                    ),
                    const SizedBox(height: 20),

                    // Category selector
                    _CategorySelector(
                      categories: _categories,
                      selected: _selectedCategory,
                      onSelect: (cat) => setState(() => _selectedCategory = cat),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 28),

                    // Input fields
                    _InputFields(
                      descController: _descController,
                      noteController: _noteController,
                      date: _selectedDate,
                      onDateTap: () => _selectDate(context),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    if (widget.transaction != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: GestureDetector(
                          onTap: _isSaving ? null : _handleDelete,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Transaction',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Fixed bottom button
      bottomNavigationBar: _BottomButton(
        isSaving: _isSaving,
        isIncome: _isIncome,
        isEditing: widget.transaction != null,
        onTap: _handleSave,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: Center(
              child: Text(
                widget.transaction != null
                    ? (_isIncome ? 'Edit Income' : 'Edit Expense')
                    : (_isIncome ? 'Add Income' : 'Add Expense'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await context.read<ExpenseProvider>().deleteTransaction(widget.transaction!.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final transaction = Transaction(
        id: widget.transaction?.id ?? const Uuid().v4(),
        title: _descController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        isIncome: _isIncome,
        note: _noteController.text.trim(),
      );

      if (widget.transaction != null) {
        await context.read<ExpenseProvider>().updateTransaction(transaction);
      } else {
        await context.read<ExpenseProvider>().addTransaction(transaction);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(widget.transaction != null 
                    ? 'Transaction updated!'
                    : (_isIncome ? 'Income added!' : 'Expense added!')),
              ],
            ),
            backgroundColor: _isIncome ? AppColors.income : AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─── Amount Card ──────────────────────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;

  const _AmountCard({
    required this.controller,
    required this.focusNode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'AMOUNT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '\$',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 160,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─── Income Toggle ───────────────────────────────────────────────────────────

class _IncomeToggle extends StatelessWidget {
  final bool isIncome;
  final ValueChanged<bool> onChanged;

  const _IncomeToggle({required this.isIncome, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isIncome 
            ? AppColors.income.withValues(alpha: 0.1) 
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isIncome ? Icons.trending_up : Icons.trending_down,
                color: isIncome ? AppColors.income : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'This is income',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isIncome ? AppColors.income : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          Switch(
            value: isIncome,
            onChanged: onChanged,
            activeThumbColor: AppColors.income,
          ),
        ],
      ),
    );
  }
}

// ─── Category Selector ────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onSelect;
  final bool isDark;

  const _CategorySelector({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT CATEGORY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: categories.map((cat) {
              final isSelected = cat == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () => onSelect(cat),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? []
                              : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                ),
                              ],
                        ),
                        child: Icon(
                          cat.icon,
                          color: isSelected
                              ? AppColors.primary
                              : isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Input Fields ─────────────────────────────────────────────────────────────

class _InputFields extends StatelessWidget {
  final TextEditingController descController;
  final TextEditingController noteController;
  final DateTime date;
  final VoidCallback onDateTap;
  final bool isDark;

  const _InputFields({
    required this.descController,
    required this.noteController,
    required this.date,
    required this.onDateTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final dateStr = dateFormat.format(date) == dateFormat.format(DateTime.now())
        ? 'Today, ${dateFormat.format(date)}'
        : dateFormat.format(date);

    return Column(
      children: [
        _InputCard(
          isDark: isDark,
          icon: Icons.edit_rounded,
          child: TextField(
            controller: descController,
            decoration: InputDecoration(
              hintText: 'Description',
              hintStyle: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onDateTap,
          child: _InputCard(
            isDark: isDark,
            icon: Icons.calendar_today_rounded,
            child: Text(
              dateStr,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _InputCard(
          isDark: isDark,
          icon: Icons.notes_rounded,
          child: TextField(
            controller: noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Add a note...',
              hintStyle: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  final IconData icon;
  final Widget child;
  final bool isDark;

  const _InputCard({
    required this.icon,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 8), child: child)),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSaving;
  final bool isIncome;
  final bool isEditing;

  const _BottomButton({
    required this.onTap,
    required this.isSaving,
    required this.isIncome,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      color: Colors.transparent,
      child: PrimaryButton(
        label: isSaving ? 'Saving...' : (isEditing ? 'Save Changes' : (isIncome ? 'Add Income' : 'Add Expense')),
        icon: isSaving ? null : (isEditing ? Icons.check_circle_outline_rounded : Icons.add_circle_rounded),
        isLoading: isSaving,
        onTap: onTap,
        color: isIncome ? AppColors.income : AppColors.primary,
      ),
    );
  }
}
