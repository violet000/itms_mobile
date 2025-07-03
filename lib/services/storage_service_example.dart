import 'package:itms_mobile/services/storage_service.dart';

/// StorageService 使用示例
class StorageServiceExample {
  
  /// 示例1: 在页面初始化时获取仓储信息
  static Future<void> initializeStorageData() async {
    try {
      final storageData = await StorageService().getStorageAreas();
      print('页面初始化获取仓储数据: $storageData');
    } catch (e) {
      print('初始化仓储数据失败: $e');
    }
  }

  /// 示例2: 在用户手动刷新时强制获取最新数据
  static Future<void> refreshStorageData() async {
    try {
      final storageData = await StorageService().refreshStorageAreas();
      print('手动刷新获取最新仓储数据: $storageData');
    } catch (e) {
      print('刷新仓储数据失败: $e');
    }
  }

  /// 示例4: 在用户登出时清除缓存
  static void clearStorageCache() {
    StorageService().clearCache();
    print('仓储缓存已清除');
  }

  /// 示例5: 在仓储管理页面使用
  static Future<Map<String, dynamic>> getStorageForManagement() async {
    try {
      // 这里会自动使用缓存或从API获取
      return await StorageService().getStorageAreas();
    } catch (e) {
      print('获取仓储管理数据失败: $e');
      return <String, dynamic>{};
    }
  }

  /// 示例6: 在报表页面使用
  static Future<Map<String, dynamic>> getStorageForReport() async {
    try {
      // 报表页面可能需要最新数据，可以强制刷新
      return await StorageService().refreshStorageAreas();
    } catch (e) {
      print('获取仓储报表数据失败: $e');
      return <String, dynamic>{};
    }
  }
}

/// 在Widget中使用StorageService的示例
class StorageWidgetExample {
  
  /// 在StatefulWidget中使用
  static Future<void> loadStorageDataInWidget() async {
    try {
      final storageService = StorageService();
      final data = await storageService.getStorageAreas();
      
      // 处理数据...
      print('Widget中获取的仓储数据: $data');
      
      // 如果需要强制刷新
      // final freshData = await storageService.refreshStorageAreas();
      
    } catch (e) {
      print('Widget中获取仓储数据失败: $e');
    }
  }
} 