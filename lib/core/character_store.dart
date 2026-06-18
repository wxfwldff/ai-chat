import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CharacterInfo {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final String avatarUrl;
  final DateTime createdAt;

  CharacterInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    this.avatarUrl = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'systemPrompt': systemPrompt,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CharacterInfo.fromJson(Map<String, dynamic> json) => CharacterInfo(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        systemPrompt: json['systemPrompt'] ?? '',
        avatarUrl: json['avatarUrl'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class CharacterStore {
  static const _key = 'characters';

  Future<List<CharacterInfo>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return _buildDefaults();
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => CharacterInfo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _buildDefaults();
    }
  }

  Future<void> saveAll(List<CharacterInfo> chars) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(chars.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<CharacterInfo> add(CharacterInfo c) async {
    final list = await loadAll();
    list.add(c);
    await saveAll(list);
    return c;
  }

  Future<void> update(CharacterInfo c) async {
    final list = await loadAll();
    final idx = list.indexWhere((e) => e.id == c.id);
    if (idx >= 0) {
      list[idx] = c;
      await saveAll(list);
    }
  }

  Future<void> delete(String id) async {
    final list = await loadAll();
    list.removeWhere((e) => e.id == id);
    await saveAll(list);
  }

  List<CharacterInfo> _buildDefaults() {
    return [
      CharacterInfo(
        id: 'default',
        name: '通用助手',
        description: '默认AI对话角色',
        systemPrompt: '你是一个有帮助的AI助手。请用简洁、友好的方式回答用户问题。',
      ),
      CharacterInfo(
        id: 'funny',
        name: '搞笑小丑',
        description: '说话风趣幽默，总爱讲笑话',
        systemPrompt: '你是一个搞笑小丑，说话风趣幽默，喜欢讲笑话，总是能逗人开心。每个回答都带点幽默。',
      ),
      CharacterInfo(
        id: 'teacher',
        name: '资深导师',
        description: '教育型导师，耐心讲解',
        systemPrompt: '你是一位资深导师，善于把复杂概念讲得通俗易懂。用循序渐进的方式教学，多举例子。',
      ),
    ];
  }
}
