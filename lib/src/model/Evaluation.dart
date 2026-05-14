class EvaluationConfig {
  bool? evaluationEnabled;
  List<EvaluationScoreConfig>? configs;
  List<String>? triggerMessages;

  EvaluationConfig({this.evaluationEnabled, this.configs, this.triggerMessages});

  EvaluationConfig.fromJson(Map<String, dynamic> json) {
    evaluationEnabled = json['evaluationEnabled'] as bool?;
    if (json['configs'] is List) {
      configs = (json['configs'] as List)
          .map((e) => EvaluationScoreConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (json['triggerMessages'] is List) {
      triggerMessages =
          (json['triggerMessages'] as List).map((e) => e.toString()).toList();
    }
  }
}

class EvaluationScoreConfig {
  String? content;
  int? score;
  String? feedback;
  int? status;

  EvaluationScoreConfig({this.content, this.score, this.feedback, this.status});

  EvaluationScoreConfig.fromJson(Map<String, dynamic> json) {
    content = json['content'] as String?;
    score = json['score'] as int?;
    feedback = json['feedback'] as String?;
    status = json['status'] as int?;
  }
}

class EvaluationStatus {
  // 0=未评价 1=已评价 2=已关闭评价 3=空会话,无法评价
  int? status;

  EvaluationStatus({this.status});

  EvaluationStatus.fromJson(Map<String, dynamic> json) {
    status = json['status'] as int?;
  }
}
