import 'package:flutter/foundation.dart';

/// Web错误处理工具类
class WebErrorHandler {
  /// 安全执行异步操作，避免Web release模式下的类型错误
  static Future<T?> safeAsync<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      if (kDebugMode) {
        print('Web异步操作错误: $e');
      }
      return null;
    }
  }
  
  /// 安全执行同步操作
  static T? safeSync<T>(T Function() operation) {
    try {
      return operation();
    } catch (e) {
      if (kDebugMode) {
        print('Web同步操作错误: $e');
      }
      return null;
    }
  }
  
  /// 包装Future以避免类型错误
  static Future<void> safeVoid(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (e) {
      if (kDebugMode) {
        print('Web void操作错误: $e');
      }
      // 确保即使出错也返回一个完成的Future
      return;
    }
  }
  
  /// 安全执行可能抛出类型错误的操作
  static T? safeTypeOperation<T>(T Function() operation) {
    try {
      return operation();
    } catch (e) {
      if (kDebugMode) {
        print('Web类型操作错误: $e');
      }
      return null;
    }
  }
}