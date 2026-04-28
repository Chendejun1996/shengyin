import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 笙音日志服务 —— 自动捕获所有异常并写入本地文件
///
/// 日志文件保存在: <应用文档目录>/logs/shengyin-YYYYMMDD-HHmmss.log
/// 最多保留 10 个日志文件，超出自动清理最旧的。
class LogService {
  static final LogService _instance = LogService._();
  factory LogService() => _instance;
  LogService._();

  File? _logFile;
  IOSink? _sink;
  StringBuffer _buffer = StringBuffer();
  bool _initialized = false;
  static const int _maxLogFiles = 10;

  /// 初始化日志服务，设置全局错误处理器
  Future<void> init() async {
    if (_initialized) return;

    final dir = Directory('${await _getLogDir()}/logs');
    if (!await dir.exists()) await dir.create(recursive: true);

    // 清理旧日志
    await _cleanOldLogs(dir);

    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    _logFile = File('${dir.path}/shengyin-$timestamp.log');
    _sink = _logFile!.openWrite();

    // 写一条启动日志
    _write('═══════════════════════════════════════════');
    _write('笙音 v0.1.0 启动');
    _write('时间: ${DateTime.now().toLocal()}');
    _write('平台: ${defaultTargetPlatform}');
    _write('═══════════════════════════════════════════');

    // ─── 注册全局错误处理器 ───
    // 1. Flutter 框架错误（build 阶段、layout 等）
    FlutterError.onError = (FlutterErrorDetails details) {
      _write('[FLUTTER_ERROR] ${details.exception}');
      _write('  Stack: ${details.stack}');
      FlutterError.presentError(details);
    };

    // 2. 平台错误（原生插件报错等）
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _write('[PLATFORM_ERROR] $error');
      _write('  Stack: $stack');
      return true; // 不崩溃
    };

    // 3. 已注册 runZonedGuarded（在 main.dart 中），这里只记录
    _initialized = true;
  }

  /// 记录一条日志（带时间戳和线程信息）
  void log(String message, {Object? error, StackTrace? stackTrace}) {
    final prefix = error != null ? '[ERROR]' : '[INFO]';
    _write('$prefix $message');
    if (error != null) {
      _write('  Error: $error');
    }
    if (stackTrace != null) {
      _write('  Stack: $stackTrace');
    }
  }

  /// 捕获未被 Flutter.onError 捕获到的异常（由 runZonedGuarded 调用）
  void captureGuardedError(Object error, StackTrace stack) {
    _write('[UNCAUGHT] $error');
    _write('  Stack: $stack');
  }

  /// 获取所有日志文件列表（按修改时间排序）
  Future<List<File>> getLogFiles() async {
    final dir = Directory('${await _getLogDir()}/logs');
    if (!await dir.exists()) return [];
    final files = await dir.list().where((e) => e.path.endsWith('.log')).cast<File>().toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// 获取最新日志文件的路径
  Future<String?> getLatestLogPath() async {
    final files = await getLogFiles();
    return files.isNotEmpty ? files.first.path : null;
  }

  /// 读取最新日志文件的内容（后 N 行）
  Future<String> readLatestLog({int tailLines = 100}) async {
    final files = await getLogFiles();
    if (files.isEmpty) return '暂无日志';
    final lines = await files.first.readAsLines();
    if (lines.length <= tailLines) return lines.join('\n');
    return lines.sublist(lines.length - tailLines).join('\n');
  }

  /// 关闭日志文件
  Future<void> close() async {
    _write('═══════════════════════════════════════════');
    _write('笙音 关闭');
    _write('═══════════════════════════════════════════');
    await _sink?.flush();
    await _sink?.close();
    _initialized = false;
  }

  // ─── 私有方法 ───

  void _write(String text) {
    final line = '[${DateTime.now().toIso8601String()}] $text';
    _buffer.writeln(line);
    _sink?.writeln(line);
    // debugPrint 在 release 模式下不输出，仅用于 debug
    debugPrint(line);
  }

  Future<String> _getLogDir() async {
    // 优先使用应用文档目录，fallback 到临时目录
    try {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (_) {
      final dir = await getTemporaryDirectory();
      return dir.path;
    }
  }

  Future<void> _cleanOldLogs(Directory dir) async {
    try {
      final files = await dir.list().where((e) => e.path.endsWith('.log')).toList();
      if (files.length > _maxLogFiles) {
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        for (var i = 0; i < files.length - _maxLogFiles; i++) {
          await files[i].delete();
        }
      }
    } catch (_) {
      // 清理失败不影响主功能
    }
  }
}
