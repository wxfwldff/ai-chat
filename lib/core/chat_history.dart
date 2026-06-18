import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String role; // 'user' / 'assistant'
  final String content;
  final DateTime time;
  final String? imageUrl;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? time,
    this.imageUrl,
  }) : time = time ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'time': time.toIso8601String(),
        'imageUrl': imageUrl,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] ?? 'user',
        content: json['content'] ?? '',
        time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
        imageUrl: json['imageUrl'],
      );
}

class ChatThread {
  final String id;
  final String characterId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatThread({
    required this.id,
    required this.characterId,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'characterId': characterId,
        'messages': messages.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'] ?? '',
        characterId: json['characterId'] ?? 'default',
        messages: (json['messages'] as List?)
                ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );
}

class ChatHistoryStore {
  static const _key = 'chat_threads';

  Future<List<ChatThread>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ChatThread.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<ChatThread> threads) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(threads.map((e) => e.toJson()).toList()));
  }

  Future<ChatThread> create(String characterId) async {
    final threads = await loadAll();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final thread = ChatThread(id: id, characterId: characterId);
    threads.add(thread);
    await _saveAll(threads);
    return thread;
  }

  Future<void> addMessage(String threadId, ChatMessage msg) async {
    final threads = await loadAll();
    final idx = threads.indexWhere((t) => t.id == threadId);
    if (idx >= 0) {
      threads[idx].messages.add(msg);
      threads[idx] = ChatThread(
        id: threads[idx].id,
        characterId: threads[idx].characterId,
        messages: threads[idx].messages,
        createdAt: threads[idx].createdAt,
        updatedAt: DateTime.now(),
      );
      await _saveAll(threads);
    }
  }

  Future<void> deleteThread(String threadId) async {
    final threads = await loadAll();
    threads.removeWhere((t) => t.id == threadId);
    await _saveAll(threads);
  }
}
