import 'package:itms_mobile/data/datasources/api/18082/service_18082.dart';

/// 由于仓储库位信息需要实时更新，该类去对仓储库位信息进行缓存以及更新
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Map<String, dynamic>? _cachedStorageAreas;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiration = Duration(minutes: 5); // 缓存5分钟

  /// 获取仓储库位信息（带缓存）
  Future<Map<String, dynamic>> getStorageAreas() async {
    // 检查缓存是否有效
    if (_isCacheValid()) {
      return _cachedStorageAreas!;
    }

    try {
      final response = await Service18082().getStorageAreas();
      
      // 更新缓存
      _cachedStorageAreas = response;
      _lastFetchTime = DateTime.now();
      
      return response;
    } catch (e) {
      // 如果API调用失败但有缓存数据，返回缓存数据
      if (_cachedStorageAreas != null) {
        return _cachedStorageAreas!;
      }
      // 没有缓存数据，重新抛出异常
      rethrow;
    }
  }

  /// 强制刷新仓储库位信息
  Future<Map<String, dynamic>> refreshStorageAreas() async {
    try {
      final response = await Service18082().getStorageAreas();
      
      // 更新缓存
      _cachedStorageAreas = response;
      _lastFetchTime = DateTime.now();
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 清除缓存
  void clearCache() {
    _cachedStorageAreas = null;
    _lastFetchTime = null;
  }

  /// 检查缓存是否有效
  bool _isCacheValid() {
    if (_cachedStorageAreas == null || _lastFetchTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    final timeDifference = now.difference(_lastFetchTime!);
    
    return timeDifference < _cacheExpiration;
  }
} 