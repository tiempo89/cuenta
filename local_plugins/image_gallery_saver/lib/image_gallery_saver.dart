import 'package:flutter/services.dart';

class ImageGallerySaver {
  static const MethodChannel _channel = MethodChannel('image_gallery_saver');

  static Future<Map<String, dynamic>> saveFile(String filePath,
      {String? name}) async {
    try {
      final result = await _channel.invokeMethod('saveFile', {
        'filePath': filePath,
        'name': name,
      });
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'isSuccess': false, 'errorMessage': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> saveImage(Uint8List imageBytes) async {
    try {
      final result = await _channel.invokeMethod('saveImage', {
        'imageBytes': imageBytes,
      });
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'isSuccess': false, 'errorMessage': e.toString()};
    }
  }
}
