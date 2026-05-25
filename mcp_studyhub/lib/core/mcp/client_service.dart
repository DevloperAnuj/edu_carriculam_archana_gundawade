import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_content.dart';
import '../models/student_profile.dart';
import 'mcp_transport.dart';

final mcpClientServiceProvider = Provider((ref) => MCPClientService());

/// MCP Client Service — Objective 1 (MCP Technical Foundations)
///
/// Implements the MCP Host role:
/// - Spawns the Python MCP server (edu-mcp-server) via Stdio transport
/// - Communicates using JSON-RPC 2.0 (MCP spec 2024-11-05)
/// - Calls Prompts, Tools, and Resources primitives
/// - Falls back to rich profile-aware mock when server is unavailable
class MCPClientService {
  final MCPTransport _transport = MCPTransport();
  bool _serverStarted = false;

  bool get isConnected => _transport.isAvailable;

  Future<void> ensureStarted() async {
    if (_serverStarted) return;
    _serverStarted = true;
    final serverPath = _resolveServerPath();
    await _transport.start(serverPath);
  }

  // ── Objective 1: MCP Prompt primitive ─────────────────────────────────────

  /// Calls MCP Prompt: `synthesis_report`
  /// Passes full student profile as arguments — Objective 2 personalization.
  Future<String> synthesizeReport(
    String chapterId, {
    required StudentProfile profile,
    bool regenerate = false,
  }) async {
    await ensureStarted();

    if (isConnected) {
      try {
        return await _transport.getPrompt('synthesis_report', {
          'chapter_id': chapterId,
          'grade': profile.grade.toString(),
          'learning_style': profile.learningStyle.name,
          'interests': profile.interests.join(','),
          'difficulty': profile.adaptiveDifficulty(chapterId),
          'previous_score': (profile.quizScores[chapterId] ?? '').toString(),
        });
      } catch (e) {
        debugPrint('[MCP] synthesizeReport error: $e — using fallback');
      }
    }

    // Rich fallback — still personalized using student profile
    return _fallbackSynthesis(chapterId, profile);
  }

  /// Calls MCP Prompt: `generate_quiz`
  /// Returns adaptive questions calibrated to student performance.
  Future<List<QuizQuestion>> generateQuiz(
    String chapterId, {
    required StudentProfile profile,
  }) async {
    await ensureStarted();

    if (isConnected) {
      try {
        final raw = await _transport.getPrompt('generate_quiz', {
          'chapter_id': chapterId,
          'grade': profile.grade.toString(),
          'learning_style': profile.learningStyle.name,
          'difficulty': profile.adaptiveDifficulty(chapterId),
          'previous_score': (profile.quizScores[chapterId] ?? '').toString(),
        });
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[MCP] generateQuiz error: $e — using fallback');
      }
    }

    return _fallbackQuiz(chapterId, profile);
  }

  // ── Objective 1: MCP Tool primitive ───────────────────────────────────────

