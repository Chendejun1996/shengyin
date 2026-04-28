# 更新日志

## v1.1.0 (2026-04-28)

✨ **新功能**
- 自动本地日志：App 崩溃或网络异常自动保存日志到设备本地文件
- 设置页新增「日志管理」模块，支持查看和分享日志
- 后端所有请求自动记录到 `/vol1/shengyin-logs/`

🔧 **优化**
- 修复 Android APK 签名不一致问题，以后更新无需卸载重装
- Release 页面标注修复内容，更新更清晰

## v1.0.2 (2026-04-28)

🐛 **Bug 修复**
- 修复 Android 闪退：MainActivity 包名路径与 build.gradle 不一致
- CI 中移除 Android 的 `flutter create` 步骤，避免覆盖已配置的文件

## v1.0.1 (2026-04-28)

🐛 **Bug 修复**
- 添加 INTERNET 网络权限
- 开放 HTTP 明文连接支持
- 应用名改为「笙音」

## v1.0.0 (2026-04-28)

🎉 **首个正式版**
- 支持音乐流媒体播放
- 标签编辑
- MusicBrainz 自动刮削
- 跨平台：Android / Windows / Linux / macOS
