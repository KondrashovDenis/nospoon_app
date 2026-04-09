import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/sound_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpoonApp());
}

class SpoonApp extends StatefulWidget {
  const SpoonApp({super.key});

  @override
  State<SpoonApp> createState() => _SpoonAppState();
}

class _SpoonAppState extends State<SpoonApp> {
  SpoonTheme _theme = SpoonTheme.phosphorGreen;
  bool _scanlines = true;
  bool _glow = true;
  bool _flicker = false;
  bool _initialized = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await SoundService().init();
    await NotificationService.init();
    setState(() {
      _theme = SpoonTheme.values[prefs.getInt('theme') ?? 0];
      _scanlines = prefs.getBool('scanlines') ?? true;
      _glow = prefs.getBool('glow') ?? true;
      _flicker = prefs.getBool('flicker') ?? false;
      _showOnboarding = !(prefs.getBool('onboarding_done') ?? false);
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0D0D0D),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF00FF41)),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Spoon Messenger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(_theme),
      home: _showOnboarding
          ? OnboardingScreen(
              onComplete: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboarding_done', true);
                setState(() => _showOnboarding = false);
              },
            )
          : MainScreen(
        theme: _theme,
        scanlines: _scanlines,
        glow: _glow,
        flicker: _flicker,
        onThemeChanged: (t) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('theme', t.index);
          setState(() => _theme = t);
        },
        onScanlinesChanged: (v) => setState(() => _scanlines = v),
        onGlowChanged: (v) => setState(() => _glow = v),
        onFlickerChanged: (v) => setState(() => _flicker = v),
      ),
    );
  }
}
