import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../widgets/state_views.dart';

/// Invite & Earn (light theme, per design sheet):
/// referral code + Copy, share row (FB/WA/TG/share), stats grid,
/// invite milestones, orange "Invite Friends" CTA.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  static const _bg = Color(0xFFF7F8FA);

  bool _loading = true;
  String _code = 'CV123456';
  int _successful = 0;
  int _pending = 0;
  int _earned = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await AppRepository.instance.referralInfo();
    if (!mounted) return;
    setState(() {
      final code = info['referralCode']?.toString() ?? '';
      if (code.isNotEmpty) _code = code;
      _successful = (info['activeReferrals'] as num?)?.toInt() ??
          (info['totalReferrals'] as num?)?.toInt() ??
          0;
      _pending = (info['pendingReferrals'] as num?)?.toInt() ?? 0;
      _earned = (info['totalCoinsEarned'] as num?)?.toInt() ?? 0;
      _loading = false;
    });
  }

  String get _shareText =>
      'Join me on CoinVault and earn coins daily! Use my referral code $_code 🎁';

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _share(String channel) {
    // No share plugin in this project — copy the invite text instead.
    _copy(_shareText, 'Invite message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite message copied — paste it in $channel'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Invite & Earn',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: _loading
          ? const ShimmerCardList(rows: 4)
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.cardBackground,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  _codeCard(),
                  const SizedBox(height: 20),
                  _statsGrid(),
                  const SizedBox(height: 20),
                  _milestones(),
                  const SizedBox(height: 20),
                  _howItWorks(),
                  const SizedBox(height: 24),
                  _inviteButton(),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Earn coins for every friend who joins & earns',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ───────────────────────────── code card ─────────────────────────────
  Widget _codeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandHeader,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          const Text(
            'Invite friends, earn coins',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Give 100 coins, get 100 coins — every time',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          // referral code + copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR REFERRAL CODE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CopyButton(onTap: () => _copy(_code, 'Referral code')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── stats grid ─────────────────────────────
  Widget _statsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: [
        _StatTile(
          label: 'Successful',
          value: '$_successful',
          icon: Icons.group_rounded,
          color: AppColors.success,
        ),
        _StatTile(
          label: 'Pending',
          value: '$_pending',
          icon: Icons.hourglass_top_rounded,
          color: AppColors.warning,
        ),
        _StatTile(
          label: 'Total Earned',
          value: '$_earned',
          icon: Icons.emoji_events_rounded,
          color: AppColors.gold,
        ),
      ],
    );
  }

  // ───────────────────────────── milestones ─────────────────────────────
  Widget _milestones() {
    final steps = <Map<String, dynamic>>[
      {
        'count': 1,
        'bonus': 100,
        'label': 'First friend',
        'icon': Icons.person_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'count': 5,
        'bonus': 500,
        'label': '5 friends',
        'icon': Icons.people_rounded,
        'color': AppColors.primary,
      },
      {
        'count': 10,
        'bonus': 1000,
        'label': '10 friends',
        'icon': Icons.emoji_events_rounded,
        'color': AppColors.gold,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('Milestones',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  )),
              const Spacer(),
              Text('$_successful invited',
                  style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final reached = _successful >= (steps[i ~/ 2]['count'] as int);
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    color: reached ? AppColors.primary : AppColors.border,
                  ),
                );
              }
              final s = steps[i ~/ 2];
              final reached = _successful >= (s['count'] as int);
              return _MilestoneBadge(
                count: s['count'] as int,
                bonus: s['bonus'] as int,
                icon: s['icon'] as IconData,
                color: s['color'] as Color,
                reached: reached,
              );
            }),
          ),
          const SizedBox(height: 12),
          ...steps.map((s) {
            final reached = _successful >= (s['count'] as int);
            final bonus = s['bonus'] as int;
            final need = (s['count'] as int) - _successful;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(
                    reached
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 17,
                    color: reached
                        ? AppColors.success
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s['label'] as String,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration:
                            reached ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Text(
                    reached
                        ? 'Claimed'
                        : (need > 0 ? '$need to go' : 'Ready'),
                    style: TextStyle(
                      color: reached
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+$bonus',
                    style: TextStyle(
                      color: reached ? AppColors.textTertiary : AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ───────────────────────────── how it works ─────────────────────────────
  Widget _howItWorks() {
    const steps = [
      ('Share your code', Icons.share_rounded),
      ('Friend joins & verifies', Icons.person_add_rounded),
      ('Both get 100 coins', Icons.emoji_events_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How it works',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 12),
          ...steps.map((s) {
            final i = steps.indexOf(s) + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$i',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(s.$2, size: 17, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.$1,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          // share row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareButton(
                  icon: Icons.facebook_rounded,
                  label: 'FB',
                  color: const Color(0xFF1877F2),
                  onTap: () => _share('Facebook'),
                ),
                _ShareButton(
                  icon: Icons.chat_rounded,
                  label: 'WA',
                  color: const Color(0xFF25D366),
                  onTap: () => _share('WhatsApp'),
                ),
                _ShareButton(
                  icon: Icons.send_rounded,
                  label: 'TG',
                  color: const Color(0xFF229ED9),
                  onTap: () => _share('Telegram'),
                ),
                _ShareButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: AppColors.primary,
                  onTap: () => _share('any app'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── CTA ─────────────────────────────
  Widget _inviteButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _share('any app'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.group_add_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Invite Friends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ SHARED WIDGETS ═══════════════════════════
class _CopyButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CopyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryDark),
              SizedBox(width: 6),
              Text(
                'Copy',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MilestoneBadge extends StatelessWidget {
  final int count, bonus;
  final IconData icon;
  final Color color;
  final bool reached;
  const _MilestoneBadge({
    required this.count,
    required this.bonus,
    required this.icon,
    required this.color,
    required this.reached,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: reached ? color : AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(
              color: reached ? color : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Icon(
            reached ? Icons.check_rounded : icon,
            color: reached ? Colors.white : AppColors.textTertiary,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '+$bonus',
          style: TextStyle(
            color: reached ? AppColors.textTertiary : color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
