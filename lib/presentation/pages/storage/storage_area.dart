import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/presentation/widgets/common/map_control.dart';
import 'package:itms_mobile/core/utils/storage_utils.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart';
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:itms_mobile/core/utils/util.dart';
import 'package:itms_mobile/presentation/widgets/common/storage_location_visualizer.dart';
import 'package:itms_mobile/presentation/widgets/common/storage_location_detail_dialog.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';

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

    AppLogger.debug('StorageArea.cells.length: ${StorageArea.cells.length}');

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
                  data: storageLocationDTOS.map((dynamic item) {
                    // 确保数据格式正确，包含shelfId
                    final Map<String, dynamic> point = Map<String, dynamic>.from(item as Map<dynamic, dynamic>);
                    // 如果原始数据中有storageShelfDTO，提取shelfId
                    if (point.containsKey('storageShelfDTO') && point['storageShelfDTO'] != null) {
                      final shelfDTO = point['storageShelfDTO'] as Map<String, dynamic>;
                      point['shelfId'] = shelfDTO['shelfId']?.toString();
                    }
                    return point;
                  }).toList(),
                  onTapPoint: (point) {
                    AppLogger.info('点击了点位: ${point['id']}');
                    // 显示库位详情弹框
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return StorageLocationDetailDialog(
                          locationData: point,
                        );
                      },
                    );
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
