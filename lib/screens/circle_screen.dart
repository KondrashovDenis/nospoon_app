/// Экран круга — реальная лента посланий
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';
import '../transport/circles_storage.dart';
import '../transport/messenger.dart';
import '../services/logger_service.dart';
import '../services/sound_service.dart';
import 'dart:typed_data';
import '../core/codec.dart';
import 'compose_screen.dart';
import 'ceremony_screen.dart';
import 'qr_screen.dart';

class CircleScreen extends StatefulWidget {
  final Circle circle;
  final SpoonTheme theme;
  final bool scanlines;
  final bool glow;
  final bool flicker;

  const CircleScreen({
    super.key,
    required this.circle,
    required this.theme,
    required this.scanlines,
    required this.glow,
    required this.flicker,
  });

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  List<ReceivedMessage> _messages = [];
  bool _loading = false;
  String? _error;
  SpoonMessenger? _messenger;
  String? _loadingCid;

  @override
  void initState() {
    super.initState();
    _initMessenger();
  }

  Future<void> _initMessenger() async {
    try {
      _messenger = await SpoonMessenger.create();
      logger.info('Messenger initialized for circle: ${widget.circle.key}');
      _loadFeed();
    } catch (e) {
      logger.error('Messenger init error: $e');
      setState(() => _error = 'Messenger init error: $e');
    }
  }

