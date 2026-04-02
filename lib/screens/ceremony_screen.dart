/// Церемония декодирования — главная фича приложения
/// 4 экрана: биты → BF код → пароль → текст
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'dart:async';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';
import '../core/codec.dart';

enum CeremonyStage { loading, bits, brainfuck, password, result, error }

class CeremonyScreen extends StatefulWidget {
  final Uint8List binary;
  final SpoonTheme theme;
  final String? cid;

  const CeremonyScreen({
    super.key,
    required this.binary,
    required this.theme,
    this.cid,
  });

  @override
  State<CeremonyScreen> createState() => _CeremonyScreenState();
}

class _CeremonyScreenState extends State<CeremonyScreen>
    with SingleTickerProviderStateMixin {
  CeremonyStage _stage = CeremonyStage.loading;
  String _displayBits = '';
  String _displayBf = '';
  String _displayText = '';
  String _errorMessage = '';
  String _bfCode = '';
  final _passwordController = TextEditingController();

  late AnimationController _animController;
  Timer? _typeTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _startCeremony();
  }

  @override
  void dispose() {
    _animController.dispose();
    _typeTimer?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _startCeremony() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _showBits();
  }

  /// Экран 1 — поток битов Spoon
  void _showBits() {
    setState(() => _stage = CeremonyStage.bits);

    final fakeBits = List.generate(256, (i) =>
      (i % 7 == 0) ? '0' : '1'
    ).join();

    int index = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (index >= fakeBits.length) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 800), _showBrainfuck);
        return;
      }
      setState(() {
        _displayBits = fakeBits.substring(0, index + 1);
      });
      index += 4;
    });
  }

  /// Экран 2 — BF код
  void _showBrainfuck() {
    try {
      final decoded = SpoonCodec.decode(widget.binary);
      _bfCode = decoded.bfCode;
    } catch (e) {
      _bfCode = '+++[>++<-]>.[...]';
    }

    setState(() {
      _stage = CeremonyStage.brainfuck;
      _displayBf = '';
    });

    int index = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (index >= _bfCode.length) {
        timer.cancel();
        Future.delayed(
          const Duration(milliseconds: 800),
          _checkPassword,
        );
        return;
      }
      setState(() {
        _displayBf = _bfCode.substring(0, index + 1);
      });
      index += 3;
    });
  }

  /// Экран 3 — проверка пароля
  void _checkPassword() {
    final result = SpoonCodec.decode(widget.binary);
    if (result.success) {
      _revealText(result.text);
    } else {
      setState(() {
        _stage = CeremonyStage.password;
      });
    }
  }

  void _submitPassword() {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    final result = SpoonCodec.decode(
      widget.binary,
      password: password,
    );

    if (result.success) {
      _revealText(result.text);
    } else {
      setState(() {
        _errorMessage = 'ACCESS DENIED';
        _stage = CeremonyStage.error;
      });
    }
  }

  /// Экран 4 — текст появляется посимвольно
  void _revealText(String text) {
    setState(() {
      _stage = CeremonyStage.result;
      _displayText = '';
    });

    int index = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (index >= text.length) {
        timer.cancel();
        return;
      }
      setState(() {
        _displayText = text.substring(0, index + 1);
      });
      index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(widget.theme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: GlowText(
          '> CEREMONY',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
      ),
      body: CrtScreen(
        theme: widget.theme,
        scanlines: true,
        glow: true,
        flicker: false,
        child: _buildStage(colors),
      ),
    );
  }

  Widget _buildStage(dynamic colors) {
    switch (_stage) {
      case CeremonyStage.loading:
        return _buildLoading(colors);
      case CeremonyStage.bits:
        return _buildBits(colors);
      case CeremonyStage.brainfuck:
        return _buildBrainfuck(colors);
      case CeremonyStage.password:
        return _buildPassword(colors);
      case CeremonyStage.result:
        return _buildResult(colors);
      case CeremonyStage.error:
        return _buildError(colors);
    }
  }

  Widget _buildLoading(dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlowText(
            'INITIALIZING...',
            style: GoogleFonts.vt323(fontSize: 28, color: colors.primary),
            glowColor: colors.primary,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              color: colors.primary,
              backgroundColor: colors.dim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBits(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlowText(
            '> SPOON BINARY STREAM',
            style: GoogleFonts.vt323(fontSize: 20, color: colors.primary),
            glowColor: colors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.binary.length} bytes',
            style: GoogleFonts.vt323(color: colors.textDim, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                _displayBits,
                style: GoogleFonts.vt323(
                  color: colors.secondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrainfuck(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlowText(
            '> BRAINFUCK INTERPRETER',
            style: GoogleFonts.vt323(fontSize: 20, color: colors.primary),
            glowColor: colors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            '${_bfCode.length} instructions',
            style: GoogleFonts.vt323(color: colors.textDim, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _displayBf,
                      style: GoogleFonts.vt323(
                        color: colors.primary,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                  BlinkingCursor(color: colors.cursor, fontSize: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassword(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlowText(
            '> ACCESS RESTRICTED',
            style: GoogleFonts.vt323(fontSize: 24, color: colors.primary),
            glowColor: colors.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'enter key to decrypt:',
            style: GoogleFonts.vt323(color: colors.textDim, fontSize: 20),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '> ',
                style: GoogleFonts.vt323(color: colors.primary, fontSize: 24),
              ),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  style: GoogleFonts.vt323(color: colors.text, fontSize: 24),
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '________',
                    hintStyle: GoogleFonts.vt323(
                      color: colors.textDim, fontSize: 24,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _submitPassword(),
                ),
              ),
              BlinkingCursor(color: colors.cursor, fontSize: 24),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitPassword,
              child: Text(
                '> DECRYPT',
                style: GoogleFonts.vt323(fontSize: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlowText(
            '> MESSAGE DECODED',
            style: GoogleFonts.vt323(fontSize: 20, color: colors.primary),
            glowColor: colors.primary,
          ),
          if (widget.cid != null) ...[
            const SizedBox(height: 4),
            Text(
              'cid: ${widget.cid!.substring(0, 20)}...',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 14),
            ),
          ],
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '> ',
                        style: GoogleFonts.vt323(
                          color: colors.primary, fontSize: 28,
                        ),
                      ),
                      Expanded(
                        child: GlowText(
                          _displayText,
                          style: GoogleFonts.vt323(
                            fontSize: 28,
                            color: colors.primary,
                            height: 1.4,
                          ),
                          glowColor: colors.primary,
                          glowRadius: 12,
                        ),
                      ),
                      BlinkingCursor(color: colors.cursor, fontSize: 28),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlowText(
            _errorMessage,
            style: GoogleFonts.vt323(
              fontSize: 40,
              color: Colors.red,
            ),
            glowColor: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'message unavailable',
            style: GoogleFonts.vt323(color: colors.textDim, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'ttl expired or wrong key',
            style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '> BACK',
              style: GoogleFonts.vt323(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
