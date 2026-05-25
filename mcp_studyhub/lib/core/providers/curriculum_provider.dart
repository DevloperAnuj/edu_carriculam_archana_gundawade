import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/onboarding/student_profile_provider.dart';
import '../models/curriculum.dart';
import 'teacher_curriculum_provider.dart';

final curriculumProvider = FutureProvider<Curriculum?>((ref) async {
  final profileState = ref.watch(studentProfileProvider);
  final teacherAdditions = ref.watch(teacherCurriculumProvider).value ?? {};

  return profileState.when(
    data: (profile) async {
      if (profile == null) return null;
      final grade = profile.grade;
      try {
        final String response = await rootBundle.loadString(
          'assets/curriculum/grade_${grade}_curriculum.json',
        );
        final base = Curriculum.fromJson(json.decode(response));
        return _merge(base, teacherAdditions[grade] ?? {});
      } catch (e) {
        // ignore: avoid_print
        print('Error loading curriculum: $e');
        return null;
      }
    },
    error: (e, _) => null,
    loading: () => null,
  );
});

/// Merges teacher-added chapters into the base curriculum.
/// New subjects are appended; additional chapters are added to existing subjects.
Curriculum _merge(
  Curriculum base,
  Map<String, List<Chapter>> additions,
) {
  if (additions.isEmpty) return base;

  final subjectMap = {for (final s in base.subjects) s.name: s};

  for (final entry in additions.entries) {
    final subjectName = entry.key;
    final extraChapters = entry.value;
    if (subjectMap.containsKey(subjectName)) {
      final existing = subjectMap[subjectName]!;
      subjectMap[subjectName] = Subject(
        name: existing.name,
        iconAsset: existing.iconAsset,
        chapters: [...existing.chapters, ...extraChapters],
      );
    } else {
      subjectMap[subjectName] = Subject(
        name: subjectName,
        iconAsset: 'assets/icons/custom.png',
        chapters: extraChapters,
      );
    }
  }

  return Curriculum(grade: base.grade, subjects: subjectMap.values.toList());
}
