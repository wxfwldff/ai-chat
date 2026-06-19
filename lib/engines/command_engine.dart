import 'dart:convert';
import 'package:flutter/foundation.dart';

/// AI命令解析与执行引擎
/// 允许AI通过自然语言指令动态修改UI风格
class CommandEngine extends ChangeNotifier {
  // UI 可配置属性
  String _themeColor = '#2196F3';
  double _fontSize = 16.0;
  String _fontColor = '#000000';
  bool _glassEffect = true;
  double _glassBlur = 20.0;
  double _glassOpacity = 0.6;
  double _glassRadius = 16.0;

  // Getters
  String get themeColor => _themeColor;
  double get fontSize => _fontSize;
  String get fontColor => _fontColor;
  bool get glassEffect => _glassEffect;
  double get glassBlur => _glassBlur;
  double get glassOpacity => _glassOpacity;
  double get glassRadius => _glassRadius;

  // Setters
  set themeColor(String v) { _themeColor = v; notifyListeners(); }
  set fontSize(double v) { _fontSize = v.clamp(12.0, 24.0); notifyListeners(); }
  set fontColor(String v) { _fontColor = v; notifyListeners(); }
  set glassEffect(bool v) { _glassEffect = v; notifyListeners(); }
  set glassBlur(double v) { _glassBlur = v.clamp(5.0, 50.0); notifyListeners(); }
  set glassOpacity(double v) { _glassOpacity = v.clamp(0.2, 1.0); notifyListeners(); }
  set glassRadius(double v) { _glassRadius = v.clamp(4.0, 32.0); notifyListeners(); }

  /// 解析并执行AI命令
  String execute(String command) {
    final cmd = command.toLowerCase().trim();
    debugPrint('[CommandEngine] Executing: $cmd');

    // 改主题颜色
    final colorMatch = RegExp(r'(主题|颜色|颜色改成|改成|变为)\s*(#[0-9a-fA-F]{6}|[赤橙黄绿青蓝紫黑白红绿蓝])').firstMatch(cmd);
    if (colorMatch != null) {
      final colorStr = colorMatch.group(2)!;
      final mapped = _mapColorName(colorStr);
      _themeColor = mapped;
      notifyListeners();
      return '已将主题颜色改为 ${mapped}';
    }

    // 字体大小
    final fontSizeMatch = RegExp(r'(字体大小|字号|字体)\s*([0-9]+)').firstMatch(cmd);
    if (fontSizeMatch != null) {
      final size = double.tryParse(fontSizeMatch.group(2)!) ?? 16;
      _fontSize = size.clamp(12.0, 24.0);
      notifyListeners();
      return '已将字体大小设为 ${_fontSize.toStringAsFixed(0)}';
    }

    // 玻璃效果开关
    if (cmd.contains('玻璃') || cmd.contains('毛玻璃') || cmd.contains('透明')) {
      if (cmd.contains('开') || cmd.contains('启用') || cmd.contains('显示')) {
        _glassEffect = true;
        notifyListeners();
        return '已开启玻璃效果';
      } else if (cmd.contains('关') || cmd.contains('禁用') || cmd.contains('隐藏')) {
        _glassEffect = false;
        notifyListeners();
        return '已关闭玻璃效果';
      }
    }

    // 玻璃模糊强度
    final blurMatch = RegExp(r'(模糊|模糊强度|blur)\s*([0-9]+)').firstMatch(cmd);
    if (blurMatch != null) {
      final blur = double.tryParse(blurMatch.group(2)!) ?? 20;
      _glassBlur = blur.clamp(5.0, 50.0);
      notifyListeners();
      return '已将玻璃模糊强度设为 ${_glassBlur.toStringAsFixed(0)}';
    }

    return '无法识别的命令，请尝试：\n- 改主题颜色 #FF0000\n- 字体大小 18\n- 开/关玻璃效果\n- 模糊强度 30';
  }

  String _mapColorName(String name) {
    const map = {
      '红': '#FF0000', 'red': '#FF0000',
      '绿': '#4CAF50', 'green': '#4CAF50',
      '蓝': '#2196F3', 'blue': '#2196F3',
      '黄': '#FFEB3B', 'yellow': '#FFEB3B',
      '紫': '#9C27B0', 'purple': '#9C27B0',
      '橙': '#FF9800', 'orange': '#FF9800',
      '黑': '#000000', 'black': '#000000',
      '白': '#FFFFFF', 'white': '#FFFFFF',
      '粉': '#E91E63', 'pink': '#E91E63',
      '青': '#00BCD4', 'cyan': '#00BCD4',
    };
    return map[name] ?? name;
  }

  Map<String, dynamic> toJson() => {
        'themeColor': _themeColor,
        'fontSize': _fontSize,
        'fontColor': _fontColor,
        'glassEffect': _glassEffect,
        'glassBlur': _glassBlur,
        'glassOpacity': _glassOpacity,
        'glassRadius': _glassRadius,
      };
}
