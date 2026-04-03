/// CRT визуальные эффекты
library;

import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Обёртка с CRT эффектами
class CrtScreen extends StatefulWidget {
  final Widget child;
  final SpoonTheme theme;
  final bool scanlines;
  final bool glow;
  final bool flicker;

  const CrtScreen({
    super.key,
    required this.child,
    required this.theme,
    this.scanlines = true,
    this.glow = true,
    this.flicker = false,
  });

  @override
  State<CrtScreen> createState() => _CrtScreenState();
}

class _CrtScreenState extends State<CrtScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flickerController;
  late Animation<double> _flickerAnimation;

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _flickerAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
    );
    if (widget.flicker) {
      _startFlicker();
    }
  }

  void _startFlicker() async {
    await Future.delayed(Duration(milliseconds: 2000 + (DateTime.now().millisecond % 3000)));
    if (mounted && widget.flicker) {
      _flickerController.forward().then((_) => _flickerController.reverse());
      _startFlicker();
    }
  }

  @override
  void dispose() {
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(widget.theme);

    Widget content = widget.child;

    if (widget.flicker) {
      content = AnimatedBuilder(
        animation: _flickerAnimation,
        builder: (context, child) => Opacity(
          opacity: _flickerAnimation.value,
          child: child,
        ),
        child: content,
      );
    }

    return Stack(
      children: [
        content,
        if (widget.scanlines)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScanlinesPainter(colors.primary),
              ),
            ),
          ),
        if (widget.glow)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      colors.background.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  final Color color;
  _ScanlinesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinesPainter old) => false;
}

/// Мигающий курсор
class BlinkingCursor extends StatefulWidget {
  final Color color;
  final double fontSize;

  const BlinkingCursor({super.key, required this.color, this.fontSize = 20});

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Горизонтальный прямоугольник — классический терминальный курсор
    // ширина = ~0.6 от fontSize, высота = fontSize
    final cursorWidth = widget.fontSize * 0.6;
    final cursorHeight = widget.fontSize * 1.1;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Opacity(
        opacity: _controller.value > 0.5 ? 1.0 : 0.0,
        child: Container(
          width: cursorWidth,
          height: cursorHeight,
          color: widget.color,
        ),
      ),
    );
  }
}

/// Текст с glow эффектом
class GlowText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color glowColor;
  final double glowRadius;

  const GlowText(
    this.text, {
    super.key,
    this.style,
    required this.glowColor,
    this.glowRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        shadows: [
          Shadow(color: glowColor.withValues(alpha: 0.8), blurRadius: glowRadius),
          Shadow(color: glowColor.withValues(alpha: 0.4), blurRadius: glowRadius * 2),
        ],
      ),
    );
  }
}
