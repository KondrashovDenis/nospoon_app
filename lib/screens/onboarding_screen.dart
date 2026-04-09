/// Онбординг экран — matrix rain + логотип
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/crt_effects.dart';

/// Символы Brainfuck/Spoon для matrix rain
const _matrixChars = '+-><[].,01 ';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00FF41);
    const bg = Color(0xFF0D0D0D);

    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        onTap: widget.onComplete,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Matrix rain background
            const Positioned.fill(
              child: _MatrixRain(),
            ),
            // Scanlines overlay
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ScanOverlay(),
                ),
              ),
            ),
            // Logo + text
            Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: green.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/logo_ooo_trsp.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GlowText(
                      'there is no spoon.',
                      style: GoogleFonts.vt323(fontSize: 28, color: green),
                      glowColor: green,
                    ),
                    const SizedBox(height: 48),
                    Text(
                      '[ tap to enter ]',
                      style: GoogleFonts.vt323(
                        fontSize: 18,
                        color: green.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Matrix rain — падающие символы BF/Spoon
class _MatrixRain extends StatefulWidget {
  const _MatrixRain();

  @override
  State<_MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<_MatrixRain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  final List<_RainColumn> _columns = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initColumns(Size size) {
    _columns.clear();
    const colWidth = 18.0;
    final numCols = (size.width / colWidth).ceil();

    for (int i = 0; i < numCols; i++) {
      _columns.add(_RainColumn(
        x: i * colWidth,
        speed: 0.3 + _random.nextDouble() * 0.7,
        length: 8 + _random.nextInt(16),
        offset: _random.nextDouble() * size.height,
        chars: List.generate(
          24, (_) => _matrixChars[_random.nextInt(_matrixChars.length)],
        ),
      ));
    }
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (!_initialized) _initColumns(size);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: size,
              painter: _MatrixPainter(
                columns: _columns,
                time: DateTime.now().millisecondsSinceEpoch / 1000.0,
              ),
            );
          },
        );
      },
    );
  }
}

class _RainColumn {
  final double x;
  final double speed;
  final int length;
  double offset;
  final List<String> chars;

  _RainColumn({
    required this.x,
    required this.speed,
    required this.length,
    required this.offset,
    required this.chars,
  });
}

class _MatrixPainter extends CustomPainter {
  final List<_RainColumn> columns;
  final double time;

  _MatrixPainter({required this.columns, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    const charHeight = 18.0;
    const green = Color(0xFF00FF41);

    for (final col in columns) {
      final y = (col.offset + time * col.speed * 80) % (size.height + col.length * charHeight);

      for (int i = 0; i < col.length; i++) {
        final charY = y - i * charHeight;
        if (charY < -charHeight || charY > size.height) continue;

        final alpha = (1.0 - i / col.length) * 0.6;
        if (alpha <= 0) continue;

        final tp = TextPainter(
          text: TextSpan(
            text: col.chars[i % col.chars.length],
            style: TextStyle(
              fontFamily: 'VT323',
              fontSize: 16,
              color: i == 0
                  ? Colors.white.withValues(alpha: 0.9)
                  : green.withValues(alpha: alpha),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(col.x, charY));
      }
    }
  }

  @override
  bool shouldRepaint(_MatrixPainter old) => true;
}

/// Лёгкие scanlines для онбординга
class _ScanOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF41).withValues(alpha: 0.02)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanOverlay old) => false;
}
