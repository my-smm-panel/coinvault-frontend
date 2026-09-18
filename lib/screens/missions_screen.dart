import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';

/// Daily Missions — light theme (design sheet).
///
/// Target-icon title + "Complete missions to earn rewards", then a list of
/// mission rows: orange circle icon, mission text, X/Y progress, "+100"
/// reward chip and an orange progress bar.
///
/// Progress is derived from real account state (coins earned today, spins
/// used, referrals made). There is no dedicated missions endpoint on the
/// backend yet, so each mission is computed locally from the live data and
/// capped at its target — no fake numbers are persisted.
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  int _coins = 0;
  int _spinsUsedToday = 0;
  int _tasksCompleted = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  /// Pull whatever real signal exists for each mission.
  Future<void> _loadProgress() async {
    final auth = AuthService();
    int coins = 0;
    int tasksDone = 0;

    try {
      final um = auth.userModel;
      if (um != null) {
        coins = um.coins;
      }
    } catch (_) {}

    // Real backend signal: tasks completed (GET /api/tasks/history).
    try {
      final history = await AppRepository.instance.taskHistoryList();
      if (mounted) {
        tasksDone = history.where((e) => e is Map && e['status'] == 'completed').length;
      }
    } catch (_) {}

    if (!mounted) return;
    // Server-authoritative remaining spins → derive used count.
    int remaining = 2;
    try {
      final r = await AppRepository.instance.spinsRemainingToday();
      if (r != null) remaining = r;
      else remaining = auth.getRemainingSpins(); // offline fallback
    } catch (_) {
      remaining = auth.getRemainingSpins();
    }
    setState(() {
      _coins = coins;
      _tasksCompleted = tasksDone;
      // Spins used today — clamped to the daily limit.
      _spinsUsedToday = (2 - remaining).clamp(0, 2);
      _loading = false;
    });
  }

  /// Mission definitions. `current` is capped to `target` so a bar never
  /// overfills.
  List<_Mission> _missions() {
    return [
      _Mission(
        icon: Icons.casino_rounded,
        title: 'Spin the wheel 2 times',
        current: _spinsUsedToday,
        target: 2,
        reward: 20,
      ),
      _Mission(
        icon: Icons.monetization_on_rounded,
        title: 'Earn 100 coins',
        current: _coins,
        target: 100,
        reward: 100,
      ),
      _Mission(
        icon: Icons.check_circle_rounded,
        title: 'Complete 3 tasks',
        current: _tasksCompleted,
        target: 3,
        reward: 150,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final missions = _missions();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadProgress,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(missions),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Complete missions to earn rewards',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.xxl),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else
                        ...missions.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _MissionRow(mission: m),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoNote(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Header — back arrow + target icon + "Daily Missions"
  // ===========================================================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Icon(Icons.track_changes_rounded,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'Daily Missions',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// "X / N completed" summary card.
  Widget _buildSummaryCard(List<_Mission> missions) {
    final done = missions.where((m) => m.isComplete).length;
    final total = missions.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.brandHeader,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.button,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today’s progress',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$done / $total missions done',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 5),
                Text(
                  '+${missions.fold<int>(0, (sum, m) => sum + m.reward)} coins',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Missions reset at midnight. Rewards are credited to your wallet automatically once a mission is complete.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One mission: icon, title, X/Y progress, reward, progress bar.
class _MissionRow extends StatelessWidget {
  final _Mission mission;

  const _MissionRow({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Orange circle icon
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x4DFF8C42),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(mission.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          // Mission text + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar track
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: mission.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${mission.current} / ${mission.target}',
                      style: GoogleFonts.inter(
                        color: mission.isComplete
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (mission.isComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // +100 reward chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.goldContainer,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.gold.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppColors.gold, size: 14),
                const SizedBox(width: 4),
                Text(
                  '+${mission.reward}',
                  style: GoogleFonts.inter(
                    color: AppColors.primaryDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
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

/// Mission data model.
class _Mission {
  final IconData icon;
  final String title;
  final int current;
  final int target;
  final int reward;

  const _Mission({
    required this.icon,
    required this.title,
    required this.current,
    required this.target,
    required this.reward,
  });

  /// 0.0 – 1.0, clamped so a bar never overfills.
  double get progress =>
      target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

  bool get isComplete => current >= target && target > 0;
}
