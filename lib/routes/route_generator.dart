import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/pages/login/login_page.dart';
import 'package:itms_mobile/presentation/widgets/common/error_page.dart';

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
      return buildErrorPage(context);
    });
  }
}
