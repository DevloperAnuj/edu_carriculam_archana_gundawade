// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curriculum.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chapter _$ChapterFromJson(Map<String, dynamic> json) => Chapter(
  id: json['id'] as String,
  title: json['title'] as String,
  concepts: (json['concepts'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  estimatedTime: json['estimatedTime'] as String,
  isCompleted: json['isCompleted'] as bool? ?? false,
);

Map<String, dynamic> _$ChapterToJson(Chapter instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'concepts': instance.concepts,
  'estimatedTime': instance.estimatedTime,
  'isCompleted': instance.isCompleted,
};

Subject _$SubjectFromJson(Map<String, dynamic> json) => Subject(
  name: json['name'] as String,
  iconAsset: json['iconAsset'] as String,
  chapters: (json['chapters'] as List<dynamic>)
      .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SubjectToJson(Subject instance) => <String, dynamic>{
  'name': instance.name,
  'iconAsset': instance.iconAsset,
  'chapters': instance.chapters,
};

Curriculum _$CurriculumFromJson(Map<String, dynamic> json) => Curriculum(
  grade: (json['grade'] as num).toInt(),
  subjects: (json['subjects'] as List<dynamic>)
      .map((e) => Subject.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CurriculumToJson(Curriculum instance) =>
    <String, dynamic>{'grade': instance.grade, 'subjects': instance.subjects};
