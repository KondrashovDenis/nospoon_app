// Локальное хранилище ключей кругов
// Использует shared_preferences

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class Circle {
  final String key;
  final String name;
  final DateTime createdAt;

  Circle({
    required this.key,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Circle.fromJson(Map<String, dynamic> json) => Circle(
    key: json['key'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class CirclesStorage {
  static const String _storageKey = 'circles';

  /// Получить все круги
  static Future<List<Circle>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    return list.map((e) => Circle.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Добавить круг
  static Future<void> add(Circle circle) async {
    final circles = await getAll();
    circles.add(circle);
    await _save(circles);
  }

  /// Удалить круг по ключу
  static Future<void> remove(String key) async {
    final circles = await getAll();
    circles.removeWhere((c) => c.key == key);
    await _save(circles);
  }

  /// Создать новый круг с случайным ключом
  static Future<Circle> create(String name) async {
    final key = _generateKey();
    final circle = Circle(
      key: key,
      name: name,
      createdAt: DateTime.now(),
    );
    await add(circle);
    return circle;
  }

  /// Вступить в существующий круг
  static Future<Circle> join(String key, String name) async {
    final circle = Circle(
      key: key,
      name: name,
      createdAt: DateTime.now(),
    );
    await add(circle);
    return circle;
  }

  static Future<void> _save(List<Circle> circles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(circles.map((c) => c.toJson()).toList()),
    );
  }

  static String _generateKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
