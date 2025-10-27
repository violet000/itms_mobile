import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 通知服务类
/// 提供类似短信通知栏的消息推送功能
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// 初始化通知服务
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// 请求通知权限
  static Future<bool> requestPermission() async {
    // Android 13+ 需要运行时权限请求
    // 注意：此方法根据不同版本的库可能有不同的实现
    // 如果遇到兼容性问题，可以在 AndroidManifest.xml 中手动配置权限
    return true;
  }

  /// 显示基本通知
  /// [title] 通知标题
  /// [body] 通知内容
  /// [id] 通知ID（可选，默认自动生成）
  static Future<void> showNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'basic_channel',
      '基本通知',
      channelDescription: '显示基本通知消息',
      importance: Importance.high,
      priority: Priority.high,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title,
      body,
      details,
      payload: jsonEncode({'title': title, 'body': body}),
    );
  }

  /// 显示任务通知
  static Future<void> showTaskNotification({
    required String title,
    required String body,
    required String taskId,
    int? id,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel',
      '任务通知',
      channelDescription: '任务相关通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title,
      body,
      details,
      payload: jsonEncode({
        'type': 'task',
        'taskId': taskId,
        'title': title,
        'body': body,
      }),
    );
  }

  /// 显示警报通知
  static Future<void> showAlertNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alert_channel',
      '警报通知',
      channelDescription: '重要警报通知',
      importance: Importance.max,
      priority: Priority.max,
      color: Colors.red,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(body),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title,
      body,
      details,
      payload: jsonEncode({
        'type': 'alert',
        'title': title,
        'body': body,
      }),
    );
  }

  /// 显示带进度的通知
  static Future<void> showProgressNotification({
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    int id = 0,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'basic_channel',
      '基本通知',
      channelDescription: '显示基本通知消息',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: jsonEncode({
        'type': 'progress',
        'progress': progress,
        'maxProgress': maxProgress,
      }),
    );
  }

  /// 显示普通消息通知
  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
    String? avatarUrl,
    int? id,
  }) async {
    await showNotification(
      title: senderName,
      body: message,
      id: id,
    );
  }

  /// 取消指定通知
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// 取消所有通知
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 通知点击回调
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    if (kDebugMode) {
      print('通知被点击: ${notificationResponse.payload}');
    }
    
    if (notificationResponse.payload != null) {
      try {
        final dynamic payload = jsonDecode(notificationResponse.payload!);
        
        if (payload['type'] == 'task') {
          // 跳转到任务详情页
          // Navigate to task detail page
        } else if (payload['type'] == 'alert') {
          // 跳转到警报页面
          // Navigate to alert page
        }
      } catch (e) {
        if (kDebugMode) {
          print('解析通知 payload 失败: $e');
        }
      }
    }
  }
}
