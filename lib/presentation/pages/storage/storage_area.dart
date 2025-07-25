import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/presentation/widgets/common/map_control.dart';
import 'package:itms_mobile/core/utils/storage_utils.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart';
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:itms_mobile/core/utils/util.dart';
import 'package:itms_mobile/presentation/widgets/common/storage_location_visualizer.dart';

/// 仓储库位控件封装
class StorageArea extends StatefulWidget {
  const StorageArea({super.key});
  static final cells = <GridCell>[];

  @override
  State<StorageArea> createState() => _StorageAreaState();
}

class _StorageAreaState extends State<StorageArea> {

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments
        as Map?; // 获取父控件传递下来的参数(库位坐标以及库位详细信息)

    // 解构storageAreas
    final areaName =
        StorageUtils.getCellsByAreaId(args as Map<String, dynamic>)['areaName']
            as String?;
    final Map<String, dynamic>? areaInfo = args['areaInfo'] as Map<String, dynamic>?;
    final List<dynamic>? storageLocationDTOS =
        args != null ? args['storageLocationDTOS'] as List<dynamic>? : null;

    if (storageLocationDTOS == null || storageLocationDTOS is! List) {
      return const Center(child: Text('暂无点位数据'));
    }

    StorageArea.cells.clear();
    if (storageLocationDTOS != null) {
      StorageArea.cells
          .addAll(StorageUtils.buildGridCells(storageLocationDTOS));
    }

    print('StorageArea.cells.length: ${StorageArea.cells.length}');

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
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 5, bottom: 10, left: 10, right: 10),
              child: DecoratedBox(
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
                child: StorageLocationVisualizer(
                  data: List<Map<String, dynamic>>.from(storageLocationDTOS),
                  onTapPoint: (point) {
                    print('点击了点位: ${point['id']}');
                  },
                ),
              ),
            ),
          ),
          Container(
            height: 50,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: LandmarkStatus.values.map((status) {
                return Row(
                  children: [
                    Container(
                      width: 20,
                      height: 12,
                      color: Util.hexToColor(status.color),
                    ),
                    const SizedBox(width: 2),
                    Text(status.displayName),
                    const SizedBox(width: 8),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
