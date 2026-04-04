/// QR экран — показать QR код ключа круга и сканировать чужой
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';
import '../transport/circles_storage.dart';

/// Показать QR код ключа круга
class QrShowScreen extends StatelessWidget {
  final Circle circle;
  final SpoonTheme theme;

  const QrShowScreen({
    super.key,
    required this.circle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(theme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: GlowText(
          '> SHARE BOARD',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
      ),
      body: CrtScreen(
        theme: theme,
        scanlines: true,
        glow: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlowText(
                circle.name,
                style: GoogleFonts.vt323(fontSize: 28, color: colors.primary),
                glowColor: colors.primary,
              ),
              const SizedBox(height: 32),

              // QR код
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: colors.primary, width: 2),
                ),
                child: QrImageView(
                  data: 'spoon://board/${circle.key}',
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'key:',
                style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: circle.key));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'key copied to clipboard',
                        style: GoogleFonts.vt323(fontSize: 18),
                      ),
                      backgroundColor: colors.dim,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: GlowText(
                  circle.key,
                  style: GoogleFonts.vt323(
                    fontSize: 22,
                    color: colors.primary,
                    letterSpacing: 2,
                  ),
                  glowColor: colors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'tap to copy',
                style: GoogleFonts.vt323(color: colors.textDim, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Сканировать QR код чужого круга
class QrScanScreen extends StatefulWidget {
  final SpoonTheme theme;

  const QrScanScreen({super.key, required this.theme});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final value = barcode!.rawValue!;

    if (value.startsWith('spoon://board/') || value.startsWith('spoon://circle/')) {
      _scanned = true;
      final key = value.replaceFirst('spoon://board/', '').replaceFirst('spoon://circle/', '');
      await _scannerController.stop();

      if (mounted) {
        _showJoinDialog(key);
      }
    }
  }

  void _showJoinDialog(String key) {
    final colors = AppTheme.getColors(widget.theme);
    final nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.background,
        title: GlowText(
          '> BOARD FOUND',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'key: $key',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: GoogleFonts.vt323(color: colors.text, fontSize: 20),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'board name_',
                hintStyle: GoogleFonts.vt323(
                  color: colors.textDim, fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'CANCEL',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await CirclesStorage.join(key, nameController.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                Navigator.pop(context, true);
              }
            },
            child: GlowText(
              'JOIN',
              style: GoogleFonts.vt323(fontSize: 18, color: colors.primary),
              glowColor: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(widget.theme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: GlowText(
          '> SCAN BOARD',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(colors.primary),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'scan board QR code',
                style: GoogleFonts.vt323(
                  color: colors.primary,
                  fontSize: 20,
                  shadows: [
                    Shadow(color: colors.primary, blurRadius: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final Color color;
  _ScanOverlayPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    const boxSize = 220.0;
    final rect = Rect.fromCenter(
      center: center,
      width: boxSize,
      height: boxSize,
    );

    const cornerSize = 20.0;
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerSize, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerSize), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerSize, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerSize), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerSize, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerSize), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerSize, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerSize), paint);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) => false;
}
