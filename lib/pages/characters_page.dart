import 'package:flutter/material.dart';
import '../core/character_store.dart';
import '../engines/emotion_engine.dart';
import '../engines/memory_db.dart';
import '../widgets/glass_card.dart';

class CharactersPage extends StatefulWidget {
  final EmotionEngine emotion;
  final MemoryDB companionDB;

  const CharactersPage({
    super.key,
    required this.emotion,
    required this.companionDB,
  });

  @override
  State<CharactersPage> createState() => _CharactersPageState();
}

class _CharactersPageState extends State<CharactersPage> {
  final _store = CharacterStore();
  List<CharacterInfo> _characters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chars = await _store.loadAll();
    setState(() {
      _characters = chars;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('角色管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _characters.isEmpty
              ? const Center(child: Text('还没有角色，点击右上角添加'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _characters.length,
                  itemBuilder: (context, i) => _buildCharacterCard(_characters[i]),
                ),
    );
  }

  Widget _buildCharacterCard(CharacterInfo char) {
    final isDefault = char.id == 'default';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        blur: 12,
        opacity: 0.7,
        radius: 16,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isDefault ? Colors.blue.withOpacity(0.1) : Colors.pink.withOpacity(0.1),
            child: Text(char.name[0], style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDefault ? Colors.blue : Colors.pink,
            )),
          ),
          title: Text(char.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(char.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('编辑')),
              if (!isDefault) const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
            ],
            onSelected: (v) {
              if (v == 'edit') _showEditDialog(char);
              if (v == 'delete') _deleteChar(char);
            },
          ),
          onTap: isDefault ? null : () => _selectCharacter(char),
        ),
      ),
    );
  }

  Future<void> _selectCharacter(CharacterInfo char) async {
    // 切换角色
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换到 ${char.name}'), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _deleteChar(CharacterInfo char) async {
    await _store.delete(char.id);
    _load();
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final promptCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加角色'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '角色名称', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: promptCtrl, decoration: const InputDecoration(labelText: '系统提示词', border: OutlineInputBorder()), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                await _store.add(CharacterInfo(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  systemPrompt: promptCtrl.text.trim(),
                ));
                _load();
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(CharacterInfo char) {
    final nameCtrl = TextEditingController(text: char.name);
    final descCtrl = TextEditingController(text: char.description);
    final promptCtrl = TextEditingController(text: char.systemPrompt);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑角色'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '角色名称', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: promptCtrl, decoration: const InputDecoration(labelText: '系统提示词', border: OutlineInputBorder()), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await _store.update(CharacterInfo(
                id: char.id,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                systemPrompt: promptCtrl.text.trim(),
              ));
              _load();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
