class TextBody {
  String? content;
  String? image;
  String? video;
  String? color;

  TextBody({
    this.content,
    this.image,
    this.video,
    this.color,
  });

  // JSON 解析
  factory TextBody.fromJson(Map<String, dynamic> json) {
    return TextBody(
      content: json['content'] as String?,
      image: json['image'] as String?,
      video: json['video'] as String?,
      color: json['color'] as String?,
    );
  }

  // JSON 序列化
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'image': image,
      'video': video,
      'color': color,
    };
  }
}
