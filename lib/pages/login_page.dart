import 'package:flutter/material.dart';
import '../core/config.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _config = AppConfig();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _apiKeyCtrl;
  late TextEditingController _apiUrlCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _nameCtrl;

  bool _obscureKey = true;
  bool _saving = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl = TextEditingController(text: _config.chatApiKey);
    _apiUrlCtrl = TextEditingController(text: _config.chatApiUrl);
    _modelCtrl = TextEditingController(text: _config.chatModel);
    _nameCtrl = TextEditingController(text: _config.characterName);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _apiUrlCtrl.dispose();
    _modelCtrl.dispose();
    _nameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    _config.chatApiKey = _apiKeyCtrl.text.trim();
    _config.chatApiUrl = _apiUrlCtrl.text.trim();
    _config.chatModel = _modelCtrl.text.trim();
    _config.characterName = _nameCtrl.text.trim();
    await _config.save();
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, size: 64, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'AI Companion',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '配置你的AI伙伴',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 40),
                      _buildField(
                        controller: _nameCtrl,
                        label: '角色名称',
                        icon: Icons.person,
                        hint: '小晴',
                      ),
                      const SizedBox(height: 16),
                      _buildKeyField(),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _apiUrlCtrl,
                        label: 'API地址 (Base URL)',
                        icon: Icons.link,
                        hint: 'https://api.openai.com/v1/chat/completions',
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _modelCtrl,
                        label: '模型名',
                        icon: Icons.model_training,
                        hint: 'gpt-4o-mini',
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF667eea),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 4,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('开始使用', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildKeyField() {
    return TextFormField(
      controller: _apiKeyCtrl,
      obscureText: _obscureKey,
      style: const TextStyle(color: Colors.white),
      validator: (v) => (v == null || v.trim().isEmpty) ? '请输入API Key' : null,
      decoration: InputDecoration(
        labelText: 'API Key',
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: 'sk-...',
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.key, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureKey ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () => setState(() => _obscureKey = !_obscureKey),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
