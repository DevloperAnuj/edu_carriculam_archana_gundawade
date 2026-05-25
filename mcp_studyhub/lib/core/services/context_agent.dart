import '../models/student_profile.dart';

/// Context Management Agent — Objective 3 (LMS Integration & Context Capturing)
///
/// Implements the "Context Management Agent" pattern described in the report
/// (Parsian & Khademi, 2010). Responsible for:
///   1. Maintaining the current learner model from interactions
///   2. Deriving implicit learning style evidence from behaviour
///   3. Generating adaptive difficulty recommendations
///   4. Identifying learning gaps from quiz performance
///   5. Providing next-chapter recommendations
class ContextAgent {
  /// Derive the adaptive difficulty level for a chapter based on performance.
  /// Directly implements the adaptive learning loop (Objective 2).
  static String adaptiveDifficulty(StudentProfile profile, String chapterId) {
    return profile.adaptiveDifficulty(chapterId);
  }

  /// Identify chapters where the student has performance gaps (score < 60%).
  static List<LearningGap> identifyGaps(StudentProfile profile) {
    return profile.quizScores.entries
        .where((e) => e.value < 60)
        .map((e) => LearningGap(
              chapterId: e.key,
              score: e.value,
              severity: e.value < 40 ? GapSeverity.critical : GapSeverity.moderate,
            ))
        .toList()
      ..sort((a, b) => a.score.compareTo(b.score));
  }

  /// Compute overall mastery percentage across all attempted chapters.
  static double overallMastery(StudentProfile profile) {
    if (profile.quizScores.isEmpty) return 0.0;
    final total = profile.quizScores.values.fold(0, (sum, s) => sum + s);
    return total / profile.quizScores.length;
  }

  /// Recommend next chapters based on the learner's context:
  /// - Prioritises revisiting gaps (score < 60%)
  /// - Then suggests the next logical chapter in each subject
  static List<ChapterRecommendation> recommend({
    required StudentProfile profile,
    required List<String> allChapterIds,
    required Map<String, String> chapterTitles,
    required Map<String, String> chapterSubjects,
  }) {
    final completed = _completedChapters(profile);
    final recs = <ChapterRecommendation>[];

    // 1. Revisit chapters with low scores (gaps)
    for (final gap in identifyGaps(profile)) {
      recs.add(ChapterRecommendation(
        chapterId: gap.chapterId,
        title: chapterTitles[gap.chapterId] ?? gap.chapterId,
        subject: chapterSubjects[gap.chapterId] ?? '',
        reason: 'Revisit: score ${gap.score}% — strengthen your foundation',
        priority: RecommendationPriority.gap,
      ));
    }

    // 2. Suggest next uncompleted chapter per subject
    final subjectChapters = <String, List<String>>{};
    for (final cid in allChapterIds) {
      final subject = chapterSubjects[cid] ?? 'Other';
      subjectChapters.putIfAbsent(subject, () => []).add(cid);
    }

    for (final entry in subjectChapters.entries) {
      for (final cid in entry.value) {
        if (!completed.contains(cid) && !recs.any((r) => r.chapterId == cid)) {
          recs.add(ChapterRecommendation(
            chapterId: cid,
            title: chapterTitles[cid] ?? cid,
            subject: entry.key,
            reason: 'Next in ${entry.key}',
            priority: RecommendationPriority.next,
          ));
          break; // one suggestion per subject
        }
      }
    }

    return recs.take(5).toList();
  }

  /// Implicitly update the learner context after a quiz attempt.
  /// Returns an updated [StudentProfile] with the new score recorded.
  static StudentProfile updateFromQuizResult({
    required StudentProfile profile,
    required String chapterId,
    required String subjectName,
    required int score,
  }) {
    final newScores = Map<String, int>.from(profile.quizScores);
    newScores[chapterId] = score;

    // Auto-mark as completed if passed (≥ 60%)
    Map<String, Map<String, bool>>? newProgress;
    if (score >= 60) {
      newProgress = Map<String, Map<String, bool>>.from(profile.progressTracking);
      newProgress[subjectName] = Map<String, bool>.from(
        newProgress[subjectName] ?? {},
      )..[chapterId] = true;
    }

    return profile.copyWith(
      quizScores: newScores,
      progressTracking: newProgress ?? profile.progressTracking,
    );
  }

  static Set<String> _completedChapters(StudentProfile profile) {
    return {
      for (final subject in profile.progressTracking.values)
        for (final entry in subject.entries)
          if (entry.value) entry.key,
    };
  }
}

// ─── Value types ─────────────────────────────────────────────────────────────

enum GapSeverity { moderate, critical }

class LearningGap {
  final String chapterId;
  final int score;
  final GapSeverity severity;
  const LearningGap({
    required this.chapterId,
    required this.score,
    required this.severity,
  });
}

enum RecommendationPriority { gap, next }

class ChapterRecommendation {
  final String chapterId;
  final String title;
  final String subject;
  final String reason;
  final RecommendationPriority priority;
  const ChapterRecommendation({
    required this.chapterId,
    required this.title,
    required this.subject,
    required this.reason,
    required this.priority,
  });
}