  Future<void> _loadFeed() async {
    if (_messenger == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    SoundService().startModemLoop();

    try {
      logger.info('Loading feed for board: ${widget.circle.key}');
      final messages = await _messenger!.receive(widget.circle.key);
      logger.info('Feed loaded: ${messages.length} messages');

      SoundService().stopModemLoop();
      await SoundService().playClick();

      // Фильтровать истёкшие сообщения (TTL)
      final active = messages.where((m) => m.error != 'TTL истёк').toList();

      if (!mounted) return;
      setState(() {
        _messages = active;
        _loading = false;
      });
    } catch (e) {
      SoundService().stopModemLoop();
      logger.error('Feed load error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteCircle() async {
    final colors = AppTheme.getColors(widget.theme);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.background,
        title: GlowText(
          '> DELETE BOARD',
          style: GoogleFonts.vt323(fontSize: 22, color: Colors.red),
          glowColor: Colors.red,
        ),
        content: Text(
          'Remove "${widget.circle.name}" from your list?\n\nOthers will keep access.',
          style: GoogleFonts.vt323(color: colors.text, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'DELETE',
              style: GoogleFonts.vt323(color: Colors.red, fontSize: 18),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CirclesStorage.remove(widget.circle.key);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(widget.theme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: GlowText(
          '> ${widget.circle.name}',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QrShowScreen(
                  circle: widget.circle,
                  theme: widget.theme,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeed,
          ),
        ],
      ),
      body: CrtScreen(
        theme: widget.theme,
        scanlines: widget.scanlines,
        glow: widget.glow,
        flicker: widget.flicker,
        child: _buildBody(colors),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'delete_circle',
            onPressed: _deleteCircle,
            backgroundColor: colors.dim,
            child: Icon(Icons.delete_outline, color: Colors.red),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'compose',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ComposeScreen(
                  circle: widget.circle,
                  theme: widget.theme,
                  messenger: _messenger,
                ),
              ),
            ).then((_) => _loadFeed()),
            backgroundColor: colors.dim,
            child: Icon(Icons.edit, color: colors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(dynamic colors) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlowText(
              'LOADING FEED...',
              style: GoogleFonts.vt323(fontSize: 24, color: colors.primary),
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlowText(
              'ERROR',
              style: GoogleFonts.vt323(fontSize: 32, color: Colors.red),
              glowColor: Colors.red,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: GoogleFonts.vt323(
                  color: colors.textDim, fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: _loadFeed,
              child: Text('RETRY', style: GoogleFonts.vt323(fontSize: 20)),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlowText(
              'no messages.',
              style: GoogleFonts.vt323(fontSize: 32, color: colors.primary),
              glowColor: colors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'be the first to send.',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 20),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeed,
      color: colors.primary,
      backgroundColor: colors.dim,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (ctx, i) => _buildMessageTile(_messages[i], colors),
      ),
    );
  }

  Widget _buildMessageTile(ReceivedMessage msg, dynamic colors) {
    final publishedAt = DateTime.fromMillisecondsSinceEpoch(msg.publishedAt);
    final timeStr =
        '${publishedAt.hour.toString().padLeft(2, '0')}:'
        '${publishedAt.minute.toString().padLeft(2, '0')} '
        '${publishedAt.day.toString().padLeft(2, '0')}.'
        '${publishedAt.month.toString().padLeft(2, '0')}';

    final isLoading = _loadingCid == msg.cid;

    return GestureDetector(
      onTap: isLoading ? null : () => _openCeremony(msg),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: msg.success ? colors.secondary : colors.dim,
          ),
          color: colors.dim,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '> ${msg.cid.substring(0, 20)}...',
                    style: GoogleFonts.vt323(
                      color: msg.success ? colors.primary : colors.textDim,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isLoading)
                    Row(
                      children: [
                        Text(
                          'Loading message...',
                          style: GoogleFonts.vt323(
                            color: colors.textDim, fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'tap to decode',
                      style: GoogleFonts.vt323(
                        color: colors.textDim, fontSize: 16,
                      ),
                    ),
                  Text(
                    timeStr,
                    style: GoogleFonts.vt323(
                      color: colors.textDim, fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: colors.primary,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(Icons.chevron_right, color: colors.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _openCeremony(ReceivedMessage msg) async {
    if (_messenger == null) return;

    setState(() => _loadingCid = msg.cid);
    logger.info('Downloading: ${msg.cid}');

    SoundService().startModemLoop();

    try {
      final binary = await _messenger!.ipfs.download(msg.cid);
      logger.info('Downloaded ${binary.length} bytes');

      SoundService().stopModemLoop();
      await SoundService().playClick();

      setState(() => _loadingCid = null);
      if (!mounted) return;

      // Диагностика пароля
      final quickCheck = SpoonCodec.decode(binary);
      logger.info('quickCheck.success: ${quickCheck.success}');
      logger.info('quickCheck.error: ${quickCheck.error}');
      logger.info('quickCheck.text length: ${quickCheck.text.length}');
      if (quickCheck.text.isNotEmpty) {
        final preview = quickCheck.text.codeUnits
            .take(10)
            .map((c) => '0x${c.toRadixString(16)}')
            .join(' ');
        logger.info('quickCheck.text bytes: $preview');
      }

      // Проверить нужен ли пароль
      String? password;
      if (quickCheck.error == 'password_required') {
        logger.info('Password required — showing dialog');
        password = await _showPasswordFlow(binary);
        if (password == null) return;
      } else {
        logger.info('No password needed — opening ceremony');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CeremonyScreen(
              binary: binary,
              theme: widget.theme,
              cid: msg.cid,
              password: password,
            ),
          ),
        );
      }
    } catch (e) {
      SoundService().stopModemLoop();
      logger.error('Download error: $e');
      setState(() => _loadingCid = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'error: $e',
              style: GoogleFonts.vt323(fontSize: 16),
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.3),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Флоу ввода пароля с обработкой неверного пароля
  Future<String?> _showPasswordFlow(Uint8List binary) async {
    String? password = await _showPasswordDialog();

    while (password != null && password.isNotEmpty) {
      logger.info('Checking password: ${password.length} chars');

      final result = SpoonCodec.decode(binary, password: password);
      logger.info('Password check: success=${result.success} error=${result.error}');

      if (result.success) {
        logger.info('Password correct!');
        return password;
      }

      if (result.error == 'wrong_password') {
        logger.info('Wrong password — showing error dialog');
        final action = await _showWrongPasswordDialog();
        if (action == 'try_again') {
          password = await _showPasswordDialog();
        } else {
          return null;
        }
      } else {
        // TTL или другая ошибка
        return null;
      }
    }
    return null;
  }

  Future<String?> _showPasswordDialog() async {
    final colors = AppTheme.getColors(widget.theme);
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.background,
        title: GlowText(
          '> ACCESS RESTRICTED',
          style: GoogleFonts.vt323(fontSize: 20, color: colors.primary),
          glowColor: colors.primary,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'enter key to decrypt:',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: GoogleFonts.vt323(color: colors.text, fontSize: 20),
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '________',
                hintStyle: GoogleFonts.vt323(
                  color: colors.textDim, fontSize: 20,
                ),
              ),
              onSubmitted: (_) => Navigator.pop(ctx, controller.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              'CANCEL',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: GlowText(
              'DECRYPT',
              style: GoogleFonts.vt323(fontSize: 18, color: colors.primary),
              glowColor: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showWrongPasswordDialog() async {
    final colors = AppTheme.getColors(widget.theme);

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.background,
        title: GlowText(
          '> WRONG PASSWORD KEY',
          style: GoogleFonts.vt323(fontSize: 20, color: Colors.red),
          glowColor: Colors.red,
        ),
        content: Text(
          'The key you entered is incorrect.\nThis message cannot be decrypted.',
          style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'exit'),
            child: Text(
              'EXIT',
              style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'try_again'),
            child: GlowText(
              'TRY AGAIN',
              style: GoogleFonts.vt323(fontSize: 18, color: colors.primary),
              glowColor: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
