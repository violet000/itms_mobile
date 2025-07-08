import 'package:flutter/material.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart'; // 用于GridCell

class StorageUtils {
  /// 根据 status 返回颜色
  static Color getStatusColor(int status) {
    return status == 1
        ? const Color.fromARGB(255, 213, 213, 213)
        : const Color.fromARGB(255, 238, 137, 4);
  }

  static Map<String, int> calcUnits(List<GridCell> cells) {
    int xUnits = 1;
    int yUnits = 1;
    if (cells.isNotEmpty) {
      double maxX = cells.map((cell) => cell.x).reduce((a, b) => a > b ? a : b);
      double maxY = cells.map((cell) => cell.y).reduce((a, b) => a > b ? a : b);
      xUnits = maxX.ceil();
      yUnits = maxY.ceil();
      xUnits = xUnits < 1 ? 1 : xUnits;
      yUnits = yUnits < 1 ? 1 : yUnits;
    }
    return {'xUnits': xUnits, 'yUnits': yUnits};
  }

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

  // 计算区域的坐标范围
  static Map<String, int> calculateAreaRange(
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

  /// 将 storageLocationDTOS 转为 GridCell 列表
  static List<GridCell> buildGridCells(List<dynamic> storageLocationDTOS) {
    return storageLocationDTOS.map((dynamic storageLocationDTO) {
      final x = double.parse(storageLocationDTO['xplace'].toString());
      final y = double.parse(storageLocationDTO['yplace'].toString());
      return GridCell(
        x: x,
        y: y,
        id: storageLocationDTO['id'].toString(),
        color: getStatusColor(storageLocationDTO['status'] as int),
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

  // 获取所有区域ID
  List<String> get areaIds => _areaCells.keys.toList();

  // 获取指定区域的单元格数据
  List<GridCell> getCellsByAreaId(String areaId) {
    return _areaCells[areaId] ?? [];
  }

  // 获取指定区域的名称
  String getAreaName(String areaId) {
    return _areaNames[areaId] ?? '未知区域';
  }

  // 更新仓储区域数据
  void updateAreaData(String areaId, String areaName, List<GridCell> cells) {
    _areaCells[areaId] = cells;
    _areaNames[areaId] = areaName;
  }

  // 清空所有数据
  void clearAllData() {
    _areaCells.clear();
    _areaNames.clear();
  }

  // 获取所有区域的单元格数据（用于计算全局范围）
  List<GridCell> getAllCells() {
    List<GridCell> allCells = [];
    for (var cells in _areaCells.values) {
      allCells.addAll(cells);
    }
    return allCells;
  }

  // 向后兼容的方法（为了不破坏现有代码）
  List<GridCell> get cells => getCellsByAreaId('A001');
  List<GridCell> get cells2 => getCellsByAreaId('A002');
  List<GridCell> get cells3 => getCellsByAreaId('A003');

  void updateCells(
      List<GridCell> area1, List<GridCell> area2, List<GridCell> area3) {
    updateAreaData('A001', '仓储一区', area1);
    updateAreaData('A002', '仓储二区', area2);
    updateAreaData('A003', '仓储三区', area3);
  }
}
