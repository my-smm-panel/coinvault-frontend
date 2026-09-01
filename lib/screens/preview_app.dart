import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/mock_data.dart';
import '../models/ui_models.dart';
import '../widgets/mascot_bear.dart';
import '../widgets/ui_kit.dart';

enum PreviewPage {
  splash,
  onboardingTasks,
  onboardingCoins,
  onboardingWithdraw,
  welcome,
  verifyPhone,
  home,
  earn,
  tasks,
  taskDetail,
  surveys,
  spin,
  scratch,
  checkin,
  challenges,
  refer,
  wallet,
  withdraw,
  withdrawUpi,
  withdrawHistory,
  notifications,
  leaderboard,
  history,
  profile,
  settings,
  help,
}

class CoinVaultPreviewApp extends StatefulWidget {
  const CoinVaultPreviewApp({super.key});

  @override
  State<CoinVaultPreviewApp> createState() => _CoinVaultPreviewAppState();
}

class _CoinVaultPreviewAppState extends State<CoinVaultPreviewApp> {
  PreviewPage _page = PreviewPage.splash;
  Timer? _splashTimer;
  int _mainIndex = 0;
  int _taskFilter = 0;
  int _surveyFilter = 0;
  int _challengeFilter = 0;
  int _withdrawHistoryFilter = 0;
  int _leaderboardFilter = 0;
  int _historyFilter = 0;
  double _wheelTurns = 0;
  String _spinResult = 'You have 3 free spins';
  final _upiController = TextEditingController(text: 'arbazbasha@upi');
  final _amountController = TextEditingController(text: '1000');
  final _otp = List.generate(6, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) _go(PreviewPage.onboardingTasks);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _upiController.dispose();
    _amountController.dispose();
    for (final controller in _otp) {
      controller.dispose();
    }
    super.dispose();
  }

  void _go(PreviewPage next) {
    setState(() => _page = next);
  }

  void _goMain(int index) {
    setState(() {
      _mainIndex = index;
      _page = switch (index) {
        0 => PreviewPage.home,
        1 => PreviewPage.earn,
        2 => PreviewPage.spin,
        3 => PreviewPage.withdraw,
        _ => PreviewPage.profile,
      };
    });
  }

  void _spinWheel() {
    final rewards = [10, 25, 50, 75, 100, 250, 500, 1000];
    final idx = math.Random().nextInt(rewards.length);
    final segmentTurns = 1 / rewards.length;
    setState(() {
      _wheelTurns += 6 + ((rewards.length - idx) * segmentTurns) - (segmentTurns / 2);
      _spinResult = 'Last spin: +${rewards[idx]} coins';
    });
  }

  void _fillOtp(String digit) {
    for (final controller in _otp) {
      if (controller.text.isEmpty) {
        controller.text = digit;
        break;
      }
    }
    if (_otp.every((c) => c.text.isNotEmpty)) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _goMain(0);
      });
    } else {
      setState(() {});
    }
  }

  void _backspaceOtp() {
    for (final controller in _otp.reversed) {
      if (controller.text.isNotEmpty) {
        controller.clear();
        break;
      }
    }
    setState(() {});
  }

  void _showAllScreens() {
    final entries = <({String title, PreviewPage page})>[
      (title: 'Home', page: PreviewPage.home),
      (title: 'Earn Categories', page: PreviewPage.earn),
      (title: 'Task List', page: PreviewPage.tasks),
      (title: 'Task Detail', page: PreviewPage.taskDetail),
      (title: 'Surveys', page: PreviewPage.surveys),
      (title: 'Spin Wheel', page: PreviewPage.spin),
      (title: 'Scratch Card', page: PreviewPage.scratch),
      (title: 'Daily Check-in', page: PreviewPage.checkin),
      (title: 'Challenges', page: PreviewPage.challenges),
      (title: 'Refer & Earn', page: PreviewPage.refer),
      (title: 'Wallet', page: PreviewPage.wallet),
      (title: 'Withdraw', page: PreviewPage.withdraw),
      (title: 'Withdraw to UPI', page: PreviewPage.withdrawUpi),
      (title: 'Withdraw History', page: PreviewPage.withdrawHistory),
      (title: 'Notifications', page: PreviewPage.notifications),
      (title: 'Leaderboard', page: PreviewPage.leaderboard),
      (title: 'History', page: PreviewPage.history),
      (title: 'Profile', page: PreviewPage.profile),
      (title: 'Settings', page: PreviewPage.settings),
      (title: 'Help Center', page: PreviewPage.help),
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const Text(
                'All Screens',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4, width: double.infinity),
              ...entries.map(
                (entry) => InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _go(entry.page);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2 - 28,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      entry.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(_page),
          child: switch (_page) {
            PreviewPage.splash => _buildSplash(),
            PreviewPage.onboardingTasks => _buildOnboardingTasks(),
            PreviewPage.onboardingCoins => _buildOnboardingCoins(),
            PreviewPage.onboardingWithdraw => _buildOnboardingWithdraw(),
            PreviewPage.welcome => _buildWelcome(),
            PreviewPage.verifyPhone => _buildVerifyPhone(),
            PreviewPage.home => _buildHome(),
            PreviewPage.earn => _buildEarn(),
            PreviewPage.tasks => _buildTasks(),
            PreviewPage.taskDetail => _buildTaskDetail(),
            PreviewPage.surveys => _buildSurveys(),
            PreviewPage.spin => _buildSpin(),
            PreviewPage.scratch => _buildScratch(),
            PreviewPage.checkin => _buildCheckin(),
            PreviewPage.challenges => _buildChallenges(),
            PreviewPage.refer => _buildRefer(),
            PreviewPage.wallet => _buildWallet(),
            PreviewPage.withdraw => _buildWithdraw(),
            PreviewPage.withdrawUpi => _buildWithdrawUpi(),
            PreviewPage.withdrawHistory => _buildWithdrawHistory(),
            PreviewPage.notifications => _buildNotifications(),
            PreviewPage.leaderboard => _buildLeaderboard(),
            PreviewPage.history => _buildHistory(),
            PreviewPage.profile => _buildProfile(),
            PreviewPage.settings => _buildSettings(),
            PreviewPage.help => _buildHelp(),
          },
        ),
      ),
    );
  }

  Widget _buildSplash() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: SafeArea(
        child: Column(
          children: [
            const StatusBarMock(dark: true),
            Expanded(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  tween: Tween(begin: .9, end: 1),
                  curve: Curves.easeOutBack,
                  builder: (_, value, child) => Transform.scale(scale: value, child: child ?? const SizedBox.shrink()),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      MascotBear(size: 190, withCoin: true),
                      SizedBox(height: 18),
                      Text(
                        'CoinVault',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Complete Tasks, Earn Coins,\nWithdraw Real Cash',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 26),
              child: Column(
                children: [
                  Text('Loading...', style: TextStyle(color: Colors.white.withOpacity(.95))),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: .84,
                      backgroundColor: Colors.white.withOpacity(.35),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _onboardingBase({
    required String title,
    required String subtitle,
    required Widget art,
    required int activeDot,
    required String cta,
    required VoidCallback onTap,
    VoidCallback? onSkip,
  }) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: SafeArea(
        child: Column(
          children: [
            const StatusBarMock(dark: true),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onSkip ?? () => _go(PreviewPage.welcome),
                child: const Text('Skip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            Expanded(child: Center(child: art)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = index == activeDot;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isActive ? 1 : .55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(cta, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingTasks() => _onboardingBase(
        title: 'Complete Tasks',
        subtitle: 'Install apps, register, watch videos\nand explore exciting offers.',
        activeDot: 0,
        cta: 'Next',
        onTap: () => _go(PreviewPage.onboardingCoins),
        art: Stack(
          alignment: Alignment.center,
          children: [
            const MascotBear(size: 200),
            Positioned(left: 24, top: 48, child: _floatingBubble(Icons.download_rounded)),
            Positioned(right: 26, top: 24, child: _floatingBubble(Icons.verified_user_rounded)),
            Positioned(left: 42, bottom: 30, child: _floatingBubble(Icons.local_offer_rounded)),
            Positioned(right: 38, bottom: 26, child: _floatingBubble(Icons.play_circle_fill_rounded)),
          ],
        ),
      );

  Widget _buildOnboardingCoins() => _onboardingBase(
        title: 'Earn Coins',
        subtitle: 'Earn coins for every task you complete.\n100 Coins = ₹10',
        activeDot: 1,
        cta: 'Next',
        onTap: () => _go(PreviewPage.onboardingWithdraw),
        art: Stack(
          alignment: Alignment.center,
          children: [
            const MascotBear(size: 200),
            ...List.generate(8, (i) {
              final dx = [-90.0, -35.0, 40.0, 95.0, -70.0, 0.0, 70.0, 30.0];
              final dy = [-70.0, -115.0, -95.0, -50.0, 55.0, -140.0, 25.0, 95.0];
              return Transform.translate(
                offset: Offset(dx, dy),
                child: const Text('🪙', style: TextStyle(fontSize: 28)),
              );
            }),
          ],
        ),
      );

  Widget _buildOnboardingWithdraw() => _onboardingBase(
        title: 'Withdraw Cash',
        subtitle: 'Withdraw your earnings easily via UPI,\nBank, Gift Cards & more.',
        activeDot: 2,
        cta: 'Get Started',
        onTap: () => _go(PreviewPage.welcome),
        art: const MascotBear(size: 210, withCoin: true, coinBelow: true),
      );

  Widget _buildWelcome() {
    return ScreenScaffold(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBarMock(),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Welcome Back 👋', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Login to continue', style: TextStyle(fontSize: 14, color: AppColors.muted)),
          ),
          const Spacer(),
          AppSecondaryButton(
            label: 'Continue with Google',
            leading: _circleText('G'),
            onTap: () => _goMain(0),
          ),
          AppSecondaryButton(
            label: 'Continue with Phone',
            leading: const Icon(Icons.phone_rounded, color: AppColors.orange),
            onTap: () => _go(PreviewPage.verifyPhone),
          ),
          AppSecondaryButton(
            label: 'Continue as Guest',
            leading: const Icon(Icons.person_outline_rounded, color: AppColors.orange),
            onTap: () => _goMain(0),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(bottom: 34),
            child: Center(
              child: Text(
                'By continuing, you agree to our\nTerms & Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyPhone() {
    return ScreenScaffold(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBarMock(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.welcome)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Verify Phone', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Enter 6 digit code sent to\n+91 98765 43210',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _otp
                .map(
                  (controller) => Container(
                    width: 46,
                    height: 54,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.text,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text('Resend code in 00:30', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          _buildNumberPad(),
          const SizedBox(height: 22),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return ScreenScaffold(
      bottomNav: NavBar(index: _mainIndex, onTap: _goMain),
      child: Column(
        children: [
          const StatusBarMock(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi, Arbaz 👋', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      SizedBox(height: 2),
                      Text('Good to see you back!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _go(PreviewPage.notifications),
                  child: Stack(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_none_rounded),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOut,
              builder: (_, value, child) => Transform.translate(offset: Offset(0, (1 - value) * 18), child: Opacity(opacity: value, child: child ?? const SizedBox.shrink())),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.orangeLight, AppColors.orange]),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: AppColors.orange.withOpacity(.24), blurRadius: 22, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Coin Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 4),
                          FittedBox(
                            child: Text('12,450 🪙', style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.w900)),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _PillText('100 Coins = ₹10'),
                              _PillText('₹124.50'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const MascotBear(size: 120),
                  ],
                ),
              ),
            ),
          ),
          SurfaceCard(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('7 Day Streak', style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('Keep it going!', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
                ...List.generate(7, (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: AppColors.green,
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: List.generate(MockData.quickActions.length, (index) {
                final item = MockData.quickActions[index];
                final target = [PreviewPage.spin, PreviewPage.scratch, PreviewPage.checkin][index];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
                    child: GestureDetector(
                      onTap: () => _go(target),
                      child: SurfaceCard(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            GradientIconBox(
                              colors: item.colors,
                              child: Icon(item.icon, color: Colors.white, size: 22),
                            ),
                            const SizedBox(height: 8),
                            Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Row(
              children: [
                const Expanded(child: Text('Continue Tasks', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w700))),
                TextButton(onPressed: _showAllScreens, child: const Text('All Screens')),
              ],
            ),
          ),
          ...MockData.offers.take(2).map(
                (offer) => _offerRow(offer, onTap: () => _go(PreviewPage.taskDetail), buttonLabel: 'Start'),
              ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _go(PreviewPage.challenges),
                    child: _miniHomeCard('Daily Bonus', 'Claimed', Icons.local_fire_department_rounded),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _go(PreviewPage.refer),
                    child: _miniHomeCard('Refer & Earn', 'Invite Now', Icons.card_giftcard_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarn() {
    return ScreenScaffold(
      bottomNav: NavBar(index: 1, onTap: _goMain),
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Earn Coins',
            subtitle: 'Complete tasks and earn big',
            trailing: RoundIconButton(icon: Icons.grid_view_rounded, onTap: _showAllScreens),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: MockData.categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .95,
              ),
              itemBuilder: (_, index) {
                final item = MockData.categories[index];
                return GestureDetector(
                  onTap: () => _go(index == 2 ? PreviewPage.surveys : PreviewPage.tasks),
                  child: SurfaceCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: RewardChip(label: item.reward),
                        ),
                        GradientIconBox(
                          colors: item.colors,
                          child: Icon(item.icon, color: Colors.white, size: 26),
                          size: 54,
                        ),
                        const Spacer(),
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasks() {
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'App Install',
            subtitle: 'Install apps and earn coins',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.earn)),
          ),
          MiniTabBar(
            tabs: const ['All', 'New', 'High Paying'],
            index: _taskFilter,
            onChanged: (i) => setState(() => _taskFilter = i),
          ),
          ...MockData.offers.map((offer) => _offerRow(offer, onTap: () => _go(PreviewPage.taskDetail))),
          TextLink(text: 'How it works?', onTap: () => _go(PreviewPage.taskDetail)),
        ],
      ),
    );
  }

  Widget _buildTaskDetail() {
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Rush',
            subtitle: 'Install & Open',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.tasks)),
          ),
          SurfaceCard(
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6658FF), AppColors.purple]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  alignment: Alignment.center,
                  child: const Text('R', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.purple)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Expanded(child: LabelValue(label: 'Reward', value: '220 Coins')),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD95E), AppColors.gold]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🪙  Earn ₹22.00', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          ),
          const MetricRow(leftTitle: 'Time', leftValue: '5 mins', rightTitle: 'Difficulty', rightValue: 'Easy', rightColor: AppColors.green),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Steps to Complete', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(34, 4, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepLine('1. Click on Install'),
                _StepLine('2. Install the app'),
                _StepLine('3. Open the app'),
                _StepLine('4. Explore for 1 minute'),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Note: Make sure you open the app after installing.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ),
          TextLink(text: 'How it works?', onTap: () {}),
          AppPrimaryButton(label: 'Install Now', onTap: () => _go(PreviewPage.home)),
        ],
      ),
    );
  }

  Widget _buildSurveys() {
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Surveys',
            subtitle: 'Answer surveys and earn',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.earn)),
          ),
          MiniTabBar(
            tabs: const ['All', 'High Paying', 'New'],
            index: _surveyFilter,
            onChanged: (i) => setState(() => _surveyFilter = i),
          ),
          ...MockData.surveys.map(
            (survey) => SurfaceCard(
              child: Row(
                children: [
                  Expanded(child: Text(survey.duration, style: const TextStyle(fontWeight: FontWeight.w800))),
                  RewardChip(label: '${survey.reward} 🪙', bg: AppColors.orangeSoft, fg: AppColors.orangeDeep),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 78,
                    child: AppPrimaryButton(label: 'Start', compact: true, onTap: () {}, margin: EdgeInsets.zero),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpin() {
    return ScreenScaffold(
      dark: true,
      background: const [AppColors.dark, AppColors.darkSoft],
      bottomNav: NavBar(index: 2, onTap: _goMain, dark: true),
      child: Column(
        children: [
          const StatusBarMock(dark: true),
          AppTitleBlock(
            title: 'Spin & Win',
            subtitle: 'Spin the wheel and win coins',
            dark: true,
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.home), dark: true),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 330,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned(top: 4, child: Icon(Icons.arrow_drop_down_rounded, size: 48, color: AppColors.gold)),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _wheelTurns),
                  duration: const Duration(milliseconds: 4200),
                  curve: Curves.easeOutCubic,
                  builder: (_, turns, child) => Transform.rotate(
                    angle: turns * 2 * math.pi,
                    child: child ?? const SizedBox.shrink(),
                  ),
                  child: _SpinWheelGraphic(),
                ),
              ],
            ),
          ),
          Text(_spinResult, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          AppPrimaryButton(label: 'Spin Now', onTap: _spinWheel),
          TextLink(text: 'Watch Ad for Extra Spin', onTap: () {}, dark: true),
        ],
      ),
    );
  }

  Widget _buildScratch() {
    return ScreenScaffold(
      dark: true,
      background: const [AppColors.dark, AppColors.darkSoft],
      bottomNav: NavBar(index: 2, onTap: _goMain, dark: true),
      child: Column(
        children: [
          const StatusBarMock(dark: true),
          AppTitleBlock(
            title: 'Scratch & Win',
            subtitle: 'Scratch card and win coins',
            dark: true,
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.home), dark: true),
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .96, end: 1),
            duration: const Duration(milliseconds: 1600),
            curve: Curves.easeInOut,
            builder: (_, scale, child) => Transform.scale(scale: scale, child: child ?? const SizedBox.shrink()),
            child: SurfaceCard(
              color: Colors.transparent,
              child: Container(
                height: 210,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.orangeLight, AppColors.orange]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        'Scratch\n& Win',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 28,
                      child: Container(
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.85),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Scratch Here', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('You have 3 cards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          AppPrimaryButton(label: 'Get More Cards', onTap: () {}),
          TextLink(text: 'Watch Ad', onTap: () {}, dark: true),
        ],
      ),
    );
  }

  Widget _buildCheckin() {
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Daily Check-in',
            subtitle: 'Check-in daily and earn coins',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.home)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(alignment: Alignment.centerLeft, child: Text('7 Day Streak', style: TextStyle(fontWeight: FontWeight.w800))),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _DayChip('Day 1', '50', done: true),
              _DayChip('Day 2', '75', done: true),
              _DayChip('Day 3', '100', active: true),
              _DayChip('Day 4', '150'),
              _DayChip('Day 5', '250'),
              _DayChip('Day 6', '400'),
              _DayChip('Day 7', '750'),
            ],
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(label: 'Check-in Today', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildChallenges() {
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Challenges',
            subtitle: 'Complete challenges, earn more',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.home)),
          ),
          MiniTabBar(
            tabs: const ['Daily', 'Weekly', 'Monthly'],
            index: _challengeFilter,
            onChanged: (i) => setState(() => _challengeFilter = i),
          ),
          ...MockData.challenges.map(
            (challenge) => SurfaceCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(challenge.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(challenge.progress, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: challenge.percent,
                            minHeight: 8,
                            backgroundColor: AppColors.line,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  RewardChip(label: challenge.reward, bg: AppColors.orangeSoft, fg: AppColors.orangeDeep),
                ],
              ),
            ),
          ),
          TextLink(text: 'View All Challenges', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildRefer() {
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Refer & Earn',
            subtitle: 'Invite friends and earn more',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.home)),
          ),
          const SizedBox(height: 8),
          const Icon(Icons.card_giftcard_rounded, size: 88, color: AppColors.orange),
          const SizedBox(height: 10),
          const Text('Your Referral Code', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          SurfaceCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text('ARBA210', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.orangeDeep)),
                ),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
                  child: const Text('Copy'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Share your link and earn 200 Coins when each friend joins and completes a task.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.4),
            ),
          ),
          AppPrimaryButton(label: 'Invite Now', onTap: () {}),
          SurfaceCard(
            child: Row(
              children: const [
                Expanded(child: LabelValue(label: 'Friends Joined', value: '12')),
                Expanded(child: LabelValue(label: 'Earnings', value: '6,000')),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 2),
            child: Align(alignment: Alignment.centerLeft, child: Text('Recent Referrals', style: TextStyle(fontWeight: FontWeight.w800))),
          ),
          ...[
            ('Bablo Sharma', '2 hr ago'),
            ('Priya Singh', '3 hr ago'),
            ('Aman Kumar', '5 hr ago'),
          ].map((item) => SurfaceCard(child: Row(children: [const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)), Text(item.$2, style: const TextStyle(fontSize: 12, color: AppColors.muted))])), const RewardChip(label: '+500', bg: AppColors.orangeSoft, fg: AppColors.orangeDeep)]))),
        ],
      ),
    );
  }

  Widget _buildWallet() {
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Wallet',
            subtitle: 'All your earnings',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.profile)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.orangeLight, AppColors.orange]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Coins', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        SizedBox(height: 4),
                        FittedBox(child: Text('12,450 🪙', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))),
                        SizedBox(height: 8),
                        _PillText('₹124.50'),
                      ],
                    ),
                  ),
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 58),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _metricCard('Pending Coins', '1,200')),
                const SizedBox(width: 10),
                Expanded(child: _metricCard('Lifetime Earnings', '24,850')),
                const SizedBox(width: 10),
                Expanded(child: _metricCard('Withdrawn', '₹1,240')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
            child: Row(
              children: [
                const Expanded(child: Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.w800))),
                TextButton(onPressed: () => _go(PreviewPage.history), child: const Text('View All')),
              ],
            ),
          ),
          ...MockData.walletHistory.map(_activityRow),
        ],
      ),
    );
  }

  Widget _buildWithdraw() {
    return ScreenScaffold(
      bottomNav: NavBar(index: 3, onTap: _goMain),
      child: Column(
        children: [
          const StatusBarMock(),
          const AppTitleBlock(title: 'Withdraw', subtitle: 'Withdraw your earnings'),
          ...MockData.withdrawMethods.map((method) {
            final goTo = method.title == 'Bank Transfer'
                ? PreviewPage.withdrawHistory
                : method.title == 'PhonePe' || method.title == 'UPI' || method.title == 'Google Pay'
                    ? PreviewPage.withdrawUpi
                    : PreviewPage.wallet;
            return GestureDetector(
              onTap: () => _go(goTo),
              child: SurfaceCard(
                child: Row(
                  children: [
                    GradientIconBox(
                      colors: method.colors,
                      child: Text(method.glyph, style: TextStyle(color: method.title == 'Bank Transfer' ? AppColors.ink : Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(method.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(method.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWithdrawUpi() {
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Withdraw to UPI',
            subtitle: 'Min. 1000 Coins = ₹100',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.withdraw)),
          ),
          SurfaceCard(
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Available Balance\n12,450 Coins (₹124.50)', style: TextStyle(fontWeight: FontWeight.w700, height: 1.45)),
            ),
          ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter Amount', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['1000', '2000', '5000', '10000']
                      .map((amount) => ChoiceChip(
                            label: Text(amount),
                            selected: _amountController.text == amount,
                            onSelected: (_) => setState(() => _amountController.text = amount),
                            selectedColor: AppColors.orangeSoft,
                            side: const BorderSide(color: AppColors.line),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UPI ID', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TextField(
                  controller: _upiController,
                  decoration: _inputDecoration(),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Make sure UPI ID is correct. Money will be sent to your linked account.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          AppPrimaryButton(label: 'Withdraw Now', onTap: () => _go(PreviewPage.withdrawHistory)),
          TextLink(text: 'It will take 3-30 minutes', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildWithdrawHistory() {
    final tabs = ['All', 'Pending', 'Success', 'Failed'];
    final rows = [
      ('UPI', '23 Apr 2025, 10:00 AM', '₹100', 'Success', AppColors.green),
      ('Amazon Gift Card', '20 Apr 2025, 04:20 PM', '₹50', 'Pending', AppColors.orangeDeep),
      ('PhonePe', '18 Apr 2025, 00:15 AM', '₹150', 'Pending', AppColors.orangeDeep),
      ('Bank Transfer', '15 Apr 2025, 11:45 AM', '₹300', 'Failed', AppColors.red),
    ];
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Withdrawal History',
            subtitle: 'Track all your cashouts',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.withdraw)),
          ),
          MiniTabBar(
            tabs: tabs,
            index: _withdrawHistoryFilter,
            onChanged: (i) => setState(() => _withdrawHistoryFilter = i),
          ),
          ...rows.map(
            (row) => SurfaceCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.bg,
                    child: Text(row.$1 == 'Amazon Gift Card' ? 'a' : row.$1.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(row.$2, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(row.$3, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(row.$4, style: TextStyle(fontSize: 12, color: row.$5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Notifications',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.home)),
            trailing: TextButton(onPressed: () {}, child: const Text('Mark all as read')),
          ),
          ...MockData.notifications.map(_notificationRow),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final tabs = ['Weekly', 'Monthly', 'All Time'];
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Leaderboard',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.profile)),
          ),
          MiniTabBar(
            tabs: tabs,
            index: _leaderboardFilter,
            onChanged: (i) => setState(() => _leaderboardFilter = i),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _PodiumTile(rank: '2', name: 'Saket', score: '9,12,450', color: Color(0xFFB0B8C6), offset: 18),
                SizedBox(width: 12),
                _PodiumTile(rank: '1', name: 'Arbaz', score: '10,22,450', color: AppColors.gold, offset: 0),
                SizedBox(width: 12),
                _PodiumTile(rank: '3', name: 'Priya', score: '8,45,440', color: Color(0xFFC97B4A), offset: 26),
              ],
            ),
          ),
          ...[
            ('4', 'Arbaz', '18,450'),
            ('5', 'Neha', '16,220'),
            ('6', 'Raj', '15,200'),
            ('7', 'Pooja', '14,050'),
          ].map((item) => SurfaceCard(child: Row(children: [Container(width: 28, height: 28, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle), child: Text(item.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))), const SizedBox(width: 10), const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)), const SizedBox(width: 10), Expanded(child: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700))), Text(item.$3, style: const TextStyle(color: AppColors.orangeDeep, fontWeight: FontWeight.w800))]))),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    final tabs = ['All', 'Earned', 'Spent'];
    final rows = [
      ('Earned', 'App Install (Rush)', '+220', '24 Apr', Icons.download_rounded, [AppColors.orangeLight, AppColors.orange]),
      ('Survey Completed', 'Survey', '+120', '23 Apr', Icons.poll_rounded, [AppColors.purple, Color(0xFFA855F7)]),
      ('Spin', 'Spin Wheel', '+50', '23 Apr', Icons.casino_rounded, [AppColors.purple, Color(0xFFB84BFF)]),
      ('Daily Check-in', '7-day Streak bonus', '+100', '23 Apr', Icons.calendar_today_rounded, [AppColors.gold, AppColors.orange]),
      ('Watch Video', 'Video bonus', '+50', '23 Apr', Icons.play_circle_fill_rounded, [Color(0xFF11C1FF), AppColors.blue]),
    ];

    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'History',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.wallet)),
          ),
          MiniTabBar(
            tabs: tabs,
            index: _historyFilter,
            onChanged: (i) => setState(() => _historyFilter = i),
          ),
          ...rows.map(
            (row) => SurfaceCard(
              child: Row(
                children: [
                  GradientIconBox(colors: row.$6, child: Icon(row.$5, color: Colors.white)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(row.$2, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(row.$3, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(row.$4, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return ScreenScaffold(
      bottomNav: NavBar(index: 4, onTap: _goMain),
      child: Column(
        children: [
          const StatusBarMock(),
          const SizedBox(height: 8),
          const MascotBear(size: 150, withCoin: true),
          const SizedBox(height: 6),
          const Text('Arbaz Khan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('arbazbasha@gmail.com', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              children: [
                const Row(
                  children: [
                    Text('Level 12', style: TextStyle(fontWeight: FontWeight.w800)),
                    Spacer(),
                    Text('7,450 / 10,000', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    minHeight: 8,
                    value: .62,
                    backgroundColor: AppColors.line,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
                  ),
                ),
              ],
            ),
          ),
          SurfaceCard(
            child: Column(
              children: [
                _menuTile('Personal Info', Icons.person_outline_rounded),
                _menuTile('KYC Verification', Icons.verified_rounded, trailing: const RewardChip(label: 'Verified')),
                _menuTile('Wallet', Icons.account_balance_wallet_rounded, onTap: () => _go(PreviewPage.wallet)),
                _menuTile('Leaderboard', Icons.emoji_events_rounded, onTap: () => _go(PreviewPage.leaderboard)),
                _menuTile('Settings', Icons.settings_outlined, onTap: () => _go(PreviewPage.settings)),
                _menuTile('Help Center', Icons.help_outline_rounded, onTap: () => _go(PreviewPage.help)),
                _menuTile('Privacy Policy', Icons.shield_outlined),
                _menuTile('Logout', Icons.logout_rounded, danger: true, showChevron: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Settings',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.profile)),
          ),
          SurfaceCard(
            child: Column(
              children: [
                _menuTile('Profile', Icons.person_outline_rounded),
                _menuTile('Security', Icons.lock_outline_rounded),
                _menuTile('Preferences', Icons.tune_rounded),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.dark_mode_outlined, size: 20, color: AppColors.ink),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w700))),
                      Switch(value: true, activeColor: Colors.white, activeTrackColor: AppColors.orange, onChanged: (_) {}),
                    ],
                  ),
                ),
                _menuTile('Language', Icons.language_rounded, subtitle: 'English'),
                _menuTile('Notification', Icons.notifications_outlined),
                _menuTile('Rate Us', Icons.star_outline_rounded),
                _menuTile('About CoinVault', Icons.info_outline_rounded, subtitle: 'v1.0.0'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelp() {
    return ScreenScaffold(
      child: Column(
        children: [
          const StatusBarMock(),
          AppTitleBlock(
            title: 'Help Center',
            leading: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(PreviewPage.profile)),
          ),
          SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Search for help'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(alignment: Alignment.centerLeft, child: Text('Popular Questions', style: TextStyle(fontWeight: FontWeight.w800))),
          ),
          SurfaceCard(
            child: Column(
              children: [
                _simpleHelp('How to earn coins?'),
                _simpleHelp('How to withdraw?'),
                _simpleHelp('Withdrawal takes time?'),
                _simpleHelp('Which surveys pay more?'),
                _simpleHelp('How referral works?'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              children: [
                const Text('Still need help?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 10),
                AppPrimaryButton(label: 'Contact Support', onTap: () {}, margin: EdgeInsets.zero),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPad() {
    final digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: digits.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.3,
        ),
        itemBuilder: (_, index) {
          final digit = digits[index];
          if (digit.isEmpty) return const SizedBox.shrink();
          return InkWell(
            onTap: digit == '⌫' ? _backspaceOtp : () => _fillOtp(digit),
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Text(digit, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }

  Widget _floatingBubble(IconData icon) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(.35)),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  Widget _offerRow(OfferItem offer, {VoidCallback? onTap, String buttonLabel = 'Start'}) {
    return GestureDetector(
      onTap: onTap,
      child: SurfaceCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: offer.color, borderRadius: BorderRadius.circular(14)),
              child: Text(offer.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(offer.title, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                      if (offer.tag.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        RewardChip(label: offer.tag, bg: AppColors.orangeSoft, fg: AppColors.orangeDeep),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(offer.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RewardChip(label: offer.reward),
                const SizedBox(height: 8),
                SizedBox(
                  width: 78,
                  child: AppPrimaryButton(label: buttonLabel, compact: true, onTap: onTap, margin: EdgeInsets.zero),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniHomeCard(String title, String action, IconData icon) {
    return SurfaceCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.orangeSoft, child: Icon(icon, color: AppColors.orange)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(action, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value) {
    return SurfaceCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Widget _activityRow(ActivityItem item) {
    return SurfaceCard(
      child: Row(
        children: [
          GradientIconBox(colors: item.colors, child: Icon(item.icon, color: Colors.white)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Text(item.amount, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _notificationRow(ActivityItem item) {
    return SurfaceCard(
      child: Row(
        children: [
          GradientIconBox(colors: item.colors, child: Icon(item.icon, color: Colors.white)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Text(item.trailing, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _menuTile(
    String title,
    IconData icon, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool danger = false,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: danger ? AppColors.red : AppColors.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w700, color: danger ? AppColors.red : AppColors.ink),
              ),
            ),
            if (subtitle != null)
              Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            if (trailing != null) trailing,
            if (showChevron) const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _simpleHelp(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.6),
      ),
    );
  }
}

class _PillText extends StatelessWidget {
  final String text;

  const _PillText(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

class _StepLine extends StatelessWidget {
  final String text;

  const _StepLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(height: 1.35)),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final String reward;
  final bool done;
  final bool active;

  const _DayChip(this.label, this.reward, {this.done = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? const LinearGradient(colors: [AppColors.gold, AppColors.orange])
        : null;
    final color = active
        ? Colors.white
        : done
            ? AppColors.green
            : AppColors.ink;
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: bg,
        color: active ? null : (done ? AppColors.greenSoft : const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.white70 : AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(reward, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _PodiumTile extends StatelessWidget {
  final String rank;
  final String name;
  final String score;
  final Color color;
  final double offset;

  const _PodiumTile({
    required this.rank,
    required this.name,
    required this.score,
    required this.color,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offset),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(rank, style: TextStyle(color: color == AppColors.gold ? AppColors.ink : Colors.white, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 8),
          const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 26)),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(score, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SpinWheelGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 284,
      height: 284,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 8),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(.35),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFF7C3AED),
                  AppColors.gold,
                  AppColors.green,
                  AppColors.blue,
                  Color(0xFFFF2B7A),
                  AppColors.orange,
                  Color(0xFF6658FF),
                  Color(0xFF11C1FF),
                  Color(0xFF7C3AED),
                ],
              ),
            ),
          ),
          ...List.generate(8, (i) {
            const labels = ['10', '25', '50', '75', '100', '250', '500', '1000'];
            final angle = ((i * 45) - 90 + 22.5) * math.pi / 180;
            return Positioned(
              left: 142 + math.cos(angle) * 92 - 18,
              top: 142 + math.sin(angle) * 92 - 10,
              child: Transform.rotate(
                angle: (i * 45) * math.pi / 180,
                child: Text(
                  labels[i],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            );
          }),
          Container(
            width: 102,
            height: 102,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Colors.white, AppColors.gold]),
            ),
            alignment: Alignment.center,
            child: const Text('SPIN', style: TextStyle(color: AppColors.orangeDeep, fontSize: 22, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

Widget _circleText(String text) {
  return Container(
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
  );
}
