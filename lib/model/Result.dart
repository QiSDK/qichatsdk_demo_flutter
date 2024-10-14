class Result<T> {
  int? code;
  String? msg;
  T? data;

  Result({this.code, this.msg, this.data});

  // This method requires a function to convert JSON into the desired generic type T
  Result.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
    code = json['code'];
    msg = json['msg'];
    data = json['data'] != null ? fromJsonT(json['data']) : null;
  }

  Map<String, dynamic> toJson(Object Function(T? data) toJsonT) {
    final Map<String, dynamic> json = {};
    json['code'] = code;
    json['msg'] = msg;
    if (data != null) {
      json['data'] = toJsonT(data);
    }
    return json;
  }
}
