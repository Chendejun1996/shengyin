import 'package:flutter/material.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.music.loadStats();
      _urlCtrl.text = context.music.api.baseUrl;
    });
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
                  subtitle: const Text('v0.1.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
