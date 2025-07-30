import 'package:flutter/material.dart';
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart';
import 'package:itms_mobile/presentation/widgets/common/map_control.dart';
import 'package:itms_mobile/presentation/widgets/common/storage_location_visualizer.dart';
import 'package:itms_mobile/presentation/widgets/common/storage_location_detail_dialog.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';
import 'package:itms_mobile/core/utils/storage_utils.dart';
import 'package:itms_mobile/services/storage_service.dart';
import 'package:itms_mobile/data/datasources/api/8062/service_8062.dart';
import 'package:itms_mobile/presentation/widgets/common/custom_dialog.dart';
import 'package:itms_mobile/presentation/widgets/common/message_toast.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:itms_mobile/data/dataview/hand_task_data_source.dart';

String getTime(String? dateTime) {
  if (dateTime == null) return '';
  final parts =
      dateTime.contains(' ') ? dateTime.split(' ') : dateTime.split('T');
  return parts.length > 1 ? parts[1] : dateTime;
}

class HandTaskDetailPage extends StatefulWidget {
  const HandTaskDetailPage({super.key});

  @override
  State<HandTaskDetailPage> createState() => _HandTaskDetailPageState();
}

class _HandTaskDetailPageState extends State<HandTaskDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;
  int selectedAreaIndex = 0; // 当前选中的库区索引
  String? activeSelect; // 'start' or 'end'，当前激活的库位选择
  List<Map<String, dynamic>> itemList = [];
  List<GridCell> currentAreaCells = []; // 当前库区的库位数据
  Map<String, int> currentAreaRange = {}; // 当前库区的范围信息
  HandTask? currentHandTask; // 当前任务数据
  String? startStorageLocationId;
  String? endStorageLocationId;
  String? startShelfId;
  late Service8062 _service8062; // 8062服务实例
  bool _isUpdatingArea = false; // 是否正在更新库区数据

  @override
  void initState() {
    super.initState();
    _initService8062();
    _getStorageAreas();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // 在切换过程中立即设置更新状态，防止显示旧数据
        _isUpdatingArea = true;
        print('indexIsChanging: $_isUpdatingArea');
        // 立即清空数据，防止显示旧数据
        setState(() {
          currentAreaCells = [];
          currentAreaRange = {};
          _tabIndex = _tabController.index; // 立即更新 tab 索引
        });
        return;
      }
      // 当 tab 切换时，显示加载并更新当前库区数据
      _updateAreaDataForCurrentTabWithLoading();
    });
  }

  Future<void> _initService8062() async {
    _service8062 = await Service8062.create();
    setState(() {}); // 如需刷新界面
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 获取仓储库位信息
  Future<void> _getStorageAreas() async {
    try {
      Map<String, dynamic>? response = StorageService.getCachedStorageAreas();
      if (response == null || !response.containsKey('retList')) {
        return;
      }
      final retList = response['retList'] as List<dynamic>;
      itemList.clear();
      for (var item in retList) {
        final map = item as Map<String, dynamic>;
        itemList.add(map);
      }
      setState(() {});
      if (itemList.isNotEmpty) {
        _updateCurrentAreaData('A001');
      }
    } catch (e) {
      AppLogger.error('获取仓储库位信息失败: $e');
    }
  }

  // 获取库区名称
  String _getAreaName(String areaId) {
    final areaData = itemList.firstWhere(
      (item) => item['id'] == areaId,
      orElse: () => <String, dynamic>{},
    );
    return areaData['name'] as String? ?? areaId;
  }

  // 清空当前库区数据
  void _clearCurrentAreaData() {
    setState(() {
      currentAreaCells = [];
      currentAreaRange = {};
      _isUpdatingArea = true;
    });
  }

  // 更新当前库区数据（异步版本）
  Future<void> _updateCurrentAreaDataAsync(String areaId) async {
    // 添加小延迟以模拟数据处理时间
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final areaData = itemList.firstWhere(
      (item) => item['id'] == areaId,
      orElse: () => <String, dynamic>{},
    );

    if (areaData.isEmpty) {
      currentAreaCells = [];
      currentAreaRange = {};
      setState(() {
        _isUpdatingArea = false;
      });
      return;
    }

    final storageLocationDTOS =
        areaData['storageLocationDTOS'] as List<dynamic>?;

    if (storageLocationDTOS != null && storageLocationDTOS.isNotEmpty) {
      try {
        currentAreaCells = StorageUtils.buildGridCells(storageLocationDTOS);
        currentAreaRange = StorageUtils.calculateAreaMaxRange(
            currentAreaCells, currentAreaCells);
      } catch (e) {
        currentAreaCells = [];
        currentAreaRange = {};
      }
    } else {
      currentAreaCells = [];
      currentAreaRange = {};
    }
    setState(() {
      _isUpdatingArea = false;
    });
  }

  // 更新当前库区数据
  void _updateCurrentAreaData(String areaId) {
    final areaData = itemList.firstWhere(
      (item) => item['id'] == areaId,
      orElse: () => <String, dynamic>{},
    );

    if (areaData.isEmpty) {
      currentAreaCells = [];
      currentAreaRange = {};
      setState(() {});
      return;
    }

    final storageLocationDTOS =
        areaData['storageLocationDTOS'] as List<dynamic>?;

    if (storageLocationDTOS != null && storageLocationDTOS.isNotEmpty) {
      try {
        currentAreaCells = StorageUtils.buildGridCells(storageLocationDTOS);
        currentAreaRange = StorageUtils.calculateAreaMaxRange(
            currentAreaCells, currentAreaCells);
      } catch (e) {
        currentAreaCells = [];
        currentAreaRange = {};
      }
    } else {
      currentAreaCells = [];
      currentAreaRange = {};
    }
    setState(() {});
  }

  // 根据当前 tab 更新库区数据（带加载提示）
  Future<void> _updateAreaDataForCurrentTabWithLoading() async {
    if (currentHandTask == null) return;

    // 立即清空当前数据，防止显示错误的库区信息
    setState(() {
      currentAreaCells = [];
      currentAreaRange = {};
    });

    String _areaId;
    if (_tabIndex == 0) {
      // 起始库位 tab
      _areaId = currentHandTask!.origArea;
    } else {
      // 终点库位 tab
      _areaId = currentHandTask!.destArea;
    }

    EasyLoading.show(status: '正在切换仓储区域...');

    try {
      await _updateCurrentAreaDataAsync(_areaId);
    } finally {
      EasyLoading.dismiss();
    }
  }

  // 根据当前 tab 更新库区数据
  void _updateAreaDataForCurrentTab() {
    if (currentHandTask == null) return;

    String _areaId;
    if (_tabIndex == 0) {
      // 起始库位 tab
      _areaId = currentHandTask!.origArea;
    } else {
      // 终点库位 tab
      _areaId = currentHandTask!.destArea;
    }

    _updateCurrentAreaData(_areaId);
  }

  // 构建头部
  Widget _buildHeader(HandTask handTask) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: 180,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/images/result.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                ),
              ),
            ),
            // 任务号和状态
            Positioned(
              left: 16,
              top: 16,
              right: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '任务号：${handTask.jobId ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12, // 缩小字体
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Text(
                            '状态: ${JobStatus.fromCode(handTask.status).displayName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12, // 缩小字体
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 白色卡片中下对齐
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '作业类型：${OperateType.values.firstWhere((element) => element.value == handTask.operateType, orElse: () => OperateType.values.first).displayName}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '托盘编号：${handTask.carryContainerId ?? ''}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '起始库位：${handTask.origCell ?? ''}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '开始时间：${getTime(handTask.execStartTime)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '终点库位：${handTask.destCell ?? ''}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '结束时间：${getTime(handTask.execEndTime)}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '备注：${handTask.note ?? ''}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  // 取消任务
  Future<void> _cancelJob() async {
    if (currentHandTask == null) {
      context.showErrorMessage('任务数据为空');
      return;
    }

    final result = await context.showConfirmDialog(
      title: '确认取消',
      content: '确定要取消任务 ${currentHandTask!.jobId} 吗？\n',
      confirmText: '确认取消',
      cancelText: '返回',
      confirmColor: const Color.fromARGB(255, 3, 93, 220),
    );

    if (result != ConfirmResult.confirm) {
      return;
    }

    EasyLoading.show(status: '取消中...');
    try {
      final response = await _service8062.cancelJob(currentHandTask!.jobId);
      if (!mounted) return;
      EasyLoading.dismiss();
      if (response['retCode'] == HTTPCode.success.code) {
        context.showSuccessMessage('${response['retMsg']?.toString()}');
        await StorageService.preloadStorageAreas(forceRefresh: true);
        await _getStorageAreas();
        setState(() {});
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/inner_work/hand-task', (route) => false);
      } else {
        final String errorMsg = response['retMsg']?.toString() ?? '取消任务失败';
        print('errorMsg: $errorMsg');
        context.showErrorMessage(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      EasyLoading.dismiss();
      context.showErrorMessage('${e.toString()}');
    }
  }

  // 人工完成任务
  Future<void> _manualCompleteJob() async {
    if (currentHandTask == null) {
      context.showErrorMessage('任务数据为空');
      return;
    }

    final result = await context.showConfirmDialog(
      title: '确认人工完成',
      content: '确定要人工放置${currentHandTask!.destCell}库位吗？\n',
      confirmText: '确认完成',
      cancelText: '返回',
      confirmColor: const Color.fromARGB(255, 3, 93, 220),
    );

    if (result != ConfirmResult.confirm) {
      return;
    }

    EasyLoading.show(status: '手动完成中...');
    try {
      final response = await _service8062.manualCompleteJob(<String, dynamic>{
        'jobId': currentHandTask!.jobId,
        'origCell': currentHandTask!.origCell,
        'destCell': currentHandTask!.destCell,
        'carryContainerId': currentHandTask!.carryContainerId,
      });
      if (!mounted) return;
      EasyLoading.dismiss();
      if (response['retCode'] == HTTPCode.success.code) {
        context.showSuccessMessage('${response['retMsg']?.toString()}');
        await StorageService.preloadStorageAreas(forceRefresh: true);
        await _getStorageAreas();
        setState(() {});
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/inner_work/hand-task', (route) => false);
      } else {
        final String errorMsg = response['retMsg']?.toString() ?? '人工完成任务失败';
        context.showErrorMessage(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      EasyLoading.dismiss();
      context.showErrorMessage('${e.toString()}');
    }
  }

  // 重试任务
  Future<void> _retryJob() async {
    if (currentHandTask == null) {
      context.showErrorMessage('任务数据为空');
      return;
    }

    final result = await context.showConfirmDialog(
      title: '确认重试',
      content: '确定要重试任务 ${currentHandTask!.jobId} 吗？\n',
      confirmText: '确认重试',
      cancelText: '返回',
      confirmColor: const Color.fromARGB(255, 3, 93, 220),
    );

    if (result != ConfirmResult.confirm) {
      return;
    }

    EasyLoading.show(status: '重试中...');
    try {
      final response = await _service8062.retryJob(currentHandTask!.jobId);
      if (!mounted) return;
      EasyLoading.dismiss();
      if (response['retCode'] == HTTPCode.success.code) {
        context.showSuccessMessage('${response['retMsg']?.toString()}');
        await StorageService.preloadStorageAreas(forceRefresh: true);
        await _getStorageAreas();
        setState(() {});
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/inner_work/hand-task', (route) => false);
      } else {
        final String errorMsg = response['retMsg']?.toString() ?? '重试任务失败';
        AppLogger.error('重试任务失败: $errorMsg');
        context.showErrorMessage(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      EasyLoading.dismiss();
      context.showErrorMessage('${e.toString()}');
    }
  }

  // 构建仓储区域地图
  Widget _buildStorageMap(
      String startStorageLocationId, String endStorageLocationId) {
    if (currentAreaCells.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text('暂未找到库位数据', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: StorageLocationVisualizer(
          data: currentAreaCells.map((cell) {
            return {
              'id': cell.id,
              'xplace': cell.x,
              'yplace': cell.y,
              'status': cell.status,
              'shelfId': cell.shelfId,
            };
          }).toList(),
          onTapPoint: (Map<String, dynamic> point) {
            // 显示库位详情弹框
            showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return StorageLocationDetailDialog(
                  locationData: point,
                );
              },
            );
            
            // 原有的点击处理逻辑
            final cell = GridCell(
              id: point['id'] as String,
              x: (point['xplace'] as num).toDouble(),
              y: (point['yplace'] as num).toDouble(),
              status: point['status'] as int,
              shelfId: point['shelfId'] as String?,
              color: Colors.grey,
            );
            _onCellTap(cell);
          },
          startLocationId: startStorageLocationId,
          endLocationId: endStorageLocationId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final handTask = args as HandTask?;
    if (handTask == null) {
      return const Scaffold(
        body: Center(child: Text('未获取到任务详情')),
      );
    }

    // 保存当前任务数据并初始化库区数据
    if (currentHandTask?.jobId != handTask.jobId) {
      currentHandTask = handTask;
      startStorageLocationId = handTask.origCell;
      endStorageLocationId = handTask.destCell;
      // 根据当前 tab 初始化库区数据
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateAreaDataForCurrentTabWithLoading();
      });
    }

    return PageScaffold(
      title: '任务详情',
      showBackButton: true,
      onBackPressed: () {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/inner_work/hand-task', (route) => false);
      },
      child: Column(
        children: [
          // 顶部卡片
          _buildHeader(handTask),
          const SizedBox(height: 2),
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white, // 选中背景色
                    borderRadius: BorderRadius.circular(6),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.orange, // 选中字体色
                  unselectedLabelColor: Colors.black, // 未选中字体色
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle:
                      const TextStyle(fontWeight: FontWeight.normal),
                  tabs: [
                    Container(
                      height: 40, // 可根据需要调整高度
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            _tabIndex == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Tab(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '起始库位',
                              style: TextStyle(fontSize: 12),
                            ),
                            if (currentHandTask != null)
                              Text(
                                _getAreaName(currentHandTask!.origArea),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            _tabIndex == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Tab(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '终点库位',
                              style: TextStyle(fontSize: 12),
                            ),
                            if (currentHandTask != null)
                              Text(
                                _getAreaName(currentHandTask!.destArea),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    key: ValueKey('tab_${_tabIndex}_${currentHandTask?.jobId}'),
                    controller: _tabController,
                    children: [
                      // 起始库位 tab
                      _buildStorageMap(
                          startStorageLocationId ?? '', ''), // 只显示起始库位
                      // 终点库位 tab
                      _buildStorageMap(
                          '', endStorageLocationId ?? ''), // 只显示终点库位
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _retryJob,
                        child: Text('任务重试'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () {
                          if (_tabIndex == 0) {
                            _cancelJob();
                          } else {
                            _manualCompleteJob();
                          }
                        },
                        child: Text(_tabIndex == 0 ? '取消任务' : '手动完成'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
