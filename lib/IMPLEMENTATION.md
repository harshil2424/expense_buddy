# 🤖 Expense Buddy — AI Agent Implementation Plan

> Feed each prompt to your AI coding agent **in order**. One prompt at a time. Test after every phase.

---

## 📦 Project Context

- **Framework:** Flutter (Dart)
- **Database:** SQLite via sqflite
- **State Management:** Provider
- **AI Backend:** Cloudflare Workers AI (Llama 3.2-1B)
- **Existing files:** See project structure below

## 📁 Existing Project Structure

```
lib/
├── main.dart
├── app_shell.dart
├── core/
│   ├── theme/app_theme.dart
│   ├── models/models.dart
│   └── widgets/shared_widgets.dart
└── features/
    ├── onboarding/presentation/screens/onboarding_screen.dart
    ├── dashboard/presentation/screens/dashboard_screen.dart
    ├── add_expense/presentation/screens/add_expense_screen.dart
    ├── transactions/presentation/screens/transactions_screen.dart
    ├── ai_insights/presentation/screens/ai_insights_screen.dart
    └── profile/presentation/screens/profile_screen.dart
```

---

## ✅ Prompt Execution Order

```
Phase 1 → Database & Models        (Prompts 1.1 → 1.3)
Phase 2 → State Management         (Prompts 2.1 → 2.4)
Phase 3 → Wire UI to Real Data     (Prompts 3.1 → 3.5)
Phase 4 → AI Integration           (Prompts 4.1 → 4.2)
Phase 5 → Polish & Edge Cases      (Prompts 5.1 → 5.5)
```

---

# PHASE 1 — Database Layer

---

## Prompt 1.1 — Update pubspec.yaml

```
Update the pubspec.yaml file in the root of the project.

Add the following dependencies under the dependencies section:
  sqflite: ^2.3.2
  path: ^1.9.0
  provider: ^6.1.2
  http: ^1.2.0
  uuid: ^4.3.3
  intl: ^0.19.0

Output the complete updated pubspec.yaml file.
Then run: flutter pub get
```

---

## Prompt 1.2 — Create DatabaseHelper

```
Create a new file: lib/core/database/database_helper.dart

Build a singleton class called DatabaseHelper that manages
a SQLite database named expense_buddy.db at version 1.

On database creation, create these two tables:

Table 1 — transactions:
  id          TEXT PRIMARY KEY
  title       TEXT NOT NULL
  amount      REAL NOT NULL
  category    TEXT NOT NULL
  date        TEXT NOT NULL
  is_income   INTEGER NOT NULL DEFAULT 0
  note        TEXT

Table 2 — budget:
  id            INTEGER PRIMARY KEY AUTOINCREMENT
  monthly_limit REAL NOT NULL
  month         TEXT NOT NULL UNIQUE

Implement these methods:

  Future<void> insertTransaction(Map<String, dynamic> data)
  Future<List<Map<String, dynamic>>> getAllTransactions()
  Future<List<Map<String, dynamic>>> getTransactionsByMonth(String month)
    → month is in format yyyy-MM
    → filter using: WHERE date LIKE 'yyyy-MM%'
  Future<void> deleteTransaction(String id)
  Future<void> updateTransaction(String id, Map<String, dynamic> data)
  Future<void> setBudget(double limit, String month)
    → use INSERT OR REPLACE
  Future<Map<String, dynamic>?> getBudget(String month)
  Future<void> closeDb()

Use sqflite and path packages.
Output the complete file.
```

---

## Prompt 1.3 — Create ExpenseRepository + Model Serialization

