import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

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

class AiProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  AiAnalysisResult? _result;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  AiAnalysisResult? get result => _result;
  bool get hasResult => _result != null;

  static const String systemPrompt = """
You are a professional personal finance analyst assistant for Indian users.
Your role is to analyze monthly expense data and provide structured, 
data-driven financial insights.

Rules you must follow:
- Always respond in ONLY valid raw JSON. No markdown. No explanation. No preamble.
- All monetary values are in Indian Rupees (₹).
- Use a formal, professional tone. Avoid casual language.
- Base every insight and recommendation on the actual numbers provided.
- NEVER use placeholder text like "<insight title>" or "<2 formal sentences>".
- NEVER use pipe-separated values like "<warning|positive|neutral>". Pick ONE specific value.
- NEVER invent data that was not provided.
- Budget score must follow the exact scoring formula provided in the prompt.
- Every recommendation must include a specific ₹ savings amount per month.
- Insights must reference actual category names and percentages from the data.
""";

  static const String responseSchema = '''
Return ONLY this JSON object. No other text. Calculate real values from the data provided:
{
  "budgetScore": <integer 0-100 calculated using the formula above>,
  "scoreLabel": "Pick one: Excellent, Good, Fair, Needs Attention, or Critical",
  "summary": "2 formal sentences based on the data. Reference actual ₹ figures.",
  "projectedMonthEnd": <number — calculate from daily average>,
  "savingsRate": <number — calculate (income-expense)/income * 100>,
  "insights": [
    {
      "title": "Specific category or pattern name",
      "subtitle": "One formal sentence with specific ₹ or % figures",
      "badge": "Concise label with real numbers",
      "type": "Pick one: warning, positive, or neutral",
      "impact": "Pick one: high, medium, or low"
    }
  ],
  "recommendations": [
    {
      "number": 1,
      "title": "Action title — verb + category",
      "description": "Specific current spend, target spend, and action required",
      "savingsLabel": "Save ₹X/mo",
      "savingsAmount": <number>
    }
  ],
  "potentialSavings": <number — sum of savingsAmount>,
  "positiveNote": "One sentence acknowledging a real positive habit from the data"
}
''';

  String _buildContext(List<Transaction> transactions, double budget) {
    // ... (same implementation as before)
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.day;
    final daysRemaining = daysInMonth - daysElapsed;

    final expenses = transactions.where((t) => !t.isIncome).toList();
    final incomes  = transactions.where((t) =>  t.isIncome).toList();
    final totalExpenses = expenses.fold(0.0, (s, t) => s + t.amount);
    final totalIncome   = incomes.fold(0.0,  (s, t) => s + t.amount);
    final savingsRate   = totalIncome > 0
        ? ((totalIncome - totalExpenses) / totalIncome * 100).toStringAsFixed(1)
        : '0.0';

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

    final topTxns = [...expenses]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top3 = topTxns.take(3).map((t) =>
      '  - ${t.title} (${t.category.label}): ₹${t.amount.toStringAsFixed(0)}'
    ).join('\n');

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

  bool _isTemplateResponse(Map<String, dynamic> json) {
    // Check if AI echoed back instructions/placeholders
    final summary = json['summary']?.toString().toLowerCase() ?? '';
    if (summary.contains('<') || summary.contains('sentence') || summary.contains('placeholder')) return true;

    final insights = json['insights'] as List?;
    if (insights != null && insights.isNotEmpty) {
      final first = insights.first;
      final type = first['type']?.toString() ?? '';
      if (type.contains('|')) return true;
      if (first['title']?.toString().contains('<') ?? false) return true;
    }
    
    return false;
  }

  Future<void> analyze(List<Transaction> transactions, double budget, {int retryCount = 0}) async {
    if (transactions.isEmpty) {
      _error = 'No transactions to analyze. Add at least 3 expenses first.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    if (retryCount == 0) _error = null;
    notifyListeners();

    try {
      final context = _buildContext(transactions, budget);

      final userMessage = '''
THE DATA:
$context

THE TASK:
Analyze the data above. Detect patterns and generate specific recommendations.

THE SCORE FORMULA (Calculate this exactly):
Start with 100 points. Deduct:
- Budget usage: 61-75% (-10), 76-90% (-20), 91-100% (-30), Over (-40)
- Savings rate: 10-19% (-10), 1-9% (-15), <=0% (-25)
- Category overspend (>10% above benchmark): -5 per category (max -15)
- Projection > budget: 1-20% (-5), >20% (-10)

IMPORTANT: Do NOT return placeholders or example text. Calculate REAL numbers from "THE DATA" provided above.

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

      debugPrint('AI RAW RESPONSE (via Worker): ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Worker returned status ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final raw = decoded['result'];
      debugPrint('AI RESULT FIELD: $raw');

      Map<String, dynamic> json;
      if (raw is Map<String, dynamic>) {
        json = raw;
      } else if (raw is String) {
        try {
          json = jsonDecode(raw);
        } catch (_) {
          debugPrint('AI RESPONSE: Attempting to extract JSON from string...');
          final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
          if (match == null) {
            debugPrint('AI ERROR: No JSON block found in string: $raw');
            throw const FormatException('No JSON found in response');
          }
          final jsonStr = match.group(0)!;
          debugPrint('AI EXTRACTED JSON: $jsonStr');
          json = jsonDecode(jsonStr);
        }
      } else {
        debugPrint('AI ERROR: Unexpected value type for result: ${raw.runtimeType}');
        throw const FormatException('Unexpected response format');
      }

      // ── Template Detection & Retry ────────────────────────────────
      if (_isTemplateResponse(json) && retryCount < 1) {
        debugPrint('AI WARNING: Template response detected. Retrying in 1s...');
        await Future.delayed(const Duration(seconds: 1));
        return analyze(transactions, budget, retryCount: retryCount + 1);
      }
      
      if (_isTemplateResponse(json)) {
        throw const FormatException('AI returned template text instead of real analysis');
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

      final rawRecs = (json['recommendations'] as List?) ?? [];
      final recommendations = rawRecs.map((r) => Recommendation(
        number:       (r['number']       as num?)?.toInt()    ?? 1,
        title:         r['title']        as String?           ?? 'Recommendation',
        description:   r['description']  as String?           ?? '',
        savingsLabel:  r['savingsLabel'] as String?           ?? 'Save ₹0/mo',
      )).toList();

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
      _error = 'AI Analysis failed: ${e.message}';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Analysis failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearResult() {
    _result = null;
    notifyListeners();
  }
}

