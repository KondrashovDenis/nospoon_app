/// Экран доски — лента посланий
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/envelope.dart';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';
import '../transport/circles_storage.dart';
import '../transport/messenger.dart';
import '../transport/relay_client.dart';
import '../services/logger_service.dart';
import '../services/sound_service.dart';
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
  final SpoonMessenger _messenger = SpoonMessenger.create();
  List<FeedEntry> _messages = [];
  bool _loading = false;
  String? _error;
  String? _loadingCid;
  String _loadingLabel = '';

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    SoundService().startModemLoop();

    try {
      final messages = await _messenger.feed(widget.circle.key);
      logger.info('Feed loaded: ${messages.length} messages');

      SoundService().stopModemLoop();
      await SoundService().playClick();

      if (!mounted) return;
      setState(() {
        _messages = messages;
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
            child: const Icon(Icons.delete_outline, color: Colors.red),
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

  String _remaining(int expiresAtMs) {
    final left = DateTime.fromMillisecondsSinceEpoch(expiresAtMs)
        .difference(DateTime.now());
    if (left.isNegative) return 'expired';
    if (left.inDays > 0) {
      return 'expires in ${left.inDays}d ${left.inHours % 24}h';
    }
    if (left.inHours > 0) {
      return 'expires in ${left.inHours}h ${left.inMinutes % 60}m';
    }
    final minutes = left.inMinutes < 1 ? 1 : left.inMinutes;
    return 'expires in ${minutes}m';
  }

  Widget _buildMessageTile(FeedEntry msg, dynamic colors) {
    final publishedAt = DateTime.fromMillisecondsSinceEpoch(msg.publishedAt);
    final timeStr =
        '${publishedAt.hour.toString().padLeft(2, '0')}:'
        '${publishedAt.minute.toString().padLeft(2, '0')} '
        '${publishedAt.day.toString().padLeft(2, '0')}.'
        '${publishedAt.month.toString().padLeft(2, '0')}';

    final isLoading = _loadingCid == msg.cid;

    return GestureDetector(
      onTap: _loadingCid != null ? null : () => _openCeremony(msg),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: colors.secondary),
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
                      color: colors.primary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoading ? _loadingLabel : 'tap to decode',
                    style: GoogleFonts.vt323(
                      color: colors.textDim, fontSize: 16,
                    ),
                  ),
                  Text(
                    '$timeStr · ${_remaining(msg.expiresAt)}',
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.vt323(fontSize: 16)),
        backgroundColor: Colors.red.withValues(alpha: 0.3),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _openCeremony(FeedEntry msg) async {
    setState(() {
      _loadingCid = msg.cid;
      _loadingLabel = 'loading message...';
    });

    SoundService().startModemLoop();

    try {
      final blob = await _messenger.download(widget.circle.key, msg.cid);
      logger.info('Downloaded ${blob.length} bytes');

      SoundService().stopModemLoop();
      await SoundService().playClick();
      if (!mounted) return;

      final opened = await _openEnvelope(blob);
      if (!mounted) return;
      setState(() => _loadingCid = null);
      if (opened == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CeremonyScreen(
            message: opened,
            theme: widget.theme,
            cid: msg.cid,
          ),
        ),
      );
    } catch (e) {
      SoundService().stopModemLoop();
      logger.error('Open error: $e');
      if (!mounted) return;
      setState(() => _loadingCid = null);
      _showError('error: $e');
    }
  }

  /// Расшифровать конверт. Для сообщения с паролем спрашивает пароль и даёт
  /// повторить при ошибке. null — пользователь отказался либо сообщение
  /// прочесть нельзя (причина уже показана).
  Future<OpenedMessage?> _openEnvelope(Uint8List blob) async {
    String? password;

    try {
      if (MessageEnvelope.needsPassword(blob)) {
        logger.info('Password required');
        password = await _showPasswordDialog();
        if (password == null || password.isEmpty) return null;
      }
    } on EnvelopeException {
      _showError('message unreadable: unknown format');
      return null;
    }

    while (true) {
      if (!mounted) return null;
      setState(() => _loadingLabel = 'decrypting...');

      try {
        return await MessageEnvelope.open(
          blob,
          boardKey: widget.circle.key,
          password: password,
        );
      } on EnvelopeException catch (e) {
        logger.info('Open failed: ${e.error.name}');
        switch (e.error) {
          case EnvelopeError.wrongPassword:
            if (await _showWrongPasswordDialog() != 'try_again') return null;
            password = await _showPasswordDialog();
            if (password == null || password.isEmpty) return null;
          case EnvelopeError.expired:
            _showError('ttl expired');
            return null;
          default:
            _showError('message unreadable: wrong board key or corrupted data');
            return null;
        }
      }
    }
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
