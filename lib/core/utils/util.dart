import 'package:flutter/material.dart';
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:itms_mobile/services/color_settings_service.dart';

class Util {
  static Color getStatusColor(int status) {
    final landmarkStatus = LandmarkStatus.fromCode(status);
    return _hexToColor(landmarkStatus.color);
  }

  // 异步获取状态颜色（使用自定义设置）
  static Future<Color> getStatusColorAsync(int status) async {
    final landmarkStatus = LandmarkStatus.fromCode(status);
    final colorString = await ColorSettingsService.getColorForStatus(landmarkStatus);
    return _hexToColor(colorString);
  }

  // 颜色字符串转Color对象
  static Color hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  /// 将 #RRGGBB 字符串转为 Color
  static Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // 默认不透明
    }
    return Color(int.parse(hex, radix: 16));
  }

}
