
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局配置：API 密钥、供应商选择、角色配置
class AppConfig extends ChangeNotifier {
  static final AppConfig _instance = AppConfig._();
  factory AppConfig() => _instance;
  AppConfig._();

  // ========== API 供应商配置 ==========
  String _chatProvider = 'openai'; // openai / claude / custom
  String _chatApiKey = '';
  String _chatApiUrl = 'https://api.openai.com/v1/chat/completions';
  String _chatModel = 'gpt-4o-mini';

  String _imageProvider = 'openai'; // openai / stable diffusion / custom
  String _imageApiKey = '';
  String _imageApiUrl = 'https://api.openai.com/v1/images/generations';
  String _imageModel = 'dall-e-3';

  String _ttsProvider = 'openai'; // openai / edge / custom
  String _ttsApiKey = '';
  String _ttsApiUrl = 'https://api.openai.com/v1/audio/speech';
  String _ttsModel = 'tts-1';
  String _ttsVoice = 'alloy';

  // ========== Getters ==========
  String get chatProvider => _chatProvider;
  String get chatApiKey => _chatApiKey;
  String get chatApiUrl => _chatApiUrl;
  String get chatModel => _chatModel;
  String get imageProvider => _imageProvider;
  String get imageApiKey => _imageApiKey;
  String get imageApiUrl => _imageApiUrl;
  String get imageModel => _imageModel;
  String get ttsProvider => _ttsProvider;
  String get ttsApiKey => _ttsApiKey;
  String get ttsApiUrl => _ttsApiUrl;
  String get ttsModel => _ttsModel;
  String get ttsVoice => _ttsVoice;

  // ========== Setters ==========
  set chatProvider(String v) { _chatProvider = v; notifyListeners(); save(); }
  set chatApiKey(String v) { _chatApiKey = v; notifyListeners(); save(); }
  set chatApiUrl(String v) { _chatApiUrl = v; notifyListeners(); save(); }
  set chatModel(String v) { _chatModel = v; notifyListeners(); save(); }
  set imageProvider(String v) { _imageProvider = v; notifyListeners(); save(); }
  set imageApiKey(String v) { _imageApiKey = v; notifyListeners(); save(); }
  set imageApiUrl(String v) { _imageApiUrl = v; notifyListeners(); save(); }
  set imageModel(String v) { _imageModel = v; notifyListeners(); save(); }
  set ttsProvider(String v) { _ttsProvider = v; notifyListeners(); save(); }
  set ttsApiKey(String v) { _ttsApiKey = v; notifyListeners(); save(); }
  set ttsApiUrl(String v) { _ttsApiUrl = v; notifyListeners(); save(); }
  set ttsModel(String v) { _ttsModel = v; notifyListeners(); save(); }
  set ttsVoice(String v) { _ttsVoice = v; notifyListeners(); save(); }

  // ========== 角色配置 ==========
  String _characterName = '小晴';
  String _characterEmoji = '🌸';
  String _characterPersonality = '温柔体贴，善解人意';
  String _characterBackground = '一个善良的虚拟伙伴';

  String get characterName => _characterName;
  String get characterEmoji => _characterEmoji;
  String get characterPersonality => _characterPersonality;
  String get characterBackground => _characterBackground;

  set characterName(String v) { _characterName = v; notifyListeners(); save(); }
  set characterEmoji(String v) { _characterEmoji = v; notifyListeners(); save(); }
  set characterPersonality(String v) { _characterPersonality = v; notifyListeners(); save(); }
  set characterBackground(String v) { _characterBackground = v; notifyListeners(); save(); }

  // ========== 持久化 ==========
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _chatProvider = prefs.getString('chat_provider') ?? 'openai';
    _chatApiKey = prefs.getString('chat_api_key') ?? '';
    _chatApiUrl = prefs.getString('chat_api_url') ?? 'https://api.openai.com/v1/chat/completions';
    _chatModel = prefs.getString('chat_model') ?? 'gpt-4o-mini';
    _imageProvider = prefs.getString('image_provider') ?? 'openai';
    _imageApiKey = prefs.getString('image_api_key') ?? '';
    _imageApiUrl = prefs.getString('image_api_url') ?? 'https://api.openai.com/v1/images/generations';
    _imageModel = prefs.getString('image_model') ?? 'dall-e-3';
    _ttsProvider = prefs.getString('tts_provider') ?? 'openai';
    _ttsApiKey = prefs.getString('tts_api_key') ?? '';
    _ttsApiUrl = prefs.getString('tts_api_url') ?? 'https://api.openai.com/v1/audio/speech';
    _ttsModel = prefs.getString('tts_model') ?? 'tts-1';
    _ttsVoice = prefs.getString('tts_voice') ?? 'alloy';
    _characterName = prefs.getString('char_name') ?? '小晴';
    _characterEmoji = prefs.getString('char_emoji') ?? '🌸';
    _characterPersonality = prefs.getString('char_personality') ?? '温柔体贴，善解人意';
    _characterBackground = prefs.getString('char_background') ?? '一个善良的虚拟伙伴';
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_provider', _chatProvider);
    await prefs.setString('chat_api_key', _chatApiKey);
    await prefs.setString('chat_api_url', _chatApiUrl);
    await prefs.setString('chat_model', _chatModel);
    await prefs.setString('image_provider', _imageProvider);
    await prefs.setString('image_api_key', _imageApiKey);
    await prefs.setString('image_api_url', _imageApiUrl);
    await prefs.setString('image_model', _imageModel);
    await prefs.setString('tts_provider', _ttsProvider);
    await prefs.setString('tts_api_key', _ttsApiKey);
    await prefs.setString('tts_api_url', _ttsApiUrl);
    await prefs.setString('tts_model', _ttsModel);
    await prefs.setString('tts_voice', _ttsVoice);
    await prefs.setString('char_name', _characterName);
    await prefs.setString('char_emoji', _characterEmoji);
    await prefs.setString('char_personality', _characterPersonality);
    await prefs.setString('char_background', _characterBackground);
  }
}
