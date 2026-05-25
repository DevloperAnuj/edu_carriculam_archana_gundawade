import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/curriculum.dart';
import '../../core/providers/curriculum_provider.dart';
import '../../core/providers/teacher_curriculum_provider.dart';
import '../onboarding/student_profile_provider.dart';

class CurriculumEditorScreen extends ConsumerWidget {
  const CurriculumEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider).value;
    final curriculumAsync = ref.watch(curriculumProvider);
    final teacherAdditions = ref.watch(teacherCurriculumProvider).value ?? {};

    final grade = profile?.grade ?? 10;
    final gradeAdditions = teacherAdditions[grade] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Curriculum Editor'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('New Subject'),
            onPressed: () => _showAddSubjectDialog(context, ref, grade),
          ),
        ],
      ),
      body: curriculumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (curriculum) {
          if (curriculum == null) {
            return const Center(child: Text('No curriculum loaded.'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Editing Grade $grade curriculum. '
                        'New subjects and chapters you add here will immediately '
                        'appear in the student\'s dashboard. '
                        'Custom chapters are marked with a "Custom" badge.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

              // Subjects list
              ...curriculum.subjects.map((subject) {
                final customChapters = gradeAdditions[subject.name] ?? [];
                final customIds = customChapters.map((c) => c.id).toSet();

                return _SubjectSection(
                  subject: subject,
                  customChapterIds: customIds,
                  grade: grade,
                  onAddChapter: () =>
                      _showAddChapterDialog(context, ref, grade, subject.name),
                  onDeleteChapter: (chapterId) => ref
                      .read(teacherCurriculumProvider.notifier)
                      .removeChapter(
                        grade: grade,
                        subjectName: subject.name,
                        chapterId: chapterId,
                      ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showAddSubjectDialog(
      BuildContext context, WidgetRef ref, int grade) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Subject'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subject Name',
            hintText: 'e.g. Economics, Environmental Science',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              _showAddChapterDialog(context, ref, grade, name);
            },
            child: const Text('Next: Add Chapter'),
          ),
        ],
      ),
    );
  }

  void _showAddChapterDialog(
      BuildContext context, WidgetRef ref, int grade, String subjectName) {
    final titleCtrl = TextEditingController();
    final conceptsCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '60min');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Chapter to $subjectName'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Chapter Title *',
                    hintText: 'e.g. Thermodynamics',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: conceptsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Key Concepts (comma-separated) *',
                    hintText: 'e.g. Heat Transfer, Specific Heat, Entropy',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Time',
                    hintText: '60min',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final notifier =
                  ref.read(teacherCurriculumProvider.notifier);
              final id =
                  notifier.generateId(grade, subjectName);
              final chapter = Chapter(
                id: id,
                title: titleCtrl.text.trim(),
                concepts: conceptsCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
                estimatedTime: timeCtrl.text.trim().isEmpty
                    ? '60min'
                    : timeCtrl.text.trim(),
              );
              notifier.addChapter(
                grade: grade,
                subjectName: subjectName,
                chapter: chapter,
              );
              // Invalidate curriculum so student view refreshes
              ref.invalidate(curriculumProvider);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '"${chapter.title}" added to $subjectName'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
            child: const Text('Add Chapter'),
          ),
        ],
      ),
    );
  }
}

class _SubjectSection extends StatelessWidget {
  final Subject subject;
  final Set<String> customChapterIds;
  final int grade;
  final VoidCallback onAddChapter;
  final ValueChanged<String> onDeleteChapter;

  const _SubjectSection({
    required this.subject,
    required this.customChapterIds,
    required this.grade,
    required this.onAddChapter,
    required this.onDeleteChapter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.book_outlined),
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${subject.chapters.length} chapters'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Chapter'),
              onPressed: onAddChapter,
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          const Divider(height: 1),
          ...subject.chapters.map((chapter) {
            final isCustom = customChapterIds.contains(chapter.id);
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: isCustom
                    ? Colors.teal.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  isCustom ? Icons.edit_note : Icons.article_outlined,
                  size: 16,
                  color: isCustom
                      ? Colors.teal
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(chapter.title)),
                  if (isCustom)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.teal.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'Custom',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                '${chapter.concepts.join(', ')}  ·  ${chapter.estimatedTime}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: isCustom
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      tooltip: 'Remove chapter',
                      onPressed: () => _confirmDelete(
                          context, chapter.title, chapter.id),
                    )
                  : const Icon(Icons.lock_outline,
                      size: 16, color: Colors.grey),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String title, String chapterId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Chapter?'),
        content: Text('Remove "$title" from the curriculum?\n\n'
            'This cannot be undone. Student progress for this chapter will remain saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onDeleteChapter(chapterId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