```
Do two things:

PART A — Update lib/core/models/models.dart

Add toMap() and fromMap() methods to the Transaction class:

  Map<String, dynamic> toMap() should return:
    {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'is_income': isIncome ? 1 : 0,
      'note': note ?? '',
    }

  factory Transaction.fromMap(Map<String, dynamic> map) should:
    - parse category using ExpenseCategory.values.byName(map['category'])
    - parse date using DateTime.parse(map['date'])
    - parse isIncome from map['is_income'] == 1

PART B — Create lib/core/database/expense_repository.dart

Class ExpenseRepository that wraps DatabaseHelper:

  Future<void> addTransaction(Transaction t)
    → calls db.insertTransaction(t.toMap())

  Future<List<Transaction>> getTransactions()
    → calls db.getAllTransactions()
    → maps each row to Transaction.fromMap()

  Future<List<Transaction>> getTransactionsForMonth(DateTime month)
    → formats month as 'yyyy-MM'
    → calls db.getTransactionsByMonth()
    → maps to Transaction list

  Future<void> deleteTransaction(String id)

  Future<void> updateTransaction(Transaction t)
    → calls db.updateTransaction(t.id, t.toMap())

  Future<void> setMonthlyBudget(double amount, DateTime month)
    → formats month as 'yyyy-MM'
    → calls db.setBudget()

  Future<double?> getMonthlyBudget(DateTime month)
    → returns the monthly_limit value or null if not set

Output both complete files.
```

---

# PHASE 2 — State Management

---

## Prompt 2.1 — Create ExpenseProvider

```
Create lib/core/providers/expense_provider.dart

Class ExpenseProvider extends ChangeNotifier

Private state:
  List<Transaction> _transactions = []
  bool _isLoading = false
  DateTime _selectedMonth = DateTime.now()
  final ExpenseRepository _repository = ExpenseRepository()

Public getters:
  List<Transaction> get transactions → returns _transactions
  bool get isLoading → returns _isLoading
  DateTime get selectedMonth → returns _selectedMonth

  double get totalExpenses
    → sum of amounts where isIncome == false

  double get totalIncome
    → sum of amounts where isIncome == true

  Map<ExpenseCategory, double> get categoryTotals
    → group _transactions by category (excluding income)
    → return Map<ExpenseCategory, double> with summed amounts
    → only include categories with amount > 0

  List<Transaction> get recentTransactions
    → return last 5 transactions sorted by date descending

Methods:
  Future<void> loadTransactions() async
    → set _isLoading = true, notifyListeners()
    → call _repository.getTransactionsForMonth(_selectedMonth)
    → set _transactions = result
    → set _isLoading = false, notifyListeners()

  Future<void> addTransaction(Transaction t) async
    → call _repository.addTransaction(t)
    → call loadTransactions()

  Future<void> deleteTransaction(String id) async
    → call _repository.deleteTransaction(id)
    → call loadTransactions()

  Future<void> updateTransaction(Transaction t) async
    → call _repository.updateTransaction(t)
    → call loadTransactions()

  void setMonth(DateTime month)
    → set _selectedMonth = month
    → call loadTransactions()

Call loadTransactions() at the end of the constructor.
Import Transaction, ExpenseCategory, ExpenseRepository.
Output the complete file.
```

---

## Prompt 2.2 — Create BudgetProvider

```
Create lib/core/providers/budget_provider.dart

Class BudgetProvider extends ChangeNotifier

Constructor accepts ExpenseProvider as a parameter:
  BudgetProvider(this._expenseProvider)

Private state:
  final ExpenseProvider _expenseProvider
  double _monthlyLimit = 0.0
  final ExpenseRepository _repository = ExpenseRepository()

Public getters:
  double get monthlyLimit → _monthlyLimit

  double get usedAmount
    → _expenseProvider.totalExpenses

  double get remainingAmount
    → (_monthlyLimit - usedAmount).clamp(0, double.infinity)

  double get usedPercentage
    → _monthlyLimit > 0 ? (usedAmount / _monthlyLimit * 100).clamp(0, 100) : 0

  bool get isOverBudget → usedAmount > _monthlyLimit && _monthlyLimit > 0
  bool get isNearLimit → usedPercentage >= 80 && !isOverBudget
  bool get hasBudget → _monthlyLimit > 0

  Color get statusColor
    → if usedPercentage < 60 → Color(0xFF10B981) green
    → if usedPercentage < 80 → Color(0xFFF59E0B) yellow
    → else → Color(0xFFFF6B6B) red

Methods:
  Future<void> loadBudget(DateTime month) async
    → call _repository.getMonthlyBudget(month)
    → if result != null, set _monthlyLimit = result
    → else _monthlyLimit = 0.0
    → notifyListeners()

  Future<void> setBudget(double amount, DateTime month) async
    → call _repository.setMonthlyBudget(amount, month)
    → set _monthlyLimit = amount
    → notifyListeners()

  void update(ExpenseProvider expenseProvider)
    → this method is called by ProxyProvider on updates
    → notifyListeners()

Call loadBudget(DateTime.now()) in constructor.
Import AppColors from theme or use hardcoded Color values.
Output the complete file.
```

