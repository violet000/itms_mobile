import 'package:itms_mobile/core/constants/constant.dart';

class ColorSettingsService {
  // 内存存储的颜色设置
  static Map<LandmarkStatus, String> _colorSettings = {};
  static bool _isInitialized = false;
  
  // 初始化颜色设置
  static void _initialize() {
    if (!_isInitialized) {
      for (var status in LandmarkStatus.values) {
        _colorSettings[status] = status.color;
      }
      _isInitialized = true;
    }
  }
  
  // 获取当前颜色设置
  static Future<Map<LandmarkStatus, String>> getColorSettings() async {
    _initialize();
    return Map.from(_colorSettings);
  }
  
  // 保存颜色设置
  static Future<bool> saveColorSettings(Map<LandmarkStatus, String> colorSettings) async {
    try {
      _colorSettings = Map.from(colorSettings);
      return true;
    } catch (e) {
      print('保存颜色设置失败: $e');
      return false;
    }
  }
  
  // 重置颜色设置
  static Future<bool> resetColorSettings() async {
    try {
      _initialize();
      return true;
    } catch (e) {
      print('重置颜色设置失败: $e');
      return false;
    }
  }
  
  // 获取指定状态的颜色值
  static Future<String> getColorForStatus(LandmarkStatus status) async {
    _initialize();
    return _colorSettings[status] ?? status.color;
  }
} 