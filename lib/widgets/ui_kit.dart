import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final Widget? leading;
  final bool compact;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    this.leading,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: SizedBox(
        height: compact ? 42 : 54,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withOpacity(.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(compact ? 12 : 16),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 10),
                  ],
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScreenScaffold extends StatelessWidget {
  final Widget child;
  final bool dark;
  final Widget? bottomNav;
  final EdgeInsetsGeometry padding;
  final List<Color>? background;

  const ScreenScaffold({
    super.key,
    required this.child,
    this.dark = false,
    this.bottomNav,
    this.padding = const EdgeInsets.only(bottom: 98),
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: background ?? (dark ? [AppColors.dark, AppColors.darkSoft] : [Colors.white, const Color(0xFFF8FAFC)]),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(child: child),
                ),
              ),
            ),
            if (bottomNav != null)
              Positioned(left: 0, right: 0, bottom: 0, child: bottomNav!),
          ],
        ),
      ),
    );
  }
}

class StatusBarMock extends StatelessWidget {
  final bool dark;

  const StatusBarMock({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final color = dark ? Colors.white : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('9:41', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          Text('5G  ▮▮▮', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class AppTitleBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool dark;
  final Widget? leading;
  final Widget? trailing;

  const AppTitleBlock({
    super.key,
    required this.title,
    this.subtitle,
    this.dark = false,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(color: muted, fontSize: 13, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool dark;
  final double size;

  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.dark = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark ? Colors.white.withOpacity(.12) : Colors.black.withOpacity(.04),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: dark ? Colors.white : AppColors.ink, size: 20),
        ),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class RewardChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const RewardChip({
    super.key,
    required this.label,
    this.bg = AppColors.greenSoft,
    this.fg = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

class GradientIconBox extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final double size;
  final BorderRadius borderRadius;

  const GradientIconBox({
    super.key,
    required this.colors,
    required this.child,
    this.size = 46,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: borderRadius,
      ),
      child: Center(child: child),
    );
  }
}

class NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final bool dark;

  const NavBar({
    super.key,
    required this.index,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.wallet_giftcard_rounded, 'Earn'),
      (Icons.casino_rounded, 'Spin'),
      (Icons.account_balance_wallet_rounded, 'Withdraw'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 22),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withOpacity(.42) : Colors.white.withOpacity(.97),
        border: Border(top: BorderSide(color: dark ? Colors.white12 : AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == index;
          final accent = dark ? AppColors.gold : AppColors.orange;
          final fg = active ? accent : (dark ? Colors.white70 : AppColors.muted);
          return InkWell(
            onTap: () => onTap(i),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: active ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: active && !dark
                          ? [
                              BoxShadow(
                                color: AppColors.orange.withOpacity(.24),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(items[i].$1, color: active ? (dark ? Colors.black : Colors.white) : fg, size: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(items[i].$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class MiniTabBar extends StatelessWidget {
  final List<String> tabs;
  final int index;
  final ValueChanged<int>? onChanged;

  const MiniTabBar({
    super.key,
    required this.tabs,
    this.index = 0,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: List.generate(tabs.length, (i) {
          final active = i == index;
          return InkWell(
            onTap: onChanged == null ? null : () => onChanged!(i),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: active ? AppColors.brandGradient : null,
                color: active ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: active ? Colors.white : AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class MetricRow extends StatelessWidget {
  final String leftTitle;
  final String leftValue;
  final String rightTitle;
  final String rightValue;
  final Color? rightColor;

  const MetricRow({
    super.key,
    required this.leftTitle,
    required this.leftValue,
    required this.rightTitle,
    required this.rightValue,
    this.rightColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(leftTitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(leftValue, style: style),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rightTitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(rightValue, style: style?.copyWith(color: rightColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LabelValue extends StatelessWidget {
  final String label;
  final String value;

  const LabelValue({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class TextLink extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool dark;

  const TextLink({super.key, required this.text, this.onTap, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: dark ? Colors.white : AppColors.orange,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class DividerGap extends StatelessWidget {
  const DividerGap({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 4);
  }
}
