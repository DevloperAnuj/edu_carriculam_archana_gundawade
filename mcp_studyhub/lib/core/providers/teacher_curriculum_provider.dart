import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/curriculum.dart';

// grade (int) → subject name → list of teacher-added chapters
typedef TeacherAdditions = Map<int, Map<String, List<Chapter>>>;

final teacherCurriculumProvider =
    AsyncNotifierProvider<TeacherCurriculumNotifier, TeacherAdditions>(
        TeacherCurriculumNotifier.new);

class TeacherCurriculumNotifier extends AsyncNotifier<TeacherAdditions> {
  @override
  Future<TeacherAdditions> build() => _load();

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/teacher_curriculum_additions.json');
  }

  Future<TeacherAdditions> _load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return {};
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final result = <int, Map<String, List<Chapter>>>{};
      for (final gradeEntry in raw.entries) {
        final grade = int.tryParse(gradeEntry.key) ?? 0;
        final subjects = gradeEntry.value as Map<String, dynamic>;
        result[grade] = {
          for (final s in subjects.entries)
            s.key: (s.value as List<dynamic>)
                .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
                .toList(),
        };
      }
      return result;
    } catch (e) {
      debugPrint('TeacherCurriculum load error: $e');
      return {};
    }
  }

  Future<void> _save(TeacherAdditions data) async {
    try {
      final file = await _file;
      final encoded = {
        for (final g in data.entries)
          g.key.toString(): {
            for (final s in g.value.entries)
              s.key: s.value.map((c) => c.toJson()).toList(),
          },
      };
      await file.writeAsString(jsonEncode(encoded));
    } catch (e) {
      debugPrint('TeacherCurriculum save error: $e');
    }
  }

  Future<void> addChapter({
    required int grade,
    required String subjectName,
    required Chapter chapter,
  }) async {
    final current = Map<int, Map<String, List<Chapter>>>.from(state.value ?? {});
    current[grade] = Map<String, List<Chapter>>.from(current[grade] ?? {});
    current[grade]![subjectName] =
        List<Chapter>.from(current[grade]![subjectName] ?? [])..add(chapter);
    state = AsyncData(current);
    await _save(current);
  }

  Future<void> removeChapter({
    required int grade,
    required String subjectName,
    required String chapterId,
  }) async {
    final current = Map<int, Map<String, List<Chapter>>>.from(state.value ?? {});
    if (current[grade] == null || current[grade]![subjectName] == null) return;
    current[grade]![subjectName] =
        current[grade]![subjectName]!.where((c) => c.id != chapterId).toList();
    if (current[grade]![subjectName]!.isEmpty) {
      current[grade]!.remove(subjectName);
    }
    if (current[grade]!.isEmpty) current.remove(grade);
    state = AsyncData(current);
    await _save(current);
  }

  /// Generates a unique ID for a teacher-added chapter.
  String generateId(int grade, String subjectName) {
    final prefix =
        'custom_${grade}_${subjectName.toLowerCase().replaceAll(' ', '_')}';
    final existing = state.value?[grade]?[subjectName] ?? [];
    return '${prefix}_${existing.length + 1}';
  }
}
