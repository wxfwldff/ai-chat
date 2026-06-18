# AI Chat

跨平台 AI 聊天应用，支持多角色对话、图片生成和语音合成。

## 功能

- 多角色 AI 对话（默认3个角色，可自定义）
- 流式消息输出
- 图片生成 (DALL·E 兼容 API)
- TTS 语音合成 (OpenAI 兼容 API)
- 多线程对话历史持久化

## 编译

### 本地

```bash
flutter pub get
flutter build apk --release
```

### GitHub Actions

推送代码到 `master` 分支自动触发编译，产物在 Actions → Build APK → Artifacts 下载。

## 配置

编辑 `lib/core/config.dart` 填入 API 密钥，或运行时在应用内设置。

## 结构

```
lib/
├── main.dart
└── core/
    ├── config.dart            # API 配置管理
    ├── api_client.dart        # 统一 API 客户端
    ├── character_store.dart   # 角色管理
    └── chat_history.dart      # 对话历史
```
