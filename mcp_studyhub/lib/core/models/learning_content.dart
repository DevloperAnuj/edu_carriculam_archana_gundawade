import 'package:json_annotation/json_annotation.dart';

part 'learning_content.g.dart';

@JsonSerializable()
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuizQuestionToJson(this);
}

@JsonSerializable()
class MultimediaResource {
  final String id;
  final String title;
  final String type; // 'video', 'article', 'infographic'
  final String url;
  final String thumbnailUrl;

  MultimediaResource({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    required this.thumbnailUrl,
  });

  factory MultimediaResource.fromJson(Map<String, dynamic> json) =>
      _$MultimediaResourceFromJson(json);
  Map<String, dynamic> toJson() => _$MultimediaResourceToJson(this);
}
