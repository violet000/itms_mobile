import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/presentation/widgets/common/map_control.dart';
import 'package:itms_mobile/core/utils/storage_utils.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart';

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

    // 解构storageAreas
    final areaName = StorageUtils.getCellsByAreaId(args as Map<String, dynamic>)['areaName'] as String?;
    final storageLocationDTOS = StorageUtils.getCellsByAreaId(args as Map<String, dynamic>)['storageLocationDTOS'] as List?;
    final Map<String, dynamic> areaInfo = StorageUtils.getCellsByAreaId(args as Map<String, dynamic>)['rangeInfo'] as Map<String, dynamic>;

    StorageArea.cells.clear();
    if (storageLocationDTOS != null) {
      StorageArea.cells
          .addAll(StorageUtils.buildGridCells(storageLocationDTOS));
    }

    return PageScaffold(
      showBackButton: true,
      title: '$areaName',
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
                              xUnits: (areaInfo['xUnits'] as int) -
                                  (areaInfo['xStart'] as int) +
                                  1,
                              yUnits: (areaInfo['yUnits'] as int) -
                                  (areaInfo['yStart'] as int) +
                                  1,
                              xStart: (areaInfo['xStart'] as int) - 1,
                              yStart: (areaInfo['yStart'] as int) - 1,
                              cells: StorageArea.cells,
                              onCellTap: (cell) {
                                AppLogger.info(
                                    '点击了格子: x=${cell.x}, y=${cell.y}');
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 18,
                      color: const Color.fromARGB(255, 213, 213, 213),
                    ),
                    const SizedBox(width: 8),
                    const Text('空闲'),
                  ],
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 18,
                      color: const Color.fromARGB(255, 238, 137, 4),
                    ),
                    const SizedBox(width: 8),
                    const Text('占用'),
                  ],
                ),
                const SizedBox(width: 10)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
