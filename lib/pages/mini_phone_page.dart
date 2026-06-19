import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';

class MiniPhonePage extends StatelessWidget {
  const MiniPhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureItem(Icons.mic, '语音通话', Colors.purple),
      _FeatureItem(Icons.record_voice_over, 'TTS试听', Colors.blue),
      _FeatureItem(Icons.image, 'AI图片', Colors.green),
      _FeatureItem(Icons.camera_alt, '拍照', Colors.orange),
      _FeatureItem(Icons.games, '小游戏', Colors.pink),
      _FeatureItem(Icons.music_note, '音乐', Colors.teal),
      _FeatureItem(Icons.psychology, '冥想', Colors.indigo),
      _FeatureItem(Icons.wb_sunny, '天气', Colors.amber),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('小手机'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 顶部装饰
            GlassCard(
              blur: 20,
              opacity: 0.6,
              radius: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_iphone, size: 24),
                    SizedBox(width: 8),
                    Text('AI 功能中心', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 功能网格
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: features.length,
                itemBuilder: (context, i) => _buildFeatureCard(features[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return GlassCard(
      blur: 10,
      opacity: 0.5,
      radius: 16,
      child: InkWell(
        onTap: () {
          // TODO: 功能接入
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: feature.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(feature.icon, color: feature.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              feature.label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final Color color;
  _FeatureItem(this.icon, this.label, this.color);
}
