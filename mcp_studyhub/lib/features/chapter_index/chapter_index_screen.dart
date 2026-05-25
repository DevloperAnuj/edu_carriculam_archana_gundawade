import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/curriculum.dart';
import '../../core/providers/curriculum_provider.dart';
import '../onboarding/student_profile_provider.dart';

class ChapterIndexScreen extends ConsumerWidget {
  final String subjectId;
  const ChapterIndexScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculumAsync = ref.watch(curriculumProvider);
    final profileState = ref.watch(studentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(subjectId)),
      body: curriculumAsync.when(
        data: (curriculum) {
          if (curriculum == null) {
            return const Center(child: Text("Curriculum not found"));
          }

          final subject = curriculum.subjects
              .where((s) => s.name == subjectId)
              .firstOrNull;
          if (subject == null) {
            return const Center(child: Text("Subject not found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subject.chapters.length,
            itemBuilder: (context, index) {
              final chapter = subject.chapters[index];
              return _ChapterCard(
                chapter: chapter,
                subjectId: subjectId,
                profileState: profileState,
              );
            },
          );
        },
        error: (err, st) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final Chapter chapter;
  final String subjectId;
  final AsyncValue<dynamic>
  profileState; // Using dynamic because of the complicated type, cast inside

  const _ChapterCard({
    required this.chapter,
    required this.subjectId,
    required this.profileState,
  });

  @override
  Widget build(BuildContext context) {
    bool isCompleted = false;
    final profile = profileState.value; // Accessing safely
    if (profile != null) {
      // accessing StudentProfile
      final progress = profile.progressTracking[subjectId];
      if (progress != null) {
        isCompleted = progress[chapter.id] == true;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? Colors.green
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            isCompleted ? Icons.check : Icons.local_library,
            color: isCompleted
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        title: Text(
          chapter.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Concepts: ${chapter.concepts.join(', ')}"),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  chapter.estimatedTime,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.push('/learn/${chapter.id}');
        },
      ),
    );
  }
}
