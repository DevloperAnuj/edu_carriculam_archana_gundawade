import 'package:json_annotation/json_annotation.dart';

part 'student_profile.g.dart';

enum LearningStyle {
  visual,
  auditory,
  kinesthetic,
  readWrite,
}

@JsonSerializable()
class StudentProfile {
  final int grade;
  final List<String> interests;
  final LearningStyle learningStyle;
  final Map<String, Map<String, bool>> progressTracking;

  // Objective 2 – Adaptive Learning: quiz scores per chapter (0–100)
  final Map<String, int> quizScores;

  // Objective 4 – Ethics & Privacy: FERPA-style consent
  final bool consentGiven;

  // Objective 5 – Governance: optional Claude API key for real AI content
  final String? apiKey;

  // Optional student name for personalisation
  final String? studentName;

  StudentProfile({
    required this.grade,
    required this.interests,
    required this.learningStyle,
    this.progressTracking = const {},
    this.quizScores = const {},
    this.consentGiven = false,
    this.apiKey,
    this.studentName,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) =>
      _$StudentProfileFromJson(json);
  Map<String, dynamic> toJson() => _$StudentProfileToJson(this);

  StudentProfile copyWith({
    int? grade,
    List<String>? interests,
    LearningStyle? learningStyle,
    Map<String, Map<String, bool>>? progressTracking,
    Map<String, int>? quizScores,
    bool? consentGiven,
    String? apiKey,
    String? studentName,
  }) {
    return StudentProfile(
      grade: grade ?? this.grade,
      interests: interests ?? this.interests,
      learningStyle: learningStyle ?? this.learningStyle,
      progressTracking: progressTracking ?? this.progressTracking,
      quizScores: quizScores ?? this.quizScores,
      consentGiven: consentGiven ?? this.consentGiven,
      apiKey: apiKey ?? this.apiKey,
      studentName: studentName ?? this.studentName,
    );
  }

  // Objective 2 – derive adaptive difficulty for a chapter
  String adaptiveDifficulty(String chapterId) {
    final score = quizScores[chapterId];
    if (score == null) return 'standard';
    if (score < 50) return 'basic';
    if (score >= 80) return 'advanced';
    return 'standard';
  }

  String get learningStyleLabel {
    switch (learningStyle) {
      case LearningStyle.visual:
        return 'Visual';
      case LearningStyle.auditory:
        return 'Auditory';
      case LearningStyle.kinesthetic:
        return 'Kinesthetic';
      case LearningStyle.readWrite:
        return 'Read/Write';
    }
  }
}
