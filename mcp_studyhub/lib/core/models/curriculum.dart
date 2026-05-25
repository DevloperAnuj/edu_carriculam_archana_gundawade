import 'package:json_annotation/json_annotation.dart';

part 'curriculum.g.dart';

@JsonSerializable()
class Chapter {
  final String id;
  final String title;
  final List<String> concepts;
  final String estimatedTime;
  final bool
  isCompleted; // Local state, technically might be in StudentProfile but useful here for UI merging

  Chapter({
    required this.id,
    required this.title,
    required this.concepts,
    required this.estimatedTime,
    this.isCompleted = false,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);
  Map<String, dynamic> toJson() => _$ChapterToJson(this);
}

@JsonSerializable()
class Subject {
  final String name;
  final String iconAsset; // Path to icon or code
  final List<Chapter> chapters;

  Subject({
    required this.name,
    required this.iconAsset,
    required this.chapters,
  });

  factory Subject.fromJson(Map<String, dynamic> json) =>
      _$SubjectFromJson(json);
  Map<String, dynamic> toJson() => _$SubjectToJson(this);
}

@JsonSerializable()
class Curriculum {
  final int grade;
  final List<Subject> subjects;

  Curriculum({required this.grade, required this.subjects});

  factory Curriculum.fromJson(Map<String, dynamic> json) =>
      _$CurriculumFromJson(json);
  Map<String, dynamic> toJson() => _$CurriculumToJson(this);
}
