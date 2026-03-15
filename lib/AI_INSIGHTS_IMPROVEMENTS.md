# 🤖 Expense Buddy — AI Prompt Improvement Plan
> Currency: ₹ Indian Rupee | Tone: Professional & Formal | Model: Llama 3.2-1B via Cloudflare Workers AI

---

## 📋 What This Document Covers

1. Improved system prompt
2. Improved user prompt with richer context
3. Smarter budget scoring logic
4. Better spending pattern detection
5. Personalized recommendations with real numbers
6. Response JSON schema (updated)
7. Full updated `ai_provider.dart` analyze() method
8. Cloudflare Worker update (optional tuning)

---

## 🔴 Problems With the Current Prompt

| Issue | Impact |
|---|---|
| Minimal spending context sent | AI gives generic advice |
| No historical comparison | Cannot detect patterns or trends |
| Budget score has no clear formula | Scores feel random |
| Recommendations lack ₹ amounts | Not actionable for Indian users |
| No category benchmarks | AI cannot say if Food is "high" or "normal" |
| Tone not specified | Responses feel casual or inconsistent |

---

## ✅ Improvement 1 — New System Prompt

Replace the existing system prompt with this:

```dart
const String systemPrompt = """
You are a professional personal finance analyst assistant for Indian users.
Your role is to analyze monthly expense data and provide structured, 
data-driven financial insights.

Rules you must follow:
- Always respond in ONLY valid raw JSON. No markdown. No explanation. No preamble.
- All monetary values are in Indian Rupees (₹).
- Use a formal, professional tone. Avoid casual language.
- Base every insight and recommendation on the actual numbers provided.
- Never invent data that was not provided.
- Budget score must follow the exact scoring formula provided in the prompt.
- Every recommendation must include a specific ₹ savings amount per month.
- Insights must reference actual category names and percentages from the data.
""";
```

---

## ✅ Improvement 2 — Richer Context in User Prompt

The current prompt sends minimal data. The new prompt sends:

- Category totals with percentages
- Daily average spend
- Highest single-day spend
- Weekend vs weekday spend ratio
- Top 3 most expensive transactions
- Number of transactions per category
- Days remaining in the month
- Savings rate (income - expenses / income)

### Updated context builder in `ai_provider.dart`:

