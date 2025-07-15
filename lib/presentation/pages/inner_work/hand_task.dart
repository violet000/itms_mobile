import 'package:flutter/material.dart';
import 'package:itms_mobile/data/dataview/HandTaskSource.dart';
import 'package:itms_mobile/data/datasources/api/8062/service_8062.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/core/constants/constant.dart';

class HandTaskPage extends StatefulWidget {
  const HandTaskPage({super.key});

  @override
  State<HandTaskPage> createState() => _HandTaskPageState();
}

class _HandTaskPageState extends State<HandTaskPage> {
  late HandTaskDataSource _handTaskDataSource;
  static Service8062? _service8062;

  // 下拉选项和当前选中
  // 作业类型选项
  final List<OperateType> _taskTypeOptions = OperateType.values;

  // 状态选项
  final List<JobStatus> _statusOptions = JobStatus.values;
  OperateType? _selectedTaskType;
  JobStatus? _selectedStatus;

  // 分页相关
  int _currentPage = 0;
  int _rowsPerPage = 10;
  int _totalRows = 0;

  // 数据状态
  bool _isLoading = false;
  String? _errorMessage;

  // 原始数据
  List<HandTask> _allHandTasks = [];

  // 过滤后的数据
  List<HandTask> _filteredHandTasks = [];

  @override
  void initState() {
    super.initState();
    _handTaskDataSource = HandTaskDataSource(
      handTasks: [],
      onDetailTap: _onDetailTap,
    );
    _initService();
    _loadData();
  }

  // 初始化服务
  void _initService() async {
    _service8062 = await Service8062.create();
  }

