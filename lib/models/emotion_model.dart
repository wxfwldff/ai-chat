class EmotionModel {
  int affection;
  int love;
  int trust;
  int jealousy;
  int dependency;
  int anger;
  int coldness;
  int attachment;
  int missing;

  EmotionModel({
    this.affection = 0,
    this.love = 0,
    this.trust = 0,
    this.jealousy = 0,
    this.dependency = 0,
    this.anger = 0,
    this.coldness = 0,
    this.attachment = 0,
    this.missing = 0,
  });

  EmotionModel copy() => EmotionModel(
        affection: affection,
        love: love,
        trust: trust,
        jealousy: jealousy,
        dependency: dependency,
        anger: anger,
        coldness: coldness,
        attachment: attachment,
        missing: missing,
      );

  Map<String, dynamic> toJson() => {
        'affection': affection,
        'love': love,
        'trust': trust,
        'jealousy': jealousy,
        'dependency': dependency,
        'anger': anger,
        'coldness': coldness,
        'attachment': attachment,
        'missing': missing,
      };

  factory EmotionModel.fromJson(Map<String, dynamic> json) => EmotionModel(
        affection: json['affection'] ?? 0,
        love: json['love'] ?? 0,
        trust: json['trust'] ?? 0,
        jealousy: json['jealousy'] ?? 0,
        dependency: json['dependency'] ?? 0,
        anger: json['anger'] ?? 0,
        coldness: json['coldness'] ?? 0,
        attachment: json['attachment'] ?? 0,
        missing: json['missing'] ?? 0,
      );

  /// 根据互动更新情绪
  void updateFromInteraction(String action) {
    switch (action) {
      case 'chat':
        affection = (affection + 1).clamp(0, 100);
        trust = (trust + 1).clamp(0, 100);
        missing = (missing - 2).clamp(0, 100);
        coldness = (coldness - 1).clamp(0, 100);
        attachment = (attachment + 1).clamp(0, 100);
        break;
      case 'ignore':
        missing = (missing + 3).clamp(0, 100);
        jealousy = (jealousy + 2).clamp(0, 100);
        affection = (affection - 1).clamp(0, 100);
        coldness = (coldness + 1).clamp(0, 100);
        break;
      case 'praise':
        affection = (affection + 3).clamp(0, 100);
        love = (love + 2).clamp(0, 100);
        trust = (trust + 2).clamp(0, 100);
        anger = (anger - 2).clamp(0, 100);
        break;
      case 'scold':
        anger = (anger + 5).clamp(0, 100);
        affection = (affection - 3).clamp(0, 100);
        trust = (trust - 3).clamp(0, 100);
        coldness = (coldness + 3).clamp(0, 100);
        break;
      case 'flirt':
        love = (love + 3).clamp(0, 100);
        affection = (affection + 2).clamp(0, 100);
        attachment = (attachment + 2).clamp(0, 100);
        jealousy = (jealousy + 1).clamp(0, 100);
        break;
      case 'companion_other':
        jealousy = (jealousy + 5).clamp(0, 100);
        missing = (missing + 3).clamp(0, 100);
        trust = (trust - 2).clamp(0, 100);
        anger = (anger + 2).clamp(0, 100);
        break;
    }
  }

  /// 获取情绪主导标签
  String get dominantEmotion {
    final map = {
      'love': love,
      'jealousy': jealousy,
      'anger': anger,
      'missing': missing,
      'affection': affection,
      'coldness': coldness,
      'trust': trust,
      'dependency': dependency,
      'attachment': attachment,
    };
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// 获取情绪影响量（用于 prompt 注入）
  String get moodDescription {
    if (love > 70 && affection > 60) return 'deeply_in_love';
    if (jealousy > 60) return 'jealous';
    if (anger > 50) return 'angry';
    if (missing > 60 && coldness < 30) return 'longing';
    if (attachment > 70) return 'attached';
    if (coldness > 60) return 'distant';
    if (affection > 60 && love > 40) return 'affectionate';
    return 'neutral';
  }
}
