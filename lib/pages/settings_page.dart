import 'package:flutter/material.dart';
import '../core/config.dart';
import '../engines/emotion_engine.dart';
import '../engines/memory_db.dart';
import '../widgets/glass_card.dart';

class SettingsPage extends StatefulWidget {
  final bool isCompanionMode;
  final Function(bool) onModeChanged;
  final EmotionEngine emotion;

  const SettingsPage({
    super.key,
    required this.isCompanionMode,
    required this.onModeChanged,
    required this.emotion,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _config = AppConfig();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 模式切换
          GlassCard(
            blur: 12,
            opacity: 0.6,
            radius: 16,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI模式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('助手模式'), icon: Icon(Icons.smart_toy)),
                      ButtonSegment(value: true, label: Text('陪伴模式'), icon: Icon(Icons.favorite)),
                    ],
                    selected: {widget.isCompanionMode},
                    onSelectionChanged: (v) => widget.onModeChanged(v.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // API配置
          GlassCard(
            blur: 12,
            opacity: 0.6,
            radius: 16,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('API配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    Icons.link,
                    'Chat API URL',
                    _config.chatApiUrl.replaceAll(RegExp(r'https?://'), '').substring(0, 20),
                    () => _editConfig('Chat API地址', _config.chatApiUrl, (v) => _config.chatApiUrl = v),
                  ),
                  const Divider(),
                  _buildSettingItem(
                    Icons.model_training,
                    '模型',
                    _config.chatModel,
                    () => _editConfig('模型名', _config.chatModel, (v) => _config.chatModel = v),
                  ),
                  const Divider(),
                  _buildSettingItem(
                    Icons.key,
                    'API Key',
                    '${_config.chatApiKey.substring(0, 8)}...',
                    () => _editConfig('API Key', _config.chatApiKey, (v) => _config.chatApiKey = v, obscure: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 情绪状态
          if (widget.isCompanionMode) ...[
            GlassCard(
              blur: 12,
              opacity: 0.6,
              radius: 16,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('情绪状态', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _buildEmotionBar('好感度', widget.emotion.emotion.affection, Colors.pink),
                    _buildEmotionBar('爱意', widget.emotion.emotion.love, Colors.red),
                    _buildEmotionBar('信任', widget.emotion.emotion.trust, Colors.blue),
                    _buildEmotionBar('吃醋', widget.emotion.emotion.jealousy, Colors.orange),
                    _buildEmotionBar('依赖', widget.emotion.emotion.dependency, Colors.purple),
                    _buildEmotionBar('生气', widget.emotion.emotion.anger, Colors.redAccent),
                    _buildEmotionBar('冷淡', widget.emotion.emotion.coldness, Colors.grey),
                    _buildEmotionBar('依恋', widget.emotion.emotion.attachment, Colors.teal),
                    _buildEmotionBar('想念', widget.emotion.emotion.missing, Colors.indigo),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[400]), maxLines: 1),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionBar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100.0,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 24, child: Text('$value', style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
        ],
      ),
    );
  }

  void _editConfig(String title, String currentValue, Function(String) onSave, {bool obscure = false}) {
    final ctrl = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              onSave(ctrl.text);
              _config.save();
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