```dart
String _buildContext(List<Transaction> transactions, double budget) {
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysElapsed = now.day;
  final daysRemaining = daysInMonth - daysElapsed;

  // ── Totals ──────────────────────────────────────────────────────
  final expenses = transactions.where((t) => !t.isIncome).toList();
  final incomes  = transactions.where((t) =>  t.isIncome).toList();
  final totalExpenses = expenses.fold(0.0, (s, t) => s + t.amount);
  final totalIncome   = incomes.fold(0.0,  (s, t) => s + t.amount);
  final savingsRate   = totalIncome > 0
      ? ((totalIncome - totalExpenses) / totalIncome * 100).toStringAsFixed(1)
      : '0.0';

  // ── Category breakdown ───────────────────────────────────────────
  final Map<String, double> catTotals = {};
  final Map<String, int>    catCounts = {};
  for (final t in expenses) {
    final key = t.category.label;
    catTotals[key] = (catTotals[key] ?? 0) + t.amount;
    catCounts[key] = (catCounts[key] ?? 0) + 1;
  }
  final sortedCats = catTotals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final categoryLines = sortedCats.map((e) {
    final pct = totalExpenses > 0
        ? (e.value / totalExpenses * 100).toStringAsFixed(1)
        : '0.0';
    return '  - ${e.key}: ₹${e.value.toStringAsFixed(0)} '
           '($pct% of total, ${catCounts[e.key]} transactions)';
  }).join('\n');

  // ── Daily analysis ───────────────────────────────────────────────
  final Map<String, double> dailyTotals = {};
  for (final t in expenses) {
    final day = '${t.date.year}-${t.date.month}-${t.date.day}';
    dailyTotals[day] = (dailyTotals[day] ?? 0) + t.amount;
  }
  final dailyAvg = daysElapsed > 0
      ? (totalExpenses / daysElapsed).toStringAsFixed(0)
      : '0';
  final projectedMonthly =
      (double.tryParse(dailyAvg) ?? 0) * daysInMonth;
  final maxDayEntry = dailyTotals.entries.isEmpty
      ? null
      : dailyTotals.entries.reduce((a, b) => a.value > b.value ? a : b);

  // ── Weekend vs weekday ───────────────────────────────────────────
  double weekendSpend  = 0;
  double weekdaySpend  = 0;
  int    weekendDays   = 0;
  int    weekdayDays   = 0;
  for (final entry in dailyTotals.entries) {
    final parts = entry.key.split('-');
    final date  = DateTime(int.parse(parts[0]),
                           int.parse(parts[1]),
                           int.parse(parts[2]));
    if (date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday) {
      weekendSpend += entry.value;
      weekendDays++;
    } else {
      weekdaySpend += entry.value;
      weekdayDays++;
    }
  }
  final weekendAvg = weekendDays > 0
      ? (weekendSpend / weekendDays).toStringAsFixed(0) : '0';
  final weekdayAvg = weekdayDays > 0
      ? (weekdaySpend / weekdayDays).toStringAsFixed(0) : '0';

  // ── Top 3 transactions ───────────────────────────────────────────
  final topTxns = [...expenses]
    ..sort((a, b) => b.amount.compareTo(a.amount));
  final top3 = topTxns.take(3).map((t) =>
    '  - ${t.title} (${t.category.label}): ₹${t.amount.toStringAsFixed(0)}'
  ).join('\n');

  // ── Indian category benchmarks ───────────────────────────────────
  const benchmarks = '''
Indian average monthly spending benchmarks (% of income):
  - Food & Dining:    25–35%
  - Transport:        8–12%
  - Shopping:         10–15%
  - Entertainment:    3–5%
  - Health:           3–6%
  - Rent & Utilities: 20–30%
  - Other:            5–10%''';

  return '''
=== FINANCIAL DATA FOR ANALYSIS ===

MONTHLY OVERVIEW:
  Month:              ${_monthName(now.month)} ${now.year}
  Days elapsed:       $daysElapsed of $daysInMonth
  Days remaining:     $daysRemaining

INCOME & EXPENSES:
  Total Income:       ₹${totalIncome.toStringAsFixed(0)}
  Total Expenses:     ₹${totalExpenses.toStringAsFixed(0)}
  Monthly Budget:     ₹${budget.toStringAsFixed(0)}
  Budget used:        ${budget > 0 ? (totalExpenses / budget * 100).toStringAsFixed(1) : 'N/A'}%
  Savings Rate:       $savingsRate%
  Projected Month-end Spend: ₹${projectedMonthly.toStringAsFixed(0)}

SPENDING BY CATEGORY:
$categoryLines

DAILY PATTERNS:
  Daily Average Spend:  ₹$dailyAvg
  Highest Single Day:   ${maxDayEntry != null ? '₹${maxDayEntry.value.toStringAsFixed(0)} on ${maxDayEntry.key}' : 'N/A'}
  Weekend Daily Avg:    ₹$weekendAvg
  Weekday Daily Avg:    ₹$weekdayAvg

TOP 3 LARGEST EXPENSES:
$top3

$benchmarks
''';
}

String _monthName(int month) {
  const names = ['','January','February','March','April','May','June',
                 'July','August','September','October','November','December'];
  return names[month];
}
```

---

## ✅ Improvement 3 — Smarter Budget Score Formula

Tell the AI exactly how to calculate the score so it is consistent every time.

Add this to the user prompt:

