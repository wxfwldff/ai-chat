import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emotion_model.dart';
import 'emotion_engine.dart';

class Moment {
  final String id;
  final String characterId;
  final String content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final DateTime createdAt;

  Moment({
    required this.id,
    required this.characterId,
    required this.content,
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'characterId': characterId,
        'content': content,
        'imageUrl': imageUrl,
        'likes': likes,
        'comments': comments,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Moment.fromJson(Map<String, dynamic> json) => Moment(
        id: json['id'] ?? '',
        characterId: json['characterId'] ?? '',
        content: json['content'] ?? '',
        imageUrl: json['imageUrl'],
        likes: json['likes'] ?? 0,
        comments: json['comments'] ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class MomentsEngine extends ChangeNotifier {
  static const _key = 'moments_data';
  List<Moment> _moments = [];
  Function(Moment)? onNewMoment;

  List<Moment> get moments => List.unmodifiable(_moments);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _moments = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _moments = list.map((e) => Moment.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _moments = [];
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_moments.map((e) => e.toJson()).toList()));
  }

  /// 根据情绪生成朋友圈内容
  String _generateContentFromMood(String mood) {
    switch (mood) {
      case 'deeply_in_love':
        return '今天想到你了 💕 整个世界都变得温柔了。';
      case 'jealous':
        return '是不是把我忘了？😕 最近好像都不怎么理我。';
      case 'angry':
        return '心情不太好...别理我。😤';
      case 'longing':
        return '夜晚容易想太多。你在做什么呢？🌙';
      case 'attached':
        return '好想一直和你在一起。🍀';
      case 'distant':
        return '一个人也挺好的。😐';
      case 'affectionate':
        return '今天天气很好，心情也很好。因为有你。☀️';
      default:
        return '又是新的一天。🌅 早安。';
    }
  }

  /// 生成并发布一条朋友圈
  Future<Moment> generateMoment(EmotionModel emotion, String characterId) async {
    final mood = emotion.moodDescription;
    final content = _generateContentFromMood(mood);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final moment = Moment(
      id: id,
      characterId: characterId,
      content: content,
      likes: 0,
      comments: 0,
    );
    _moments.insert(0, moment);
    await _save();
    onNewMoment?.call(moment);
    notifyListeners();
    debugPrint('[MomentsEngine] New moment: $content');
    return moment;
  }

  /// 添加一条自定义朋友圈
  Future<Moment> addMoment({
    required String characterId,
    required String content,
    String? imageUrl,
  }) async {
    final moment = Moment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      characterId: characterId,
      content: content,
      imageUrl: imageUrl,
    );
    _moments.insert(0, moment);
    await _save();
    onNewMoment?.call(moment);
    notifyListeners();
    return moment;
  }

  Future<void> like(String momentId) async {
    final idx = _moments.indexWhere((m) => m.id == momentId);
    if (idx >= 0) {
      final old = _moments[idx];
      _moments[idx] = Moment(
        id: old.id,
        characterId: old.characterId,
        content: old.content,
        imageUrl: old.imageUrl,
        likes: old.likes + 1,
        comments: old.comments,
        createdAt: old.createdAt,
      );
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteMoment(String momentId) async {
    _moments.removeWhere((m) => m.id == momentId);
    await _save();
    notifyListeners();
  }
}