  // 加载数据
  Future<void> _loadData() async {
    _service8062 ??= await Service8062.create();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 调用接口获取数据
      // final response = await _service8062!.qryJobByParams(<String, dynamic>{
      //   'status': _selectedStatus?.value ?? '',
      //   'operateType': _selectedTaskType?.value ?? '',
      //   'curPage': _currentPage + 1, // 接口从1开始，UI从0开始
      //   'pageSize': _rowsPerPage
      // });

      final response = await _service8062!.qryJobStatus();

      if (response['retCode'] == HTTPCode.success.code) {
        final List<dynamic> retList =
            (response['retList'] as List<dynamic>?) ?? <dynamic>[];
        final int total = (response['totalRow'] as int?) ?? 0;
        AppLogger.info('retList: $retList');
        // 转换数据格式
        _allHandTasks = retList.map<HandTask>((dynamic record) {
          final recordMap = record as Map<String, dynamic>;
          return HandTask(
            operateType: (recordMap['operateType'] as String?) ?? '',
            status: int.tryParse('${recordMap['status']}') ?? 0,
            origCell: (recordMap['origCell'] as String?) ?? '',
            destCell: (recordMap['destCell'] as String?) ?? '',
            carryContainerType:
                (recordMap['carryContainerType'] as String?) ?? '',
            execStartTime: (recordMap['execStartTime'] as String?) ?? '',
            execEndTime: (recordMap['execEndTime'] as String?) ?? '',
          );
        }).toList();

        setState(() {
          _filteredHandTasks = List<HandTask>.from(_allHandTasks);
          _handTaskDataSource = HandTaskDataSource(
            handTasks: _filteredHandTasks,
            onDetailTap: _onDetailTap,
          );
          _totalRows = total;
        });
      } else {
        setState(() {
          _errorMessage = (response['message'] as String?) ?? '获取数据失败';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络请求失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 过滤数据
  void _filterData() {
    _loadData();
  }

  // 更新数据源
  void _updateDataSource() {
    // 直接重新查询接口
    _loadData();
  }

  // 处理详情按钮点击
  void _onDetailTap(HandTask handTask) {
    print('查看详情: ${handTask.operateType}');

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('任务详情'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('作业类型: ${handTask.operateType}'),
              const SizedBox(height: 8),
              Text('状态: ${handTask.status}'),
              const SizedBox(height: 8),
              Text('起始库位: ${handTask.origCell}'),
              const SizedBox(height: 8),
              Text('终点库位: ${handTask.destCell}'),
              if (handTask.carryContainerType.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('搬运类型: ${handTask.carryContainerType}'),
              ],
              if (handTask.execStartTime.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('开始时间: ${handTask.execStartTime}'),
              ],
              if (handTask.execEndTime.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('结束时间: ${handTask.execEndTime}'),
              ],
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

  // 刷新数据
  Future<void> _refreshData() async {
    await _loadData();
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
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: const Color(0xFFE0E3E8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左侧：下拉框组
                Expanded(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<OperateType?>(
                          value: _selectedTaskType,
                          items: [
                            DropdownMenuItem<OperateType?>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(Icons.list_alt,
                                      size: 18, color: Colors.blueGrey),
                                  SizedBox(width: 6),
                                  Text('全部'),
                                ],
                              ),
                            ),
                            ..._taskTypeOptions
                                .map((type) => DropdownMenuItem<OperateType?>(
                                      value: type,
                                      child: Row(
                                        children: [
                                          Icon(Icons.assignment,
                                              size: 18, color: Colors.blueGrey),
                                          SizedBox(width: 6),
                                          Text(type.displayName),
                                        ],
                                      ),
                                    )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedTaskType = value;
                              _filterData();
                            });
                          },
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: '作业类型',
                            labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.blueGrey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Color(0xFFE0E3E8)), // 选中时同未选中
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<JobStatus?>(
                          value: _selectedStatus,
                          items: [
                            DropdownMenuItem<JobStatus?>(
                              value: null,
                              child: Row(
                                children: const [
                                  Icon(Icons.flag,
                                      size: 18, color: Colors.blueGrey),
                                  SizedBox(width: 6),
                                  Text('全部'),
                                ],
                              ),
                            ),
                            ..._statusOptions
                                .map((status) => DropdownMenuItem<JobStatus?>(
                                      value: status,
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 6),
                                          Text(status.displayName),
                                        ],
                                      ),
                                    )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                              _filterData();
                            });
                          },
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: '状态',
                            labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.blueGrey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Color(0xFFE0E3E8)), // 选中时同未选中
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧：按钮组
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedTaskType = null;
                          _selectedStatus = null;
                          _filterData();
                        });
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: SizedBox(
                        width: 30, // 固定宽度
                        height: 24,
                        child: Center(
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : const Text('重置'),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueGrey,
                        minimumSize: const Size(30, 24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        side: const BorderSide(color: Color(0xFF90CAF9)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _refreshData,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: SizedBox(
                        width: 30, // 固定宽度
                        height: 24,
                        child: Center(
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  strokeWidth: 1,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : const Text('刷新'),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(30, 24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 错误信息显示
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                    icon: Icon(Icons.close, color: Colors.red[600], size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // 表格区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('正在加载数据...'),
                        ],
                      ),
                    )
                  : _filteredHandTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('暂无数据',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: availableWidth, // 保证宽度
                            child: SfDataGrid(
                              source: _handTaskDataSource,
                              gridLinesVisibility: GridLinesVisibility.both,
                              headerGridLinesVisibility:
                                  GridLinesVisibility.both,
                              columnWidthMode: ColumnWidthMode.none,
                              headerRowHeight: 50,
                              rowHeight: 50,
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
          if (!_isLoading && _filteredHandTasks.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  // 每页行数选择
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('每页',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black87)),
                      const SizedBox(width: 4),
                      DropdownButton<int>(
                        value: _rowsPerPage,
                        underline: const SizedBox(),
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                        items: [5, 10, 20, 50].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          );
                        }).toList(),
                        onChanged: _onRowsPerPageChanged,
                      ),
                      const SizedBox(width: 4),
                      const Text('条',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black87)),
                      const SizedBox(width: 10),
                      Text('共 $_totalRows 条',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                  // 分页按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 上一页
                      IconButton(
                        onPressed: _currentPage > 0
                            ? () => _onPageChanged(_currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        color: Colors.blue,
                        splashRadius: 20,
                        tooltip: '上一页',
                      ),
                      // 页码显示
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
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
                        onPressed: _currentPage <
                                (_totalRows / _rowsPerPage).ceil() - 1
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
