import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class MascotBear extends StatelessWidget {
  final double size;
  final bool withCoin;
  final bool coinBelow;

  const MascotBear({
    super.key,
    this.size = 170,
    this.withCoin = false,
    this.coinBelow = false,
  });

  @override
  Widget build(BuildContext context) {
    final headSize = size * .46;
    final bodyWidth = size * .54;
    final bodyHeight = size * .44;
    final coinSize = size * .34;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (withCoin && !coinBelow)
            Positioned(
              right: 2,
              top: size * .14,
              child: _Coin(size: coinSize),
            ),
          if (withCoin && coinBelow)
            Positioned(
              right: size * .08,
              bottom: size * .02,
              child: _Coin(size: coinSize * 1.1),
            ),
          Positioned(
            bottom: 0,
            child: Container(
              width: bodyWidth,
              height: bodyHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(bodyWidth / 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: bodyHeight * .18,
            left: size * .16,
            child: _leg(),
          ),
          Positioned(
            bottom: bodyHeight * .18,
            right: size * .16,
            child: _leg(),
          ),
          Positioned(
            bottom: bodyHeight * .38,
            left: size * .08,
            child: Transform.rotate(
              angle: -.35,
              child: _arm(size * .20),
            ),
          ),
          Positioned(
            bottom: bodyHeight * .45,
            right: size * .06,
            child: Transform.rotate(
              angle: .55,
              child: _arm(size * .22),
            ),
          ),
          Positioned(
            top: size * .14,
            child: Container(
              width: headSize,
              height: headSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: size * .11,
            left: size * .27,
            child: _ear(headSize * .22),
          ),
          Positioned(
            top: size * .11,
            right: size * .27,
            child: _ear(headSize * .22),
          ),
          Positioned(
            top: size * .29,
            child: Container(
              width: headSize * .42,
              height: headSize * .28,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EA),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            top: size * .25,
            left: size * .39,
            child: _eye(),
          ),
          Positioned(
            top: size * .25,
            right: size * .39,
            child: _eye(),
          ),
          Positioned(
            top: size * .33,
            child: Container(
              width: 12,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF2F394A),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            top: size * .31,
            left: size * .31,
            child: _cheek(),
          ),
          Positioned(
            top: size * .31,
            right: size * .31,
            child: _cheek(),
          ),
          Positioned(
            top: size * .37,
            child: Container(
              width: 18,
              height: 10,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF2F394A), width: 2),
                ),
              ),
            ),
          ),
          if (withCoin && !coinBelow)
            Positioned(
              right: size * .16,
              top: size * .36,
              child: Transform.rotate(
                angle: .2,
                child: _paw(size * .12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ear(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF0F2F4), width: 1.5),
        ),
      );

  Widget _eye() => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF2F394A),
          shape: BoxShape.circle,
        ),
      );

  Widget _cheek() => Container(
        width: 12,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD5C9),
          borderRadius: BorderRadius.circular(20),
        ),
      );

  Widget _leg() => Container(
        width: size * .12,
        height: size * .10,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );

  Widget _arm(double length) => Container(
        width: size * .11,
        height: length,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
      );

  Widget _paw(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
}

class _Coin extends StatelessWidget {
  final double size;

  const _Coin({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE082), AppColors.gold, AppColors.orange],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '₹',
          style: TextStyle(
            color: Colors.white.withOpacity(.9),
            fontWeight: FontWeight.w800,
            fontSize: size * .38,
          ),
        ),
      ),
    );
  }
}
