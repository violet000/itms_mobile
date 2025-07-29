import 'dart:math' as math;
import 'package:itms_mobile/data/datasources/api/9087/service_9087.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';

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
  static Future<void> preloadStorageAreas({bool forceRefresh = false}) async {
    if ((!forceRefresh && _cachedStorageAreas != null) || _isLoading) return;

    _isLoading = true;
    try {
      final service = await _getService9087();
      _cachedStorageAreas = await service.qryWarehousing('');
      printEachAreaMinXYDistanceWithPoints(_cachedStorageAreas!);
    } catch (e) {
      print('预加载仓储数据失败${e}');
    } finally {
      _isLoading = false;
    }
  }

  // 计算每个区域内，所有点对的x/y最小距离，分别返回每个区的x最小值和y最小值
  static List<Map<String, double?>> calculateEachAreaMinXYDistance(
      Map<String, dynamic> storageAreas) {
    final List<Map<String, double?>> result = [];

    if (storageAreas['retList'] is List) {
      for (final area in (storageAreas['retList'] as List)) {
        final List<dynamic> locations =
            area['storageLocationDTOS'] as List<dynamic>? ?? <dynamic>[];
        double? minXDist;
        double? minYDist;

        for (int i = 0; i < locations.length; i++) {
          final x1 = double.tryParse(locations[i]['xplace'].toString()) ?? 0;
          final y1 = double.tryParse(locations[i]['yplace'].toString()) ?? 0;
          for (int j = i + 1; j < locations.length; j++) {
            final x2 = double.tryParse(locations[j]['xplace'].toString()) ?? 0;
            final y2 = double.tryParse(locations[j]['yplace'].toString()) ?? 0;
            final double xDist = (x1 - x2).abs();
            final double yDist = (y1 - y2).abs();
            if (xDist != 0 && (minXDist == null || xDist < minXDist)) {
              minXDist = xDist;
            }
            if (yDist != 0 && (minYDist == null || yDist < minYDist)) {
              minYDist = yDist;
            }
          }
        }
        result.add({
          'minXDist': minXDist,
          'minYDist': minYDist,
        });
      }
    }
    return result;
  }

  static void printEachAreaMinXYDistanceWithPoints(Map<String, dynamic> storageAreas) {
    if (storageAreas['retList'] is List) {
      for (int areaIdx = 0; areaIdx < (storageAreas['retList'] as List).length; areaIdx++) {
        final Map<String, dynamic> area = (storageAreas['retList'] as List)[areaIdx] as Map<String, dynamic>;
        final List<dynamic> locations = area['storageLocationDTOS'] as List<dynamic>? ?? <dynamic>[];
        double? minXDist;
        double? minYDist;
        List<dynamic>? minXPair;
        List<dynamic>? minYPair;

        for (int i = 0; i < locations.length; i++) {
          final x1 = double.tryParse(locations[i]['xplace'].toString()) ?? 0;
          final y1 = double.tryParse(locations[i]['yplace'].toString()) ?? 0;
          for (int j = i + 1; j < locations.length; j++) {
            final x2 = double.tryParse(locations[j]['xplace'].toString()) ?? 0;
            final y2 = double.tryParse(locations[j]['yplace'].toString()) ?? 0;
            final double xDist = (x1 - x2).abs();
            final double yDist = (y1 - y2).abs();
            if (xDist != 0 && (minXDist == null || xDist < minXDist)) {
              minXDist = xDist;
              minXPair = <dynamic>[locations[i], locations[j]];
            }
            if (yDist != 0 && (minYDist == null || yDist < minYDist)) {
              minYDist = yDist;
              minYPair = <dynamic>[locations[i], locations[j]];
            }
          }
        }
      }
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
    final response = await service.qryWarehousing('');

    _cachedStorageAreas = response;
    return response;
  }
}