  /// Calls MCP Tool: `fetch_resources`
  Future<List<MultimediaResource>> fetchResources(
    String chapterId, {
    required StudentProfile profile,
  }) async {
    await ensureStarted();

    if (isConnected) {
      try {
        final raw = await _transport.callTool('fetch_resources', {
          'chapter_id': chapterId,
          'learning_style': profile.learningStyle.name,
        });
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((r) => MultimediaResource.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[MCP] fetchResources error: $e — using fallback');
      }
    }

    return _fallbackResources(chapterId);
  }

  /// Calls MCP Tool: `record_performance` (xAPI logging)
  Future<void> recordPerformance({
    required String chapterId,
    required int score,
    required bool completed,
    int timeSpentSeconds = 0,
  }) async {
    await ensureStarted();
    if (isConnected) {
      try {
        await _transport.callTool('record_performance', {
          'chapter_id': chapterId,
          'score': score,
          'completed': completed,
          'time_spent_seconds': timeSpentSeconds,
        });
      } catch (e) {
        debugPrint('[MCP] recordPerformance error: $e');
      }
    }
  }

  /// Calls MCP Tool: `get_recommendations` (Context Management Agent support)
  Future<List<Map<String, dynamic>>> getRecommendations({
    required StudentProfile profile,
    required List<String> completedChapters,
  }) async {
    await ensureStarted();

    if (isConnected) {
      try {
        final raw = await _transport.callTool('get_recommendations', {
          'grade': profile.grade,
          'completed_chapters': completedChapters,
          'quiz_scores': profile.quizScores,
        });
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        debugPrint('[MCP] getRecommendations error: $e');
      }
    }
    return [];
  }

  // ── Objective 1: MCP Resource primitive ───────────────────────────────────

  /// Reads MCP Resource: `student://profile` (schema demonstration)
  Future<String> readStudentProfileResource() async {
    await ensureStarted();
    if (isConnected) {
      try {
        return await _transport.readResource('student://profile');
      } catch (e) {
        debugPrint('[MCP] readResource error: $e');
      }
    }
    return '{"status": "MCP server not connected"}';
  }

  void dispose() => _transport.stop();

  // ── Profile-aware fallback content ────────────────────────────────────────

  String _fallbackSynthesis(String chapterId, StudentProfile profile) {
    final styleNote = {
      LearningStyle.visual: '> 🔭 **Visual Mode** — Use the concept map on the right to build connections between ideas.',
      LearningStyle.auditory: '> 🎧 **Auditory Mode** — Read each section aloud. Discuss with a study partner.',
      LearningStyle.kinesthetic: '> ✋ **Kinesthetic Mode** — Work every example yourself before reading the solution.',
      LearningStyle.readWrite: '> 📝 **Read/Write Mode** — Rewrite key definitions in your own words as you read.',
    }[profile.learningStyle]!;

    final score = profile.quizScores[chapterId];
    String scoreNote = '';
    if (score != null) {
      if (score < 50) {
        scoreNote = '\n> ⚠️ **Adaptive Focus**: Previous score $score% — fundamentals are emphasised below.\n';
      } else if (score >= 80) {
        scoreNote = '\n> 🌟 **Advanced Mode**: Previous score $score% — deeper analysis sections are unlocked.\n';
      }
    }

    final interests = profile.interests.take(2).join(' and ');
    final difficulty = profile.adaptiveDifficulty(chapterId);
    final topic = _chapterTitle(chapterId);

    return '''# $topic
**Grade ${profile.grade} · ${profile.learningStyleLabel} Learner · Difficulty: ${difficulty[0].toUpperCase()}${difficulty.substring(1)}**

---

$styleNote$scoreNote

## Key Concepts

This chapter covers the essential principles of **$topic**. Each concept builds on the previous, forming a connected knowledge structure.

${_stylisedConceptSection(profile.learningStyle, topic)}

## Core Formulas & Principles

The mathematical and theoretical foundations are central to mastering this topic. Work through each formula systematically.

${difficulty == 'advanced' ? '## Advanced Analysis\n\nExplore derivations, edge cases, and higher-order problem-solving strategies.\n' : ''}
## Real-World Connections

${interests.isNotEmpty ? 'Connecting $topic to your interests in **$interests**:\n\nThe principles studied here appear directly in $interests-related contexts — explore these connections for deeper understanding.' : 'These concepts have broad applications across technology, science, and everyday life.'}

## Summary & Exam Tips

- Review each key concept definition from memory.
- Practice at least two numerical problems per formula.
- Attempt the adaptive quiz to identify gaps.

---
*Generated by MCP StudyHub · ${isConnected ? "MCP Server (edu-mcp-server)" : "Enhanced Mock Mode"} · Profile-Aware Content*
''';
  }

  String _stylisedConceptSection(LearningStyle style, String topic) {
    switch (style) {
      case LearningStyle.visual:
        return '- Draw a mind map connecting the key terms before reading.\n- Use colour-coding: definitions in blue, formulas in red, examples in green.';
      case LearningStyle.auditory:
        return '- Record yourself explaining each concept and play it back.\n- Use mnemonics and rhymes to remember formulas.';
      case LearningStyle.kinesthetic:
        return '- Complete a hands-on activity or experiment for each concept.\n- Build a physical model or use simulation tools.';
      case LearningStyle.readWrite:
        return '- Write structured notes with headings for each concept.\n- Create a glossary with precise definitions for every term in $topic.';
    }
  }

  List<QuizQuestion> _fallbackQuiz(String chapterId, StudentProfile profile) {
    final difficulty = profile.adaptiveDifficulty(chapterId);
    final topic = _chapterTitle(chapterId);
    final diffNote = difficulty == 'basic' ? '(foundational)' : difficulty == 'advanced' ? '(higher-order)' : '(standard)';

    return [
      QuizQuestion(
        id: 'q1',
        question: 'Which statement BEST describes the core principle of $topic? $diffNote',
        options: [
          'It involves systematic application of defined rules and formulas.',
          'It is primarily a memorisation exercise.',
          'It has no real-world applications.',
          'It can only be studied in laboratory conditions.',
        ],
        correctAnswerIndex: 0,
        explanation: '$topic is built on systematic principles that can be applied to solve real-world problems through defined methods.',
      ),
      QuizQuestion(
        id: 'q2',
        question: 'For a ${profile.learningStyleLabel} learner, the most effective way to master $topic is:',
        options: [
          profile.learningStyle == LearningStyle.visual ? 'Creating diagrams and visual summaries' : 'Passive reading of notes',
          profile.learningStyle == LearningStyle.auditory ? 'Discussing concepts aloud with peers' : 'Working through textbook exercises silently',
          profile.learningStyle == LearningStyle.kinesthetic ? 'Hands-on experimentation and practice' : 'Rote memorisation of formulas',
          profile.learningStyle == LearningStyle.readWrite ? 'Taking detailed structured notes' : 'Watching videos without taking notes',
        ],
        correctAnswerIndex: 0,
        explanation: 'Research confirms that ${profile.learningStyleLabel} learners achieve deeper retention when material is presented in their preferred modality.',
      ),
      QuizQuestion(
        id: 'q3',
        question: 'What is the recommended first step when approaching a new problem in $topic?',
        options: [
          'Identify what is given and what is asked.',
          'Immediately apply the first formula you recall.',
          'Skip to the answer.',
          'Guess based on intuition.',
        ],
        correctAnswerIndex: 0,
        explanation: 'Problem-solving always begins with careful analysis: identify known quantities, unknown quantities, and the relevant principle.',
      ),
      QuizQuestion(
        id: 'q4',
        question: 'Which of these is a key success factor for Grade ${profile.grade} students in $topic?',
        options: [
          'Regular practice with varied problem types.',
          'Studying only the night before the exam.',
          'Memorising answers without understanding.',
          'Avoiding difficult problems.',
        ],
        correctAnswerIndex: 0,
        explanation: 'Consistent practice across varied problem types builds both procedural fluency and conceptual understanding.',
      ),
      QuizQuestion(
        id: 'q5',
        question: 'The Model Context Protocol (MCP) helps in learning $topic by:',
        options: [
          'Providing personalised, context-aware educational content.',
          'Replacing the need to study.',
          'Giving the same content to all students.',
          'Making learning harder.',
        ],
        correctAnswerIndex: 0,
        explanation: 'MCP enables AI systems to access student profiles, performance history, and curriculum data to deliver truly personalised learning experiences.',
      ),
    ];
  }

  List<MultimediaResource> _fallbackResources(String chapterId) {
    final topic = _chapterTitle(chapterId);
    return [
      MultimediaResource(
        id: 'v1',
        title: '$topic – Explained',
        type: 'video',
        url: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(topic)}',
        thumbnailUrl: 'https://via.placeholder.com/300x150/6C5CE7/FFFFFF?text=${Uri.encodeComponent(topic)}',
      ),
      MultimediaResource(
        id: 'a1',
        title: '$topic – Wikipedia',
        type: 'article',
        url: 'https://en.wikipedia.org/wiki/Special:Search?search=${Uri.encodeComponent(topic)}',
        thumbnailUrl: 'https://via.placeholder.com/300x150/00B894/FFFFFF?text=Article',
      ),
      MultimediaResource(
        id: 'a2',
        title: '$topic – Khan Academy',
        type: 'article',
        url: 'https://www.khanacademy.org/search?page_search_query=${Uri.encodeComponent(topic)}',
        thumbnailUrl: 'https://via.placeholder.com/300x150/0984E3/FFFFFF?text=Khan+Academy',
      ),
    ];
  }

