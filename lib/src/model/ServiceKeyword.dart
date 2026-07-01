/// 宿主 App 通过自己的接口拿到的「服务关键词」配置。
///
/// 当用户在聊天页输入的文本**包含**任一 [keywords] 时，UISDK 会以
/// `msgSourceType = MST_AUTO_CARD`、`msgFormat = MSG_TEXT` 发送一条卡片消息，
/// 消息体即本对象的 [toJson] 结果，UI 上由 `AutoCardCell` 渲染成卡片。
///
/// [content] 是多态的：
/// - `questionType == 1`：数组，渲染成可点选项按钮（见 [options]）；
/// - `questionType == 2`：字符串，渲染成正文段落（见 [contentText]）。
class ServiceKeyword {
  // jumpCategory 取值（见规范 mst_card_msg.md）：跳转分类。
  static const int jumpNone = 0; // 无跳转
  static const int jumpMiniProgram = 1; // 小程序
  static const int jumpH5 = 2; // H5
  static const int jumpNative = 3; // 原生页

  final int? id;
  final int? questionType;
  final int? category;
  final String? subject;

  /// 原始 content，可能是 `List`（选项）或 `String`（正文）。
  final dynamic content;

  /// 右侧图片链接（仅精准问题可用）。空串 / null 表示无图。
  final String? rightImageUrl;
  final List<String> keywords;
  final int weight;

  /// 跳转分类，见 [jumpNone] / [jumpMiniProgram] / [jumpH5] / [jumpNative]。
  final int? jumpCategory;
  final String? jumpUrl;

  ServiceKeyword({
    this.id,
    this.questionType,
    this.category,
    this.subject,
    this.content,
    this.rightImageUrl,
    this.keywords = const [],
    this.weight = 0,
    this.jumpCategory,
    this.jumpUrl,
  });

  factory ServiceKeyword.fromJson(Map<String, dynamic> json) {
    return ServiceKeyword(
      id: (json['id'] as num?)?.toInt(),
      questionType: (json['questionType'] as num?)?.toInt(),
      category: (json['category'] as num?)?.toInt(),
      subject: json['subject'] as String?,
      content: json['content'],
      rightImageUrl: json['rightImageUrl'] as String?,
      keywords: (json['keywords'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      jumpCategory: (json['jumpCategory'] as num?)?.toInt(),
      jumpUrl: json['jumpUrl'] as String?,
    );
  }

  /// content 为数组时返回选项列表；否则返回空列表。
  List<String> get options => content is List
      ? (content as List).map((e) => e.toString()).toList()
      : const [];

  /// content 为字符串时返回正文；否则返回空串。
  String get contentText => content is String ? content as String : '';

  /// 是否需要跳转：jumpCategory 非「无」且 jumpUrl 非空。
  bool get hasJump =>
      (jumpCategory ?? jumpNone) != jumpNone && (jumpUrl ?? '').isNotEmpty;

  /// 原样还原条目 JSON（content 数组/字符串两种形态都保真）——即卡片消息的文本体。
  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'questionType': questionType,
      'category': category,
      'subject': subject,
      'content': content,
      'keywords': keywords,
      'weight': weight,
    };
    if (rightImageUrl != null) m['rightImageUrl'] = rightImageUrl;
    if (jumpCategory != null) m['jumpCategory'] = jumpCategory;
    if (jumpUrl != null) m['jumpUrl'] = jumpUrl;
    return m;
  }
}
