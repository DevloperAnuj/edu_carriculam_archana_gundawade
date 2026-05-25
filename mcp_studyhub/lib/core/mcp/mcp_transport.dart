import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Low-level JSON-RPC 2.0 transport over a spawned Python process (Stdio).
/// Implements the MCP (Model Context Protocol) client-side handshake and
/// message routing as specified by Anthropic's MCP 2024-11-05 spec.
class MCPTransport {
  Process? _process;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  StreamSubscription? _stdoutSub;
  int _nextId = 1;
  bool _initialized = false;
  bool _available = false;

  bool get isAvailable => _available;

  /// Attempt to start the Python MCP server at [serverPath].
  /// Returns true if the server started and the MCP handshake succeeded.
  Future<bool> start(String serverPath) async {
    try {
      final pythonExe = await _findPython();
      if (pythonExe == null) {
        debugPrint('[MCP] Python not found – falling back to mock mode.');
        return false;
      }

      final serverFile = File(serverPath);
      if (!serverFile.existsSync()) {
        debugPrint('[MCP] Server script not found at $serverPath – mock mode.');
        return false;
      }

      _process = await Process.start(
        pythonExe,
        [serverPath],
        environment: {
          ...Platform.environment,
          if (Platform.environment['ANTHROPIC_API_KEY'] == null) 'ANTHROPIC_API_KEY': '',
        },
      );

      // Route stdout lines to handler
      _stdoutSub = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLine, onError: (e) => debugPrint('[MCP] stdout error: $e'));

      // Log stderr for diagnostics
      _process!.stderr
          .transform(utf8.decoder)
          .listen((line) => debugPrint('[MCP server] $line'));

      // Perform MCP initialize handshake
      await _initialize();
      _available = true;
      debugPrint('[MCP] Server started and initialized successfully.');
      return true;
    } catch (e) {
      debugPrint('[MCP] Failed to start server: $e – using mock mode.');
      _available = false;
      return false;
    }
  }

  void _handleLine(String line) {
    if (line.trim().isEmpty) return;
    try {
      final msg = jsonDecode(line) as Map<String, dynamic>;
      final id = msg['id'];
      if (id != null && _pending.containsKey(id)) {
        _pending[id]!.complete(msg);
        _pending.remove(id);
      }
    } catch (e) {
      debugPrint('[MCP] Failed to parse line: $line');
    }
  }

  Future<Map<String, dynamic>> _sendRequest(
    String method, [
    Map<String, dynamic>? params,
  ]) async {
    final id = _nextId++;
    final request = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _process!.stdin.writeln(jsonEncode(request));
    await _process!.stdin.flush();
    return completer.future.timeout(const Duration(seconds: 30));
  }

  void _sendNotification(String method, [Map<String, dynamic>? params]) {
    final notification = <String, dynamic>{
      'jsonrpc': '2.0',
      'method': method,
      if (params != null) 'params': params,
    };
    _process!.stdin.writeln(jsonEncode(notification));
    _process!.stdin.flush();
  }

  Future<void> _initialize() async {
    await _sendRequest('initialize', {
      'protocolVersion': '2024-11-05',
      'capabilities': {
        'roots': {'listChanged': false},
      },
      'clientInfo': {'name': 'mcp-studyhub', 'version': '1.0.0'},
    });
    _sendNotification('notifications/initialized');
    _initialized = true;
  }

  /// Call a named MCP Prompt and return the text of the first message.
  Future<String> getPrompt(String name, Map<String, String> arguments) async {
    if (!_initialized) throw StateError('MCP not initialized');
    final response = await _sendRequest('prompts/get', {
      'name': name,
      'arguments': arguments,
    });
    final result = response['result'] as Map<String, dynamic>?;
    final messages = result?['messages'] as List<dynamic>?;
    if (messages != null && messages.isNotEmpty) {
      final content = messages.first['content'] as Map<String, dynamic>?;
      return content?['text'] as String? ?? '';
    }
    return '';
  }

  /// Call a named MCP Tool and return the text of the first content item.
  Future<String> callTool(String name, Map<String, dynamic> arguments) async {
    if (!_initialized) throw StateError('MCP not initialized');
    final response = await _sendRequest('tools/call', {
      'name': name,
      'arguments': arguments,
    });
    final result = response['result'] as Map<String, dynamic>?;
    final content = result?['content'] as List<dynamic>?;
    if (content != null && content.isNotEmpty) {
      return content.first['text'] as String? ?? '';
    }
    return '';
  }

  /// Read a named MCP Resource and return its content string.
  Future<String> readResource(String uri) async {
    if (!_initialized) throw StateError('MCP not initialized');
    final response = await _sendRequest('resources/read', {'uri': uri});
    final result = response['result'] as Map<String, dynamic>?;
    final contents = result?['contents'] as List<dynamic>?;
    if (contents != null && contents.isNotEmpty) {
      return contents.first['text'] as String? ?? '';
    }
    return '';
  }

  void stop() {
    _stdoutSub?.cancel();
    _process?.kill();
    _process = null;
    _initialized = false;
    _available = false;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError('Transport stopped');
    }
    _pending.clear();
  }

  /// Try common Python executable names on Windows.
  static Future<String?> _findPython() async {
    for (final exe in ['python', 'python3', 'py']) {
      try {
        final result = await Process.run(exe, ['--version']);
        if (result.exitCode == 0) return exe;
      } catch (_) {}
    }
    return null;
  }
}
