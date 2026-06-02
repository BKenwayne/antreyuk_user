import 'dart:convert';
import 'package:flutter/material.dart';

class ImageHelper {
  /// Returns an ImageProvider if the string is a valid URL or Base64.
  /// Returns null if the string is empty or invalid, allowing UI to show a placeholder icon.
  static ImageProvider? getImageProvider(String? urlStr) {
    if (urlStr == null || urlStr.isEmpty) {
      return null;
    }
    
    if (urlStr.startsWith('http://') || urlStr.startsWith('https://')) {
      return NetworkImage(urlStr);
    }
    
    try {
      final decodedBytes = base64Decode(urlStr);
      return MemoryImage(decodedBytes);
    } catch (e) {
      return null;
    }
  }
}
