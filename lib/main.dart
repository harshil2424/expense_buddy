import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'app_shell.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'core/providers/expense_provider.dart';
import 'core/providers/budget_provider.dart';
import 'core/providers/ai_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ExpenseBuddyApp());
}

class ExpenseBuddyApp extends StatelessWidget {
  const ExpenseBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ExpenseProvider>(
          create: (_) => ExpenseProvider(),
        ),
        ChangeNotifierProxyProvider<ExpenseProvider, BudgetProvider>(
          create: (ctx) => BudgetProvider(ctx.read<ExpenseProvider>()),
          update: (ctx, expense, budget) {
            budget!.update(expense);
            return budget;
          },
        ),
        ChangeNotifierProvider<AiProvider>(
          create: (_) => AiProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Expense Buddy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Change to ThemeMode.system for auto
        initialRoute: '/onboarding',
        routes: {
          '/onboarding': (_) => const OnboardingScreen(),
          '/dashboard': (_) => const AppShell(),
        },
      ),
    );
  }
}