```
BUDGET SCORE FORMULA (you must follow this exactly):
Start with 100 points. Deduct as follows:

  Budget usage deductions:
    Used 0–60% of budget:    deduct 0
    Used 61–75% of budget:   deduct 10
    Used 76–90% of budget:   deduct 20
    Used 91–100% of budget:  deduct 30
    Over budget:             deduct 40

  Savings rate deductions:
    Savings rate >= 20%:     deduct 0
    Savings rate 10–19%:     deduct 10
    Savings rate 1–9%:       deduct 15
    Savings rate <= 0%:      deduct 25

  Category overspend deductions (vs Indian benchmarks):
    Each category > 10% above benchmark: deduct 5 (max 3 categories = -15)

  Projection deductions:
    Projected month-end <= budget:       deduct 0
    Projected month-end 101–120% budget: deduct 5
    Projected month-end > 120% budget:   deduct 10

Final score = max(0, 100 - all deductions)

Score labels:
  90–100: Excellent
  75–89:  Good
  60–74:  Fair
  40–59:  Needs Attention
  0–39:   Critical
```

---

## ✅ Improvement 4 — Better Pattern Detection Instructions

Add this section to the user prompt to guide pattern detection:

```
PATTERN DETECTION INSTRUCTIONS:
Analyze the data above and identify patterns in these areas:

1. Category overspending:
   Compare each category % against Indian benchmarks.
   If a category is more than 10% above its benchmark, flag it.
   Example: "Food spending is 42% of total, which is 7–17% above the 25–35% benchmark."

2. Weekend spending:
   If weekend daily average is more than 1.5x weekday average, flag it.
   Calculate exact multiplier and ₹ difference.

3. Projection risk:
   If projected month-end spend exceeds budget, flag it.
   State exact ₹ overshoot amount.

4. Savings rate:
   If savings rate < 10%, flag it as a concern.
   If savings rate >= 20%, flag it as a positive.

5. Transaction frequency:
   If any category has more than 10 transactions, flag it as frequent spending.

For each pattern found, generate one insight object.
Generate a maximum of 4 insights. Prioritize the most impactful ones.
```

---

## ✅ Improvement 5 — Personalized Recommendations With ₹ Numbers

Add this to the user prompt:

```
RECOMMENDATION INSTRUCTIONS:
Generate exactly 3 recommendations. Each must:

1. Be based on an actual number from the data above.
2. Name the specific category or behavior to change.
3. State a specific ₹ reduction target (not a percentage).
4. Calculate the monthly savings in ₹.
5. Be actionable — tell the user exactly what to do.

Good recommendation example:
  "Reduce Food & Dining spend from ₹8,400 to ₹6,000 by cooking at home 
   4 days per week instead of ordering. Estimated saving: ₹2,400/month."

Bad recommendation example (too vague):
  "Try to spend less on food."

Always include one recommendation about:
  - The highest spending category
  - Weekend spending (if weekend avg > weekday avg)
  - A subscription or recurring expense (if Entertainment or Health is present)
```

---

## ✅ Improvement 6 — Updated JSON Response Schema

```dart
const String responseSchema = '''
Return ONLY this JSON object. No other text:
{
  "budgetScore": <integer 0-100 calculated using the formula above>,
  "scoreLabel": "<Excellent|Good|Fair|Needs Attention|Critical>",
  "summary": "<2 formal sentences. Sentence 1: overall health status with ₹ figures. Sentence 2: single most important action.>",
  "projectedMonthEnd": <number — projected total spend at month end>,
  "savingsRate": <number — percentage>,
  "insights": [
    {
      "title": "<short category or pattern name>",
      "subtitle": "<one formal sentence with specific ₹ or % figures>",
      "badge": "<concise label e.g. +18% vs avg OR On Track OR Risk>",
      "type": "<warning|positive|neutral>",
      "impact": "<high|medium|low>"
    }
  ],
  "recommendations": [
    {
      "number": <1, 2, or 3>,
      "title": "<action title — verb + category>",
      "description": "<one formal sentence with specific current ₹ amount, target ₹ amount, and how to achieve it>",
      "savingsLabel": "Save ₹X/mo",
      "savingsAmount": <number>
    }
  ],
  "potentialSavings": <sum of all recommendation savingsAmount values>,
  "positiveNote": "<one sentence acknowledging something the user is doing well>"
}
''';
```

