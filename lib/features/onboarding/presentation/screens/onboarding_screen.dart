import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Manage your daily\nlife expenses',
      description: 'Track your spending habits, set budgets, and achieve your financial goals with our intuitive tools.',
      color: const Color(0xFFFFFDE7),
    ),
    OnboardingData(
      title: 'Smart AI\nInsights',
      description: 'Get personalized financial advice and spending analysis powered by advanced AI algorithms.',
      color: const Color(0xFFE8F5E9),
    ),
    OnboardingData(
      title: 'Complete\nPrivacy',
      description: 'All your financial data is stored securely and never shared with anyone. Your privacy is our priority.',
      color: const Color(0xFFE3F2FD),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : _onboardingData[_currentPage].color,
      body: SafeArea(
        child: Column(
          children: [
            // Close button top right
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
                  child: Icon(
                    Icons.close_rounded,
                    size: 28,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),

            // Illustration Area
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) => _IllustrationWidget(index: index),
                  ),
                ),
              ),
            ),

            // Bottom Sheet Card
            _BottomCard(
              isDark: isDark,
              currentPage: _currentPage,
              totalPages: _onboardingData.length,
              data: _onboardingData[_currentPage],
              onNext: () {
                if (_currentPage < _onboardingData.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.color,
  });
}

class _IllustrationWidget extends StatelessWidget {
  final int index;
  const _IllustrationWidget({required this.index});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 4,
              ),
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Inner illustration circle
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: index == 0 
                  ? _PieIllustration() 
                  : index == 1 
                    ? _AiIllustration() 
                    : _PrivacyIllustration(),
              ),
            ),
          ),

          // Floating icons based on slide
          if (index == 0) ...[
            const Positioned(top: -10, right: -10, child: _FloatingIcon(icon: Icons.coffee, color: AppColors.primary)),
            const Positioned(bottom: 30, left: -20, child: _FloatingIcon(icon: Icons.shopping_bag, color: Color(0xFF4DB6AC))),
            const Positioned(bottom: 5, right: 30, child: _FloatingIcon(icon: Icons.home, color: Color(0xFFFFD54F))),
          ] else if (index == 1) ...[
            const Positioned(top: -10, left: -10, child: _FloatingIcon(icon: Icons.psychology_rounded, color: AppColors.primary)),
            const Positioned(bottom: 40, right: -10, child: _FloatingIcon(icon: Icons.auto_awesome_rounded, color: Color(0xFF81C784))),
          ] else ...[
            const Positioned(top: 10, right: 10, child: _FloatingIcon(icon: Icons.security_rounded, color: AppColors.primary)),
            const Positioned(bottom: 20, left: 10, child: _FloatingIcon(icon: Icons.verified_user_rounded, color: Color(0xFF64B5F6))),
          ],
        ],
      ),
    );
  }
}

class _AiIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(Icons.auto_graph_rounded, size: 100, color: Color(0xFF4DB6AC)),
      ),
    );
  }
}

class _PrivacyIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE3F2FD),
      child: const Center(
        child: Icon(Icons.lock_person_rounded, size: 100, color: Color(0xFF64B5F6)),
      ),
    );
  }
}

class _PieIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF8E1),
      child: CustomPaint(
        painter: _PiePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final segments = [
      (sweepAngle: 0.7, color: const Color(0xFFFF6B6B)),
      (sweepAngle: 0.6, color: const Color(0xFF4DB6AC)),
      (sweepAngle: 0.8, color: const Color(0xFF81C784)),
      (sweepAngle: 0.7, color: const Color(0xFFFFB74D)),
      (sweepAngle: 0.5, color: const Color(0xFF64B5F6)),
      (sweepAngle: 0.99, color: const Color(0xFFF06292)),
    ];

    double startAngle = -1.5707;
    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, seg.sweepAngle - 0.05, true, paint);

      // White separator
      final sepPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(rect, startAngle, seg.sweepAngle, true, sepPaint);

      startAngle += seg.sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FloatingIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _BottomCard extends StatelessWidget {
  final bool isDark;
  final int currentPage;
  final int totalPages;
  final OnboardingData data;
  final VoidCallback onNext;

  const _BottomCard({
    required this.isDark,
    required this.currentPage,
    required this.totalPages,
    required this.data,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == totalPages - 1;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A0A0A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 6,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // Title
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              data.title,
              key: ValueKey(data.title),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              data.description,
              key: ValueKey(data.description),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ),

          const SizedBox(height: 36),

          // CTA Action
          if (isLastPage)
            _SlideToStartButton(
              onComplete: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
            )
          else
            GestureDetector(
              onTap: onNext,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Page dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => _Dot(isActive: index == currentPage),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideToStartButton extends StatefulWidget {
  final VoidCallback onComplete;
  const _SlideToStartButton({required this.onComplete});

  @override
  State<_SlideToStartButton> createState() => _SlideToStartButtonState();
}

class _SlideToStartButtonState extends State<_SlideToStartButton> {
  double _position = 0;
  final double _buttonSize = 52;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final trackWidth = maxWidth - _buttonSize - 12;

        return Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            children: [
              const Center(
                child: Text(
                  'Swipe to get started',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: _completed ? const Duration(milliseconds: 200) : Duration.zero,
                left: _position + 6,
                top: 6,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _position = (_position + details.delta.dx).clamp(0, trackWidth);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_position >= trackWidth * 0.8) {
                      setState(() {
                        _position = trackWidth;
                        _completed = true;
                      });
                      widget.onComplete();
                    } else {
                      setState(() {
                        _position = 0;
                      });
                    }
                  },
                  child: Container(
                    width: _buttonSize,
                    height: _buttonSize,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.keyboard_double_arrow_right_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  final bool isActive;
  const _Dot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 32 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
