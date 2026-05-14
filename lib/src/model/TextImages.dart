class TextImages {
  String message;
  List<String> imgs;

  TextImages({required this.message, required this.imgs});

  factory TextImages.fromJson(Map<String, dynamic> json) {
    return TextImages(
      message: json['message'],
      imgs: List<String>.from(json['imgs']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'imgs': imgs,
    };
  }
}
