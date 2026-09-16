import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Promotional carousel for the Home screen — 5 slides, auto-advancing,
/// infinite loop, manual swipe, pagination dots (active = CoinVault orange).
/// Existing home UI is untouched; this is purely additive.
class BannerSlide {
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final VoidCallback onTap;

  const BannerSlide({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.onTap,
  });
}

class HomeBannerCarousel extends StatefulWidget {
  final List<BannerSlide> slides;
  const HomeBannerCarousel({super.key, required this.slides});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  // Large virtual page count => swiping feels infinite in both directions.
  static const int _loops = 1000;
  late final int _slideCount;
  late final int _virtualCount;
  late final int _startPage;

  @override
  void initState() {
    super.initState();
    _slideCount = widget.slides.length;
    _virtualCount = _slideCount * _loops;
    _startPage = _virtualCount ~/ 2;
    _controller = PageController(initialPage: _startPage);
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3, milliseconds: 500), (_) {
      if (!mounted || _slideCount <= 1) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final mapped = index % _slideCount;
    if (mapped != _page) setState(() => _page = mapped);
    // Re-center when drifting too far from the middle so both directions work.
    if (index < _slideCount * 2 || index > _virtualCount - _slideCount * 2) {
      final center = _startPage + mapped;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.jumpToPage(center);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_slideCount <= 1) {
      return _slideCount == 1 ? _BannerCard(slide: widget.slides.first) : const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 132,
          child: PageView.builder(
            controller: _controller,
            itemCount: _virtualCount,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) =>
                _BannerCard(slide: widget.slides[index % _slideCount]),
          ),
        ),
        const SizedBox(height: 10),
        // Pagination dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slideCount, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : const Color(0xFFD8D8E0),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerSlide slide;
  const _BannerCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E7E7), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mascot / illustration tile
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: slide.accentSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(slide.icon, color: slide.accent, size: 36),
          ),
          const SizedBox(width: 14),
          // Text + CTA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slide.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  slide.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B6B78),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: slide.onTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 6),
                      decoration: BoxDecoration(
                        color: slide.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        slide.cta,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
