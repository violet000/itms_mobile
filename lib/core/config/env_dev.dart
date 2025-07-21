import 'env_config.dart';
// import '../utils/asset_loader.dart';

// 开发环境配置
class DevConfig {
  // static Future<Map<String, dynamic>> get locationConfig => AssetLoader.loadLocationConfig();
  
  static Future<EnvConfig> get config async {
    // final locationData = await locationConfig;
    // print('locationData: $locationData');
    return EnvConfig(
      apiBaseUrl: 'http://10.34.12.130',
      appName: '智慧仓储系统(开发环境)',
      enableLogging: true,
      environment: Environment.dev,
    );
  }
}