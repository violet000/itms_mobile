import 'package:flutter/foundation.dart';
import 'env_config.dart';
import 'env_dev.dart';
import 'env_test.dart';
import 'env_prod.dart';

class Env {
  static Future<void> init() async {
    try {
      // 根据编译模式自动判断环境
      if (kDebugMode) {
        // 在调试模式下，默认使用开发环境
        final config = await DevConfig.config;
        // 确保配置被正确设置
        if (config != null) {
          EnvConfig.setInstance(config);
        }
      } else if (kProfileMode) {
        // 在性能分析模式下，使用测试环境
        final config = await TestConfig.config;
        if (config != null) {
          EnvConfig.setInstance(config);
        }
      } else {
        // 在发布模式下，使用生产环境
        final config = await ProdConfig.config;
        if (config != null) {
          EnvConfig.setInstance(config);
        }
      }
    } catch (e) {
      // 如果配置加载失败，使用默认配置
      EnvConfig.setInstance(EnvConfig(
        apiBaseUrl: 'http://localhost',
        appName: '智慧仓储系统',
        enableLogging: false,
        environment: Environment.prod,
      ));
    }
  }

  static EnvConfig get config => EnvConfig.instance;
  
  static bool get isDevelopment => EnvConfig.isDevelopment();
  static bool get isTest => EnvConfig.isTest();
  static bool get isProduction => EnvConfig.isProduction();
} 