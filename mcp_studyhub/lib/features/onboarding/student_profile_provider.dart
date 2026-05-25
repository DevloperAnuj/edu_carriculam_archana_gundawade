import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/models/student_profile.dart';

// Manual AsyncNotifierProvider
final studentProfileProvider =
    AsyncNotifierProvider<StudentProfileNotifier, StudentProfile?>(() {
      return StudentProfileNotifier();
    });

class StudentProfileNotifier extends AsyncNotifier<StudentProfile?> {
  @override
  Future<StudentProfile?> build() async {
    return _loadProfile();
  }

  Future<File> get _profileFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/student_profile.json');
  }

  Future<StudentProfile?> _loadProfile() async {
    try {
      final file = await _profileFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        return StudentProfile.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
    return null;
  }

  Future<void> saveProfile(StudentProfile profile) async {
    state = AsyncData(profile);
    try {
      final file = await _profileFile;
      await file.writeAsString(jsonEncode(profile.toJson()));
    } catch (e, st) {
      debugPrint('Error saving profile: $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteProfile() async {
    try {
      final file = await _profileFile;
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Error deleting profile: $e');
    }
    state = const AsyncData(null);
  }

  Future<void> updateProgress(
    String subject,
    String chapterId,
    bool completed,
  ) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final newProgress = Map<String, Map<String, bool>>.from(
      currentProfile.progressTracking,
    );
    newProgress[subject] = Map<String, bool>.from(
      newProgress[subject] ?? {},
    )..[chapterId] = completed;

    await saveProfile(currentProfile.copyWith(progressTracking: newProgress));
  }
}
