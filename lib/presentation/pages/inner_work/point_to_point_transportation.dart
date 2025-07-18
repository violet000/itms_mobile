import 'package:flutter/material.dart';
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';
import 'package:itms_mobile/services/storage_service.dart';
import 'package:itms_mobile/core/utils/storage_utils.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/presentation/widgets/common/map_control.dart';
import 'package:itms_mobile/presentation/widgets/common/message_toast.dart';
import 'package:itms_mobile/data/datasources/api/9087/service_9087.dart';
import 'package:itms_mobile/core/utils/util.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class PointToPointPage extends StatefulWidget {
  const PointToPointPage({super.key});

  @override
  State<PointToPointPage> createState() => _PointToPointPageState();
}

class _PointToPointPageState extends State<PointToPointPage> {
  List<Map<String, dynamic>> itemList = [];
  String? startStorageLocationId;
  String? endStorageLocationId;
  String? startShelfId;
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
      currentAreaRange = StorageUtils.calculateAreaMaxRange(
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
      _setSelectedLocation(cell.id, activeSelect!, cell.shelfId);
    }
  }

  // 显示选择对话框
  void _showSelectionDialog(GridCell cell) {
    // 判断锁定状态
    if (cell.status == LandmarkStatus.locked.code) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '该库位处于锁定状态，无法选择为起点或终点',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '关闭',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题区域
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${cell.id}库位',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 选项按钮
              _buildSelectionOption(
                icon: Icons.play_arrow,
                title: '设为起点',
                subtitle: '标记为起点库位',
                color: Colors.blue,
                onTap: () {
                  if (cell.status != LandmarkStatus.occupied.code) {
                    context.showErrorMessage('只能选择占用状态为起点');
                    return;
                  }
                  Navigator.pop(context);
                  _setSelectedLocation(cell.id, 'start', cell.shelfId);
                },
              ),
              const SizedBox(height: 12),
              _buildSelectionOption(
                icon: Icons.flag,
                title: '设为终点',
                subtitle: '标记为终点库位',
                color: Colors.red,
                onTap: () {
                  if (cell.status != LandmarkStatus.idle.code) {
                    context.showErrorMessage('只能选择空闲状态为终点');
                    return;
                  }
                  Navigator.pop(context);
                  _setSelectedLocation(cell.id, 'end', cell.shelfId);
                },
              ),
              const SizedBox(height: 12),
              _buildSelectionOption(
                icon: Icons.details,
                title: '库位详情',
                subtitle: '查看库位的详细信息',
                color: const Color.fromARGB(255, 67, 67, 68),
                onTap: () {
                  // AppLogger.info('库位详情: ${cell.id}');
                },
              ),
              const SizedBox(height: 12),
              // 取消按钮
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建选择选项
  Widget _buildSelectionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                icon,
                color: color,
                size: 14,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // 设置选中的库位
  void _setSelectedLocation(String locationId, String type, String? shelfId) {
    setState(() {
      if (type == 'start') {
        startStorageLocationId = locationId;
        startShelfId = shelfId;
      } else {
        endStorageLocationId = locationId;
      }
      activeSelect = null; // 清除激活状态
    });
    
    final typeText = type == 'start' ? '起始' : '终点';
  }

  // 显示任务确认对话框
  void _showTaskConfirmationDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题区域
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '确认开始任务',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 内容区域
              Text(
                '您确定要发起当前搬运任务吗？\n起始库位：$startStorageLocationId\n终点库位：$endStorageLocationId',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 按钮区域
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '取消',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context); // 关闭确认对话框
                          _launchCarry();
                          // context.showSuccessMessage('任务已开始');
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 12, 124, 235),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '确认',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 下发搬运指令
  Future<void> _launchCarry() async {
    EasyLoading.show(status: '发起任务中...');
    try {
      final service = await Service9087.create();
      final Map<String, dynamic> response = await service.qryLineByEscortNo(<String, dynamic>{
        'operateType': 'location2location',
        'origCell': startStorageLocationId,
        'destCell': endStorageLocationId,
        'carryContainerType': '1',
        'carryContainerId': startShelfId,
      });
      if (response['retCode'] == HTTPCode.success.code) {
        if (!mounted) return;
        context.showSuccessMessage('${response['retMsg']?.toString()}');

        startStorageLocationId = null;
        endStorageLocationId = null;
        startShelfId = null;
        activeSelect = null;
        selectedAreaIndex = 0;
        await StorageService.preloadStorageAreas(forceRefresh: true);
        await _getStorageAreas();
        setState(() {});
      } else {
        if (!mounted) return;
        context.showErrorMessage(response['retMsg']?.toString() ?? '操作失败');
      }
    } catch (e) { 
      context.showErrorMessage('${e.toString()}');
    } finally {
      EasyLoading.dismiss();
    }
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
            startLocationId: startStorageLocationId,
            endLocationId: endStorageLocationId,
          ),
        ),
      ),
    );
  }

  // 构建选中状态显示
  Widget _buildSelectionStatus() {
    return Container(
      height: 40,
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
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      startStorageLocationId != null 
                          ? '起:$startStorageLocationId' 
                          : '起始库位号',
                      style: TextStyle(
                        color: startStorageLocationId != null 
                            ? Colors.blue 
                            : Colors.grey,
                        fontSize: 12,
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
                      icon: const Icon(Icons.clear, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8), // 添加间距
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
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      endStorageLocationId != null 
                          ? '终:$endStorageLocationId' 
                          : '终点库位号',
                      style: TextStyle(
                        color: endStorageLocationId != null 
                            ? Colors.red 
                            : Colors.grey,
                        fontSize: 12,
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
                      icon: const Icon(Icons.clear, size: 14),
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
                _showTaskConfirmationDialog();
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
          _buildSelectionStatus(), // 起始和终点库位显示
          _buildBottomButton(), // 任务发起按钮
        ],
      ),
    );
  }
}
