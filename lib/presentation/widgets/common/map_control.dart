import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart';

class MapControl extends StatelessWidget {
  final int xUnits;
  final int yUnits;
  final int xStart;
  final int yStart;
  final List<GridCell> cells;
  final void Function(GridCell)? onCellTap;
  final String? startLocationId; // 起始库位ID
  final String? endLocationId; // 终点库位ID

  // 存储 cell 和 rect 的映射
  final List<MapEntry<GridCell, Rect>> cellRects = [];

  MapControl({
    Key? key,
    this.xUnits = 9,
    this.yUnits = 10,
    this.xStart = 0,
    this.yStart = 0,
    this.cells = const [],
    this.onCellTap,
    this.startLocationId,
    this.endLocationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final Offset localPosition =
                  box.globalToLocal(details.globalPosition);
              _handleTap(localPosition, constraints.biggest);
            },
            child: CustomPaint(
              painter: GridPainter(
                xUnits: xUnits,
                yUnits: yUnits,
                xStart: xStart,
                yStart: yStart,
                cells: cells,
                cellRects: cellRects,
                startLocationId: startLocationId,
                endLocationId: endLocationId,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }

  void _handleTap(Offset localPosition, Size gridSize) {
    for (final entry in cellRects) {
      if (entry.value.contains(localPosition)) {
        if (onCellTap != null) onCellTap!(entry.key);
        return;
      }
    }
  }
}

class GridPainter extends CustomPainter {
  final int xUnits;
  final int yUnits;
  final int xStart;
  final int yStart;
  final double axisWidth = 2.0;
  final Color axisColor = Colors.black;
  final Color gridColor = Colors.grey;
  final List<GridCell> cells;
  final List<MapEntry<GridCell, Rect>> cellRects;
  final String? startLocationId;
  final String? endLocationId;

  GridPainter({
    required this.xUnits,
    required this.yUnits,
    required this.xStart,
    required this.yStart,
    required this.cells,
    required this.cellRects,
    this.startLocationId,
    this.endLocationId,
  });

  // 获取库位的标记颜色
  Color _getCellMarkColor(GridCell cell) {
    if (cell.id == startLocationId) {
      return Colors.blue; // 起始库位用蓝色
    } else if (cell.id == endLocationId) {
      return Colors.red; // 终点库位用红色
    }
    return cell.color; // 其他库位保持原色
  }

  @override
  void paint(Canvas canvas, Size size) {
    cellRects.clear(); // 每次重绘前清空
    final double dx = size.width / yUnits;
    final double dy = size.height / xUnits;

    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.06)
      ..strokeWidth = 0.2;
    
    // 垂直网格线（对应Y轴，从右往左）
    for (int i = 0; i <= yUnits; i++) {
      double x = (yUnits - i) * dx;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    // 水平网格线（对应X轴，从下往上）
    for (int j = 0; j <= xUnits; j++) {
      double y = (xUnits - j) * dy;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // 绘制库位格子
    for (final cell in cells) {
      // 将实际坐标转换为显示坐标（从0开始）
      final double displayX = cell.x - xStart;
      final double displayY = cell.y - yStart;
      
      // 判断cell是否在当前显示区域内
      if (displayX >= 0 &&
          displayX <= xUnits &&
          displayY >= 0 &&
          displayY <= yUnits) {
        double padding = 2.0; // 适中的内边距
        // 计算格子在画布上的索引（使用显示坐标）
        final double xIndex = displayY; // Y轴对应画布的X方向
        final double yIndex = displayX; // X轴对应画布的Y方向
        // 画布位置
        final double baseX = (yUnits - xIndex) * dx;
        final double baseY = (xUnits - yIndex) * dy;
        final double adjustedX = baseX + padding;
        final double adjustedY = baseY + padding;
        final rect = Rect.fromLTWH(
          adjustedX,
          adjustedY,
          dx - 2 * padding,
          dy - 2 * padding,
        );

        // 获取库位的标记颜色
        final Color cellColor = _getCellMarkColor(cell);
        final bool isStartLocation = cell.id == startLocationId;
        final bool isEndLocation = cell.id == endLocationId;

        // 绘制背景
        final backgroundPaint = Paint()
          ..color = cellColor.withOpacity(isStartLocation || isEndLocation ? 0.9 : 0.85);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
          backgroundPaint,
        );

        // 绘制边框
        final borderPaint = Paint()
          ..color = cellColor.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isStartLocation || isEndLocation ? 2.0 : 1.0; // 选中库位边框更粗
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
          borderPaint,
        );

        // 在绘制库位格子循环内，绘制完rect后，先绘制shelfId文本：
        if (cell.shelfId != null && cell.shelfId!.isNotEmpty) {
          final textSpan = TextSpan(
            text: cell.shelfId,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          );
          final tp = TextPainter(
            text: textSpan,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(
            canvas,
            Offset(
              rect.left + (rect.width - tp.width) / 2,
              rect.top + (rect.height - tp.height) / 2,
            ),
          );
        }
        // 然后绘制特殊标记（保持原有特殊标记绘制逻辑不变）
        if (isStartLocation || isEndLocation) {
          // 绘制标记图标
          final double iconSize = rect.width * 0.3;
          final double iconX = rect.left + (rect.width - iconSize) / 2;
          final double iconY = rect.top + (rect.height - iconSize) / 2;
          
          final Paint iconPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;
          
          if (isStartLocation) {
            // 绘制起始标记（三角形）
            final Path startPath = Path();
            startPath.moveTo(iconX + iconSize / 2, iconY);
            startPath.lineTo(iconX, iconY + iconSize);
            startPath.lineTo(iconX + iconSize, iconY + iconSize);
            startPath.close();
            canvas.drawPath(startPath, iconPaint);
          } else if (isEndLocation) {
            // 绘制终点标记（旗帜）
            final Paint flagPaint = Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill;
            
            // 绘制旗杆
            canvas.drawRect(
              Rect.fromLTWH(iconX + iconSize * 0.4, iconY, iconSize * 0.1, iconSize),
              flagPaint,
            );
            
            // 绘制旗帜
            final Path flagPath = Path();
            flagPath.moveTo(iconX + iconSize * 0.5, iconY);
            flagPath.lineTo(iconX + iconSize, iconY + iconSize * 0.3);
            flagPath.lineTo(iconX + iconSize * 0.5, iconY + iconSize * 0.6);
            flagPath.close();
            canvas.drawPath(flagPath, flagPaint);
          }
        }
        
        cellRects.add(MapEntry(cell, rect)); // 记录
      }
    }

    var textStyle = const TextStyle(color: Colors.black, fontSize: 12);
    // X轴刻度（右边，从下往上为正轴）
    for (int i = 0; i <= xUnits; i++) {
      final int label = xStart + i;
      final textSpan = TextSpan(text: '$label', style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
          canvas,
          Offset(size.width + 2,
              size.height - i * size.height / xUnits - tp.height / 2));
    }
    // Y轴刻度（底部，从右往左为正轴）
    for (int j = 0; j <= yUnits; j++) {
      final int label = yStart + j;
      final textSpan = TextSpan(text: '$label', style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
          canvas,
          Offset((yUnits - j) * size.width / yUnits - tp.width / 2,
              size.height + 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
