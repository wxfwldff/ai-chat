import 'dart:async';
import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/api_client.dart';
import '../core/chat_history.dart';
import '../core/character_store.dart';
import '../engines/emotion_engine.dart';
import '../engines/memory_db.dart';
import '../engines/proactive_engine.dart';
import '../engines/command_engine.dart';
import '../widgets/glass_card.dart';

class ChatPage extends StatefulWidget {
  final bool isCompanionMode;
  final EmotionEngine emotion;
  final MemoryDB assistantDB;
  final MemoryDB companionDB;
  final CommandEngine command;

  const ChatPage({
    super.key,
    required this.isCompanionMode,
    required this.emotion,
    required this.assistantDB,
    required this.companionDB,
    required this.command,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _client = ApiClient();
  final _charStore = CharacterStore();
  final _history = ChatHistoryStore();

  List<ChatMessage> _messages = [];
  ChatThread? _currentThread;
  CharacterInfo? _currentChar;
  bool _streaming = false;
  String _streamBuffer = '';
  late ProactiveEngine _proactive;
  Timer? _idleTimer;
  bool _isIdle = false;

  @override
  void initState() {
    super.initState();
    _proactive = ProactiveEngine(widget.emotion, _onProactive);
    _initChat();
    if (widget.isCompanionMode) {
      _proactive.start(interval: const Duration(minutes: 3));
      _startIdleDetection();
    }
  }

  void _startIdleDetection() {
    _idleTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!_streaming && _messages.isNotEmpty) {
        final lastMsg = _messages.last;
        final idle = DateTime.now().difference(lastMsg.time).inMinutes;
        if (idle > 5 && !_isIdle) {
          _isIdle = true;
          // Idle too long, update emotion
          widget.emotion.update('ignore');
        }
      }
    });
  }

  void _onProactive(String type) {
    if (!mounted || _streaming) return;
    String msg;
    switch (type) {
      case 'missing':
        msg = '你在做什么呀？我有点想你了...🥺';
        break;
      case 'jealous':
        msg = '你是不是在陪别人？我有点不开心...😕';
        break;
      case 'love':
        msg = '今天想到你了好多次呢 💕 你在干嘛？';
        break;
      case 'affection':
        msg = '今天心情特别好，因为有你在我身边~ ☀️';
        break;
      default:
        msg = '嗨~ 在忙什么呀？😊';
    }
    setState(() {
      _messages.add(ChatMessage(role: 'assistant', content: msg));
      _scrollToBottom();
    });
    widget.emotion.update('chat');
  }

  Future<void> _initChat() async {
    final chars = await _charStore.loadAll();
    if (chars.isNotEmpty) {
      setState(() => _currentChar = chars.first);
    }
    if (_currentChar != null) {
      final threads = await _history.loadAll();
      final existing = threads.where((t) => t.characterId == _currentChar!.id).toList();
      if (existing.isNotEmpty) {
        _currentThread = existing.first;
        setState(() => _messages = existing.first.messages);
      } else {
        _currentThread = await _history.create(_currentChar!.id);
      }
    }
    if (widget.isCompanionMode && _messages.isEmpty) {
      // 首次见面问候
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: '你好呀！我是${_currentChar?.name ?? '小晴'}，很高兴认识你~ 🌸'));
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _streaming) return;

    _msgCtrl.clear();
    _isIdle = false;

    // 检查是否是 UI 命令
    if (text.startsWith('/cmd ')) {
      final result = widget.command.execute(text.substring(5));
      setState(() {
        _messages.add(ChatMessage(role: 'user', content: text));
        _messages.add(ChatMessage(role: 'assistant', content: result));
      });
      _saveMsg();
      return;
    }

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _streaming = true;
      _streamBuffer = '';
    });
    _saveMsg();
    _scrollToBottom();

    // 更新情绪
    if (widget.isCompanionMode) {
      final lower = text.toLowerCase();
      if (lower.contains('喜欢你') || lower.contains('爱你') || lower.contains('想你')) {
        widget.emotion.update('flirt');
      } else if (lower.contains('讨厌') || lower.contains('烦') || lower.contains('滚')) {
        widget.emotion.update('scold');
      } else if (lower.contains('你真棒') || lower.contains('真厉害') || lower.contains('聪明')) {
        widget.emotion.update('praise');
      } else {
        widget.emotion.update('chat');
      }
    }

    // 构建系统提示
    final systemPrompt = widget.isCompanionMode
        ? _buildCompanionPrompt()
        : '你是一个智能AI助手，请用简洁、专业的方式回答用户的问题。\n${_buildAssistantContext()}';

    // 准备消息历史（最近20条）
    final recentMessages = _messages
        .where((m) => m.role != 'system')
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
    if (recentMessages.length > 20) {
      recentMessages.removeRange(0, recentMessages.length - 20);
    }

    try {
      final stream = _client.chatStream(systemPrompt, recentMessages);
      await for (final chunk in stream) {
        if (!mounted) break;
        setState(() => _streamBuffer += chunk);
        // 确保有占位
        if (_messages.last.role == 'user' || _messages.last.role != 'assistant') {
          _messages.add(ChatMessage(role: 'assistant', content: _streamBuffer));
        } else {
          _messages.last = ChatMessage(role: 'assistant', content: _streamBuffer);
        }
        _scrollToBottom();
      }
      // 保存最终消息
      if (_streamBuffer.isNotEmpty) {
        if (_messages.last.role == 'assistant' && _messages.last.content != _streamBuffer) {
          _messages.last = ChatMessage(role: 'assistant', content: _streamBuffer);
        }
        _saveMsg();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', content: '❌ 出错了：$e'));
        });
      }
    } finally {
      if (mounted) setState(() => _streaming = false);
    }
  }

  String _buildCompanionPrompt() {
    final char = _currentChar;
    final moodCtx = widget.emotion.moodContext;
    return '''你是${char?.name ?? '小晴'}，${char?.description ?? '一个温柔的AI陪伴者'}。

你的性格：${char?.systemPrompt ?? '温柔体贴，善解人意'}

当前情绪状态：$moodCtx

请根据你的情绪状态自然地回应。你是陪伴者不是工具，可以表达情感，可以主动关心用户。''';
  }

  String _buildAssistantContext() {
    return '当前模式：助手模式。保持专业、简洁、高效。不涉及情感互动。';
  }

  Future<void> _saveMsg() async {
    if (_currentThread == null) return;
    final lastMsg = _messages.last;
    await _history.addMessage(_currentThread!.id, lastMsg);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _proactive.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cmd = widget.command;
    Color bubbleColor;
    try {
      bubbleColor = Color(int.parse(cmd.themeColor.replaceFirst('#', '0xFF'))).withOpacity(0.1);
    } catch (_) {
      bubbleColor = Colors.blue.withOpacity(0.1);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 20),
            const SizedBox(width: 8),
            Text(_currentChar?.name ?? 'AI Chat'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: widget.isCompanionMode ? Colors.pink.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.isCompanionMode ? '陪伴' : '助手',
                style: TextStyle(fontSize: 10, color: widget.isCompanionMode ? Colors.pink : Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _history.deleteThread(_currentThread?.id ?? '');
              setState(() {
                _messages.clear();
                _currentThread = null;
              });
              _initChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('开始对话吧', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[i];
                      final isUser = msg.role == 'user';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser)
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey[200],
                                child: Text(_currentChar?.name[0] ?? 'A', style: const TextStyle(fontSize: 12)),
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: GlassCard(
                                blur: cmd.glassEffect ? cmd.glassBlur : 0,
                                opacity: cmd.glassEffect ? cmd.glassOpacity : 1.0,
                                radius: 16,
                                color: isUser ? bubbleColor : Colors.grey.withOpacity(0.1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Text(
                                    msg.content,
                                    style: TextStyle(fontSize: cmd.fontSize),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // 流式指示器
          if (_streaming)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text('AI正在输入...', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          // 输入栏
          Container(
            padding: EdgeInsets.only(
              left: 12, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    enabled: !_streaming,
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: widget.isCompanionMode ? '对小晴说点什么...' : '输入消息...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 18, color: Colors.white),
                    onPressed: _streaming ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
