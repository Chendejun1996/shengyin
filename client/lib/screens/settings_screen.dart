import 'package:flutter/material.dart';
import '../extensions.dart';
import '../services/log_service.dart';
import 'dart:io';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl = TextEditingController();
  int _logFileCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.music.loadStats();
      _urlCtrl.text = context.music.api.baseUrl;
      _refreshLogCount();
    });
  }

  Future<void> _refreshLogCount() async {
    final files = await LogService().getLogFiles();
    if (mounted) setState(() => _logFileCount = files.length);
  }

  void _viewLogs() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const _LogViewerScreen(),
    )).then((_) => _refreshLogCount());
  }

  Future<void> _shareLogs() async {
    final path = await LogService().getLatestLogPath();
    if (path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂无日志')),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('日志文件: $path'),
          action: SnackBarAction(label: '查看', onPressed: _viewLogs),
        ),
      );
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.music;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Server info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('服务器信息', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('服务器: ${provider.api.baseUrl}'),
                  Text('歌曲: ${provider.stats['songs'] ?? '-'}'),
                  Text('专辑: ${provider.stats['albums'] ?? '-'}'),
                  Text('歌手: ${provider.stats['artists'] ?? '-'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Server URL
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: '服务器地址',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              try {
                await provider.api.ping();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('连接成功'), backgroundColor: Colors.green));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('连接失败: $e'), backgroundColor: Colors.red));
              }
            },
            icon: const Icon(Icons.cable),
            label: const Text('测试连接'),
          ),
          const SizedBox(height: 16),

          // Actions
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('重新扫描音乐库'),
                  trailing: provider.loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right),
                  onTap: provider.loading ? null : () async {
                    await provider.api.scan();
                    await provider.loadStats();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('扫描完成')));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('关于笙音'),
                  subtitle: Text('v0.1.0 · $_logFileCount 个日志文件'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── 日志管理 ───
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.bug_report, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('日志管理', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('查看日志'),
                  subtitle: Text('$_logFileCount 条日志记录'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _viewLogs,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('分享日志文件'),
                  subtitle: const Text('方便反馈 bug 时发送给开发者'),
                  onTap: _shareLogs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 日志查看器 —— 以图文方式展示最新日志内容
class _LogViewerScreen extends StatefulWidget {
  const _LogViewerScreen();
  @override
  State<_LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<_LogViewerScreen> {
  String _logContent = '加载中...';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final log = await LogService().readLatestLog(tailLines: 200);
    if (mounted) setState(() => _logContent = log);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: '刷新',
          ),
        ],
      ),
      body: GestureDetector(
        onLongPress: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('日志已复制到剪贴板')),
          );
        },
        child: SelectableText(
          _logContent,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            height: 1.4,
            color: Color(0xFFE0E0E0),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1A1A2E),
    );
  }
}
