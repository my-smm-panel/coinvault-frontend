import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';

/// GLOBAL CoinVault app header.
///
/// Default (all screens):  [CoinVault wordmark]            [bell]
/// Home:                   [profile] [bell] [money pill]   [wordmark]
///
/// The profile avatar lives ONLY on Home. Bell/wordmark sizes, spacing and
/// colors are fixed here — never restyle per screen.
class CvHeader extends StatelessWidget {
  final bool showBellDot;

  /// Show a back affordance on screens pushed above the main tabs.
  final bool showBack;

  /// Show the bear profile avatar (Home only).
  final bool showProfile;

  /// Put the profile avatar on the left (Home layout).
  final bool profileLeft;

  /// Show the small coin-balance pill (Home only).
  final bool showMoney;

  /// Live coin balance for the money pill.
  final int? coins;

  /// Show the "CoinVault" wordmark.
  final bool showWordmark;

  const CvHeader({
    super.key,
    this.showBellDot = false,
    this.showBack = false,
    this.showProfile = false,
    this.profileLeft = false,
    this.showMoney = false,
    this.coins,
    this.showWordmark = true,
  });

  static const Color _bg = AppColors.background;
  static const Color _surface = AppColors.surface;
  static const Color _border = AppColors.border;
  static const Color _primaryText = AppColors.textPrimary;
  static const Color _brown = AppColors.primaryDark;
  static const Color _orange = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final avatar = _avatar(context);
    final bell = _IconBtn(
      icon: Icons.notifications_none_rounded,
      label: 'Notifications',
      onTap: () => _goNotifications(context),
      dot: showBellDot,
    );
    final money = coins == null ? null : _moneyPill(coins!);
    final wordmark = RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          height: 1.0,
        ),
        children: [
          TextSpan(text: 'Coin', style: TextStyle(color: _brown)),
          TextSpan(text: 'Vault', style: TextStyle(color: _orange)),
        ],
      ),
    );

    return Material(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (profileLeft) ...[
                  if (showProfile) avatar,
                  if (showProfile) const SizedBox(width: 8),
                  bell,
                  if (showMoney && money != null) ...[
                    const SizedBox(width: 8),
                    money,
                  ],
                  const Spacer(),
                  if (showWordmark) wordmark,
                ] else ...[
                  if (showBack) ...[
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary),
                      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (showWordmark) wordmark,
                  const Spacer(),
                  bell,
                  if (showProfile) ...[
                    const SizedBox(width: 8),
                    avatar,
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    return IconButton(
      tooltip: 'Profile',
      onPressed: () => _goProfile(context),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _surface,
          border: Border.all(color: _border, width: 1),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/bear_avatar.png',
            fit: BoxFit.cover,
            width: 36,
            height: 36,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.person_rounded, color: AppColors.primary, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _moneyPill(int coins) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: _orange, size: 16),
          const SizedBox(width: 5),
          Text(
            _fmt(coins),
            style: const TextStyle(
              color: _primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    final s = StringBuffer();
    final str = n.abs().toString();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) s.write(',');
      s.write(str[i]);
      count++;
    }
    final rev = s.toString().split('').reversed.join();
    return n < 0 ? '-$rev' : rev;
  }

  void _goNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _goProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dot;
  const _IconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _HeaderColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: _HeaderColors.border, width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: _HeaderColors.primaryText, size: 20),
            if (dot)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _HeaderColors.orange,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                        BorderSide(color: _HeaderColors.surface, width: 1.5)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderColors {
  static const Color surface = AppColors.surface;
  static const Color border = AppColors.border;
  static const Color primaryText = AppColors.textPrimary;
  static const Color orange = AppColors.primary;
}
