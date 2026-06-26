import 'dart:async';
import 'dart:math' as math;

import 'package:dar_city_app/RootScreenNavigation.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/fanMainDashboard.dart';
import 'package:dar_city_app/services/auth_service.dart';
import 'package:dar_city_app/services/forget_password_service.dart';
import 'package:dar_city_app/services/google_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-launch onboarding — animated slides, then sign in.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static const onboardingCompleteKey = 'onboarding_complete';

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(onboardingCompleteKey) ?? false;
  }

  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompleteKey, true);
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController();
  Timer? _autoTimer;
  int _currentPage = 0;

  static const _slideCount = 4;
  static const _autoInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(_autoInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % _slideCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _startAutoAdvance();
  }

  Future<void> _goToPublicFanHome() async {
    await WelcomeScreen.markOnboardingComplete();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RootScreen()),
    );
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _goToAuth({required bool signUp}) async {
    await WelcomeScreen.markOnboardingComplete();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => signUp ? SignUpScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _WelcomeBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    layout.horizontalPadding,
                    8,
                    layout.horizontalPadding,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _goToLogin,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: DarColors.accentRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _WelcomeSlide(isActive: _currentPage == 0),
                      _ScheduleSlide(isActive: _currentPage == 1),
                      _AnnouncementsSlide(isActive: _currentPage == 2),
                      _GetStartedSlide(
                        isActive: _currentPage == 3,
                        onGetStarted: _goToPublicFanHome,
                        onSignIn: () => _goToAuth(signUp: false),
                        onSignUp: () => _goToAuth(signUp: true),
                      ),
                    ],
                  ),
                ),
                _PageIndicator(count: _slideCount, index: _currentPage),
                const SizedBox(height: 12),
                if (_currentPage < _slideCount - 1)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      layout.horizontalPadding,
                      0,
                      layout.horizontalPadding,
                      24,
                    ),
                    child: DarPrimaryButton(
                      label: 'Next',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                    ),
                  )
                else
                  const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0A0A),
            DarColors.chocolateBrown,
            Color(0xFF000000),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DarColors.accentRed.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DarColors.sandBrown.withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? DarColors.accentRed : DarColors.muted.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Slide 1: Welcome ─────────────────────────────────────────────────────────

class _WelcomeSlide extends StatefulWidget {
  const _WelcomeSlide({required this.isActive});

  final bool isActive;

  @override
  State<_WelcomeSlide> createState() => _WelcomeSlideState();
}