---

## ✅ Improvement 7 — Full Updated `analyze()` Method

Replace the entire `analyze()` method in `lib/core/providers/ai_provider.dart`:

```dart
Future<void> analyze(List<Transaction> transactions, double budget) async {
  if (transactions.isEmpty) {
    _error = 'No transactions to analyze. Add at least 3 expenses first.';
    notifyListeners();
    return;
  }

  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final context = _buildContext(transactions, budget);

    final userMessage = '''
$context

BUDGET SCORE FORMULA (you must follow this exactly):
Start with 100 points. Deduct as follows:

  Budget usage deductions:
    Used 0–60%:   deduct 0
    Used 61–75%:  deduct 10
    Used 76–90%:  deduct 20
    Used 91–100%: deduct 30
    Over budget:  deduct 40

  Savings rate deductions:
    >= 20%: deduct 0
    10–19%: deduct 10
    1–9%:   deduct 15
    <= 0%:  deduct 25

  Category overspend (vs Indian benchmarks, each >10% above): deduct 5 each (max -15)
  Projected month-end > budget by 1–20%: deduct 5
  Projected month-end > budget by >20%:  deduct 10

PATTERN DETECTION INSTRUCTIONS:
- Flag categories more than 10% above Indian benchmarks with exact figures
- Flag if weekend avg spend > 1.5x weekday avg (state exact multiplier)
- Flag if projected month-end exceeds budget (state ₹ overshoot)
- Flag savings rate < 10% as concern, >= 20% as positive
- Maximum 4 insights, most impactful first

RECOMMENDATION INSTRUCTIONS:
- Generate exactly 3 recommendations
- Each must reference specific ₹ amounts from the data
- Each must state exact ₹ monthly saving achievable
- Be specific: name category, current spend, target spend, how to achieve it
- Always cover: highest category, weekend behavior, one recurring cost

$responseSchema
''';

    final response = await http.post(
      Uri.parse(AppConstants.workerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'messages': [
          {'role': 'user', 'content': userMessage}
        ],
        'system': systemPrompt,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Worker returned status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final raw = decoded['result'];

    // Robust parsing — handle string or map
    Map<String, dynamic> json;
    if (raw is Map<String, dynamic>) {
      json = raw;
    } else if (raw is String) {
      // Try direct parse first
      try {
        json = jsonDecode(raw);
      } catch (_) {
        // Extract JSON block from string
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
        if (match == null) throw const FormatException('No JSON found in response');
        json = jsonDecode(match.group(0)!);
      }
    } else {
      throw const FormatException('Unexpected response format');
    }

    // ── Parse insights ────────────────────────────────────────────
    final rawInsights = (json['insights'] as List?) ?? [];
    final insights = rawInsights.map((i) {
      final type = i['type'] as String? ?? 'neutral';
      Color badgeColor;
      Color badgeBg;
      switch (type) {
        case 'warning':
          badgeColor = AppColors.primary;
          badgeBg    = AppColors.primaryLight;
          break;
        case 'positive':
          badgeColor = AppColors.income;
          badgeBg    = AppColors.emerald100;
          break;
        default:
          badgeColor = AppColors.neutral;
          badgeBg    = const Color(0xFFF1F5F9);
      }
      // Map impact to icon
      final impact = i['impact'] as String? ?? 'medium';
      IconData icon;
      Color iconColor;
      Color iconBg;
      switch (i['title']?.toString().toLowerCase() ?? '') {
        case String s when s.contains('food'):
          icon = Icons.restaurant; iconColor = AppColors.orange500; iconBg = AppColors.orange100;
          break;
        case String s when s.contains('transport'):
          icon = Icons.directions_car; iconColor = AppColors.blue500; iconBg = AppColors.blue100;
          break;
        case String s when s.contains('shopping'):
          icon = Icons.shopping_bag; iconColor = AppColors.purple500; iconBg = AppColors.purple100;
          break;
        case String s when s.contains('weekend'):
          icon = Icons.weekend; iconColor = AppColors.warning; iconBg = const Color(0xFFFEF3C7);
          break;
        case String s when s.contains('saving'):
          icon = Icons.savings; iconColor = AppColors.income; iconBg = AppColors.emerald100;
          break;
        default:
          icon = Icons.analytics; iconColor = AppColors.neutral; iconBg = const Color(0xFFF1F5F9);
      }

      return SpendingInsight(
        title:       i['title']    as String? ?? 'Insight',
        subtitle:    i['subtitle'] as String? ?? '',
        badge:       i['badge']    as String? ?? type,
        badgeColor:  badgeColor,
        badgeBgColor: badgeBg,
        icon:        icon,
        iconColor:   iconColor,
        iconBgColor: iconBg,
      );
    }).toList();

    // ── Parse recommendations ─────────────────────────────────────
    final rawRecs = (json['recommendations'] as List?) ?? [];
    final recommendations = rawRecs.map((r) => Recommendation(
      number:       (r['number']       as num?)?.toInt()    ?? 1,
      title:         r['title']        as String?           ?? 'Recommendation',
      description:   r['description']  as String?           ?? '',
      savingsLabel:  r['savingsLabel'] as String?           ?? 'Save ₹0/mo',
    )).toList();

    // ── Build result ──────────────────────────────────────────────
    _result = AiAnalysisResult(
      budgetScore:      (json['budgetScore']      as num?)?.toInt()    ?? 50,
      scoreLabel:        json['scoreLabel']        as String?           ?? 'Fair',
      summary:           json['summary']           as String?           ?? '',
      projectedMonthEnd:(json['projectedMonthEnd'] as num?)?.toDouble() ?? 0,
      savingsRate:       (json['savingsRate']      as num?)?.toDouble() ?? 0,
      insights:          insights,
      recommendations:   recommendations,
      potentialSavings:  (json['potentialSavings'] as num?)?.toDouble() ?? 0,
      positiveNote:      json['positiveNote']      as String?           ?? '',
    );

    _isLoading = false;
    notifyListeners();

  } on SocketException {
    _error = 'No internet connection. Please check your network and try again.';
    _isLoading = false;
    notifyListeners();
  } on TimeoutException {
    _error = 'The request timed out. Please try again.';
    _isLoading = false;
    notifyListeners();
  } on FormatException catch (e) {
    _error = 'The AI returned an unexpected response format. Please try again.';
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _error = 'Analysis failed: ${e.toString()}';
    _isLoading = false;
    notifyListeners();
  }
}
```

