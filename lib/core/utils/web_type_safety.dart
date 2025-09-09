import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web类型安全工具类
/// 用于处理Flutter Web在压缩代码时可能出现的类型错误
class WebTypeSafety {
  /// 安全地获取配置值，避免类型错误
  static T? safeGetConfig<T>(T Function() getter) {
    try {
      return getter();
    } catch (e) {
      if (kDebugMode) {
        print('配置获取失败: $e');
      }
      return null;
    }
  }
  
  /// 安全地执行可能抛出类型错误的操作
  static Future<T?> safeExecute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      if (kDebugMode) {
        print('操作执行失败: $e');
      }
      return null;
    }
  }
  
  /// 安全地创建Provider，避免类型错误
  static T safeCreateProvider<T>(T Function() creator) {
    try {
      return creator();
    } catch (e) {
      if (kDebugMode) {
        print('Provider创建失败: $e');
      }
      // 返回一个默认的Provider实例
      return creator();
    }
  }
  
  /// 安全地访问MediaQuery，避免类型错误
  static MediaQueryData? safeGetMediaQuery(BuildContext context) {
    try {
      return MediaQuery.of(context);
    } catch (e) {
      if (kDebugMode) {
        print('MediaQuery获取失败: $e');
      }
      return null;
    }
  }
  
  /// 安全地访问Theme，避免类型错误
  static ThemeData? safeGetTheme(BuildContext context) {
    try {
      return Theme.of(context);
    } catch (e) {
      if (kDebugMode) {
        print('Theme获取失败: $e');
      }
      return null;
    }
  }
}