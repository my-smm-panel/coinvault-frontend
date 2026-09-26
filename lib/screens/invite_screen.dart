import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../widgets/state_views.dart';

/// Referral code/link, server-provided referral statistics, and share actions.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  static const _bg = Color(0xFFF7F8FA);

  bool _loading = true;
  bool _failed = false;
  String _code = '';
  String _link = '';
  int? _active;
  int? _total;
  int? _earned;
  List<Map<String, dynamic>> _referrals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final info = await AppRepository.instance.referralInfo();
    if (!mounted) return;
    if (info == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    setState(() {
      _code = info['referralCode']?.toString() ?? '';
      _link = info['referralLink']?.toString() ?? '';
      _active = (info['activeReferrals'] as num?)?.toInt();
      _total = (info['totalReferrals'] as num?)?.toInt();
      _earned = (info['totalCoinsEarned'] as num?)?.toInt();
      _referrals = (info['referrals'] is List ? info['referrals'] as List : [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _loading = false;
    });
  }

  String get _shareText {
    if (_link.isNotEmpty) return 'Join me on CoinVault: $_link';
    if (_code.isNotEmpty) return 'Join me on CoinVault. My referral code is $_code';
    return 'Join me on CoinVault.';
  }

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
          : _failed
              ? ErrorState(
                  message: 'Referral details could not be fetched. Try again.',
                  onRetry: _load,
                )
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
                  _referrals(),
                  const SizedBox(height: 20),
                  _howItWorks(),
                  const SizedBox(height: 24),
                  _inviteButton(),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Referral details are provided by the server.',
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
            'Invite friends',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share your referral code or link',
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
                        _code.isEmpty ? 'Unavailable' : _code,
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
                if (_code.isNotEmpty)
                  _CopyButton(onTap: () => _copy(_code, 'Referral code')),
              ],
            ),
          ),
          if (_link.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Text(
                  _link,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              _CopyButton(onTap: () => _copy(_link, 'Referral link')),
            ]),
          ],
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
          label: 'Active',
          value: _active?.toString() ?? '—',
          icon: Icons.group_rounded,
          color: AppColors.success,
        ),
        _StatTile(
          label: 'Total',
          value: _total?.toString() ?? '—',
          icon: Icons.people_alt_rounded,
          color: AppColors.primary,
        ),
        _StatTile(
          label: 'Coins earned',
          value: _earned?.toString() ?? '—',
          icon: Icons.emoji_events_rounded,
          color: AppColors.gold,
        ),
      ],
    );
  }

  Widget _referrals() {
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
          const Text('Referral activity',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 10),
          if (_referrals.isEmpty)
            const Text('No referral activity to show yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
          else
            ..._referrals.map((referral) {
              final referred = referral['referred'];
              final name = referred is Map
                  ? (referred['name']?.toString().trim().isNotEmpty == true
                      ? referred['name'].toString()
                      : 'Referral')
                  : 'Referral';
              final active = referral['isActive'] == true;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text(active ? 'Active' : 'Inactive',
                      style: TextStyle(
                          color: active
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              );
            }),
        ],
      ),
    );
  }

  // ───────────────────────────── how it works ─────────────────────────────
  Widget _howItWorks() {
    const steps = [
      ('Share your referral code or link', Icons.share_rounded),
      ('Friends can use it when joining', Icons.person_add_rounded),
      ('View referral activity and stats here', Icons.insights_rounded),
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
