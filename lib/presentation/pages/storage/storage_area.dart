import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/presentation/widgets/common/map_control.dart';

/// 仓储库位控件封装
class StorageArea extends StatefulWidget {
  const StorageArea({super.key});
  static final cells = <GridCell>[];

  @override
  State<StorageArea> createState() => _StorageAreaState();
}

class _StorageAreaState extends State<StorageArea> {
  static const double _legendItemHeight = 520.0;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments
        as Map?; // 获取父控件传递下来的参数(库位坐标以及库位详细信息)
    AppLogger.info('args: ${args}');

    final areaId = args?['id'] as String?;
    final areaName = args?['name'] as String?;
    final storageLocationDTOS = args?['storageLocationDTOS'] as List?;
    final storageAreas = args?['storageAreas'] as Map<String, dynamic>?;

    // 解构storageAreas
    final areaData = storageAreas?[areaId] as Map<String, dynamic>?;
    final rangeInfo = areaData?['rangeInfo'] as Map<String, dynamic>?;

    AppLogger.info('rangeInfo: $rangeInfo');
    StorageArea.cells.clear();
    if (storageLocationDTOS != null) {
      for (var storageLocationDTO in storageLocationDTOS) {
        final x = (double.parse(storageLocationDTO['xplace'].toString()));
        final y = (double.parse(storageLocationDTO['yplace'].toString()));
        StorageArea.cells.add(GridCell(
            x: x,
            y: y,
            id: storageLocationDTO['id'].toString(),
            color: storageLocationDTO['status'] == '1'
                ? const Color.fromARGB(255, 238, 137, 4)
                : const Color.fromARGB(255, 215, 212, 212)));
      }
    }

    print('StorageArea.cells: ${StorageArea.cells.length}');

    // 动态计算xUnits和yUnits
    int xUnits = 1;
    int yUnits = 1;

    if (StorageArea.cells.isNotEmpty) {
      double maxX = StorageArea.cells
          .map((cell) => cell.x)
          .reduce((a, b) => a > b ? a : b);
      double maxY = StorageArea.cells
          .map((cell) => cell.y)
          .reduce((a, b) => a > b ? a : b);

      xUnits = maxX.ceil();
      yUnits = maxY.ceil();

      // 确保至少为1
      xUnits = xUnits < 1 ? 1 : xUnits;
      yUnits = yUnits < 1 ? 1 : yUnits;
    }

    return PageScaffold(
      showBackButton: true,
      title: '${args?['name']}',
      onBackPressed: () {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              // margin: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(
                  top: 5, bottom: 10, left: 10, right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      verticalDirection: VerticalDirection.down,
                      children: [
                        SizedBox(
                            width: double.infinity,
                            height: _legendItemHeight,
                            child: MapControl(
                              // 在父级容器的时候就做好网格区域轴的绘制， +1，-1 为了防止网格数组溢出
                              xUnits: (rangeInfo?['xUnits'] as int) - (rangeInfo?['xStart'] as int) + 1,
                              yUnits: (rangeInfo?['yUnits'] as int) - (rangeInfo?['yStart'] as int) + 1,
                              xStart: (rangeInfo?['xStart'] as int) - 1,
                              yStart: (rangeInfo?['yStart'] as int) - 1,
                              cells: StorageArea.cells,
                              onCellTap: (cell) {
                                AppLogger.info('点击了格子: x=${cell.x}, y=${cell.y}');
                              },
                            ))
                      ]),
                ),
              ),
            ),
          ),
          Container(
            height: 50,
            color: Colors.transparent,
            child: const Center(child: Text('底部区域')),
          ),
        ],
      ),
    );
  }
}
