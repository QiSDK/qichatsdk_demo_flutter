class UploadPercent {
  int? percentage;
  Urls? data;

  UploadPercent({this.percentage, this.data});

  UploadPercent.fromJson(Map<String, dynamic> json) {
    percentage = json['percentage'];
    data = json['data'] != null ? new Urls.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['percentage'] = this.percentage;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Urls {
  String? uri;
  String? hlsUri;
  String? thumbnailUri;

  Urls({this.uri, this.hlsUri, this.thumbnailUri});

  Urls.fromJson(Map<String, dynamic> json) {
    uri = json['uri'];
    hlsUri = json['hlsUri'];
    thumbnailUri = json['thumbnailUri'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['uri'] = this.uri;
    data['hlsUri'] = this.hlsUri;
    data['thumbnailUri'] = this.thumbnailUri;
    return data;
  }
}
