import 'package:flutter/material.dart';
import '../engines/moments_engine.dart';
import '../engines/emotion_engine.dart';
import '../widgets/glass_card.dart';

class MomentsPage extends StatefulWidget {
  final MomentsEngine momentsEngine;
  final EmotionEngine emotion;
  final String characterId;

  const MomentsPage({
    super.key,
    required this.momentsEngine,
    required this.emotion,
    required this.characterId,
  });

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  @override
  void initState() {
    super.initState();
    widget.momentsEngine.addListener(_onMomentsChanged);
  }

  @override
  void dispose() {
    widget.momentsEngine.removeListener(_onMomentsChanged);
    super.dispose();
  }

  void _onMomentsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final moments = widget.momentsEngine.moments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('朋友圈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showNewMomentDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _generateMoment(),
            tooltip: 'AI自动生成',
          ),
        ],
      ),
      body: moments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('还没有朋友圈动态', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('让AI发一条'),
                    onPressed: _generateMoment,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: moments.length,
              itemBuilder: (context, i) {
                final moment = moments[i];
                return _buildMomentCard(moment);
              },
            ),
    );
  }

  Widget _buildMomentCard(dynamic moment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        blur: 15,
        opacity: 0.7,
        radius: 16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.pink.withOpacity(0.1),
                    child: Text(widget.emotion.characterId[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('小晴', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          _formatTime(moment.createdAt),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(moment.content, style: const TextStyle(fontSize: 15, height: 1.5)),
              if (moment.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    moment.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: Text('图片加载失败')),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.favorite_border, size: 18),
                    onPressed: () => widget.momentsEngine.like(moment.id),
                  ),
                  Text('${moment.likes}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${moment.comments}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                    onPressed: () => widget.momentsEngine.deleteMoment(moment.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateMoment() async {
    await widget.momentsEngine.generateMoment(
      widget.emotion.emotion,
      widget.characterId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI已发布新动态'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _showNewMomentDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('发布新动态'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '说点什么...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await widget.momentsEngine.addMoment(
                  characterId: widget.characterId,
                  content: ctrl.text.trim(),
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('发布'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }
}
