import 'package:flutter/material.dart';

import '../core/provider_logos.dart';

/// ONE consistent logo resolver for every task / survey / offer card
/// anywhere in the app (home, earn, surveys, tracking, detail pages).
///
/// Resolution order:
///   1. known survey provider  (CPX Research, BitLabs, Cint, ...)
///   2. real app logo from the task title  (MPL, Ludo, Rummy Circle, Dream11)
///   3. clean neutral activity icon (never a dummy/fake brand logo)
///
/// Container is always 40–48px, rounded, `BoxFit.contain` — no stretching.
class AppLogo extends StatelessWidget {
  final String? provider;
  final String? title;
  final double size;
  final double radius;
  final IconData fallbackIcon;
  final Color fallbackColor;

  const AppLogo({
    super.key,
    this.provider,
    this.title,
    this.size = 44,
    this.radius = 12,
    this.fallbackIcon = Icons.task_alt_rounded,
    this.fallbackColor = const Color(0xFFF59E0B),
  });

  /// Resolves to a real image asset path when one exists, else null.
  String? get _asset {
    if (provider != null && provider!.trim().isNotEmpty) {
      final a = ProviderLogos.assetFor(provider!);
      if (a != null) return a;
    }
    if (title != null && title!.trim().isNotEmpty) {
      final a = ProviderLogos.assetForTitle(title!);
      if (a != null) return a;
    }
    return null;
  }

  Color get _fallbackBg => fallbackColor.withOpacity(0.12);

  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    if (asset != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
              color: const Color(0xFFE7E7E7), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _iconFallback(),
        ),
      );
    }
    return _iconFallback();
  }

  Widget _iconFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _fallbackBg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        fallbackIcon,
        size: size * 0.45,
        color: fallbackColor,
      ),
    );
  }
}
