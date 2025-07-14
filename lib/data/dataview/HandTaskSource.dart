import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class HandTask {
  HandTask({
    required this.taskType, // 作业类型
    required this.status, // 状态
    required this.startLocationId, // 起始库位
    required this.endLocationId, // 终点库位
    required this.agvNo, // AGV编号
    required this.startTime, // 开始时间
    required this.endTime, // 结束时间
  });
  final String taskType;
  final String status;
  final String startLocationId;
  final String endLocationId;
  final String agvNo;
  final String startTime;
  final String endTime;
}

// 搬运任务数据源适配
class HandTaskDataSource extends DataGridSource {
  final Function(HandTask)? onDetailTap; // 添加详情点击回调

  HandTaskDataSource({
    required List<HandTask> handTasks,
    this.onDetailTap,
  }) {
    _employees = handTasks
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'taskType', value: e.taskType),
              DataGridCell<String>(columnName: 'status', value: e.status),
              DataGridCell<String>(columnName: 'startLocationId', value: e.startLocationId),
              DataGridCell<String>(columnName: 'endLocationId', value: e.endLocationId),
              DataGridCell<String>(columnName: 'actions', value: ''), // 添加actions单元格
            ]))
        .toList();
  }

  List<DataGridRow> _employees = [];

  @override
  List<DataGridRow> get rows => _employees;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        if (cell.columnName == 'actions') {
          // 操作列显示详情按钮
          final rowIndex = _employees.indexOf(row);
          final handTask = rowIndex >= 0 && rowIndex < _employees.length 
              ? _getHandTaskFromRow(row) 
              : null;
          
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6.0),
                onTap: () {
                  if (onDetailTap != null && handTask != null) {
                    onDetailTap!(handTask);
                  } else {
                    print('查看详情: ${row.getCells()[0].value}');
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 44.0, 
                    minHeight: 32.0, 
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                  decoration: BoxDecoration( // 透明背景，用于增大触摸目标
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: Colors.transparent, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      '详情',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          // 其他列显示文本
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4.0), // 缩小内边距
            child: Text(
              cell.value.toString(),
              style: const TextStyle(fontSize: 12), // 缩小字体
            ),
          );
        }
      }).toList(),
    );
  }

  // 根据行数据获取HandTask对象
  HandTask? _getHandTaskFromRow(DataGridRow row) {
    try {
      final cells = row.getCells();
      if (cells.length >= 5) {
        return HandTask(
          taskType: cells[0].value.toString(),
          status: cells[1].value.toString(),
          startLocationId: cells[2].value.toString(),
          endLocationId: cells[3].value.toString(),
          agvNo: '', // 隐藏字段，设为空字符串
          startTime: '', // 隐藏字段，设为空字符串
          endTime: '', // 隐藏字段，设为空字符串
        );
      }
    } catch (e) {
      print('Error creating HandTask from row: $e');
    }
    return null;
  }
}