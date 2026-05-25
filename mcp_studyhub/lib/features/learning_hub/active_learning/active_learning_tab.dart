import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mcp/client_service.dart';
import '../../../core/models/learning_content.dart';
import '../../../core/services/context_agent.dart';
import '../../../core/services/xapi_service.dart';
import '../../../features/onboarding/student_profile_provider.dart';

final quizProvider =
    FutureProvider.family<List<QuizQuestion>, String>((ref, chapterId) async {
  final service = ref.watch(mcpClientServiceProvider);
  final profile = ref.watch(studentProfileProvider).value;
  if (profile == null) return [];
  return service.generateQuiz(chapterId, profile: profile);
});

class ActiveLearningTab extends ConsumerStatefulWidget {
  final String chapterId;
  const ActiveLearningTab({super.key, required this.chapterId});

  @override
  ConsumerState<ActiveLearningTab> createState() => _ActiveLearningTabState();
}

class _ActiveLearningTabState extends ConsumerState<ActiveLearningTab> {
  final Map<String, int> _answers = {};
  bool _submitted = false;
  int _score = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  Future<void> _submitQuiz(List<QuizQuestion> questions) async {
    if (_submitted) return;

    int correct = 0;
    for (final q in questions) {
      if (_answers[q.id] == q.correctAnswerIndex) correct++;
    }
    final score =
        questions.isNotEmpty ? ((correct / questions.length) * 100).round() : 0;
    final duration = DateTime.now().difference(_startTime!).inSeconds;

    setState(() {
      _submitted = true;
      _score = score;
    });

    final profile = ref.read(studentProfileProvider).value;
    if (profile == null) return;

    final studentName =
        profile.studentName ?? profile.interests.firstOrNull ?? 'Student';

    // Update profile via ContextAgent and persist
    final updatedProfile = ContextAgent.updateFromQuizResult(
      profile: profile,
      chapterId: widget.chapterId,
      subjectName: _inferSubject(widget.chapterId),
      score: score,
    );
    await ref
        .read(studentProfileProvider.notifier)
        .saveProfile(updatedProfile);

    // Log xAPI quiz scored event
    await XApiService.logQuizScored(
      chapterId: widget.chapterId,
      chapterTitle: widget.chapterId,
      studentName: studentName,
      score: score,
      durationSeconds: duration,
    );
  }

  String _inferSubject(String chapterId) {
    if (chapterId.startsWith('phys')) return 'Physics';
    if (chapterId.startsWith('math')) return 'Mathematics';
    if (chapterId.startsWith('chem')) return 'Chemistry';
    if (chapterId.startsWith('bio')) return 'Biology';
    if (chapterId.startsWith('cs')) return 'Computer Science';
    return 'General';
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider(widget.chapterId));

    return quizAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error loading quiz: $err')),
      data: (questions) {
        if (questions.isEmpty) {
          return const Center(child: Text('No questions generated.'));
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Adaptive Quiz',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (_submitted)
                  _ScoreBadge(score: _score, total: questions.length),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Difficulty is calibrated to your recent performance on this chapter.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 16),

            ...questions.map((q) => _buildQuestionCard(q)),
            const SizedBox(height: 32),

            if (!_submitted)
              Center(
                child: FilledButton.icon(
                  onPressed: _answers.length < questions.length
                      ? null
                      : () => _submitQuiz(questions),
                  icon: const Icon(Icons.send),
                  label: Text(
                    _answers.length < questions.length
                        ? 'Answer all questions (${_answers.length}/${questions.length})'
                        : 'Submit Quiz',
                  ),
                ),
              )
            else
              _ResultSummary(
                score: _score,
                onRetry: () {
                  setState(() {
                    _answers.clear();
                    _submitted = false;
                    _score = 0;
                    _startTime = DateTime.now();
                  });
                  ref.invalidate(quizProvider(widget.chapterId));
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionCard(QuizQuestion q) {
    final selectedOption = _answers[q.id];
    final isCorrect = _submitted && selectedOption == q.correctAnswerIndex;
    final isWrong = _submitted &&
        selectedOption != null &&
        selectedOption != q.correctAnswerIndex;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: _submitted
              ? (isCorrect
                  ? Colors.green
                  : (isWrong ? Colors.red : Colors.grey.withValues(alpha: 0.3)))
              : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.question,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            RadioGroup<int>(
              groupValue: selectedOption,
              onChanged: (int? val) {
                if (!_submitted && val != null) {
                  setState(() => _answers[q.id] = val);
                }
              },
              child: Column(
                children: List.generate(q.options.length, (index) {
                  final isThisCorrect =
                      _submitted && index == q.correctAnswerIndex;
                  return RadioListTile<int>(
                    value: index,
                    title: Text(q.options[index]),
                    tileColor: isThisCorrect
                        ? Colors.green.withValues(alpha: 0.1)
                        : null,
                    secondary: isThisCorrect
                        ? const Icon(Icons.check, color: Colors.green)
                        : (_submitted &&
                                index == selectedOption &&
                                index != q.correctAnswerIndex
                            ? const Icon(Icons.close, color: Colors.red)
                            : null),
                  );
                }),
              ),
            ),
            if (_submitted && (isWrong || selectedOption == null)) ...[
              const Divider(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      q.explanation,
                      style: const TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  final int total;
  const _ScoreBadge({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final color =
        score >= 80 ? Colors.green : score >= 50 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        '$score%',
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 18, color: color),
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final int score;
  final VoidCallback onRetry;
  const _ResultSummary({required this.score, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final color =
        score >= 80 ? Colors.green : score >= 50 ? Colors.orange : Colors.red;
    final message = score >= 80
        ? 'Excellent! Advanced content unlocked for this chapter.'
        : score >= 50
            ? 'Good effort. Keep practising to reach advanced level.'
            : 'Review the fundamentals — basic content will be shown to help you.';

    return Card(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              score >= 80
                  ? Icons.emoji_events
                  : score >= 50
                      ? Icons.thumb_up_outlined
                      : Icons.refresh,
              color: color,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Score: $score%',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 22, color: color),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retake Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
