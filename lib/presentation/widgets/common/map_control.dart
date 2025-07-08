import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';

class GridCell {
  final double x;
  final double y;
  final String? id;
  final Color color;
  GridCell({required this.x, required this.y, this.id, required this.color});
}

class MapControl extends StatelessWidget {
  final int xUnits;
  final int yUnits;
  final int xStart;
  final int yStart;
  final List<GridCell> cells;
  final void Function(GridCell)? onCellTap; // 

  const MapControl({
    Key? key,
    this.xUnits = 9,
    this.yUnits = 10,
    this.xStart = 0,
    this.yStart = 0,
    this.cells = const [],
    this.onCellTap, // 新增
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
              final Offset localPosition = box.globalToLocal(details.globalPosition);
              _handleTap(localPosition, constraints.biggest);
            },
            child: CustomPaint(
              painter: GridPainter(
                xUnits: xUnits,
                yUnits: yUnits,
                xStart: xStart,
                yStart: yStart,
                cells: cells,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }

  void _handleTap(Offset position, Size size) {
    final double dx = size.width / yUnits;
    final double dy = size.height / xUnits;
    // 计算点击的格子索引
    int xIndex = (xUnits - (position.dy / dy)).floor();
    int yIndex = (yUnits - (position.dx / dx)).floor();
    // 反推格子的实际坐标
    double x = xStart + xIndex.toDouble();
    double y = yStart + yIndex.toDouble();
    // 查找对应的 cell
    final cell = cells.firstWhere(
      (c) => c.x == x && c.y == y,
      orElse: () => null!,
    );
    if (cell != null && onCellTap != null) {
      onCellTap!(cell);
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

  GridPainter({
    required this.xUnits,
    required this.yUnits,
    required this.xStart,
    required this.yStart,
    required this.cells,
  });

  @override
  void paint(Canvas canvas, Size size) {
    AppLogger.info('xUnits: $xUnits');
    AppLogger.info('yUnits: $yUnits');
    AppLogger.info('xStart: $xStart');
    AppLogger.info('yStart: $yStart');
    AppLogger.info('cells: $cells');
    final double dx = size.width / yUnits;
    final double dy = size.height / xUnits;

    // 绘制网格
    final Paint originalGridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    // 垂直网格线（对应Y轴，从右往左）
    for (int i = 0; i <= yUnits; i++) {
      double x = (yUnits - i) * dx;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        originalGridPaint,
      );
    }
    // 水平网格线（对应X轴，从下往上）
    for (int j = 0; j <= xUnits; j++) {
      double y = (xUnits - j) * dy;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        originalGridPaint,
      );
    }

    // 绘制格子
    for (final cell in cells) {
      // 判断cell是否在当前显示区域内
      if (cell.x >= xStart &&
          cell.x <= xStart + xUnits &&
          cell.y >= yStart &&
          cell.y <= yStart + yUnits) {
        double padding = 5.0;
        // 计算格子在画布上的索引（使用实际坐标值）
        final double xIndex = cell.y - yStart;
        final double yIndex = cell.x - xStart;
        // 画布位置（直接使用坐标值计算，不需要额外的小数偏移）
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
        final paint = Paint()..color = cell.color;
        canvas.drawRect(rect, paint);
        // 在矩形中显示坐标信息
        var textStyle = const TextStyle(
          color: Colors.black,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        );
        // 显示xplace
        final xTextSpan =
            TextSpan(text: 'x:${cell.x.toStringAsFixed(1)}', style: textStyle);
        final xTextPainter = TextPainter(
          text: xTextSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        xTextPainter.layout();
        xTextPainter.paint(
            canvas,
            Offset(
              adjustedX + (rect.width - xTextPainter.width) / 2,
              adjustedY + rect.height / 4 - xTextPainter.height / 2,
            ));
        // 显示yplace
        final yTextSpan =
            TextSpan(text: 'y:${cell.y.toStringAsFixed(1)}', style: textStyle);
        final yTextPainter = TextPainter(
          text: yTextSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        yTextPainter.layout();
        yTextPainter.paint(
            canvas,
            Offset(
              adjustedX + (rect.width - yTextPainter.width) / 2,
              adjustedY + 3 * rect.height / 4 - yTextPainter.height / 2,
            ));
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
