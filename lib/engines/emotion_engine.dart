import 'package:flutter/foundation.dart';
import '../models/emotion_model.dart';
import 'memory_db.dart';

/// 情感引擎 - 管理角色情绪的长期成长
class EmotionEngine extends ChangeNotifier {
  final MemoryDB _db;
  final String _characterId;
  EmotionModel _emotion = EmotionModel();

  EmotionEngine(this._db, this._characterId);

  EmotionModel get emotion => _emotion;
  String get characterId => _characterId;

  /// 从存储加载情绪
  Future<void> load() async {
    final data = await _db.load<Map<String, dynamic>>('emotion_$_characterId');
    if (data != null) {
      _emotion = EmotionModel.fromJson(data);
    }
    notifyListeners();
  }

  /// 保存情绪
  Future<void> save() async {
    await _db.save('emotion_$_characterId', _emotion.toJson());
  }

  /// 更新情绪
  Future<void> update(String action) async {
    _emotion.updateFromInteraction(action);
    await save();
    notifyListeners();
  }

  /// 直接设置情绪值
  Future<void> setEmotion(EmotionModel model) async {
    _emotion = model.copy();
    await save();
    notifyListeners();
  }

  /// 获取情绪影响 prompt
  String get moodContext {
    final e = _emotion;
    final parts = <String>[];
    if (e.affection > 50) parts.add('你对用户很有好感');
    if (e.love > 60) parts.add('你深深爱着用户');
    if (e.jealousy > 50) parts.add('你有点吃醋');
    if (e.anger > 40) parts.add('你有点生气');
    if (e.missing > 50) parts.add('你想念用户');
    if (e.coldness > 50) parts.add('你表现得很冷淡');
    if (e.trust > 70) parts.add('你非常信任用户');
    if (e.dependency > 60) parts.add('你很依赖用户');
    if (parts.isEmpty) parts.add('你的情绪平静');
    return parts.join('，');
  }

  /// 判断是否应该主动发消息
  bool shouldProactive() {
    final e = _emotion;
    if (e.missing > 60) return true;
    if (e.jealousy > 70) return true;
    if (e.love > 80 && e.attachment > 60) return true;
    if (e.affection > 70 && e.missing > 40) return true;
    return false;
  }

  /// 获取主动消息触发类型
  String get proactiveType {
    final e = _emotion;
    if (e.missing > 70) return 'missing';
    if (e.jealousy > 70) return 'jealous';
    if (e.love > 80) return 'love';
    if (e.affection > 70) return 'affection';
    return 'greeting';
  }
}