---

## ✅ Improvement 8 — Update AiAnalysisResult Model

Update the `AiAnalysisResult` class in `ai_provider.dart` to include the new fields:

```dart
class AiAnalysisResult {
  final int budgetScore;
  final String scoreLabel;        // NEW: "Excellent", "Good", etc.
  final String summary;
  final double projectedMonthEnd; // NEW: projected total at month end
  final double savingsRate;       // NEW: income - expenses / income %
  final List<SpendingInsight> insights;
  final List<Recommendation> recommendations;
  final double potentialSavings;
  final String positiveNote;      // NEW: something user is doing well

  const AiAnalysisResult({
    required this.budgetScore,
    required this.scoreLabel,
    required this.summary,
    required this.projectedMonthEnd,
    required this.savingsRate,
    required this.insights,
    required this.recommendations,
    required this.potentialSavings,
    required this.positiveNote,
  });
}
```

---

## ✅ Improvement 9 — Update AI Insights Screen UI

Use the new fields to enrich the UI:

### Score card — add label below score:
```dart
// Below the score number, add:
Text(
  result.scoreLabel,
  style: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: _scoreLabelColor(result.budgetScore),
  ),
)

Color _scoreLabelColor(int score) {
  if (score >= 90) return AppColors.income;
  if (score >= 75) return AppColors.income;
  if (score >= 60) return AppColors.warning;
  if (score >= 40) return AppColors.primary;
  return AppColors.primary;
}
```

