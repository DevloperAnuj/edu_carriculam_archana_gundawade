// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentProfile _$StudentProfileFromJson(Map<String, dynamic> json) =>
    StudentProfile(
      grade: (json['grade'] as num).toInt(),
      interests: (json['interests'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      learningStyle: $enumDecode(_$LearningStyleEnumMap, json['learningStyle']),
      progressTracking:
          (json['progressTracking'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, Map<String, bool>.from(e as Map)),
              ) ??
          const {},
      quizScores:
          (json['quizScores'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
          const {},
      consentGiven: json['consentGiven'] as bool? ?? false,
      apiKey: json['apiKey'] as String?,
      studentName: json['studentName'] as String?,
    );

Map<String, dynamic> _$StudentProfileToJson(StudentProfile instance) =>
    <String, dynamic>{
      'grade': instance.grade,
      'interests': instance.interests,
      'learningStyle': _$LearningStyleEnumMap[instance.learningStyle]!,
      'progressTracking': instance.progressTracking,
      'quizScores': instance.quizScores,
      'consentGiven': instance.consentGiven,
      'apiKey': instance.apiKey,
      'studentName': instance.studentName,
    };

const _$LearningStyleEnumMap = {
  LearningStyle.visual: 'visual',
  LearningStyle.auditory: 'auditory',
  LearningStyle.kinesthetic: 'kinesthetic',
  LearningStyle.readWrite: 'readWrite',
};