---

## Prompt 2.3 — Create AiProvider

```
Create lib/core/providers/ai_provider.dart

First define this result model at the top of the file:

class AiAnalysisResult {
  final int budgetScore
  final String summary
  final List<SpendingInsight> insights
  final List<Recommendation> recommendations
  final double potentialSavings

  const AiAnalysisResult({...})
}

Class AiProvider extends ChangeNotifier

Private state:
  bool _isLoading = false
  String? _error
  AiAnalysisResult? _result

Public getters:
  bool get isLoading
  String? get error
  AiAnalysisResult? get result
  bool get hasResult → _result != null

Method: Future<void> analyze(List<Transaction> transactions, double budget)

  1. Set _isLoading = true, _error = null, notifyListeners()

  2. Build expense summary string:
     - Group transactions by category
     - Format as "Category: $total\n" for each
     - List last 10 transactions as "date | title | -$amount\n"

  3. Build the messages list:
     system: "You are a personal finance AI assistant. Analyze spending 
              data and return ONLY a raw JSON object. No markdown, no 
              explanation, just valid JSON."

     user: """
       Analyze my monthly expenses and return insights.

       Monthly Budget: $[budget]
       Total Spent: $[totalExpenses]
       Total Income: $[totalIncome]

       Spending by category:
       [categoryBreakdown]

       Recent transactions:
       [recentTransactions]

       Return this exact JSON structure:
       {
         "budgetScore": <integer 0-100>,
         "summary": "<2 sentence health summary>",
         "insights": [
           {
             "title": "<insight title>",
             "subtitle": "<one line detail>",
             "badge": "<short label>",
             "type": "<warning|positive|neutral>"
           }
         ],
         "recommendations": [
           {
             "number": <1-3>,
             "title": "<action title>",
             "description": "<one line>",
             "savingsLabel": "Save $X/mo"
           }
         ],
         "potentialSavings": <number>
       }
     """

  4. POST to AppConstants.workerUrl with body:
     { "messages": [{"role": "user", "content": userMessage}],
       "system": systemMessage }
     Headers: {"Content-Type": "application/json"}

  5. Parse response.body as JSON
     Extract result field from response
     Try to parse result as JSON (it may be a string inside result field)

  6. Map parsed JSON to AiAnalysisResult:
     - insights: map each to SpendingInsight using type field for colors
       warning → badge color red, positive → green, neutral → grey
     - recommendations: map each to Recommendation model

  7. Set _result = parsed result
     Set _isLoading = false
     notifyListeners()

  8. On any error or exception:
     Set _error = error message
     Set _isLoading = false
     notifyListeners()

Method: void clearError() → _error = null, notifyListeners()
Method: void clearResult() → _result = null, notifyListeners()

Import http, dart:convert, models.dart, AppConstants.
Output the complete file.
```

---

## Prompt 2.4 — Register Providers in main.dart

```
Update lib/main.dart

Wrap the MaterialApp with MultiProvider at the top of the widget tree.

Register these providers in order:

  1. ChangeNotifierProvider<ExpenseProvider>
       create: (_) => ExpenseProvider()

  2. ChangeNotifierProxyProvider<ExpenseProvider, BudgetProvider>
       create: (ctx) => BudgetProvider(ctx.read<ExpenseProvider>())
       update: (ctx, expense, budget) {
         budget!.update(expense);
         return budget;
       }

  3. ChangeNotifierProvider<AiProvider>
       create: (_) => AiProvider()

Import all three provider files and the provider package.
Keep all existing routes and theme setup unchanged.
Output the complete updated main.dart file.
```

