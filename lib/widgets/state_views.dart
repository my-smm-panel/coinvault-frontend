import 'package:flutter/material.dart';
import '../core/app_theme.dart';


/// Production-grade shared states: shimmer loading, empty, error + retry.
/// Used across list screens so every screen behaves identically offline,
/// while loading, and when a section has no data yet.

class AppShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFFFFFFF),
              Color(0xFFE7E7E7),
              Color(0xFFFFFFFF),
            ],
            stops: [
              _controller.value - 0.3 < 0 ? 0 : _controller.value - 0.3,
              _controller.value,
              _controller.value + 0.3 > 1 ? 1 : _controller.value + 0.3,
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton rows that mimic the standard earn/survey card layout.
class ShimmerCardList extends StatelessWidget {
  final int rows;
  final EdgeInsetsGeometry padding;

  const ShimmerCardList({super.key, this.rows = 5, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    // In a sliver the height is unbounded: avoid a nested ListView there.
    // In a full-screen loading state, allow rows to scroll on small devices.
    return LayoutBuilder(builder: (context, constraints) {
      final content = Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rows, (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(children: [
              AppShimmer(width: 46, height: 46, radius: 12),
              SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(width: 90, height: 12),
                  SizedBox(height: 8),
                  AppShimmer(width: 160, height: 10),
                ],
              )),
              AppShimmer(width: 38, height: 38, radius: 10),
            ]),
          )),
        ),
      );
      return constraints.hasBoundedHeight
          ? SingleChildScrollView(child: content)
          : content;
    });
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, this.message = 'Something went wrong', required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 34, color: AppColors.error),
            ),
            const SizedBox(height: 14),
            const Text(
              'Couldn’t load data',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}