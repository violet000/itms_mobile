import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/pages/login/login_page.dart';
import 'package:itms_mobile/presentation/pages/home/home.dart';
import 'package:itms_mobile/presentation/pages/inner_work/inbound_management_page.dart';
import 'package:itms_mobile/presentation/pages/inner_work/outbound_management_page.dart';
import 'package:itms_mobile/presentation/pages/vendor_mode/vendor_mode_page.dart';
import 'package:itms_mobile/presentation/pages/storage/storage_area.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String storageArea = '/storage/storage-area';
  static const String inboundManagement = '/inner_work/inbound';
  static const String outboundManagement = '/inner_work/outbound';
  static const String vendorMode = '/vendor_mode';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // 登录
      login: (context) => const LoginPage(),
      // 主页
      home: (context) => const HomePage(),
      // 仓储区域
      storageArea: (context) => const StorageArea(),
      // 库内作业
      inboundManagement: (context) => const InboundManagementPage(),
      outboundManagement: (context) => const OutboundManagementPage(),
      // 厂商模式
      vendorMode: (context) => const VendorModePage(),
    };
  }
} 