### Add projection card between score and insights:
```dart
if (result.projectedMonthEnd > 0)
  _ProjectionCard(
    projected: result.projectedMonthEnd,
    budget: context.read<BudgetProvider>().monthlyLimit,
    savingsRate: result.savingsRate,
  )
```

```dart
class _ProjectionCard extends StatelessWidget {
  final double projected;
  final double budget;
  final double savingsRate;

  const _ProjectionCard({
    required this.projected,
    required this.budget,
    required this.savingsRate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOver = budget > 0 && projected > budget;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOver
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.income.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Month-end Projection',
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(
                  '₹${projected.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isOver ? AppColors.primary : AppColors.income,
                  ),
                ),
                if (budget > 0)
                  Text(
                    isOver
                        ? '₹${(projected - budget).toStringAsFixed(0)} over budget'
                        : '₹${(budget - projected).toStringAsFixed(0)} under budget',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOver ? AppColors.primary : AppColors.income,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Savings Rate',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(
                '${savingsRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: savingsRate >= 20
                      ? AppColors.income
                      : savingsRate >= 10
                          ? AppColors.warning
                          : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Add positive note at bottom:
```dart
if (result.positiveNote.isNotEmpty)
  Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppColors.emerald100,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Text('✅', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            result.positiveNote,
            style: const TextStyle(
              color: Color(0xFF065F46),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  ),
```

---

## ✅ Improvement 10 — Cloudflare Worker Tuning (Optional)

Update your Worker code to pass better parameters to the model:

```javascript
const response = await env.AI.run(
  "@cf/meta/llama-3.2-1b-instruct",
  {
    messages: [
      ...(system ? [{ role: "system", content: system }] : []),
      ...messages
    ],
    max_tokens: 1500,    // increased from 1024 — richer responses need more tokens
    temperature: 0.2,    // reduced from 0.3 — lower = more consistent, factual output
    top_p: 0.9,          // nucleus sampling — keeps output focused
  }
);
```

**Why these values:**
- `max_tokens: 1500` — the new richer JSON response needs more space
- `temperature: 0.2` — lower temperature = less creativity, more accurate number-based responses
- `top_p: 0.9` — prevents wild token choices while keeping some variety

---

## 📋 Implementation Checklist for Your Agent

Feed these prompts to your agent in order:

```
Prompt A — Update AiAnalysisResult model with new fields
           (scoreLabel, projectedMonthEnd, savingsRate, positiveNote)

Prompt B — Replace analyze() method with the full updated version above
           (includes systemPrompt, _buildContext, responseSchema constants)

Prompt C — Update AI Insights screen to use new fields
           (score label color, ProjectionCard widget, positiveNote card)

Prompt D — Update Cloudflare Worker with new parameters
           (max_tokens: 1500, temperature: 0.2, top_p: 0.9)

Prompt E — Test with real data:
           Add 5+ transactions across different categories
           Set a monthly budget
           Tap Re-analyze and verify:
             - Score matches formula
             - Insights reference real ₹ amounts
             - Recommendations have specific ₹ savings
             - Projection card shows correct month-end estimate
             - Positive note appears at bottom
```

---

## 📊 Expected Quality Improvement

| Metric | Before | After |
|---|---|---|
| Score consistency | Random | Formula-driven, reproducible |
| Insight specificity | Generic phrases | Exact ₹ amounts and % vs benchmark |
| Recommendation quality | Vague tips | Specific actions with ₹ targets |
| Indian context | None | INR, Indian benchmarks, local spending norms |
| Response reliability | Occasional parse failures | Robust multi-strategy parsing |
| New fields surfaced | None | Projection, savings rate, positive note |

---

*Expense Buddy — AI Prompt Improvement Plan | ₹ INR | Professional Tone*
