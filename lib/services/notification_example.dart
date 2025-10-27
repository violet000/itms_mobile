import 'package:flutter/material.dart';
import 'package:itms_mobile/services/notification_service.dart';

/// 通知使用示例
/// 这些示例展示了如何在您的应用中使用通知服务
class NotificationExamples {
  
  /// 示例1: 显示简单通知
  static void showSimpleNotification() {
    NotificationService.showNotification(
      title: '新消息',
      body: '您有一条新的任务需要处理',
    );
  }

  /// 示例2: 显示任务通知
  static void showTaskNotification() {
    NotificationService.showTaskNotification(
      title: '新任务',
      body: '任务编号 #12345 已分配给您',
      taskId: '12345',
    );
  }

  /// 示例3: 显示警报通知
  static void showAlertNotification() {
    NotificationService.showAlertNotification(
      title: '⚠️ 异常警报',
      body: '检测到异常情况，请立即处理',
    );
  }

  /// 示例4: 显示进度通知
  static void showProgressNotification(int current, int total) {
    NotificationService.showProgressNotification(
      title: '数据同步中',
      body: '正在同步数据...',
      progress: current,
      maxProgress: total,
      id: 0, // 进度通知使用固定 ID
    );
  }

  /// 示例5: 显示聊天消息通知
  static void showMessageNotification() {
    NotificationService.showMessageNotification(
      senderName: '张三',
      message: '收到新消息',
      avatarUrl: '', // 可以是头像URL或资源路径
    );
  }

  /// 示例6: 在任务完成时显示通知
  static void showTaskCompleteNotification(String taskName) {
    NotificationService.showNotification(
      title: '任务完成',
      body: '$taskName 已完成',
    );
  }

  /// 示例7: 在数据上传/下载时显示进度
  static void updateUploadProgress(int uploaded, int total) {
    NotificationService.showProgressNotification(
      title: '上传文件',
      body: '正在上传文件...',
      progress: uploaded,
      maxProgress: total,
    );
  }

  /// 示例8: 显示系统维护通知
  static void showMaintenanceNotification() {
    NotificationService.showAlertNotification(
      title: '系统维护',
      body: '系统将在今晚22:00-24:00进行维护',
    );
  }
}

/// 通知使用示例页面
/// 您可以创建一个测试页面来测试通知功能
class NotificationTestPage extends StatelessWidget {
  const NotificationTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知测试'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: NotificationExamples.showSimpleNotification,
            child: const Text('显示基本通知'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: NotificationExamples.showTaskNotification,
            child: const Text('显示任务通知'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: NotificationExamples.showAlertNotification,
            child: const Text('显示警报通知'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // 模拟进度更新
              int progress = 0;
              for (int i = 0; i <= 100; i += 10) {
                Future.delayed(Duration(milliseconds: i * 50), () {
                  NotificationExamples.showProgressNotification(i, 100);
                });
              }
            },
            child: const Text('显示进度通知'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: NotificationExamples.showMessageNotification,
            child: const Text('显示聊天通知'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              NotificationService.cancelAllNotifications();
            },
            child: const Text('取消所有通知'),
          ),
        ],
      ),
    );
  }
}
