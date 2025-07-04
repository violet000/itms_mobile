import 'package:flutter/material.dart';

/// 应用全局主题配置
class AppTheme {
  /// 获取应用主题数据
  static ThemeData get theme => ThemeData(
    // 基础配置
    primarySwatch: Colors.blue,
    useMaterial3: true,
    
    // 取消所有按钮的水波纹效果
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    
    // ElevatedButton 样式
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
      ),
    ),
    
    // TextButton 样式
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
      ),
    ),
    
    // OutlinedButton 样式
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
      ),
    ),
    
    // IconButton 样式
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
      ),
    ),
  );
} 