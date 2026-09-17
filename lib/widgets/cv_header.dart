import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';

/// GLOBAL CoinVault app header — identical on every screen.
///
///   [CoinVault wordmark]                 [bell] [profile]
///
/// Reuse via `const CvHeader()`; never recreate per screen.
/// Bell/avatar sizes, spacing and colors are fixed here.
///
/// Use `showProfile: false` ONLY where a different, bigger profile entry is
/// intentional (e.g. Home shows its own large wallet/profile panel).
class CvHeader extends StatelessWidget {
  final bool showBellDot;
  final bool showProfile;

  const CvHeader({
    super.key,
    this.showBellDot = false,
    this.showProfile = true,
  });

  // Fixed palette (identical everywhere)
  static const Color _bg = Color(0xFFFAFAF8);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE7E7E7);
  static const Color _primaryText = Color(0xFF171717);
  static const Color _brown = Color(0xFF5A3825);
  static const Color _orange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60, // fixed header height, every screen
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── CoinVault wordmark only (no coin/dollar icon) ──
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.0,
                    ),
                    children: [
                      TextSpan(
                          text: 'Coin',
                          style: TextStyle(color: _brown)),
                      TextSpan(
                          text: 'Vault',
                          style: TextStyle(color: _orange)),
                    ],
                  ),
                ),
                const Spacer(),
                // ── Notification bell (fixed) ──
                _IconBtn(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => _goNotifications(context),
                  dot: showBellDot,
                ),
                if (showProfile) ...[
                  const SizedBox(width: 8),
                  // ── Profile avatar (fixed, same asset everywhere) ──
                  GestureDetector(
                    onTap: () => _goProfile(context),
                    child: Container(
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
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _NotificationsRoute()),
    );
  }

  void _goProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _ProfileRoute()),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool dot;
  const _IconBtn({required this.icon, required this.onTap, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE7E7E7);
  static const Color primaryText = Color(0xFF171717);
  static const Color orange = Color(0xFFF59E0B);
}

// Routes resolve to the real screens (imported here to keep screens clean
// of header wiring and avoid circular imports).
class _NotificationsRoute extends StatelessWidget {
  const _NotificationsRoute();
  @override
  Widget build(BuildContext context) => const NotificationsScreen();
}

class _ProfileRoute extends StatelessWidget {
  const _ProfileRoute();
  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
