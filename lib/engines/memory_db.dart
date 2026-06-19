import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 轻量级记忆隔离存储（使用 SharedPreferences 作为数据库，避免 sqflite 初始化问题）
/// 支持 Assistant / Companion 双模式隔离
class MemoryDB {
  final String _prefix;

  MemoryDB(this._prefix);

  // ===== 结构化记忆 =====
  Future<void> save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final fullKey = '${_prefix}_mem_$key';
    if (value is String) {
      await prefs.setString(fullKey, value);
    } else {
      await prefs.setString(fullKey, jsonEncode(value));
    }
  }

  Future<T?> load<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final fullKey = '${_prefix}_mem_$key';
    final raw = prefs.getString(fullKey);
    if (raw == null) return null;
    if (T == String) return raw as T;
    try {
      return jsonDecode(raw) as T;
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefix}_mem_$key');
  }

  // ===== 记忆条目管理 =====
  Future<List<Map<String, dynamic>>> getMemories() async {
    final raw = await load<String>('memories_list');
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> addMemory(Map<String, dynamic> memory) async {
    final list = await getMemories();
    list.add({
      ...memory,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    await save('memories_list', list);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('${_prefix}_mem_'));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
