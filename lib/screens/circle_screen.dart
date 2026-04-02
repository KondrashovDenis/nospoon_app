/// Экран круга — реальная лента посланий
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';
import '../transport/circles_storage.dart';
import '../transport/messenger.dart';
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

  @override
  void initState() {
    super.initState();
    _initMessenger();
  }

  Future<void> _initMessenger() async {
    try {
      _messenger = await SpoonMessenger.create();
      _loadFeed();
    } catch (e) {
      setState(() => _error = 'Messenger init error: $e');
    }
  }

  Future<void> _loadFeed() async {
    if (_messenger == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final messages = await _messenger!.receive(widget.circle.key);
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
      floatingActionButton: FloatingActionButton(
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
                style: GoogleFonts.vt323(color: colors.textDim, fontSize: 16),
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

    return GestureDetector(
      onTap: () => _openCeremony(msg),
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
                  Text(
                    msg.success
                        ? msg.text ?? 'tap to decode'
                        : 'tap to decode',
                    style: GoogleFonts.vt323(
                      color: colors.textDim,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    timeStr,
                    style: GoogleFonts.vt323(
                      color: colors.textDim,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCeremony(ReceivedMessage msg) async {
    if (_messenger == null) return;

    try {
      final binary = await _messenger!.ipfs.download(msg.cid);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CeremonyScreen(
              binary: binary,
              theme: widget.theme,
              cid: msg.cid,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'download error: $e',
              style: GoogleFonts.vt323(fontSize: 16),
            ),
            backgroundColor: AppTheme.getColors(widget.theme).dim,
          ),
        );
      }
    }
  }
}
