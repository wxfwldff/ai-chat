import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'config.dart';

/// 统一API调用客户端 / 单例
class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;
  ApiClient._();

  final _config = AppConfig();

  // ========== 聊天补全 ==========
  Future<String> chat(String systemPrompt, List<Map<String, String>> messages,
      {double temperature = 0.7, int maxTokens = 1024}) async {
    final provider = _config.chatProvider;
    final apiKey = _config.chatApiKey;
    final apiUrl = _config.chatApiUrl;
    final model = _config.chatModel;
    final allMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];
    if (provider == 'openai' || provider == 'custom') {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': allMessages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      }
      throw HttpException('Chat error ${response.statusCode} ${response.body}');
    }
    throw UnsupportedError('Provider $provider not supported');
  }

  // ========== 流式聊天 ==========
  Stream<String> chatStream(
      String systemPrompt, List<Map<String, String>> messages,
      {double temperature = 0.7, int maxTokens = 1024}) async* {
    final apiKey = _config.chatApiKey;
    final apiUrl = _config.chatApiUrl;
    final model = _config.chatModel;
    final allMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];
    final request = http.Request('POST', Uri.parse(apiUrl));
    request.headers.addAll({
      'Content-Type': 'application/json',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    });
    request.body = jsonEncode({
      'model': model,
      'messages': allMessages,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    });
    final client = http.Client();
    final response = await client.send(request);
    final lines =
        response.stream.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;
        if (data.isEmpty) continue;
        try {
          final chunk = jsonDecode(data);
          final content = chunk['choices'][0]['delta']['content'] ?? '';
          if (content.isNotEmpty) yield content;
        } catch (_) {}
      }
    }
    client.close();
  }

  // ========== 图片生成 ==========
  Future<List<String>> generateImages(String prompt, {int count = 1}) async {
    final apiKey = _config.imageApiKey;
    final apiUrl = _config.imageApiUrl;
    final model = _config.imageModel;
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'prompt': prompt,
        'n': count,
        'size': '1024x1024',
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List).map<String>((e) => (e['url'] ?? '') as String).toList();
    }
    throw HttpException('Image error ${response.statusCode} ${response.body}');
  }

  // ========== TTS 语音合成 ==========
  Future<Uint8List> textToSpeech(String text) async {
    final apiKey = _config.ttsApiKey;
    final apiUrl = _config.ttsApiUrl;
    final model = _config.ttsModel;
    final voice = _config.ttsVoice;
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'input': text,
        'voice': voice,
      }),
    );
    if (response.statusCode == 200) return response.bodyBytes;
    throw HttpException('TTS error ${response.statusCode} ${response.body}');
  }
}
