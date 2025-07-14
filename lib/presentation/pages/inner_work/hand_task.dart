import 'package:flutter/material.dart';
import 'package:itms_mobile/data/dataview/HandTaskSource.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';

class HandTaskPage extends StatefulWidget {
  const HandTaskPage({super.key});

  @override
  State<HandTaskPage> createState() => _HandTaskPageState();
}

class _HandTaskPageState extends State<HandTaskPage> {
  late HandTaskDataSource _handTaskDataSource;
  // 下拉选项和当前选中
  List<String> _taskTypeOptions = [];
  List<String> _statusOptions = [];
  String _selectedTaskType = '全部';
  String _selectedStatus = '全部';
  
  // 分页相关
  int _currentPage = 0;
  int _rowsPerPage = 10;
  int _totalRows = 0;
  
  // 原始数据
  final List<HandTask> _allHandTasks = [
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03204', endLocationId: 'A-03301', agvNo: 'AGV001', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区至二区', status: '执行中', startLocationId: 'A-03205', endLocationId: 'A-03302', agvNo: 'AGV002', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03207', endLocationId: 'A-03304', agvNo: 'AGV003', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03204', endLocationId: 'A-03301', agvNo: 'AGV004', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区至二区', status: '执行中', startLocationId: 'A-03205', endLocationId: 'A-03302', agvNo: 'AGV005', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03207', endLocationId: 'A-03304', agvNo: 'AGV006', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03204', endLocationId: 'A-03301', agvNo: 'AGV007', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区至二区', status: '执行中', startLocationId: 'A-03205', endLocationId: 'A-03302', agvNo: 'AGV008', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03207', endLocationId: 'A-03304', agvNo: 'AGV009', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03204', endLocationId: 'A-03301', agvNo: 'AGV010', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区至二区', status: '执行中', startLocationId: 'A-03205', endLocationId: 'A-03302', agvNo: 'AGV011', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03207', endLocationId: 'A-03304', agvNo: 'AGV012', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03204', endLocationId: 'A-03301', agvNo: 'AGV013', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区至二区', status: '执行中', startLocationId: 'A-03205', endLocationId: 'A-03302', agvNo: 'AGV014', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03207', endLocationId: 'A-03304', agvNo: 'AGV015', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03204', endLocationId: 'A-03301', agvNo: 'AGV016', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区至二区', status: '执行中', startLocationId: 'A-03205', endLocationId: 'A-03302', agvNo: 'AGV017', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03207', endLocationId: 'A-03304', agvNo: 'AGV018', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03204', endLocationId: 'A-03301', agvNo: 'AGV019', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区至二区', status: '执行中', startLocationId: 'A-03205', endLocationId: 'A-03302', agvNo: 'AGV020', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03207', endLocationId: 'A-03304', agvNo: 'AGV021', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03204', endLocationId: 'A-03301', agvNo: 'AGV022', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区至二区', status: '执行中', startLocationId: 'A-03205', endLocationId: 'A-03302', agvNo: 'AGV023', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03207', endLocationId: 'A-03304', agvNo: 'AGV024', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03204', endLocationId: 'A-03301', agvNo: 'AGV025', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区至二区', status: '执行中', startLocationId: 'A-03205', endLocationId: 'A-03302', agvNo: 'AGV026', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03207', endLocationId: 'A-03304', agvNo: 'AGV027', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03204', endLocationId: 'A-03301', agvNo: 'AGV028', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区至二区', status: '执行中', startLocationId: 'A-03205', endLocationId: 'A-03302', agvNo: 'AGV029', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03207', endLocationId: 'A-03304', agvNo: 'AGV030', startTime: '2025-01-01 10:00:00', endTime: '2025-01-01 10:00:00'),
  ];
  
  // 过滤后的数据
  List<HandTask> _filteredHandTasks = [];

  @override
  void initState() {
    super.initState();
    _taskTypeOptions = ['全部', ..._allHandTasks.map((e) => e.taskType).toSet()];
    _statusOptions = ['全部', ..._allHandTasks.map((e) => e.status).toSet()];
    _filteredHandTasks = List.from(_allHandTasks);
    _totalRows = _filteredHandTasks.length;
    _updateDataSource();
  }

  // 过滤数据
  void _filterData() {
    _filteredHandTasks = _allHandTasks.where((task) {
      final taskTypeMatch = _selectedTaskType == '全部' || task.taskType == _selectedTaskType;
      final statusMatch = _selectedStatus == '全部' || task.status == _selectedStatus;
      return taskTypeMatch && statusMatch;
    }).toList();
    _totalRows = _filteredHandTasks.length;
    _currentPage = 0;
    _updateDataSource();
  }

  // 更新数据源
  void _updateDataSource() {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredHandTasks.length);
    final pageData = _filteredHandTasks.sublist(startIndex, endIndex);
    
    setState(() {
      _handTaskDataSource = HandTaskDataSource(
        handTasks: pageData,
        onDetailTap: _onDetailTap,
      );
    });
  }

  // 处理详情按钮点击
  void _onDetailTap(HandTask handTask) {
    print('查看详情: ${handTask.taskType}');
    
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('任务详情'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('作业类型: ${handTask.taskType}'),
              const SizedBox(height: 8),
              Text('状态: ${handTask.status}'),
              const SizedBox(height: 8),
              Text('起始库位: ${handTask.startLocationId}'),
              const SizedBox(height: 8),
              Text('终点库位: ${handTask.endLocationId}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  // 分页处理
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _updateDataSource();
    });
  }

  // 每页行数变化处理
  void _onRowsPerPageChanged(int? newRowsPerPage) {
    if (newRowsPerPage != null) {
      setState(() {
        _rowsPerPage = newRowsPerPage;
        _currentPage = 0; // 重置到第一页
        _updateDataSource();
      });
    }
  }

  final headers = ['作业类型', '状态', '起始库位', '终点库位', '操作'];

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth;
    
    // 动态计算列宽
    final taskTypeWidth = availableWidth * 0.24; // 24%
    final statusWidth = availableWidth * 0.16; // 16%
    final startLocationWidth = availableWidth * 0.22; // 22%
    final endLocationWidth = availableWidth * 0.22; // 22%
    final actionsWidth = availableWidth * 0.16; // 16%

    return PageScaffold(
      title: '搬运任务',
      showBackButton: true,
      onBackPressed: () {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false,
            arguments: {'selectedTab': 1});
      },
      backgroundDecoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          // 搜索区域
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.white!),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 作业类型下拉
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      value: _selectedTaskType,
                      items: _taskTypeOptions.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type, style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTaskType = value!;
                          _filterData();
                        });
                      },
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: '作业类型',
                        labelStyle: TextStyle(fontSize: 14, color: Colors.black),
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 状态下拉
                  SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      items: _statusOptions.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status, style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                          _filterData();
                        });
                      },
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: '状态',
                        labelStyle: TextStyle(fontSize: 14, color: Colors.black),
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 清空按钮
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTaskType = '全部';
                        _selectedStatus = '全部';
                        _filterData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(fontSize: 14),
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text('清空'),
                  ),
                ],
              ),
            ),
          ),
          
          // 表格区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: availableWidth, // 保证宽度
                  child: SfDataGrid(
                    source: _handTaskDataSource,
                    gridLinesVisibility: GridLinesVisibility.both,
                    headerGridLinesVisibility: GridLinesVisibility.both,
                    columnWidthMode: ColumnWidthMode.none,
                    headerRowHeight: 50,
                    rowHeight: 40,
                    columns: [
                      GridColumn(
                        columnName: 'taskType',
                        label: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                          ),
                          child: const Text(
                            '作业类型',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        width: taskTypeWidth,
                      ),
                      GridColumn(
                        columnName: 'status',
                        label: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                          ),
                          child: const Text(
                            '状态',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        width: statusWidth,
                      ),
                      GridColumn(
                        columnName: 'startLocationId',
                        label: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                          ),
                          child: const Text(
                            '起始库位',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        width: startLocationWidth,
                      ),
                      GridColumn(
                        columnName: 'endLocationId',
                        label: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                          ),
                          child: const Text(
                            '终点库位',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        width: endLocationWidth,
                      ),
                      GridColumn(
                        columnName: 'actions',
                        label: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                          ),
                          child: const Text(
                            '操作',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        width: actionsWidth,
                        allowSorting: false,
                        allowFiltering: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 分页控件
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            // margin: const EdgeInsets.only(top: 2, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
              // border: Border.all(color: Colors.grey[200]!),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10, // 间距
              runSpacing: 8,
              children: [
                // 每页行数选择
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('每页', style: TextStyle(fontSize: 14, color: Colors.black87)),
                    const SizedBox(width: 4),
                    DropdownButton<int>(
                      value: _rowsPerPage,
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      items: [5, 10, 20, 50].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value'),
                        );
                      }).toList(),
                      onChanged: _onRowsPerPageChanged,
                    ),
                    const SizedBox(width: 4),
                    const Text('条', style: TextStyle(fontSize: 14, color: Colors.black87)),
                    const SizedBox(width: 10),
                    Text('共 $_totalRows 条', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
                // 分页按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 上一页
                    IconButton(
                      onPressed: _currentPage > 0 ? () => _onPageChanged(_currentPage - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                      color: Colors.blue,
                      splashRadius: 20,
                      tooltip: '上一页',
                    ),
                    // 页码显示
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentPage + 1} / ${(_totalRows / _rowsPerPage).ceil()}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // 下一页
                    IconButton(
                      onPressed: _currentPage < (_totalRows / _rowsPerPage).ceil() - 1
                          ? () => _onPageChanged(_currentPage + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: Colors.blue,
                      splashRadius: 20,
                      tooltip: '下一页',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