---

# PHASE 3 — Wire UI to Real Data

---

## Prompt 3.1 — Wire Dashboard Screen

```
Update lib/features/dashboard/presentation/screens/dashboard_screen.dart

Replace all hardcoded/sample data with live Provider data.
Use Consumer or context.watch where appropriate.

Changes to make:

1. Total expenses display:
   → context.watch<ExpenseProvider>().totalExpenses
   → format using: NumberFormat.currency(symbol: '\$').format(amount)

2. Donut chart segments:
   → use context.watch<ExpenseProvider>().categoryTotals
   → calculate each category percentage: (catAmount / totalExpenses * 100)
   → use category.color for each segment color
   → if categoryTotals is empty, show a single grey segment at 100%

3. Legend list below chart:
   → generate dynamically from categoryTotals map
   → show category.label, category.color dot, formatted amount
   → only show top 3 categories by amount

4. Date range text:
   → show first and last day of selected month
   → format as 'MMM d - MMM d, yyyy'

5. Income progress card:
   → amount: ExpenseProvider.totalIncome
   → progress value: totalExpenses / totalIncome (clamped 0-1)
   → if totalIncome == 0, progress = 0

6. Expenses progress card:
   → amount: ExpenseProvider.totalExpenses
   → progress value: BudgetProvider.usedPercentage / 100
   → bar color: BudgetProvider.statusColor

7. Status banner:
   → if BudgetProvider.isOverBudget:
        red background, show "⚠️ You have exceeded your budget!"
   → else if BudgetProvider.isNearLimit:
        yellow background, show "⚡ You are nearing your budget limit"
   → else if BudgetProvider.hasBudget:
        green background, show "👍 Great job! Spending is on track"
   → else:
        orange background, show "💡 Set a budget to track your progress"

8. Loading state:
   → if ExpenseProvider.isLoading, show centered CircularProgressIndicator
      with color: AppColors.primary

9. Empty state:
   → if transactions list is empty and not loading:
      show centered Column with:
        Icon(Icons.receipt_long, size: 64, color: AppColors.neutral)
        Text("No expenses yet")
        SizedBox(height: 12)
        Text("Tap + to add your first expense")

Wrap relevant sections in Consumer<ExpenseProvider> and Consumer<BudgetProvider>.
Import provider, intl, AppColors.
Output the complete updated file.
```

---

## Prompt 3.2 — Wire Add Expense Screen

```
Update lib/features/add_expense/presentation/screens/add_expense_screen.dart

Make the form fully functional:

1. Amount input:
   → Replace static display with a real TextField
   → keyboardType: TextInputType.numberWithOptions(decimal: true)
   → Store value in _amountController (TextEditingController)
   → Display in large primary-colored text style as before
   → Show red underline if amount is 0 on save attempt

2. Income toggle:
   → Add a Switch widget at the top of the form after the header
   → Label: "This is income"
   → State: bool _isIncome = false
   → When true: button turns green, label changes to "Add Income"

3. Date picker:
   → Replace static date text with a GestureDetector
   → On tap: showDatePicker() with firstDate 2 years ago, lastDate: today
   → Store picked date in DateTime _selectedDate = DateTime.now()
   → Display formatted date in the card

4. _handleSave() implementation:
   → Parse double amount = double.tryParse(_amountController.text) ?? 0
   → Validate: amount must be > 0, show SnackBar if not
   → Validate: description must not be empty, show SnackBar if not
   → Create transaction:
        Transaction(
          id: const Uuid().v4(),
          title: _descController.text.trim(),
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          isIncome: _isIncome,
          note: _noteController.text.trim(),
        )
   → Set _isSaving = true (show loading on button)
   → Call await context.read<ExpenseProvider>().addTransaction(transaction)
   → Set _isSaving = false
   → Show success SnackBar: "Expense added!"
   → Navigator.of(context).pop()

5. Button state:
   → bool _isSaving = false
   → Pass _isSaving to PrimaryButton.isLoading
   → Button label changes based on _isIncome toggle

6. Auto-focus:
   → Add FocusNode to amount TextField
   → Request focus in initState after a short delay

Import uuid, provider, ExpenseProvider.
Output the complete updated file.
```

