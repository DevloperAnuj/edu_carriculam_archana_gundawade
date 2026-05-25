import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// xAPI (Experience API / Tin Can API) Learning Record Store — Objective 3
///
/// Implements a simplified xAPI-compatible event logging system to demonstrate
/// LMS interoperability. xAPI is an eLearning standard that tracks learning
/// experiences across platforms (referenced in the report: SCORM, xAPI, LTI).
///
/// Statements are persisted locally as JSON and can be exported for
/// integration with a real Learning Record Store (LRS) or LMS.
class XApiService {
  static const _fileName = 'xapi_statements.json';

  // ─── xAPI Verb URIs (ADL standard) ────────────────────────────────────────

  static const _verbLaunched = 'http://adlnet.gov/expapi/verbs/launched';
  static const _verbCompleted = 'http://adlnet.gov/expapi/verbs/completed';
  static const _verbScored = 'http://adlnet.gov/expapi/verbs/scored';
  // ─── Public API ───────────────────────────────────────────────────────────

  /// Log: student launched a chapter
  static Future<void> logChapterLaunched({
    required String chapterId,
    required String chapterTitle,
    required String studentName,
  }) =>
      _record(
        actor: _actor(studentName),
        verb: _verb(_verbLaunched, 'launched'),
        object: _chapterObject(chapterId, chapterTitle),
      );

  /// Log: student submitted a quiz with score
  static Future<void> logQuizScored({
    required String chapterId,
    required String chapterTitle,
    required String studentName,
    required int score,
    required int durationSeconds,
  }) =>
      _record(
        actor: _actor(studentName),
        verb: _verb(_verbScored, 'scored'),
        object: _chapterObject(chapterId, chapterTitle,
            type: 'http://adlnet.gov/expapi/activities/assessment'),
        result: {
          'score': {
            'scaled': (score / 100).clamp(0.0, 1.0),
            'raw': score,
            'min': 0,
            'max': 100,
          },
          'success': score >= 60,
          'completion': score >= 60,
          'duration': 'PT${durationSeconds}S',
        },
      );

  /// Log: student completed a chapter
  static Future<void> logChapterCompleted({
    required String chapterId,
    required String chapterTitle,
    required String studentName,
  }) =>
      _record(
        actor: _actor(studentName),
        verb: _verb(_verbCompleted, 'completed'),
        object: _chapterObject(chapterId, chapterTitle),
        result: {'completion': true, 'success': true},
      );

  /// Log: app session started
  static Future<void> logSessionStarted({required String studentName}) =>
      _record(
        actor: _actor(studentName),
        verb: _verb(_verbLaunched, 'launched'),
        object: {
          'id': 'app://mcpstudyhub',
          'definition': {
            'name': {'en-US': 'MCP StudyHub Application'},
            'type': 'http://adlnet.gov/expapi/activities/application',
          },
        },
      );

  /// Read all stored xAPI statements (for Teacher Dashboard).
  static Future<List<Map<String, dynamic>>> readStatements() async {
    try {
      final file = await _statementsFile();
      if (!file.existsSync()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[xAPI] Read error: $e');
      return [];
    }
  }

  /// Export all statements as a JSON string (for data portability).
  static Future<String> exportStatements() async {
    final statements = await readStatements();
    return const JsonEncoder.withIndent('  ').convert(statements);
  }

  /// Delete all stored statements (FERPA right-to-erasure — Objective 4).
  static Future<void> deleteAllStatements() async {
    try {
      final file = await _statementsFile();
      if (file.existsSync()) await file.delete();
    } catch (e) {
      debugPrint('[xAPI] Delete error: $e');
    }
  }

  /// Count statements grouped by verb display name.
  static Future<Map<String, int>> statementSummary() async {
    final statements = await readStatements();
    final counts = <String, int>{};
    for (final s in statements) {
      final verb = (s['verb'] as Map?)?['display']?['en-US'] as String? ?? 'unknown';
      counts[verb] = (counts[verb] ?? 0) + 1;
    }
    return counts;
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  static Future<void> _record({
    required Map<String, dynamic> actor,
    required Map<String, dynamic> verb,
    required Map<String, dynamic> object,
    Map<String, dynamic>? result,
  }) async {
    try {
      final statement = <String, dynamic>{
        'id': _uuid(),
        'actor': actor,
        'verb': verb,
        'object': object,
        if (result != null) 'result': result,
        'context': {
          'platform': 'MCP StudyHub',
          'language': 'en-IN',
          'extensions': {
            'http://mcpstudyhub.local/extensions/protocol': 'MCP/1.0',
            'http://mcpstudyhub.local/extensions/report': 'Archana Gundawade – MCP in Educational Curriculum Design',
          },
        },
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'version': '1.0.3',
        'authority': {
          'objectType': 'Agent',
          'name': 'MCP StudyHub LRS',
          'mbox': 'mailto:lrs@mcpstudyhub.local',
        },
      };

      final file = await _statementsFile();
      List<dynamic> existing = [];
      if (file.existsSync()) {
        try {
          existing = jsonDecode(await file.readAsString()) as List<dynamic>;
        } catch (_) {}
      }
      existing.add(statement);
      await file.writeAsString(jsonEncode(existing));
    } catch (e) {
      debugPrint('[xAPI] Record error: $e');
    }
  }

  static Map<String, dynamic> _actor(String name) => {
        'objectType': 'Agent',
        'name': name.isNotEmpty ? name : 'Student',
        'mbox': 'mailto:student@mcpstudyhub.local',
      };

  static Map<String, dynamic> _verb(String id, String display) => {
        'id': id,
        'display': {'en-US': display},
      };

  static Map<String, dynamic> _chapterObject(
    String chapterId,
    String chapterTitle, {
    String type = 'http://adlnet.gov/expapi/activities/module',
  }) =>
      {
        'id': 'chapter://$chapterId',
        'definition': {
          'name': {'en-US': chapterTitle},
          'type': type,
        },
      };

  static Future<File> _statementsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static String _uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final r = now.hashCode.abs();
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (m) {
        final v = m.group(0) == 'x' ? (r >> 4) & 0xf : ((r >> 2) & 0x3) | 0x8;
        return v.toRadixString(16);
      },
    );
  }
}