  String _chapterTitle(String chapterId) {
    const titles = {
      'phys_10_01': 'Light – Reflection and Refraction',
      'phys_10_02': 'The Human Eye and the Colourful World',
      'phys_10_03': 'Electricity',
      'math_10_01': 'Real Numbers',
      'math_10_02': 'Polynomials',
      'math_10_03': 'Quadratic Equations',
      'chem_10_01': 'Chemical Reactions and Equations',
      'chem_10_02': 'Acids, Bases and Salts',
      'bio_10_01': 'Life Processes',
      'bio_10_02': 'Control and Coordination',
      'phys_12_01': 'Electric Charges and Fields',
      'phys_12_02': 'Electrostatic Potential and Capacitance',
      'phys_12_03': 'Current Electricity',
      'math_12_01': 'Relations and Functions',
      'math_12_02': 'Calculus – Derivatives',
      'math_12_03': 'Integrals',
      'cs_12_01': 'Python Revision Tour',
      'cs_12_02': 'Data Structures in Python',
      'chem_12_01': 'Electrochemistry',
      'chem_12_02': 'Chemical Kinetics',
    };
    return titles[chapterId] ?? chapterId.replaceAll('_', ' ').toUpperCase();
  }

  static String _resolveServerPath() {
    try {
      final exe = Platform.resolvedExecutable;
      final exeDir = File(exe).parent;
      // Development path: project root / mcp_server / server.py
      final candidates = [
        '${exeDir.path}/../../../../mcp_server/server.py',
        '${exeDir.path}/../../../mcp_server/server.py',
        '${Directory.current.path}/../mcp_server/server.py',
        '${Directory.current.path}/mcp_server/server.py',
      ];
      for (final path in candidates) {
        final f = File(path);
        if (f.existsSync()) return f.path;
      }
    } catch (_) {}
    return '../mcp_server/server.py';
  }
}