---

## Prompt 3.3 — Wire Transactions Screen

```
Update lib/features/transactions/presentation/screens/transactions_screen.dart

Make the list fully functional with real data, search, and delete:

1. Data source:
   → Replace SampleData.transactions with:
      context.watch<ExpenseProvider>().transactions
   → Wrap in Consumer<ExpenseProvider>

2. Search:
   → Add String _searchQuery = '' state
   → On _searchController onChanged: setState(() => _searchQuery = value)
   → Filter transactions:
      where title.toLowerCase().contains(_searchQuery.toLowerCase())
      OR category.label.toLowerCase().contains(_searchQuery.toLowerCase())

3. Filter chips (This week / This month / This year):
   → Apply filter on top of search results
   → This week: date.isAfter(DateTime.now().subtract(Duration(days: 7)))
   → This month: date.month == now.month && date.year == now.year
   → This year: date.year == now.year

4. Final displayed list = search filtered + time filtered, sorted by date desc

5. Grouping logic (apply to final list):
   → Today: same day as now
   → Yesterday: one day before now
   → Older: format as 'MMM dd'

6. Swipe to delete:
   → Wrap each TransactionCard in a Dismissible widget
   → key: Key(transaction.id)
   → direction: DismissDirection.endToStart
   → background: red rounded container with Icons.delete_outline on right
   → onDismissed: context.read<ExpenseProvider>().deleteTransaction(transaction.id)
   → confirmDismiss: show AlertDialog "Delete this transaction?" Yes/No

7. Empty state (when filtered list is empty):
   → Center column with:
        Icon(Icons.search_off, size: 56, color: AppColors.neutral)
        SizedBox(height: 12)
        Text("No transactions found")
        if _searchQuery is not empty:
          Text("Try a different search term")

8. Loading state:
   → if ExpenseProvider.isLoading, show CircularProgressIndicator centered

Output the complete updated file.
```

---

## Prompt 3.4 — Wire AI Insights Screen

```
Update lib/features/ai_insights/presentation/screens/ai_insights_screen.dart

Connect to AiProvider, ExpenseProvider, BudgetProvider:

1. _reanalyze() method:
   → Get transactions from context.read<ExpenseProvider>().transactions
   → If transactions.isEmpty, show SnackBar:
      "Add at least 3 expenses before analyzing"
      return early
   → Get budget from context.read<BudgetProvider>().monthlyLimit
   → Call: await context.read<AiProvider>().analyze(transactions, budget)

2. Loading state (AiProvider.isLoading == true):
   → Replace each card section with a ShimmerSkeleton widget
   → ShimmerSkeleton is a grey animated container with same height as real card
   → Animate opacity between 0.3 and 1.0 using AnimationController repeat

3. Error state (AiProvider.error != null):
   → Show a card with:
        Icon(Icons.error_outline, color: AppColors.primary, size: 40)
        Text(AiProvider.error!)
        ElevatedButton("Try Again") → calls clearError() then _reanalyze()

4. Empty state (no result and not loading):
   → Show a centered card:
        Icon(Icons.auto_awesome, color: AppColors.primary, size: 48)
        Text("No analysis yet")
        Text("Tap Re-analyze to get AI-powered insights")

5. Result state (AiProvider.result != null):

   Budget health card:
   → gauge percentage: result.budgetScore / 100
   → description text: result.summary
   → animate gauge from 0 to value using AnimationController in initState

   Insights section:
   → map result.insights to InsightCard widgets
   → badge color based on type field:
      warning → AppColors.primary (red)
      positive → AppColors.income (green)
      neutral → AppColors.neutral (grey)

   Recommendations section:
   → map result.recommendations to RecommendationCard widgets

   Potential savings card:
   → new card at bottom showing result.potentialSavings
   → formatted as currency
   → green background tint

6. Re-analyze button:
   → disabled (grey) when isLoading or transactions.isEmpty
   → shows "Analyzing..." when loading

Wrap entire body in Consumer<AiProvider>.
Output the complete updated file.
```

