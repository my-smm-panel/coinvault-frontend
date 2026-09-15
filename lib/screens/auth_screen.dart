import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

/// Login screen — dark CoinVault theme with an intro video in the centre
/// (Part 2), matching the wireframe: top bar, video, Continue with Google.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late VideoPlayerController _videoController;
  String _selectedLang = 'English';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Part 2 — intro video plays automatically and loops.
    _videoController =
        VideoPlayerController.asset('assets/videos/intro.mp4')
          ..initialize().then((_) {
            if (mounted && _videoController.value.isInitialized) {
              setState(() {});
              _videoController.setLooping(true);
              _videoController.play();
            }
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (mounted) {
        setState(() => _error = 'Sign-in cancelled. Please try again.');
      }
    } catch (e) {
      debugPrint('AuthScreen sign-in error: $e');
      final msg = e is Exception ? e.toString() : 'Sign-in failed. Try again.';
      if (mounted) {
        setState(() => _error = msg.replaceFirst(RegExp(r'^Exception: '), ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _videoController.value.isInitialized;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: Stack(
        children: [
          // Warm radial amber spotlight glow behind the video
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.5, -0.3),
                  radius: 0.7,
                  colors: [
                    Color(0xFFFF8A2A),
                    Color(0x33C94A0A),
                    Color(0x000F0D0B),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Part 1 — top-right language pill
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 12),
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.public, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(_selectedLang, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            const Icon(Icons.expand_more, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Part 2 — intro video (replaces old bear/coin area)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ready
                          ? Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFFFF8A2A).withOpacity(0.18), blurRadius: 30, offset: const Offset(0, 8)),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: AspectRatio(
                                aspectRatio: _videoController.value.aspectRatio,
                                child: VideoPlayer(_videoController),
                              ),
                            )
                          : const CircularProgressIndicator(
                              color: Color(0xFFFF8A2A),
                              strokeWidth: 2.6,
                            ),
                    ),
                  ),
                ),

                // Brand wordmark
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Coin', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1)),
                      TextSpan(text: 'Vault', style: TextStyle(color: Color(0xFFFF8A2A), fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Part 3 — Continue with Google button (full width, white pill)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: _loading ? null : _signInWithGoogle,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _loading ? Colors.white.withOpacity(0.7) : Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: _loading
                          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A2A)))))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _GoogleGLogo(size: 24),
                                const SizedBox(width: 12),
                                const Text('Continue with Google', style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward, color: Color(0xFF1F1F1F), size: 20),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Google "G" logo ----------
class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GLogoPainter()));
  }
}

class _GLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final ringPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke;
    final colors = [const Color(0xFF4285F4), const Color(0xFF34A853), const Color(0xFFFBBC05), const Color(0xFFEA4335)];
    final sweep = 2 * 3.141592653589793;
    for (int i = 0; i < colors.length; i++) {
      ringPaint.color = colors[i];
      canvas.drawArc(Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height), -1.5708 + (sweep / 4) * i, sweep / 4, false, ringPaint);
    }
    final barPaint = Paint()..color = colors[0];
    final barRect = Rect.fromCenter(center: Offset(size.width * 0.7, size.height * 0.5), width: size.width * 0.42, height: size.height * 0.18);
    canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(1)), barPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
