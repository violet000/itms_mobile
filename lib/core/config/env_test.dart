import 'env_config.dart';

// 测试环境配置
class TestConfig {
  static EnvConfig get config => EnvConfig(
        apiBaseUrl: 'https://test-api.example.com',
        appName: '智慧仓储系统(测试环境)',
        enableLogging: true,
        environment: Environment.test,
      );
} 