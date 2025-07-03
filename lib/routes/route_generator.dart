import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/pages/login/login_page.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    // 根据路由名称返回对应的页面
    switch (settings.name) {
      case '/':
      case '/login':
        return MaterialPageRoute<dynamic>(builder: (_) => const LoginPage());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute<dynamic>(builder: (context) {
      return WillPopScope(
        onWillPop: () async {
          // 跳转到主页并清空页面栈
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          return false; // 阻止默认返回
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('错误'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (route) => false);
              },
            ),
          ),
          body: const Center(
            child: Text('页面不存在'),
          ),
        ),
      );
    });
  }
}
