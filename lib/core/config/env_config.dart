enum Environment {
  dev,
  test,
  prod,
}

class EnvConfig {
  final String apiBaseUrl;
  final String appName;
  final bool enableLogging;
  final Environment environment;

  static EnvConfig? _instance;
  
  // 提供公共的setter方法用于外部设置实例
  static void setInstance(EnvConfig instance) {
    _instance = instance;
  }

  factory EnvConfig({
    required String apiBaseUrl,
    required String appName,
    required bool enableLogging,
    required Environment environment,
  }) {
    _instance ??= EnvConfig._internal(
      apiBaseUrl: apiBaseUrl,
      appName: appName,
      enableLogging: enableLogging,
      environment: environment,
    );
    return _instance!;
  }

  EnvConfig._internal({
    required this.apiBaseUrl,
    required this.appName,
    required this.enableLogging,
    required this.environment,
  });

  static EnvConfig get instance {
    if (_instance == null) {
      // 如果实例为空，返回默认配置
      _instance = EnvConfig._internal(
        apiBaseUrl: 'http://localhost',
        appName: '智慧仓储系统',
        enableLogging: false,
        environment: Environment.prod,
      );
    }
    return _instance!;
  }

  static bool isDevelopment() => _instance?.environment == Environment.dev;
  static bool isTest() => _instance?.environment == Environment.test;
  static bool isProduction() => _instance?.environment == Environment.prod;

} 