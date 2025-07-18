import 'package:flutter/material.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart'; // 用于GridCell
import 'package:itms_mobile/core/utils/util.dart';

class StorageUtils {
  static Map<String, dynamic> getCellsByAreaId(Map<String, dynamic> args) {
    final areaId = args['id'] as String?;
    final areaName = args['name'] as String?;
    final storageLocationDTOS = args['storageLocationDTOS'] as List?;
    final storageAreas = args['storageAreas'] as Map<String, dynamic>?;
    final areaData = storageAreas?[areaId] as Map<String, dynamic>?;
    final rangeInfo = areaData?['rangeInfo'] as Map<String, dynamic>?;
    return <String, dynamic>{
      'areaId': areaId,
      'areaName': areaName,
      'storageLocationDTOS': storageLocationDTOS,
      'storageAreas': storageAreas,
      'rangeInfo': rangeInfo,
    };
  }

  // 计算独立的区域的坐标范围
  static Map<String, int> calculateAreaMinRange(
      List<GridCell> cells, List<GridCell> allCellList) {
    if (cells.isEmpty) {
      return <String, int>{
        'xStart': 0,
        'xUnits': 1,
        'yStart': 0,
        'yUnits': 1,
      };
    }

    double minX = cells.map((cell) => cell.x).reduce((a, b) => a < b ? a : b);
    double maxX = cells.map((cell) => cell.x).reduce((a, b) => a > b ? a : b);
    double minY = cells.map((cell) => cell.y).reduce((a, b) => a < b ? a : b);

    // 动态计算所有区域中Y坐标的最大值
    final allCells = allCellList;
    double maxY;
    if (allCells.isEmpty) {
      maxY = minY; // 如果没有其他区域的数据，使用当前区域的最大Y值
    } else {
      maxY = allCells.map((cell) => cell.y).reduce((a, b) => a > b ? a : b);
    }

    return <String, int>{
      'xStart': minX.toInt(),
      'xUnits': maxX.ceil().toInt(),
      'yStart': minY.toInt(),
      'yUnits': maxY.ceil().toInt(),
    };
  }


  // 计算极值区域的坐标范围
  static Map<String, int> calculateAreaMaxRange(
      List<GridCell> cells, List<GridCell> allCellList,
      [String? areaId]) {
    if (cells.isEmpty) {
      return <String, int>{
        'xStart': 0,
        'xUnits': 1,
        'yStart': 0,
        'yUnits': 1,
      };
    }

    // 计算当前区域的X和Y坐标的最小值作为起始点
    double currentMinX =
        cells.map((cell) => cell.x).reduce((a, b) => a < b ? a : b);
    double currentMinY =
        cells.map((cell) => cell.y).reduce((a, b) => a < b ? a : b);

    // 使用指定区域的最大范围，如果没有指定则使用全局最大范围
    double maxRangeX = StorageDataManager().getMaxRangeX(areaId);
    double maxRangeY = StorageDataManager().getMaxRangeY(areaId);

    if (areaId != null) {
      print('计算区域: $areaId');
    }

    // 计算绘制范围：从最小值到最小值+范围
    int xUnits = currentMinX.floor().toInt() + maxRangeX.ceil().toInt();
    int yUnits = currentMinY.floor().toInt() + maxRangeY.ceil().toInt();

    return <String, int>{
      'xStart': currentMinX.floor().toInt(), // 使用当前区域的X轴最小值作为起始点
      'xUnits': xUnits, // X轴绘制到：起始点 + 范围
      'yStart': currentMinY.floor().toInt(), // 使用当前区域的Y轴最小值作为起始点
      'yUnits': yUnits, // Y轴绘制到：起始点 + 范围
    };
  }

  /// 将 storageLocationDTOS 转为 GridCell 列表
  static List<GridCell> buildGridCells(List<dynamic> storageLocationDTOS) {
    return storageLocationDTOS.map((dynamic storageLocationDTO) {
      final x = double.parse(storageLocationDTO['xplace'].toString());
      final y = double.parse(storageLocationDTO['yplace'].toString());
      final shelfId =
          storageLocationDTO['storageShelfDTO']?['shelfId']?.toString();
      return GridCell(
        x: x,
        y: y,
        id: storageLocationDTO['id'].toString(),
        color: Util.getStatusColor(storageLocationDTO['status'] as int),
        shelfId: shelfId,
        status: storageLocationDTO['status'] as int,
      );
    }).toList();
  }
}

