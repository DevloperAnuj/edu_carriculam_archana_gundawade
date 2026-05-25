import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/student_profile.dart';
import '../../core/services/xapi_service.dart';
import '../../core/services/context_agent.dart';
import '../onboarding/student_profile_provider.dart';

final _xapiSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  return XApiService.statementSummary();
});

final _xapiStatementsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return XApiService.readStatements();
});

/// Teacher Dashboard — Objective 4 & 5 (Ethics / Responsible Implementation)
///
/// Provides educators with a transparent view of student learning data:
/// - xAPI event log summary (verbs fired, counts)
/// - Adaptive difficulty rationale (shows WHY difficulty was set)
/// - Learning gap identification (ContextAgent output)
/// - Overall mastery metric
/// - Algorithmic transparency: shows the rules driving personalisation
class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider).value;
    final summaryAsync = ref.watch(_xapiSummaryProvider);
    final statementsAsync = ref.watch(_xapiStatementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          FilledButton.tonalIcon(
            icon: const Icon(Icons.edit_note),
            label: const Text('Edit Curriculum'),
            onPressed: () => context.push('/teacher/curriculum'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
            onPressed: () {
              ref.invalidate(_xapiSummaryProvider);
              ref.invalidate(_xapiStatementsProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Algorithmic Transparency Banner ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Algorithmic Transparency: Difficulty is set by quiz score. '
                    'Score < 50% → Basic, 50–79% → Standard, ≥ 80% → Advanced. '
                    'Content is personalised by grade + learning style via MCP prompts.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Student Overview ─────────────────────────────────────────────
          _SectionTitle(icon: Icons.person_outlined, title: 'Student Overview'),
          if (profile == null)
            const Card(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No student profile found.'),
            ))
          else
            _StudentOverviewCard(profile: profile),
          const SizedBox(height: 24),

          // ── xAPI Event Summary ───────────────────────────────────────────
          _SectionTitle(
              icon: Icons.bar_chart_outlined, title: 'xAPI Event Summary'),
          summaryAsync.when(
            data: (summary) => summary.isEmpty
                ? const _EmptyCard('No xAPI events recorded yet.')
                : _XapiSummaryCard(summary: summary),
            loading: () =>
                const Card(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => _EmptyCard('Error: $e'),
          ),
          const SizedBox(height: 24),

          // ── Learning Gaps ────────────────────────────────────────────────
          _SectionTitle(
              icon: Icons.warning_amber_outlined, title: 'Learning Gaps'),
          if (profile == null)
            const _EmptyCard('No profile data.')
          else
            _LearningGapsCard(profile: profile),
          const SizedBox(height: 24),

          // ── Recent xAPI Events ───────────────────────────────────────────
          _SectionTitle(
              icon: Icons.receipt_long_outlined, title: 'Recent Learning Events'),
          statementsAsync.when(
            data: (statements) => statements.isEmpty
                ? const _EmptyCard('No events recorded yet.')
                : _RecentEventsCard(statements: statements),
            loading: () =>
                const Card(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => _EmptyCard('Error: $e'),
          ),
          const SizedBox(height: 24),

          // ── Adaptive Algorithm Explanation ───────────────────────────────
          _SectionTitle(
              icon: Icons.auto_fix_high_outlined,
              title: 'Adaptive Algorithm Rationale'),
          if (profile != null) _AdaptiveRationaleCard(profile: profile),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StudentOverviewCard extends StatelessWidget {
  final StudentProfile profile;
  const _StudentOverviewCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final mastery = ContextAgent.overallMastery(profile);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Grade',
                    value: 'Grade ${profile.grade}',
                    icon: Icons.school_outlined,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Learning Style',
                    value: profile.learningStyleLabel,
                    icon: Icons.psychology_outlined,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Chapters Assessed',
                    value: '${profile.quizScores.length}',
                    icon: Icons.quiz_outlined,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Avg Mastery',
                    value: '${mastery.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: mastery >= 80
                        ? Colors.green
                        : mastery >= 50
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ],
            ),
            if (profile.quizScores.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('Quiz Scores per Chapter',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              ...profile.quizScores.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 220,
                          child: Text(e.key,
                              style: const TextStyle(fontSize: 12)),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: e.value / 100,
                            color: e.value >= 80
                                ? Colors.green
                                : e.value >= 50
                                    ? Colors.orange
                                    : Colors.red,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${e.value}%',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _XapiSummaryCard extends StatelessWidget {
  final Map<String, int> summary;
  const _XapiSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary.values.fold(0, (a, b) => a + b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Events: $total',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...summary.entries.map((e) {
              final pct = total > 0 ? e.value / total : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(e.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13)),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${e.value}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LearningGapsCard extends StatelessWidget {
  final StudentProfile profile;
  const _LearningGapsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final gaps = ContextAgent.identifyGaps(profile);
    if (gaps.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('No learning gaps detected. All attempted chapters scored ≥ 60%.'),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${gaps.length} gap(s) identified:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...gaps.map((g) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    g.severity == GapSeverity.critical
                        ? Icons.error_outline
                        : Icons.warning_amber_outlined,
                    color: g.severity == GapSeverity.critical
                        ? Colors.red
                        : Colors.orange,
                  ),
                  title: Text(g.chapterId),
                  subtitle: Text(
                    '${g.score}% — ${g.severity == GapSeverity.critical ? "Critical: score below 40%" : "Moderate: score below 60%"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Chip(
                    label: Text('${g.score}%',
                        style: const TextStyle(fontSize: 11)),
                    backgroundColor: g.severity == GapSeverity.critical
                        ? Colors.red.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _RecentEventsCard extends StatelessWidget {
  final List<Map<String, dynamic>> statements;
  const _RecentEventsCard({required this.statements});

  @override
  Widget build(BuildContext context) {
    final recent = statements.reversed.take(10).toList();
    return Card(
      child: Column(
        children: recent.map((s) {
          final actor =
              (s['actor'] as Map?)?['name'] as String? ?? 'Unknown';
          final verb =
              (s['verb'] as Map?)?['display']?['en-US'] as String? ?? '?';
          final objectName = (s['object'] as Map?)?['definition']?['name']
              ?['en-US'] as String? ?? '?';
          final ts = s['timestamp'] as String? ?? '';
          final score =
              (s['result'] as Map?)?['score']?['raw'] as int?;

          return ListTile(
            dense: true,
            leading: _verbIcon(verb),
            title: Text(
              '$actor $verb $objectName',
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatTimestamp(ts),
              style: const TextStyle(fontSize: 11),
            ),
            trailing: score != null
                ? Chip(
                    label: Text('$score%',
                        style: const TextStyle(fontSize: 11)),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _verbIcon(String verb) {
    switch (verb) {
      case 'launched':
        return const Icon(Icons.play_circle_outline, color: Colors.blue);
      case 'completed':
        return const Icon(Icons.check_circle_outline, color: Colors.green);
      case 'scored':
        return const Icon(Icons.grade_outlined, color: Colors.orange);
      default:
        return const Icon(Icons.circle_outlined, color: Colors.grey);
    }
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _AdaptiveRationaleCard extends StatelessWidget {
  final StudentProfile profile;
  const _AdaptiveRationaleCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How the adaptive algorithm works:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _RuleRow(
              color: Colors.red,
              label: 'Basic difficulty',
              rule: 'Quiz score < 50% — foundational content, extra scaffolding',
            ),
            _RuleRow(
              color: Colors.orange,
              label: 'Standard difficulty',
              rule: 'No score yet OR 50–79% — grade-level curriculum',
            ),
            _RuleRow(
              color: Colors.green,
              label: 'Advanced difficulty',
              rule: 'Quiz score ≥ 80% — deeper analysis, derivations unlocked',
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Current chapter difficulty assignments:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (profile.quizScores.isEmpty)
              const Text('No chapters assessed yet — all set to Standard.',
                  style: TextStyle(color: Colors.grey))
            else
              ...profile.quizScores.entries.map((e) {
                final difficulty = profile.adaptiveDifficulty(e.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 220,
                          child: Text(e.key,
                              style: const TextStyle(fontSize: 12))),
                      Chip(
                        label: Text(difficulty,
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor: difficulty == 'advanced'
                            ? Colors.green.withValues(alpha: 0.15)
                            : difficulty == 'basic'
                                ? Colors.red.withValues(alpha: 0.15)
                                : Colors.orange.withValues(alpha: 0.15),
                      ),
                      const SizedBox(width: 8),
                      Text('(score: ${e.value}%)',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final Color color;
  final String label;
  final String rule;
  const _RuleRow(
      {required this.color, required this.label, required this.rule});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          Expanded(
              child: Text(rule,
                  style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _Metric(
      {required this.label,
      required this.value,
      required this.icon,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
