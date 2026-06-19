import 'dart:async';
import 'package:flutter/foundation.dart';
import 'emotion_engine.dart';

/// 主动行为引擎 - 根据情绪自动触发角色主动消息
class ProactiveEngine extends ChangeNotifier {
  final EmotionEngine _emotion;
  final Function(String type) _onProactive;
  Timer? _timer;
  bool _running = false;

  ProactiveEngine(this._emotion, this._onProactive);

  bool get running => _running;

  void start({Duration interval = const Duration(minutes: 5)}) {
    if (_running) return;
    _running = true;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _checkAndTrigger());
    debugPrint('[ProactiveEngine] Started (interval: ${interval.inMinutes}min)');
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    debugPrint('[ProactiveEngine] Stopped');
  }

  void _checkAndTrigger() {
    if (!_emotion.shouldProactive()) return;
    final type = _emotion.proactiveType;
    debugPrint('[ProactiveEngine] Triggered: $type');
    _onProactive(type);
  }

  /// 手动触发一次检测
  void checkNow() => _checkAndTrigger();

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
