import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/curriculum.dart';
import '../../core/models/student_profile.dart';
import '../../core/providers/curriculum_provider.dart';
import '../../core/services/context_agent.dart';
import '../../core/services/xapi_service.dart';
import '../onboarding/student_profile_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _logSession());
  }

  Future<void> _logSession() async {
    final profile = ref.read(studentProfileProvider).value;
    if (profile == null) return;
    final name = profile.studentName ?? profile.interests.firstOrNull ?? 'Student';
    await XApiService.logSessionStarted(studentName: name);
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(studentProfileProvider);
    final curriculumState = ref.watch(curriculumProvider);
    final profile = profileState.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          profile != null
              ? 'Welcome${profile.studentName != null ? ", ${profile.studentName}" : ""}!'
              : 'MCP StudyHub',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: 'Teacher Dashboard',
            onPressed: () => context.push('/teacher'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings & Governance',
            onPressed: () => context.push('/settings'),
          ),
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.person_outline, size: 16),
                label: Text('Grade ${profile.grade}'),
              ),
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Side Navigation
          NavigationRail(
            selectedIndex: _navIndex,
            onDestinationSelected: (i) => setState(() => _navIndex = i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Subjects'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.trending_up_outlined),
                selectedIcon: Icon(Icons.trending_up),
                label: Text('Progress'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.lightbulb_outlined),
                selectedIcon: Icon(Icons.lightbulb),
                label: Text('Suggested'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // Main content
          Expanded(
            child: IndexedStack(
              index: _navIndex,
              children: [
                _SubjectsPane(curriculumState: curriculumState, profile: profile),
                _ProgressPane(profile: profile),
                _RecommendationsPane(
                  profile: profile,
                  curriculumState: curriculumState,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subjects Pane ──────────────────────────────────────────────────────────────

class _SubjectsPane extends ConsumerWidget {
  final AsyncValue<dynamic> curriculumState;
  final StudentProfile? profile;
  const _SubjectsPane(
      {required this.curriculumState, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Subjects',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Expanded(
            child: curriculumState.when(
              data: (curriculum) {
                if (curriculum == null) {
                  return const Center(
                      child: Text('No curriculum data found for your grade.'));
                }
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: curriculum.subjects.length,
                  itemBuilder: (context, index) {
                    final subject = curriculum.subjects[index];
                    return _SubjectCard(subject: subject, profile: profile);
                  },
                );
              },
              error: (err, _) => Center(child: Text('Error: $err')),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Pane ──────────────────────────────────────────────────────────────

class _ProgressPane extends StatelessWidget {
  final StudentProfile? profile;
  const _ProgressPane({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Center(child: Text('No profile data.'));
    }
    final mastery = ContextAgent.overallMastery(profile!);
    final gaps = ContextAgent.identifyGaps(profile!);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Learning Progress',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),

        // Mastery card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Overall Mastery',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: mastery / 100,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                  color: mastery >= 80
                      ? Colors.green
                      : mastery >= 50
                          ? Colors.orange
                          : Colors.red,
                ),
                const SizedBox(height: 8),
                Text('${mastery.toStringAsFixed(1)}% across '
                    '${profile!.quizScores.length} assessed chapter(s)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quiz scores per chapter
        if (profile!.quizScores.isNotEmpty) ...[
          Text('Quiz Scores',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...profile!.quizScores.entries.map((e) {
            final difficulty = profile!.adaptiveDifficulty(e.key);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(e.key),
                subtitle: Text('Adaptive difficulty: $difficulty'),
                trailing: Chip(
                  label: Text('${e.value}%'),
                  backgroundColor: e.value >= 80
                      ? Colors.green.withValues(alpha: 0.15)
                      : e.value >= 50
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                ),
              ),
            );
          }),
        ],

        // Learning gaps
        if (gaps.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Learning Gaps',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...gaps.map((g) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
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
                    '${g.score}% — ${g.severity.name}',
                  ),
                  trailing: OutlinedButton(
                    onPressed: () =>
                        context.push('/learn/${g.chapterId}'),
                    child: const Text('Revisit'),
                  ),
                ),
              )),
        ],
      ],
    );
  }
}

// ── Recommendations Pane ───────────────────────────────────────────────────────

class _RecommendationsPane extends StatelessWidget {
  final StudentProfile? profile;
  final AsyncValue<dynamic> curriculumState;
  const _RecommendationsPane(
      {required this.profile, required this.curriculumState});

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Center(child: Text('Complete onboarding to see suggestions.'));
    }

    return curriculumState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (curriculum) {
        if (curriculum == null) {
          return const Center(child: Text('No curriculum data.'));
        }

        final allIds = <String>[];
        final titles = <String, String>{};
        final subjects = <String, String>{};
        for (final s in curriculum.subjects) {
          for (final c in s.chapters) {
            allIds.add(c.id);
            titles[c.id] = c.title;
            subjects[c.id] = s.name;
          }
        }

        final recs = ContextAgent.recommend(
          profile: profile!,
          allChapterIds: allIds,
          chapterTitles: titles,
          chapterSubjects: subjects,
        );

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Suggested Next Steps',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Personalised recommendations based on your progress and learning gaps.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 20),
            if (recs.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Great work! All chapters are on track. '
                    'Head to Subjects to explore more chapters.',
                  ),
                ),
              )
            else
              ...recs.map((r) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            r.priority == RecommendationPriority.gap
                                ? Colors.orange.withValues(alpha: 0.15)
                                : Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                        child: Icon(
                          r.priority == RecommendationPriority.gap
                              ? Icons.refresh
                              : Icons.arrow_forward,
                          color: r.priority == RecommendationPriority.gap
                              ? Colors.orange
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(r.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text('${r.subject} — ${r.reason}'),
                      trailing: FilledButton(
                        onPressed: () =>
                            context.push('/learn/${r.chapterId}'),
                        child: const Text('Start'),
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

// ── Subject Card ───────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final StudentProfile? profile;
  const _SubjectCard({required this.subject, required this.profile});

  @override
  Widget build(BuildContext context) {
    int completed = 0;
    final total = subject.chapters.length;
    if (profile != null &&
        profile!.progressTracking.containsKey(subject.name)) {
      completed =
          profile!.progressTracking[subject.name]!.values.where((v) => v).length;
    }
    final progress = total > 0 ? completed / total : 0.0;

    final iconData = _subjectIcon(subject.name);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/subject/${subject.name}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Center(
                  child: Icon(iconData,
                      size: 48,
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 4),
                  Text('$completed / $total chapters',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _subjectIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('physics')) return Icons.science_outlined;
    if (lower.contains('math')) return Icons.calculate_outlined;
    if (lower.contains('chem')) return Icons.biotech_outlined;
    if (lower.contains('bio')) return Icons.eco_outlined;
    if (lower.contains('computer') || lower.contains('cs')) {
      return Icons.computer_outlined;
    }
    return Icons.book_outlined;
  }
}
