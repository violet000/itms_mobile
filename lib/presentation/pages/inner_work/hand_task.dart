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

  final List<HandTask> _handTasks = [
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03204', endLocationId: 'A-03301'),
    HandTask(taskType: '一区至二区', status: '执行中', startLocationId: 'A-03205', endLocationId: 'A-03302'),
    HandTask(taskType: '一区内调整', status: '待执行', startLocationId: 'A-03207', endLocationId: 'A-03304'),
  ];

  @override
  void initState() {
    super.initState();
    _handTaskDataSource = HandTaskDataSource(
      handTasks: _handTasks,
      onDetailTap: _onDetailTap, // 传递详情点击回调
    );
  }

  // 处理详情按钮点击
  void _onDetailTap(HandTask handTask) {
    print('查看详情: ${handTask.taskType}');
    // 这里可以添加导航到详情页面的逻辑
    // 例如：Navigator.pushNamed(context, '/task-detail', arguments: handTask);
    
    // 显示一个简单的对话框作为示例
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

  final headers = ['作业类型', '状态', '库位编号', '起始库位', '终点库位', '操作'];

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
      child: Flex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: SfDataGrid(
                source: _handTaskDataSource,
                gridLinesVisibility: GridLinesVisibility.both,
                headerGridLinesVisibility: GridLinesVisibility.both,
                columnWidthMode: ColumnWidthMode.none, // 使用固定宽度模式
                headerRowHeight: 40,
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
        ],
      ),
    );
  }
}
