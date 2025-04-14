class ReplyMessageItem {
  String? id;
  String? fileName;
  int? size;
  String? content;

  ReplyMessageItem({this.id, this.fileName, this.size, this.content});

  ReplyMessageItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fileName = json['fileName'];
    size = json['size'];
    content = json['content'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['fileName'] = this.fileName;
    data['size'] = this.size;
    data['content'] = this.content;
    return data;
  }
}
