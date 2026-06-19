import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config.dart';
import 'engines/emotion_engine.dart';
import 'engines/memory_db.dart';
import 'engines/moments_engine.dart';
import 'engines/proactive_engine.dart';
import 'engines/command_engine.dart';
import 'pages/login_page.dart';
import 'pages/chat_page.dart';
import 'pages/moments_page.dart';
import 'pages/characters_page.dart';
import 'pages/mini_phone_page.dart';
import 'pages/settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const AICompanionApp());
}

class AICompanionApp extends StatefulWidget {
  const AICompanionApp({super.key});

  @override
  State<AICompanionApp> createState() => _AICompanionAppState();
}

class _AICompanionAppState extends State<AICompanionApp> {
  final AppConfig _config = AppConfig();
  final CommandEngine _cmd = CommandEngine();
  bool _initialized = false;
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _config.load();
    setState(() {
      _hasApiKey = _config.chatApiKey.isNotEmpty;
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (!_hasApiKey) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AI Companion',
        theme: _buildTheme(),
        home: LoginPage(onLogin: () => setState(() => _hasApiKey = true)),
      );
    }

    return _buildApp();
  }

  ThemeData _buildTheme() {
    Color primary;
    try {
      primary = Color(int.parse(_cmd.themeColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      primary = Colors.blue;
    }
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primary,
      brightness: Brightness.light,
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        indicatorColor: primary.withOpacity(0.2),
      ),
    );
  }

  Widget _buildApp() {
    return ListenableBuilder(
      listenable: Listenable.merge([_config, _cmd]),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AI Companion',
        theme: _buildTheme(),
        home: const MainShell(),
      ),
    );
  }
}

/// 主壳 - 底部导航 + 双模式切换
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _isCompanionMode = true; // true=Companion, false=Assistant

  // 全局引擎
  late final MemoryDB _assistantDB = MemoryDB('assistant');
  late final MemoryDB _companionDB = MemoryDB('companion');
  late final EmotionEngine _emotion = EmotionEngine(_companionDB, 'default');
  late final MomentsEngine _moments = MomentsEngine();
  late final CommandEngine _command = CommandEngine();

  final AppConfig _config = AppConfig();

  @override
  void initState() {
    super.initState();
    _emotion.load();
    _moments.load();
  }

  void _onModeChanged(bool companion) {
    setState(() => _isCompanionMode = companion);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ChatPage(
        isCompanionMode: _isCompanionMode,
        emotion: _emotion,
        assistantDB: _assistantDB,
        companionDB: _companionDB,
        command: _command,
      ),
      MomentsPage(
        momentsEngine: _moments,
        emotion: _emotion,
        characterId: 'default',
      ),
      CharactersPage(
        emotion: _emotion,
        companionDB: _companionDB,
      ),
      const MiniPhonePage(),
      SettingsPage(
        isCompanionMode: _isCompanionMode,
        onModeChanged: _onModeChanged,
        emotion: _emotion,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final cmd = _command;
    final useGlass = cmd.glassEffect;
    final blur = cmd.glassBlur;
    final opacity = cmd.glassOpacity;
    final radius = cmd.glassRadius;

    final navItems = [
      _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
      _NavItem(Icons.explore_outlined, Icons.explore, 'Moments'),
      _NavItem(Icons.people_outline, Icons.people, 'Characters'),
      _NavItem(Icons.phone_iphone, Icons.phone_iphone, 'Mini'),
      _NavItem(Icons.settings_outlined, Icons.settings, 'Settings'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withOpacity(useGlass ? opacity : 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: useGlass
            ? Stack(
                children: [
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: Container(color: Colors.transparent),
                  ),
                  _buildNavBar(navItems),
                ],
              )
            : _buildNavBar(navItems),
      ),
    );
  }

  Widget _buildNavBar(List<_NavItem> items) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      backgroundColor: Colors.transparent,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: items.map((item) => BottomNavigationBarItem(
        icon: Icon(item.icon),
        activeIcon: Icon(item.activeIcon),
        label: item.label,
      )).toList(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _NavItem(this.icon, this.activeIcon, this.label);
}