---

## Prompt 3.5 — Budget Setting Bottom Sheet

```
Do two things:

PART A — Create lib/features/dashboard/presentation/widgets/budget_sheet.dart

A StatefulWidget called BudgetSheet shown as a modal bottom sheet.

UI layout:
  - Drag handle at top center
  - Title "Set Monthly Budget" (bold, large)
  - Subtitle showing current budget:
      if hasBudget: "Current: $[amount]"
      else: "No budget set"
  - Large TextField:
      keyboardType: TextInputType.numberWithOptions(decimal: true)
      prefix: Text("\$")
      hint: "Enter monthly limit"
      autofocus: true
      pre-fill with current budget if hasBudget
  - PrimaryButton "Save Budget"
      on tap:
        parse double from input
        if <= 0, show validation error text below field
        else call context.read<BudgetProvider>().setBudget(amount, DateTime.now())
        then Navigator.pop(context)
        then show SnackBar "Budget updated!"

PART B — Update dashboard_screen.dart

Add a small IconButton next to the budget progress bar:
  icon: Icons.edit_rounded
  size: 18
  color: AppColors.primary
  
  onTap:
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: BudgetSheet(),
      ),
    )

Output both complete files.
```

---

# PHASE 4 — AI Integration Details

---

## Prompt 4.1 — Create AppConstants

```
Create lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // Replace this with your actual Cloudflare Worker URL
  static const String workerUrl = 'YOUR_CLOUDFLARE_WORKER_URL_HERE';

  static const String dbName = 'expense_buddy.db';
  static const int dbVersion = 1;
  static const String appName = 'Expense Buddy';

  static const String defaultUserName = 'Alex Johnson';

  // Budget warning thresholds
  static const double nearLimitThreshold = 80.0;
  static const double overBudgetThreshold = 100.0;
}

Then update AiProvider to use AppConstants.workerUrl instead
of any hardcoded URL string.

Also update DatabaseHelper to use AppConstants.dbName
and AppConstants.dbVersion.

Output all three updated files.
```

---

## Prompt 4.2 — Harden AI Response Parsing

```
Update the analyze() method in lib/core/providers/ai_provider.dart

The Cloudflare Worker returns JSON in this shape:
{ "result": "<string or object>" }

The result field might be:
  a) A JSON string that needs to be parsed again
  b) A plain string with JSON embedded in it
  c) Already a Map object

Make the parsing robust:

1. First decode the outer response body as JSON
2. Extract the 'result' field
3. If result is a String:
   → Try jsonDecode(result) to get the inner JSON
   → If that fails, try to extract JSON using regex:
      RegExp(r'\{.*\}', dotAll: true).firstMatch(result)?.group(0)
   → Parse that extracted string
4. If result is already a Map, use it directly

5. Safely extract each field with null fallbacks:
   budgetScore: (json['budgetScore'] as num?)?.toInt() ?? 50
   summary: json['summary'] as String? ?? 'Analysis complete.'
   insights: (json['insights'] as List?)?.map(...) ?? []
   recommendations: (json['recommendations'] as List?)?.map(...) ?? []
   potentialSavings: (json['potentialSavings'] as num?)?.toDouble() ?? 0.0

6. If insights or recommendations are empty lists from parsing,
   create one default item each so the UI always has something to show.

Output the complete updated ai_provider.dart file.
```

---

# PHASE 5 — Polish & Edge Cases

---

## Prompt 5.1 — Global Error Handling

```
Update these files to add proper error handling:

1. expense_repository.dart:
   → Wrap all db calls in try-catch
   → On error, print the error and rethrow
   → Add a custom ExpenseException class with a message field

2. expense_provider.dart:
   → Wrap loadTransactions, addTransaction, deleteTransaction in try-catch
   → Add String? _error state
   → On catch: set _error = e.toString(), notifyListeners()
   → Add getter: String? get error
   → Add method: void clearError()

3. ai_provider.dart:
   → Catch SocketException → _error = 'No internet connection. Check your network.'
   → Catch TimeoutException → _error = 'Request timed out. Try again.'
   → Catch FormatException → _error = 'AI returned an unexpected response. Try again.'
   → Catch generic Exception → _error = 'Something went wrong: ${e.toString()}'

4. Add a global error listener in app_shell.dart:
   → In build(), use a Consumer<ExpenseProvider>
   → If provider.error != null, show a SnackBar once using addPostFrameCallback
   → After showing, call provider.clearError()

Output all updated files.
```

