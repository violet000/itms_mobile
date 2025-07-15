import 'package:itms_mobile/data/datasources/api/9087/service_9087.dart';

class StorageService {
  static StorageService? _instance;
  static Map<String, dynamic>? _cachedStorageAreas;
  static bool _isLoading = false;
  static Service9087? _service9087;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  // 获取Service实例
  static Future<Service9087> _getService9087() async {
    _service9087 ??= await Service9087.create();
    return _service9087!;
  }

  // 预加载仓储数据
  static Future<void> preloadStorageAreas() async {
    if (_cachedStorageAreas != null || _isLoading) return;
    
    _isLoading = true;
    try {
      final service = await _getService9087();
      _cachedStorageAreas = await service.getStorageAreas();
    } catch (e) {
      print('预加载仓储数据失败${e}');
    } finally {
      _isLoading = false;
    }
  }

  // 获取缓存数据
  static Map<String, dynamic>? getCachedStorageAreas() {
    return _cachedStorageAreas;
  }

  // 清除缓存
  static void clearCache() {
    _cachedStorageAreas = null;
  }

  // 仓储数据
  Future<Map<String, dynamic>> getStorageAreas() async {
    // 如果有缓存，取缓存数据
    if (_cachedStorageAreas != null) {
      return _cachedStorageAreas!;
    }

    // 否则去调取接口数据
    final service = await _getService9087();
    final response = await service.getStorageAreas();
    
    _cachedStorageAreas = response;
    return response;
  }
} 