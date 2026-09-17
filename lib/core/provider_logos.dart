import 'package:flutter/material.dart';

/// Real company logos for survey/task providers.
/// White tile + logo image; falls back to a colored letter tile
/// when the asset is missing so nothing ever looks broken.
class ProviderLogos {
  static const Map<String, String> assets = {
    'cint': 'assets/logos/cint.png',
    'prime surveys': 'assets/logos/prime.png',
    'prime': 'assets/logos/prime.png',
    'timewall': 'assets/logos/timewall.png',
    'bitlabs': 'assets/logos/bitlabs.png',
    'cpx research': 'assets/logos/cpx.png',
    'cpx': 'assets/logos/cpx.png',
    'pollfish': 'assets/logos/pollfish.png',
    'pubscale': 'assets/logos/pubscale.png',
    'offerpro': 'assets/logos/offerpro.png',
    'offer pro': 'assets/logos/offerpro.png',
    'growdeck': 'assets/logos/growdeck.png',
    'grow deck': 'assets/logos/growdeck.png',
    'cpi droid': 'assets/logos/cpidroid.png',
    'lootably': 'assets/logos/lootably.png',
    'adscend': 'assets/logos/adscend.png',
  };

  static const Map<String, Color> colors = {
    'cint': Color(0xFF8B5CF6),
    'prime surveys': Color(0xFF3B82F6),
    'timewall': Color(0xFF10B981),
    'bitlabs': Color(0xFF8B5CF6),
    'cpx research': Color(0xFF3B82F6),
    'pollfish': Color(0xFF14B8A6),
    'pubscale': Color(0xFFF66B06),
    'offerpro': Color(0xFFEC4899),
    'growdeck': Color(0xFFF59E0B),
    'cpi droid': Color(0xFF10B981),
    'lootably': Color(0xFF3B82F6),
    'adscend': Color(0xFF14B8A6),
  };

  static String? assetFor(String name) =>
      assets[name.trim().toLowerCase()];

  /// Real app logos for game/task apps (matched from the task title).
  static const Map<String, String> appAssets = {
    'mpl': 'assets/apps/mpl.png',
    'mobile premier league': 'assets/apps/mpl.png',
    'ludo': 'assets/apps/ludo.png',
    'ludo supreme': 'assets/apps/ludo.png',
    'rummy': 'assets/apps/rummy.png',
    'rummy circle': 'assets/apps/rummy.png',
    'dream11': 'assets/apps/dream11.png',
    'dream 11': 'assets/apps/dream11.png',
  };

  /// Try to find a real app logo by scanning the task title for known apps.
  static String? assetForTitle(String title) {
    final t = title.toLowerCase();
    for (final key in appAssets.keys) {
      if (t.contains(key)) return appAssets[key];
    }
    return null;
  }

  static Color colorFor(String name) =>
      colors[name.trim().toLowerCase()] ?? const Color(0xFFF66B06);
}

/// White logo tile with fallback to colored letter.
class ProviderLogo extends StatelessWidget {
  final String provider;
  final double size;
  final double radius;

  const ProviderLogo(this.provider,
      {super.key, this.size = 48, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final asset = ProviderLogos.assetFor(provider);
    final color = ProviderLogos.colorFor(provider);
    final letter = provider.isEmpty
        ? 'C'
        : provider.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: asset == null
            ? _letter(color, letter)
            : Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    _letter(color, letter),
              ),
      ),
    );
  }

  Widget _letter(Color color, String letter) {
    return Container(
      color: color.withOpacity(0.12),
      child: Center(
        child: Text(letter,
            style: TextStyle(
                color: color,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}
