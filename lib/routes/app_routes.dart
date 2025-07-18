import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/pages/login/login_page.dart';
import 'package:itms_mobile/presentation/pages/home/home.dart';
import 'package:itms_mobile/presentation/pages/inner_work/hand_task.dart';
import 'package:itms_mobile/presentation/pages/inner_work/hand_task_detail.dart';
import 'package:itms_mobile/presentation/pages/inner_work/point_to_point_transportation.dart';
import 'package:itms_mobile/presentation/pages/personal_center/personal_center_page.dart';
import 'package:itms_mobile/presentation/pages/personal_center/landmark_color_settings_page.dart';
import 'package:itms_mobile/presentation/pages/personal_center/shelf_management_page.dart';
import 'package:itms_mobile/presentation/pages/storage/storage_area.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String storageArea = '/storage/storage-area';
  static const String handTask = '/inner_work/hand-task';
  static const String handTaskDetail = '/inner_work/hand-task-detail';
  static const String pointToPoint = '/inner_work/point-to-point';
  static const String personalCenter = '/personal_center';
  static const String landmarkColorSettings = '/personal_center/landmark-color-settings';
  static const String shelfManagement = '/personal_center/shelf-management';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // 登录
      login: (context) => const LoginPage(),
      // 主页
      home: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return HomePage(arguments: args);
      },
      // 仓储区域
      storageArea: (context) => const StorageArea(),
      // 库内作业
      handTask: (context) => const HandTaskPage(),
      handTaskDetail: (context) => const HandTaskDetailPage(),
      pointToPoint: (context) => const PointToPointPage(),
      // 个人中心
      personalCenter: (context) => const PersonalCenterPage(),
      landmarkColorSettings: (context) => const LandmarkColorSettingsPage(),
      shelfManagement: (context) => const ShelfManagementPage(),
    };
  }
} 