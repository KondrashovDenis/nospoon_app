import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'dart:async';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';
import '../core/codec.dart';
import '../services/sound_service.dart';

enum CeremonyStage { loading, bits, brainfuck, result, error }

class CeremonyScreen extends StatefulWidget {
  final Uint8List binary;
  final SpoonTheme theme;
  final String? cid;
  final String? password;

  const CeremonyScreen({
    super.key,
    required this.binary,
    required this.theme,
    this.cid,
    this.password,
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

  late AnimationController _animController;
  Timer? _typeTimer;
  final _scrollController = ScrollController();
  final _bfScrollController = ScrollController();

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
    _scrollController.dispose();
    _bfScrollController.dispose();
    super.dispose();
  }

  Future<void> _startCeremony() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _showBits();
  }

  void _showBits() {
    setState(() => _stage = CeremonyStage.bits);

    final fakeBits = widget.binary
        .map((b) => b.toRadixString(2).padLeft(8, '0'))
        .join();
    final displayBits = fakeBits.length > 512
        ? fakeBits.substring(0, 512)
        : fakeBits;

    int index = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 12), (timer) {
      if (index >= displayBits.length) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), _showBrainfuck);
        return;
      }
      final char = displayBits[index];
      setState(() {
        _displayBits = displayBits.substring(0, index + 1);
      });
      if (index % 4 == 0) {
        if (char == '0') {
          SoundService().playBitZero();
        } else {
          SoundService().playBitOne();
        }
      }
      index += 2;
    });
  }

  void _showBrainfuck() {
    try {
      final decoded = SpoonCodec.decode(
        widget.binary,
        password: widget.password,
      );
      _bfCode = decoded.bfCode;
    } catch (e) {
      _bfCode = '+++[>++<-]>.';
    }

    final displayBf = _bfCode.length > 2000
        ? _bfCode.substring(0, 2000)
        : _bfCode;

    setState(() {
      _stage = CeremonyStage.brainfuck;
      _displayBf = '';
    });

    SoundService().resetPlusCount();
    SoundService().resetMinusCount();

    int index = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 8), (timer) {
      if (index >= displayBf.length) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 500), _decodeAndReveal);
        return;
      }

      final char = displayBf[index];
      setState(() {
        _displayBf = displayBf.substring(0, index + 1);
      });

      if (_bfScrollController.hasClients) {
        _bfScrollController.animateTo(
          _bfScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
        );
      }

      if (index % 3 == 0) {
        switch (char) {
          case '+': SoundService().playPlus();
          case '-': SoundService().playMinus();
          case '>': SoundService().playRight();
          case '<': SoundService().playLeft();
          case '[': SoundService().playLoopOpen();
          case ']': SoundService().playLoopClose();
          case '.': SoundService().playOutput();
        }
      }
      index += 2;
    });
  }

  void _decodeAndReveal() {
    final result = SpoonCodec.decode(
      widget.binary,
      password: widget.password,
    );

    if (result.success && result.text.isNotEmpty) {
      _revealText(result.text);
    } else if (result.error == 'password_required' ||
               (!result.success && widget.password != null)) {
      _revealText('Enter password to see this message');
    } else {
      setState(() {
        _errorMessage = 'TTL EXPIRED';
        _stage = CeremonyStage.error;
      });
    }
  }

  void _revealText(String text) {
    setState(() {
      _stage = CeremonyStage.result;
      _displayText = '';
    });

    int index = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (index >= text.length) {
        timer.cancel();
        SoundService().playSuccess();
        return;
      }
      setState(() {
        _displayText = text.substring(0, index + 1);
      });
      SoundService().playCharacter(text.codeUnitAt(index));
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
          '> DECODING',
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
          const SizedBox(height: 4),
          Text(
            '${widget.binary.length} bytes',
            style: GoogleFonts.vt323(color: colors.textDim, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Align(
                alignment: Alignment.topLeft,
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
          const SizedBox(height: 4),
          Text(
            '${_bfCode.length} instructions',
            style: GoogleFonts.vt323(color: colors.textDim, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: _bfScrollController,
              child: Align(
                alignment: Alignment.topLeft,
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
              child: Row(
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
            style: GoogleFonts.vt323(fontSize: 40, color: Colors.red),
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
            child: Text('> BACK', style: GoogleFonts.vt323(fontSize: 20)),
          ),
        ],
      ),
    );
  }
}
