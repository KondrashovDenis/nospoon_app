/// Экран написания послания
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/crt_effects.dart';
import '../transport/circles_storage.dart';

class ComposeScreen extends StatefulWidget {
  final Circle circle;
  final SpoonTheme theme;

  const ComposeScreen({
    super.key,
    required this.circle,
    required this.theme,
  });

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _textController = TextEditingController();
  final _passwordController = TextEditingController();
  String _ttl = '24h';
  bool _usePassword = false;
  bool _sending = false;

  final _ttlOptions = ['1h', '6h', '24h', '7d'];

  @override
  void dispose() {
    _textController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(widget.theme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: GlowText(
          '> COMPOSE',
          style: GoogleFonts.vt323(fontSize: 22, color: colors.primary),
          glowColor: colors.primary,
        ),
      ),
      body: CrtScreen(
        theme: widget.theme,
        scanlines: true,
        glow: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '> circle: ${widget.circle.name}',
                style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Поле текста
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: GoogleFonts.vt323(color: colors.text, fontSize: 20),
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: 'type your message_',
                    hintStyle: GoogleFonts.vt323(
                      color: colors.textDim,
                      fontSize: 20,
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // TTL выбор
              Text(
                '> TTL:',
                style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Row(
                children: _ttlOptions.map((ttl) {
                  final selected = _ttl == ttl;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _ttl = ttl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected ? colors.primary : colors.secondary,
                          ),
                          color: selected ? colors.dim : Colors.transparent,
                        ),
                        child: Text(
                          ttl,
                          style: GoogleFonts.vt323(
                            color: selected ? colors.primary : colors.textDim,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Пароль опционально
              Row(
                children: [
                  Checkbox(
                    value: _usePassword,
                    onChanged: (v) => setState(() => _usePassword = v ?? false),
                    activeColor: colors.primary,
                    checkColor: colors.background,
                  ),
                  Text(
                    'password',
                    style: GoogleFonts.vt323(color: colors.textDim, fontSize: 18),
                  ),
                ],
              ),
              if (_usePassword) ...[
                TextField(
                  controller: _passwordController,
                  style: GoogleFonts.vt323(color: colors.text, fontSize: 18),
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'enter password_',
                    hintStyle: GoogleFonts.vt323(
                      color: colors.textDim, fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Кнопка отправки
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: colors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ENCODING...',
                              style: GoogleFonts.vt323(fontSize: 20),
                            ),
                          ],
                        )
                      : Text('> SEND', style: GoogleFonts.vt323(fontSize: 22)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (_textController.text.isEmpty) return;

    setState(() => _sending = true);

    // TODO v1.4.0 — реальная отправка через SpoonMessenger
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _sending = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'message encoded. sending... (v1.4.0)',
            style: GoogleFonts.vt323(fontSize: 18),
          ),
          backgroundColor: AppTheme.getColors(widget.theme).dim,
        ),
      );
    }
  }
}
