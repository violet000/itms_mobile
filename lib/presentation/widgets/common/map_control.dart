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

  GridPainter({
    required this.xUnits,
    required this.yUnits,
    required this.xStart,
    required this.yStart,
    required this.cells,
    required this.cellRects,
  });

  // 根据背景色计算对比色，确保文字清晰可见
  Color _getContrastColor(Color backgroundColor) {
    // 计算亮度
    final double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
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

        final backgroundPaint = Paint()
          ..color = cell.color.withOpacity(0.85);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
          backgroundPaint,
        );

        final borderPaint = Paint()
          ..color = cell.color.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
          borderPaint,
        );
        
        // // 绘制库位编号
        // final textStyle = TextStyle(
        //   color: _getContrastColor(cell.color),
        //   fontSize: 10,
        //   fontWeight: FontWeight.w600,
        // );
        // final textSpan = TextSpan(text: cell.id, style: textStyle);
        // final textPainter = TextPainter(
        //   text: textSpan,
        //   textAlign: TextAlign.center,
        //   textDirection: TextDirection.ltr,
        // );
        // textPainter.layout();
        // textPainter.paint(
        //   canvas,
        //   Offset(
        //     adjustedX + (rect.width - textPainter.width) / 2,
        //     adjustedY + (rect.height - textPainter.height) / 2,
        //   ),
        // );
        
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
      // tp.paint(
      //     canvas,
      //     Offset(size.width + 2,
      //         size.height - i * size.height / xUnits - tp.height / 2));
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
      // tp.paint(
      //     canvas,
      //     Offset((yUnits - j) * size.width / yUnits - tp.width / 2,
      //         size.height + 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
