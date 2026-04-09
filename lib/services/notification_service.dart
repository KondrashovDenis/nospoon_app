/// Локальные push-уведомления + фоновый polling
/// Workmanager работает только на Android/iOS, на десктопе — noop
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../transport/messenger.dart';
import '../transport/circles_storage.dart';

const _bgTaskName = 'nospoon_check_messages';
const _bgTaskUnique = 'nospoon_periodic_check';

bool get _isMobile => Platform.isAndroid || Platform.isIOS;

/// Вызывается из background isolate — workmanager callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _bgTaskName) {
      await NotificationService._checkNewMessages();
    }
    return true;
  });
}

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    if (!_isMobile) {
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
    _initialized = true;

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  /// Включить/выключить фоновый polling
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', enabled);

    if (!_isMobile) return;

    if (enabled) {
      await Workmanager().registerPeriodicTask(
        _bgTaskUnique,
        _bgTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    } else {
      await Workmanager().cancelByUniqueName(_bgTaskUnique);
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications') ?? false;
  }

  /// Проверка новых сообщений из background
  static Future<void> _checkNewMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('notifications') ?? false)) return;

      final circles = await CirclesStorage.getAll();
      if (circles.isEmpty) return;

      final messenger = await SpoonMessenger.create();

      for (final circle in circles) {
        try {
          final messages = await messenger.receive(circle.key);
          final lastChecked = prefs.getInt('last_check_${circle.key}') ?? 0;

          final newMessages = messages.where(
            (m) => m.publishedAt > lastChecked && m.success,
          ).toList();

          if (newMessages.isNotEmpty) {
            await _showNotification(
              circle.name,
              '${newMessages.length} new message${newMessages.length > 1 ? 's' : ''}',
              circle.key.hashCode,
            );
          }

          if (messages.isNotEmpty) {
            final latest = messages.map((m) => m.publishedAt).reduce(
              (a, b) => a > b ? a : b,
            );
            await prefs.setInt('last_check_${circle.key}', latest);
          }
        } catch (e) {
          debugPrint('Notification check error for ${circle.name}: $e');
        }
      }
    } catch (e) {
      debugPrint('Notification check error: $e');
    }
  }

  static Future<void> _showNotification(
    String title,
    String body,
    int id,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'nospoon_messages',
      'New Messages',
      channelDescription: 'Notifications for new spoon messages',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(id, '> $title', body, details);
  }
}