---

## Prompt 5.2 — Empty States

```
Create lib/core/widgets/empty_state_widget.dart

A reusable widget EmptyStateWidget with these named parameters:
  IconData icon
  String title
  String subtitle
  Widget? action   (optional button)

UI:
  Centered Column with padding:
    Icon(icon, size: 72, color: AppColors.neutral.withOpacity(0.5))
    SizedBox(height: 16)
    Text(title, bold, size 18, centered)
    SizedBox(height: 8)
    Text(subtitle, bodyMedium style, centered, max 2 lines)
    if action != null: SizedBox(height: 24) then action

Then use this widget in:

1. DashboardScreen:
   When transactions.isEmpty and not loading:
   EmptyStateWidget(
     icon: Icons.receipt_long_rounded,
     title: 'No expenses yet',
     subtitle: 'Tap the + button to add your first expense',
   )

2. TransactionsScreen:
   When filtered list is empty:
   EmptyStateWidget(
     icon: Icons.search_off_rounded,
     title: 'No transactions found',
     subtitle: _searchQuery.isNotEmpty
       ? 'Try a different search term'
       : 'No transactions for this period',
   )

3. AiInsightsScreen:
   When no result and not loading:
   EmptyStateWidget(
     icon: Icons.auto_awesome_rounded,
     title: 'No insights yet',
     subtitle: 'Add at least 3 expenses and tap Re-analyze',
     action: PrimaryButton(label: 'Re-analyze', onTap: _reanalyze),
   )

Output the new widget file and all three updated screen files.
```

---

## Prompt 5.3 — Form Validation

```
Update lib/features/add_expense/presentation/screens/add_expense_screen.dart

Add proper inline form validation:

1. State variables to track validation:
   bool _amountError = false
   bool _descriptionError = false

2. Amount field:
   → Show red border when _amountError == true
   → Red helper text: "Please enter a valid amount"
   → Reset error when user starts typing: onChanged clears _amountError

3. Description field:
   → Show red border when _descriptionError == true
   → Red helper text: "Please add a description"
   → Reset error when user starts typing

4. _handleSave() validation:
   → Parse amount, if <= 0: set _amountError = true, return
   → If description empty: set _descriptionError = true, return
   → Only proceed if both valid

5. Save button:
   → Disabled (opacity 0.5) when amount is 0.00
   → Re-enabled when user types any amount > 0

6. Auto-focus amount field on screen open:
   → In initState, add postFrameCallback to request focus on amount field

7. Keyboard behavior:
   → Amount field: done action moves to description field
   → Description field: done action moves to note field
   → Note field: done action triggers save

Output the complete updated file.
```

---

## Prompt 5.4 — Date and Currency Utility

```
Create lib/core/utils/app_date_utils.dart

class AppDateUtils with these static methods:

  static String formatCurrency(double amount)
    → uses NumberFormat.currency(symbol: '\$', decimalDigits: 2)
    → example output: "$1,234.56"

  static String formatCurrencyCompact(double amount)
    → if amount >= 1000: "\$${(amount/1000).toStringAsFixed(1)}k"
    → else: formatCurrency(amount)

  static String formatDate(DateTime date)
    → 'MMM dd, yyyy' using DateFormat

  static String formatTime(DateTime date)
    → 'hh:mm a' using DateFormat

  static String formatMonthYear(DateTime date)
    → 'MMMM yyyy' using DateFormat

  static String relativeDate(DateTime date)
    → if isSameDay(date, DateTime.now()): return 'Today'
    → if isSameDay(date, DateTime.now().subtract(Duration(days:1))): return 'Yesterday'
    → else: return formatDate(date)

  static String monthKey(DateTime date)
    → returns 'yyyy-MM' using DateFormat

  static bool isSameMonth(DateTime a, DateTime b)
    → a.year == b.year && a.month == b.month

  static bool isSameDay(DateTime a, DateTime b)
    → a.year == b.year && a.month == b.month && a.day == b.day

  static bool isThisWeek(DateTime date)
    → date.isAfter(DateTime.now().subtract(Duration(days: 7)))

  static String dateRangeLabel(DateTime month)
    → "MMM 1 - MMM [lastDay], yyyy" for the given month

  static DateTime firstDayOfMonth(DateTime date)
  static DateTime lastDayOfMonth(DateTime date)

Then replace all inline date and currency formatting
throughout the codebase with these utility methods.

Output the new utility file.
```

