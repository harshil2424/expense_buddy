class AppConstants {
  AppConstants._();

  // Replace this with your actual Cloudflare Worker URL
  static const String workerUrl =
      'https://your-worker-url.workers.dev/';

  static const String dbName = 'expense_buddy.db';
  static const int dbVersion = 1;
  static const String appName = 'Expense Buddy';

  static const String defaultUserName = 'Alex Johnson';

  // Budget warning thresholds
  static const double nearLimitThreshold = 80.0;
  static const double overBudgetThreshold = 100.0;
}
