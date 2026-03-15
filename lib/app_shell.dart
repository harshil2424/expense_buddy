import 'package:flutter/material.dart';
import 'core/widgets/shared_widgets.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/transactions/presentation/screens/transactions_screen.dart';
import 'features/add_expense/presentation/screens/add_expense_screen.dart';
import 'features/ai_insights/presentation/screens/ai_insights_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    if (index == 2) {
      // Open Add Expense as modal bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _AddExpenseModal(),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
        children: [
          const DashboardScreen(),
          const AiInsightsScreen(),
          const TransactionsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _AddExpenseModal extends StatelessWidget {
  const _AddExpenseModal();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: const AddExpenseScreen(),
    );
  }
}