---

## Prompt 5.5 — End-to-End Integration Test

```
Do a final review and fix pass on the entire codebase.

Go through each file and ensure:

1. All imports are correct and resolve properly
2. No references to SampleData remain in screens (only models.dart is ok)
3. Every screen uses Provider data, not hardcoded values
4. All provider methods are called correctly with context.read or context.watch
5. Navigator routes match what is defined in main.dart
6. AppShell IndexedStack has correct screen order matching bottom nav indices:
   index 0 → DashboardScreen
   index 1 → AiInsightsScreen
   index 2 → (handled by modal, not indexed)
   index 3 → TransactionsScreen
   index 4 → ProfileScreen

7. AppShell onNavTap correctly opens AddExpense as modal for index 2

8. Verify this complete user flow works:
   a. Open app → OnboardingScreen shows
   b. Tap "Swipe to get started" → AppShell with DashboardScreen
   c. Dashboard shows empty state
   d. Tap + in bottom nav → AddExpense modal opens
   e. Enter amount 250, select Shopping, description "New shoes", tap Add
   f. Modal closes, Dashboard shows $250.00 total and Shopping slice in chart
   g. Go to Transactions tab → entry appears under Today
   h. Swipe left on entry → confirm delete dialog → entry removed
   i. Dashboard updates to $0.00
   j. Add 3 more expenses in different categories
   k. Go to Dashboard → tap edit icon near budget bar → enter 1000 → save
   l. Budget bar shows correct percentage
   m. Go to AI Insights → tap Re-analyze
   n. Loading skeleton shows → result appears with score, insights, recommendations

Output a list of all files that were changed and what was fixed in each.
```

---

## 💡 Tips for Your Agent

```
✅ One prompt at a time — never combine two prompts
✅ Always ask for the COMPLETE file, not just the changed section
✅ Run flutter pub get after Prompt 1.1
✅ Run flutter analyze after each phase to catch errors early
✅ If agent drifts, paste the original file + this plan and say:
   "Continue from Prompt X.X using the context above"
✅ After Phase 2, run the app to verify providers are registered
✅ After Phase 3, test each screen manually before moving on
✅ Replace YOUR_CLOUDFLARE_WORKER_URL_HERE in AppConstants before Phase 4
```

---

## 📊 Progress Tracker

```
Phase 1 — Database
  [ ] 1.1 pubspec.yaml updated
  [ ] 1.2 DatabaseHelper created
  [ ] 1.3 ExpenseRepository + model serialization

Phase 2 — State Management
  [ ] 2.1 ExpenseProvider
  [ ] 2.2 BudgetProvider
  [ ] 2.3 AiProvider
  [ ] 2.4 Providers registered in main.dart

Phase 3 — UI Wired
  [ ] 3.1 Dashboard wired
  [ ] 3.2 Add Expense wired
  [ ] 3.3 Transactions wired
  [ ] 3.4 AI Insights wired
  [ ] 3.5 Budget sheet added

Phase 4 — AI Integration
  [ ] 4.1 AppConstants created
  [ ] 4.2 AI response parsing hardened

Phase 5 — Polish
  [ ] 5.1 Error handling
  [ ] 5.2 Empty states
  [ ] 5.3 Form validation
  [ ] 5.4 Date/currency utils
  [ ] 5.5 End-to-end test passed
```

---

*Generated for Expense Buddy Flutter App — AI Agent Vibe Coding Plan*
