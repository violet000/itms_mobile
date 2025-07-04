import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/presentation/widgets/common/map_control.dart';

/// 仓储库位控件封装
class StorageArea extends StatefulWidget {
  const StorageArea({super.key});
  static final cells = [
    // 第一行
    GridCell(x: 0, y: 0, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 1, y: 0, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 3, y: 0, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 4, y: 0, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 7, y: 0, color: const Color.fromARGB(255, 12, 110, 238)),
    // 第二行
    GridCell(x: 0, y: 1, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 1, y: 1, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 3, y: 1, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 4, y: 1, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 7, y: 1, color: const Color.fromARGB(255, 12, 110, 238)),
    // 第三行
    GridCell(x: 0, y: 2, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 1, y: 2, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 3, y: 2, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 4, y: 2, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 7, y: 2, color: const Color.fromARGB(255, 12, 110, 238)),
    // 第四行
    GridCell(x: 7, y: 3, color: const Color.fromARGB(255, 12, 110, 238)),
    // 第六行
    GridCell(x: 7, y: 5, color: const Color.fromARGB(255, 12, 110, 238)),
    // 第七行
    GridCell(x: 0, y: 6, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 1, y: 6, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 3, y: 6, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 4, y: 6, color: const Color.fromARGB(255, 12, 110, 238)),
    // 第八行
    GridCell(x: 0, y: 7, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 1, y: 7, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 3, y: 7, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 4, y: 7, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 7, y: 7, color: const Color.fromARGB(255, 12, 110, 238)),
    // 第九行
    GridCell(x: 0, y: 8, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 1, y: 8, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 3, y: 8, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 4, y: 8, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 7, y: 8, color: const Color.fromARGB(255, 12, 110, 238)),
    // 第十行
    GridCell(x: 0, y: 9, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 1, y: 9, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 3, y: 9, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 4, y: 9, color: const Color.fromARGB(255, 12, 110, 238)),
    GridCell(x: 7, y: 9, color: const Color.fromARGB(255, 12, 110, 238)),
  ];

  @override
  State<StorageArea> createState() => _StorageAreaState();
}

class _StorageAreaState extends State<StorageArea> {
  static const double _legendItemHeight = 520.0;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments
        as Map?; // 获取父控件传递下来的参数(库位坐标以及库位详细信息)
    AppLogger.info('args: $args');

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
                      child: CustomPaint(
                        painter: GridPainter(cells: StorageArea.cells),
                      ),
                    )
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
