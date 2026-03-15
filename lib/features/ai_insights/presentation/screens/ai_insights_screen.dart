import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/providers/ai_provider.dart';
import '../../../../core/providers/budget_provider.dart';
import '../../../../core/providers/expense_provider.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  bool _isAnalyzing = false;

  Future<void> _reanalyze(BuildContext context) async {
    final aiProvider = context.read<AiProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    
    final transactions = expenseProvider.transactions;
    
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some transactions first to analyze!')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    await aiProvider.analyze(transactions, budgetProvider.monthlyLimit);
    if (mounted) setState(() => _isAnalyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiProvider = context.watch<AiProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    
    final result = aiProvider.result;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                children: [
                  // Budget Health Card
                  _BudgetHealthCard(
                    isDark: isDark,
                    utilization: budgetProvider.usedPercentage / 100,
                    totalSpent: budgetProvider.usedAmount,
                    budget: budgetProvider.monthlyLimit,
                    score: result?.budgetScore,
                    scoreLabel: result?.scoreLabel,
                  ),
                  const SizedBox(height: 28),

                  if (aiProvider.error != null) ...[
                    _ErrorState(
                      error: aiProvider.error!, 
                      onRetry: () => _reanalyze(context),
                      isDark: isDark,
                    ),
                  ] else if (result == null && !aiProvider.isLoading) ...[
                    _WelcomeState(onAnalyze: () => _reanalyze(context), isDark: isDark),
                  ] else if (aiProvider.isLoading || _isAnalyzing) ...[
                    _LoadingState(isDark: isDark),
                  ] else if (result != null) ...[
                    // New Projection Card
                    if (result.projectedMonthEnd > 0)
                      _ProjectionCard(
                        projected: result.projectedMonthEnd,
                        budget: budgetProvider.monthlyLimit,
                        savingsRate: result.savingsRate,
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Insights
                    const SectionHeader(title: 'Monthly Insights'),
                    const SizedBox(height: 14),
                    ...result.insights.map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InsightCard(insight: insight, isDark: isDark),
                    )),

                    const SizedBox(height: 20),

                    // Recommendations
                    const SectionHeader(title: 'Smart Recommendations'),
                    const SizedBox(height: 14),
                    ...result.recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecommendationCard(recommendation: rec, isDark: isDark),
                    )),
                    
                    const SizedBox(height: 12),
                    
                    // Positive Note Card
                    if (result.positiveNote.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
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
                  ],

                  const SizedBox(height: 24),

                  // Re-analyze button
                  if (result != null)
                    PrimaryButton(
                      label: 'Re-analyze Spending',
                      icon: Icons.refresh_rounded,
                      onTap: () => _reanalyze(context),
                      isLoading: _isAnalyzing || aiProvider.isLoading,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 10),
          Text('AI Insights', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _WelcomeState extends StatelessWidget {
  final VoidCallback onAnalyze;
  final bool isDark;
  const _WelcomeState({required this.onAnalyze, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.insights_rounded,
          size: 80,
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 24),
        Text(
          'Unlock Smart Insights',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Get personalized recommendations and spending analysis powered by AI.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Analyze My Spending',
          icon: Icons.bolt_rounded,
          onTap: onAnalyze,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorState({
    required this.error,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.error_outline_rounded, color: AppColors.primary, size: 64),
        const SizedBox(height: 24),
        Text(
          'Analysis Failed',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Try Again',
          icon: Icons.refresh_rounded,
          onTap: onRetry,
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  final bool isDark;
  const _LoadingState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          'AI Agent is analyzing...',
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This may take a few seconds',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ─── Budget Health Card ───────────────────────────────────────────────────────

class _BudgetHealthCard extends StatelessWidget {
  final bool isDark;
  final double utilization;
  final double totalSpent;
  final double budget;
  final int? score;
  final String? scoreLabel;

  const _BudgetHealthCard({
    required this.isDark,
    required this.utilization,
    required this.totalSpent,
    required this.budget,
    this.score,
    this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = score ?? (utilization * 100).round();
    final remaining = budget - totalSpent;
    final isOver = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular gauge
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(88, 88),
                  painter: _CircleGaugePainter(
                    progress: (score != null ? score! / 100 : utilization).clamp(0.0, 1.0),
                    color: score != null 
                        ? (score! >= 75 ? AppColors.income : (score! >= 50 ? AppColors.warning : AppColors.primary))
                        : (isOver ? AppColors.primary : AppColors.income),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (scoreLabel != null)
                      Text(
                        scoreLabel!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _scoreLabelColor(score!),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(score != null ? 'Budget Score' : 'Budget Health', 
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  score != null
                    ? "Based on your spending patterns, the AI has calculated a financial health score of $score/100."
                    : (isOver 
                        ? "You've exceeded your budget by \$${(-remaining).toStringAsFixed(0)}. Try reducing non-essential spending."
                        : "You've spent $percentage% of your monthly budget. You have \$${remaining.toStringAsFixed(0)} left for the month."),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreLabelColor(int score) {
    if (score >= 90) return AppColors.income;
    if (score >= 75) return AppColors.income;
    if (score >= 60) return AppColors.warning;
    if (score >= 40) return AppColors.primary;
    return AppColors.primary;
  }
}

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

class _CircleGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  const _CircleGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 7.0;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707, // -90 degrees
      progress * 2 * 3.14159,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Insight Card ─────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final SpendingInsight insight;
  final bool isDark;

  const _InsightCard({required this.insight, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: insight.iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(insight.icon, color: insight.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(insight.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: insight.badgeBgColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              insight.badge,
              style: TextStyle(
                color: insight.badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recommendation Card ──────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final bool isDark;

  const _RecommendationCard({required this.recommendation, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${recommendation.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recommendation.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(recommendation.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                recommendation.savingsLabel.split('/')[0],
                style: const TextStyle(
                  color: AppColors.income,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (recommendation.savingsLabel.contains('/'))
                Text(
                  '/${recommendation.savingsLabel.split('/')[1]}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.neutral,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