// 仓储数据管理器
class StorageDataManager {
  static final StorageDataManager _instance = StorageDataManager._internal();
  factory StorageDataManager() => _instance;
  StorageDataManager._internal();

  // 使用Map来存储动态的仓储区域数据
  final Map<String, List<GridCell>> _areaCells = {};
  final Map<String, String> _areaNames = {};

  // 为每个区域分别缓存最大范围值
  final Map<String, double> _cachedMaxRangeX = {};
  final Map<String, double> _cachedMaxRangeY = {};
  final Map<String, bool> _isCacheValid = {};

  // 获取所有区域ID
  List<String> get areaIds => _areaCells.keys.toList();

  // 获取指定区域的单元格数据
  List<GridCell> getCellsByAreaId(String areaId) {
    return _areaCells[areaId] ?? [];
  }

  // 获取区域名称
  String getAreaName(String areaId) {
    return _areaNames[areaId] ?? '未知区域';
  }

  // 更新仓储区域数据
  void updateAreaData(String areaId, String areaName, List<GridCell> cells) {
    _areaCells[areaId] = cells;
    _areaNames[areaId] = areaName;
    // 数据更新后，该区域的缓存失效
    _isCacheValid[areaId] = false;
  }

  // 清空所有数据
  void clearAllData() {
    _areaCells.clear();
    _areaNames.clear();
    _cachedMaxRangeX.clear();
    _cachedMaxRangeY.clear();
    _isCacheValid.clear();
  }

  // 获取所有区域的单元格数据（用于计算全局范围）
  List<GridCell> getAllCells() {
    List<GridCell> allCells = [];
    for (var cells in _areaCells.values) {
      allCells.addAll(cells);
    }
    return allCells;
  }

  // 获取指定区域的最大范围X
  double getMaxRangeX([String? areaId]) {
    if (areaId != null) {
      return _getAreaMaxRangeX(areaId);
    }
    // 如果没有指定区域，返回所有区域中的最大值
    double maxRange = 0;
    for (String id in _areaCells.keys) {
      double range = _getAreaMaxRangeX(id);
      if (range > maxRange) {
        maxRange = range;
      }
    }
    return maxRange;
  }

  // 获取指定区域的最大范围Y
  double getMaxRangeY([String? areaId]) {
    if (areaId != null) {
      return _getAreaMaxRangeY(areaId);
    }
    // 如果没有指定区域，返回所有区域中的最大值
    double maxRange = 0;
    for (String id in _areaCells.keys) {
      double range = _getAreaMaxRangeY(id);
      if (range > maxRange) {
        maxRange = range;
      }
    }
    return maxRange;
  }

  // 获取指定区域的最大范围X（内部方法）
  double _getAreaMaxRangeX(String areaId) {
    if (_isCacheValid[areaId] != true) {
      _calculateAreaMaxRanges(areaId);
    }
    return _cachedMaxRangeX[areaId] ?? 0;
  }

  // 获取指定区域的最大范围Y（内部方法）
  double _getAreaMaxRangeY(String areaId) {
    if (_isCacheValid[areaId] != true) {
      _calculateAreaMaxRanges(areaId);
    }
    return _cachedMaxRangeY[areaId] ?? 0;
  }

  // 计算并缓存指定区域的最大范围
  void _calculateAreaMaxRanges(String areaId) {
    List<GridCell> areaCells = getCellsByAreaId(areaId);

    if (areaCells.isEmpty) {
      _cachedMaxRangeX[areaId] = 0;
      _cachedMaxRangeY[areaId] = 0;
    } else {
      double maxX =
          areaCells.map((cell) => cell.x).reduce((a, b) => a > b ? a : b);
      double minX =
          areaCells.map((cell) => cell.x).reduce((a, b) => a < b ? a : b);
      double maxY =
          areaCells.map((cell) => cell.y).reduce((a, b) => a > b ? a : b);
      double minY =
          areaCells.map((cell) => cell.y).reduce((a, b) => a < b ? a : b);

      _cachedMaxRangeX[areaId] = maxX - minX;
      _cachedMaxRangeY[areaId] = maxY - minY;
    }

    _isCacheValid[areaId] = true;
  }
}
