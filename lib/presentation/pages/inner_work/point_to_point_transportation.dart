import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';
import 'package:itms_mobile/services/storage_service.dart';
import 'package:itms_mobile/core/utils/storage_utils.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/presentation/widgets/common/map_control.dart';
import 'package:itms_mobile/presentation/widgets/common/message_toast.dart';

class PointToPointPage extends StatefulWidget {
  const PointToPointPage({super.key});

  @override
  State<PointToPointPage> createState() => _PointToPointPageState();
}

class _PointToPointPageState extends State<PointToPointPage> {
  List<Map<String, dynamic>> itemList = [];
  String? startStorageLocationId;
  String? endStorageLocationId;
  int selectedAreaIndex = 0; // 当前选中的库区索引
  String? activeSelect; // 'start' or 'end'，当前激活的库位选择
  List<GridCell> currentAreaCells = []; // 当前库区的库位数据
  Map<String, int> currentAreaRange = {}; // 当前库区的范围信息

  @override
  void initState() {
    super.initState();
    _getStorageAreas();
  }

  // 获取仓储库位信息
  Future<void> _getStorageAreas() async {
    try {
      Map<String, dynamic>? response = StorageService.getCachedStorageAreas();
      if (response == null || !response.containsKey('retList')) {
        return print('仓储数据错误或为空');
      }
      final retList = response['retList'] as List<dynamic>;
      itemList.clear();
      for (var item in retList) {
        final map = item as Map<String, dynamic>;
        itemList.add(map);
      }
      setState(() {});
      // 初始化第一个库区的数据
      if (itemList.isNotEmpty) {
        _updateCurrentAreaData(0);
      }
    } catch (e) {
      AppLogger.error('获取仓储库位信息失败: $e');
    }
  }

  // 更新当前库区数据
  void _updateCurrentAreaData(int areaIndex) {
    if (areaIndex < 0 || areaIndex >= itemList.length) return;
    
    final areaData = itemList[areaIndex];
    final storageLocationDTOS = areaData['storageLocationDTOS'] as List<dynamic>?;
    
    if (storageLocationDTOS != null) {
      currentAreaCells = StorageUtils.buildGridCells(storageLocationDTOS);
      currentAreaRange = StorageUtils.calculateAreaRange(
        currentAreaCells, 
        currentAreaCells
      );
    } else {
      currentAreaCells = [];
      currentAreaRange = {};
    }
    
    setState(() {});
  }

  // 获取当前选中的库区数据
  Map<String, dynamic>? get currentAreaData {
    if (itemList.isEmpty) return null;
    if (selectedAreaIndex < 0 || selectedAreaIndex >= itemList.length) return null;
    return itemList[selectedAreaIndex];
  }

  // 处理库位点击
  void _onCellTap(GridCell cell) {
    if (activeSelect == null) {
      // 如果没有激活选择模式，显示选择对话框
      _showSelectionDialog(cell);
    } else {
      // 直接设置选中的库位
      _setSelectedLocation(cell.id, activeSelect!);
    }
  }

  // 显示选择对话框
  void _showSelectionDialog(GridCell cell) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择库位 ${cell.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.blue),
              title: const Text('设为起始库位'),
              onTap: () {
                Navigator.pop(context);
                _setSelectedLocation(cell.id, 'start');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text('设为终点库位'),
              onTap: () {
                Navigator.pop(context);
                _setSelectedLocation(cell.id, 'end');
              },
            ),
          ],
        ),
      ),
    );
  }

  // 设置选中的库位
  void _setSelectedLocation(String locationId, String type) {
    setState(() {
      if (type == 'start') {
        startStorageLocationId = locationId;
      } else {
        endStorageLocationId = locationId;
      }
      activeSelect = null; // 清除激活状态
    });
    
    final typeText = type == 'start' ? '起始' : '终点';
    context.showSuccessMessage('已设置${typeText}库位: $locationId');
  }

  // 构建顶部选择器
  Widget _buildTopSelectors() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          // 库区选择器
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedAreaIndex,
                isExpanded: true,
                hint: const Text('选择库区'),
                items: itemList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final area = entry.value;
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text((area['name'] as String?) ?? '未知库区'),
                  );
                }).toList(),
                onChanged: (index) {
                  if (index != null) {
                    setState(() {
                      selectedAreaIndex = index;
                    });
                    _updateCurrentAreaData(index);
                  }
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  // 构建库位显示区域
  Widget _buildStorageMap() {
    if (currentAreaCells.isEmpty) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text('暂无库位数据', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: MapControl(
            xUnits: (currentAreaRange['xUnits'] ?? 10) - (currentAreaRange['xStart'] ?? 0) + 1,
            yUnits: (currentAreaRange['yUnits'] ?? 10) - (currentAreaRange['yStart'] ?? 0) + 1,
            xStart: (currentAreaRange['xStart'] ?? 0) - 1,
            yStart: (currentAreaRange['yStart'] ?? 0) - 1,
            cells: currentAreaCells,
            onCellTap: _onCellTap,
          ),
        ),
      ),
    );
  }

  // 构建选中状态显示
  Widget _buildSelectionStatus() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          // 起始库位
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: startStorageLocationId != null 
                    ? Colors.blue.withOpacity(0.1) 
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: startStorageLocationId != null 
                      ? Colors.blue 
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_arrow,
                    color: startStorageLocationId != null 
                        ? Colors.blue 
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      startStorageLocationId != null 
                          ? '起点: $startStorageLocationId' 
                          : '起始库位',
                      style: TextStyle(
                        color: startStorageLocationId != null 
                            ? Colors.blue 
                            : Colors.grey,
                      ),
                    ),
                  ),
                  if (startStorageLocationId != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          startStorageLocationId = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 8),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2), // 添加间距
          // 终点库位
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: endStorageLocationId != null 
                    ? Colors.red.withOpacity(0.1) 
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: endStorageLocationId != null 
                      ? Colors.red 
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: endStorageLocationId != null 
                        ? Colors.red 
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      endStorageLocationId != null 
                          ? '终点: $endStorageLocationId' 
                          : '终点库位',
                      style: TextStyle(
                        color: endStorageLocationId != null 
                            ? Colors.red 
                            : Colors.grey,
                      ),
                    ),
                  ),
                  if (endStorageLocationId != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          endStorageLocationId = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 8),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建底部按钮
  Widget _buildBottomButton() {
    final hasStartLocation = startStorageLocationId != null;
    final hasEndLocation = endStorageLocationId != null;
    final canStartTask = hasStartLocation && hasEndLocation;
    
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canStartTask 
                    ? const Color.fromARGB(255, 12, 124, 235)
                    : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: canStartTask ? () {
                AppLogger.info('开始任务 - 起始库位: ${startStorageLocationId}, 终点库位: ${endStorageLocationId}');
                context.showSuccessMessage('任务已开始');
              } : null,
              child: Text(
                canStartTask ? '开始任务' : '请先选择起始和终点库位',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '点到点搬运',
      showBackButton: true,
      onBackPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'selectedTab': 1},
        );
      },
      child: Column(
        children: [
          _buildTopSelectors(), // 仓储区域选择
          _buildStorageMap(), // 仓储区域地图
          _buildSelectionStatus(), // 起始和终点库位选择
          _buildBottomButton(), // 任务发起按钮
        ],
      ),
    );
  }
}
