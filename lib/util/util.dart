import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Util {
  static Future<String?> xFileToBase64(XFile xFile) async {
    try {
      // 读取文件字节
      File file = File(xFile.path);
      if (kDebugMode) {
        print('图片大小${file.readAsBytesSync().lengthInBytes / 1024 / 1024}');
      }

      List<int> imageBytes = await file.readAsBytes();

      // 将文件字节编码为Base64字符串
      String base64Image = base64Encode(imageBytes);
      return base64Image;
    } catch (e) {
      print("Error converting XFile to Base64: $e");
      return null;
    }
  }

  static String convertDateToString(DateTime? dateTime){
    if (dateTime == null){
      return "2000-05-12 12:00:00";
    }
    // Convert to GMT-8 by subtracting 8 hours
    DateTime gmt8DateTime = dateTime.toUtc().add(Duration(hours: 8));

    //print("Original DateTime (UTC): $dateTime");
    //print("Converted to GMT-8: $gmt8DateTime");
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(gmt8DateTime);
  }

  static String convertTime(String? utcTime){
    // Original date and time in UTC
    String dateString = utcTime ?? "2000-05-12 12:00:00";
    DateTime dateTime = DateTime.parse(dateString);

    // Convert to GMT-8 by subtracting 8 hours
    DateTime gmt8DateTime = dateTime.toUtc().add(Duration(hours: -8));

    print("Original DateTime (UTC): $dateTime");
    print("Converted to GMT-8: $gmt8DateTime");
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(gmt8DateTime);
  }

  static DateTime? parseStringToDateTime(String? str) {
    if (str == null || str.isEmpty) {
      return null; // 如果字符串为空或为 null，返回 null
    }

    try {
      return DateTime.parse(str); // 尝试将字符串转换为 DateTime
    } catch (e) {
      print('Error parsing string to DateTime: $e');
      return null; // 如果转换失败，返回 null
    }
  }

  Future<String> generateThumbnail(String videoPath) async {
    try {
      // Get the temporary directory to store the thumbnail
      final Directory tempDir = await getTemporaryDirectory();
      var fileAr = videoPath.split("/");
      var fileName = videoPath.split("/").last;
      if (fileAr.length > 3){
        fileName = fileAr[fileAr.length - 2];
      }

      //var ex = videoPath.split(".").last;
      fileName = fileName + ".jpg";
      final String thumbnailPath = '${tempDir.path}/${fileName}';

      if (File(thumbnailPath).existsSync()){
        print("缩略图地址已存在:" + thumbnailPath);
        return thumbnailPath;
      }

      // FFmpeg command to extract a frame from the video
      final String command = '-i "$videoPath" -ss 00:00:01 -vframes 1 "$thumbnailPath"';

      // Run the FFmpeg command
      await FFmpegKit.execute(command);

      // Check if the thumbnail was generated
      if (File(thumbnailPath).existsSync()) {
        //setState(() {
          //_thumbnailPath = thumbnailPath;
          print("缩略图地址:" + thumbnailPath);
        //});
        return thumbnailPath;
      } else {
        print("Thumbnail generation failed.");
        return "";
      }
    } catch (e) {
      print("Error generating thumbnail: $e");
      return "";
    }
  }

  Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
      var _versionName = packageInfo.version; // Version name (e.g., 1.0.0)
      var _versionCode = packageInfo.buildNumber; // Version code (e.g., 1)
      return '$_versionName ($_versionCode)';
  }


}