class _WelcomeSlideState extends State<_WelcomeSlide>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _spinController;
  late AnimationController _glowController;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _scale = Tween<double>(begin: 0.65, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.elasticOut),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    if (widget.isActive) _activateAnimations();
  }

  void _activateAnimations() {
    _entranceController.forward(from: 0);
    _spinController.repeat();
    _glowController.repeat(reverse: true);
  }

  void _pauseAnimations() {
    _spinController.stop();
    _glowController.stop();
  }

  @override
  void didUpdateWidget(_WelcomeSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _activateAnimations();
    } else if (!widget.isActive && oldWidget.isActive) {
      _pauseAnimations();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _spinController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = DarLayoutMetrics.of(context).horizontalPadding;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _entranceController,
          _spinController,
          _glowController,
        ]),
        builder: (context, child) {
          final spin = _spinController.value * 2 * math.pi;
          final glow = _glowController.value;

          return Opacity(
            opacity: _fade.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _scale.value,
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing outer glow
                        Container(
                          width: 210 + glow * 28,
                          height: 210 + glow * 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: DarColors.accentRed
                                    .withValues(alpha: 0.18 + glow * 0.22),
                                blurRadius: 45 + glow * 35,
                                spreadRadius: 6 + glow * 10,
                              ),
                              BoxShadow(
                                color: DarColors.lightSandBrown
                                    .withValues(alpha: 0.08 + glow * 0.12),
                                blurRadius: 60 + glow * 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        // Orbital ring — rotates like a planet orbit
                        Transform.rotate(
                          angle: spin * 0.6,
                          child: Container(
                            width: 215,
                            height: 215,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: DarColors.lightSandBrown
                                    .withValues(alpha: 0.25 + glow * 0.15),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: -spin * 0.4 + math.pi / 4,
                          child: Container(
                            width: 195,
                            height: 195,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: DarColors.accentRed
                                    .withValues(alpha: 0.15 + glow * 0.2),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        // 3D tumble — basketball / globe spin
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0025)
                            ..rotateY(spin)
                            ..rotateZ(math.sin(spin) * 0.18),
                          child: Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  DarColors.cardBrown,
                                  DarColors.chocolateBrown,
                                ],
                                center: Alignment(-0.3 + math.cos(spin) * 0.2, -0.2),
                              ),
                              border: Border.all(
                                color: DarColors.lightSandBrown
                                    .withValues(alpha: 0.55),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DarColors.accentRed
                                      .withValues(alpha: 0.35 + glow * 0.15),
                                  blurRadius: 24 + glow * 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Image.asset(
                                'assets/images/dar-city-logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        // Highlight sweep
                        Transform.rotate(
                          angle: spin * 1.2,
                          child: Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.transparent,
                                  DarColors.accentRed.withValues(alpha: 0.0),
                                  DarColors.accentRed.withValues(alpha: 0.12),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.4, 0.55, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Welcome to\nDar City Basketball',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Stay close to your team — schedule, news, tickets, and more.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DarColors.lightSandBrown.withValues(alpha: 0.95),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Slide 2: Schedule ────────────────────────────────────────────────────────

class _ScheduleSlide extends StatefulWidget {
  const _ScheduleSlide({required this.isActive});

  final bool isActive;

  @override
  State<_ScheduleSlide> createState() => _ScheduleSlideState();
}

class _ScheduleSlideState extends State<_ScheduleSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const _games = [
    ('Sat, Jun 21', 'Dar City vs JKT', '7:00 PM · National Stadium'),
    ('Wed, Jun 25', 'Team Practice', '9:00 AM · Court A'),
    ('Sun, Jun 29', 'Dar City vs Outsiders', '6:30 PM · Home Arena'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(_ScheduleSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = DarLayoutMetrics.of(context).horizontalPadding;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideHeader(
            icon: Icons.calendar_month_rounded,
            title: 'Team Schedule',
            subtitle: 'Never miss a game or practice',
          ),
          const SizedBox(height: 24),
          ...List.generate(_games.length, (i) {
            final delay = i * 0.15;
            final anim = CurvedAnimation(
              parent: _controller,
              curve: Interval(delay, 0.55 + delay, curve: Curves.easeOutCubic),
            );
            return AnimatedBuilder(
              animation: anim,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(40 * (1 - anim.value), 0),
                  child: Opacity(
                    opacity: anim.value,
                    child: _ScheduleCard(
                      date: _games[i].$1,
                      title: _games[i].$2,
                      venue: _games[i].$3,
                      highlight: i == 0,
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.date,
    required this.title,
    required this.venue,
    this.highlight = false,
  });

  final String date;
  final String title;
  final String venue;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarColors.cardBrown,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? DarColors.accentRed.withValues(alpha: 0.5)
              : DarColors.lightSandBrown.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              color: highlight ? DarColors.accentRed : DarColors.lightSandBrown,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date.toUpperCase(),
                      style: const TextStyle(
                        color: DarColors.lightSandBrown,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      venue,
                      style: TextStyle(
                        color: DarColors.muted.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (highlight)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DarColors.accentRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NEXT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Slide 3: Announcements ───────────────────────────────────────────────────

class _AnnouncementsSlide extends StatefulWidget {
  const _AnnouncementsSlide({required this.isActive});

  final bool isActive;

  @override
  State<_AnnouncementsSlide> createState() => _AnnouncementsSlideState();
}

class _AnnouncementsSlideState extends State<_AnnouncementsSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const _items = [
    ('New season jerseys are here!', 'Shop now in the fan store', Icons.checkroom_outlined),
    ('Playoffs watch party this Friday', 'Doors open 5 PM · Fan zone', Icons.groups_outlined),
    ('Coach Anya: Morning drill moved to 8 AM', 'Updated training schedule', Icons.campaign_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(_AnnouncementsSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = DarLayoutMetrics.of(context).horizontalPadding;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SlideHeader(
            icon: Icons.notifications_active_outlined,
            title: 'Announcements',
            subtitle: 'Team news and updates in real time',
          ),
          const SizedBox(height: 24),
          ...List.generate(_items.length, (i) {
            final delay = i * 0.12;
            final anim = CurvedAnimation(
              parent: _controller,
              curve: Interval(delay, 0.6 + delay, curve: Curves.easeOutBack),
            );
            return AnimatedBuilder(
              animation: anim,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - anim.value)),
                  child: Opacity(
                    opacity: anim.value.clamp(0.0, 1.0),
                    child: _AnnouncementCard(
                      title: _items[i].$1,
                      body: _items[i].$2,
                      icon: _items[i].$3,
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarColors.sandBrown.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DarColors.lightSandBrown.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DarColors.chocolateBrown.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: DarColors.accentRed, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: DarColors.muted.withValues(alpha: 0.95),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide 4: Get started ─────────────────────────────────────────────────────

class _GetStartedSlide extends StatefulWidget {
  const _GetStartedSlide({
    required this.isActive,
    required this.onGetStarted,
    required this.onSignIn,
    required this.onSignUp,
  });

  final bool isActive;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  State<_GetStartedSlide> createState() => _GetStartedSlideState();
}

class _GetStartedSlideState extends State<_GetStartedSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(_GetStartedSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = DarLayoutMetrics.of(context).horizontalPadding;
    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DarColors.cardBrown,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: DarColors.lightSandBrown.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.sports_basketball,
                      color: DarColors.accentRed, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Ready to join the city?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Browse news, schedules, live scores, and team info — no sign in required. Create an account when you want tickets, shop, or more.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DarColors.muted.withValues(alpha: 0.95),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FeatureChip(icon: Icons.event_seat, label: 'Tickets'),
                  const SizedBox(height: 8),
                  _FeatureChip(icon: Icons.live_tv, label: 'Live scores'),
                  const SizedBox(height: 8),
                  _FeatureChip(icon: Icons.storefront_outlined, label: 'Fan shop'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            DarPrimaryButton(
              label: 'Get Started',
              icon: Icons.arrow_forward_rounded,
              onPressed: widget.onGetStarted,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9)),
                ),
                GestureDetector(
                  onTap: widget.onSignIn,
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: DarColors.accentRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9)),
                ),
                GestureDetector(
                  onTap: widget.onSignUp,
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: DarColors.accentRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DarColors.sandBrown.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: DarColors.lightSandBrown, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideHeader extends StatelessWidget {
  const _SlideHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DarColors.accentRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: DarColors.accentRed, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: DarColors.lightSandBrown.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Auth flow — login, sign up, forgot password, verify, complete profile
// ═══════════════════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final result = await AuthService.login(
      emailController.text.trim(),
      passwordController.text,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result['success'] == true) {
      await storage.write(key: 'api_token', value: result['token']);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RootScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login Failed!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _backToWelcome() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.all(layout.horizontalPadding),
          child: ResponsiveAuthShell(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _backToWelcome,
                  ),
                ),
                const SizedBox(height: 8),
                Image.asset(
                  'assets/images/dar-city-logo.png',
                  width: 160,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to continue',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 30),
                Card(
                  color: const Color(0xFF1A1A1A),
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.email, color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Email required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Password required' : null,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: isLoading ? null : _handleLogin,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.white70),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final result = await AuthService.registerStepOne(
      emailController.text.trim(),
      passwordController.text,
      confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result['success'] == true) {
      final String token = result['token'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(token: token),
        ),
      );
    } else {
      _showError(result);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => isGoogleLoading = true);

    final result = await GoogleAuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() => isGoogleLoading = false);

    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showError(result);
    }
  }

  void _showError(Map<String, dynamic> result) {
    String message = result['message'] ?? 'An error occurred';

    if (result['errors'] != null) {
      if (result['errors']['email'] != null) {
        message = result['errors']['email'][0];
      } else if (result['errors']['password'] != null) {
        message = result['errors']['password'][0];
      } else if (result['errors']['password_confirmation'] != null) {
        message = result['errors']['password_confirmation'][0];
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.all(layout.horizontalPadding),
          child: ResponsiveAuthShell(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/dar-city-logo.png',
                  width: 160,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join Dar City Basketball',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 30),
                Card(
                  color: const Color(0xFF1A1A1A),
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Email address',
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.email, color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(value.trim())) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white54,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Confirm password',
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white54,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: isLoading || isGoogleLoading
                                  ? null
                                  : _handleSignUp,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign In',
                        style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool _isLoading = false;
  String? _successMessage;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _successMessage = null;
    });

    final result =
        await ForgotPasswordService.sendResetLink(emailController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _successMessage = result['message']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Forgot Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(layout.horizontalPadding),
        child: ResponsiveAuthShell(
          child: Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Reset your password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your registered email and we’ll send you a password reset link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.email, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _successMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSendLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Send Reset Link',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.token});

  final String token;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool isVerifying = false;
  bool isResending = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
      );
      return;
    }

    setState(() => isVerifying = true);

    final result = await AuthService.verifyEmail(
      token: widget.token,
      code: code,
    );

    if (!mounted) return;
    setState(() => isVerifying = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(token: widget.token),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Verification failed')),
      );
    }
  }

  Future<void> _resendCode() async {
    setState(() => isResending = true);

    final result = await AuthService.resendVerificationCode(widget.token);

    if (!mounted) return;
    setState(() => isResending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Failed to resend code')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
                  child: ResponsiveAuthShell(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const Icon(Icons.mark_email_read_outlined,
                            size: 80, color: Colors.red),
                          const SizedBox(height: 30),
                          const Text(
                            'Check your email',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "We've sent a 6-digit verification code to your email. Please enter it below to continue.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          CodeInputRow(
                            controllers: _controllers,
                            focusNodes: _focusNodes,
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            "Didn't receive the code?",
                            style: TextStyle(color: Colors.white70, fontSize: 15),
                          ),
                          TextButton(
                            onPressed: isResending ? null : _resendCode,
                            child: isResending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Text(
                                    'Resend Code',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: isVerifying ? null : _verifyCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: isVerifying
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      'Verify',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
            );
          },
        ),
      ),
    );
  }
}

class CodeInputRow extends StatelessWidget {
  const CodeInputRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(controllers.length, (index) {
        return SizedBox(
          width: 45,
          height: 60,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            enableSuggestions: false,
            autocorrect: false,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (index < controllers.length - 1) {
                  focusNodes[index + 1].requestFocus();
                } else {
                  focusNodes[index].unfocus();
                }
              } else if (value.isEmpty && index > 0) {
                focusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, required this.token});

  final String token;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _preferredPlayerController = TextEditingController();
  final _favoriteJerseyController = TextEditingController();
  final storage = const FlutterSecureStorage();

  String? _role;
  bool isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _preferredPlayerController.dispose();
    _favoriteJerseyController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.completeProfile(
      token: widget.token,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _role!,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result['success']) {
      await storage.write(key: 'api_token', value: result['token']);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RootScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ProfileTextField(
              label: 'Full Name',
              controller: _fullNameController,
            ),
            const SizedBox(height: 16),
            ProfileTextField(
              label: 'Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ProfileTextField(
              label: 'Preferred Player (Optional)',
              controller: _preferredPlayerController,
            ),
            const SizedBox(height: 16),
            ProfileTextField(
              label: 'Favorite Jersey (Optional)',
              controller: _favoriteJerseyController,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Fan',
                        style: TextStyle(color: Colors.white)),
                    leading: Radio<String>(
                      value: 'fan',
                      groupValue: _role,
                      onChanged: (value) => setState(() => _role = value),
                      activeColor: Colors.red,
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Sponsor',
                        style: TextStyle(color: Colors.white)),
                    leading: Radio<String>(
                      value: 'sponsor',
                      groupValue: _role,
                      onChanged: (value) => setState(() => _role = value),
                      activeColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
