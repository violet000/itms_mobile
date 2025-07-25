import 'package:flutter/material.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart';

class MapControl extends StatelessWidget {
  final List<GridCell> cells;
  final void Function(GridCell)? onCellTap;
  final String? startLocationId;
  final String? endLocationId;

  // 新增参数
  final double cellWidth;
  final double cellHeight;
  final int? xMin, xMax, yMin, yMax;
  final int? forceXUnits, forceYUnits;

  MapControl({
    Key? key,
    this.cells = const [],
    this.onCellTap,
    this.startLocationId,
    this.endLocationId,
    this.cellWidth = 40,
    this.cellHeight = 40,
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.forceXUnits,
    this.forceYUnits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 自动计算x/y范围
    final xs = cells.map((c) => c.x).toList();
    final ys = cells.map((c) => c.y).toList();
    int minX = xMin ?? (xs.isEmpty ? 0 : xs.reduce((a, b) => a < b ? a : b)).toInt();
    int maxX = xMax ?? (xs.isEmpty ? 0 : xs.reduce((a, b) => a > b ? a : b)).toInt();
    int minY = yMin ?? (ys.isEmpty ? 0 : ys.reduce((a, b) => a < b ? a : b)).toInt();
    int maxY = yMax ?? (ys.isEmpty ? 0 : ys.reduce((a, b) => a > b ? a : b)).toInt();

    // 处理只有1格的情况
    int xUnits = forceXUnits ?? (maxX - minX + 1);
    int yUnits = forceYUnits ?? (maxY - minY + 1);
    if (xUnits == 1 && forceXUnits != null) xUnits = forceXUnits!;
    if (yUnits == 1 && forceYUnits != null) yUnits = forceYUnits!;

    // 限制画布最大宽高，防止极大极小导致空白
    final minCanvasSize = 200.0;
    final maxCanvasSize = 2000.0;
    final width = (yUnits * cellWidth).clamp(minCanvasSize, maxCanvasSize);
    final height = (xUnits * cellHeight).clamp(minCanvasSize, maxCanvasSize);

    // 计算初始缩放比例，使内容自适应居中
    final media = MediaQuery.of(context);
    final viewWidth = media.size.width - 40;
    final viewHeight = media.size.height - 200;
    final scaleX = viewWidth / (yUnits * cellWidth);
    final scaleY = viewHeight / (xUnits * cellHeight);
    final initialScale = [scaleX, scaleY, 1.0].reduce((a, b) => a < b ? a : b).clamp(0.1, 1.0);

    // 用Matrix4初始化TransformationController
    final Matrix4 initialMatrix = Matrix4.identity();
    initialMatrix.scale(initialScale);
    initialMatrix.translate((viewWidth - width * initialScale) / 2 / initialScale, (viewHeight - height * initialScale) / 2 / initialScale);
    final transformationController = TransformationController(initialMatrix);

    return InteractiveViewer(
      minScale: 0.1,
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(200),
      transformationController: transformationController,
      child: SizedBox(
        width: width,
        height: height,
        child: GestureDetector(
          onTapUp: (details) {
            if (onCellTap != null) {
              // 计算点击位置对应的cell
              final localPosition = details.localPosition;
              // 反向映射到cell坐标
              int cellY = maxY - (localPosition.dx ~/ cellWidth);
              int cellX = maxX - (localPosition.dy ~/ cellHeight);
              final tapped = cells.where(
                (c) => c.x.toInt() == cellX && c.y.toInt() == cellY,
              ).toList();
              if (tapped.isNotEmpty) onCellTap!(tapped.first);
            }
          },
          child: CustomPaint(
            painter: _MapPainter(
              cells: cells,
              cellWidth: cellWidth,
              cellHeight: cellHeight,
              xMin: minX,
              xMax: maxX,
              yMin: minY,
              yMax: maxY,
              startLocationId: startLocationId,
              endLocationId: endLocationId,
            ),
            size: Size(width, height),
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<GridCell> cells;
  final double cellWidth;
  final double cellHeight;
  final int xMin, xMax, yMin, yMax;
  final String? startLocationId, endLocationId;

  _MapPainter({
    required this.cells,
    required this.cellWidth,
    required this.cellHeight,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    this.startLocationId,
    this.endLocationId,
  });

  Color _getCellMarkColor(GridCell cell) {
    if (cell.id == startLocationId) {
      return Colors.blue;
    } else if (cell.id == endLocationId) {
      return Colors.red;
    }
    return cell.color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 先声明xUnits/yUnits，避免变量遮蔽
    int yUnits = yMax - yMin + 1;
    int xUnits = xMax - xMin + 1;
    // 调试输出
    print('MapPainter paint: xUnits=$xUnits, yUnits=$yUnits, size=$size');
    // 绘制网格线
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.06)
      ..strokeWidth = 0.2;
    // 垂直网格线（Y轴：右往左）
    for (int i = 0; i <= yUnits; i++) {
      double x = i * cellWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    // 水平网格线（X轴：下往上）
    for (int j = 0; j <= xUnits; j++) {
      double y = j * cellHeight;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    // 绘制库位格子
    for (final cell in cells) {
      // 右下为原点，X轴向上，Y轴向左
      final double displayX = (yMax - cell.y) * cellWidth;
      final double displayY = (xMax - cell.x) * cellHeight;
      final rect = Rect.fromLTWH(
        displayX + 2.0,
        displayY + 2.0,
        cellWidth - 4.0,
        cellHeight - 4.0,
      );
      final Color cellColor = _getCellMarkColor(cell);
      final bool isStartLocation = cell.id == startLocationId;
      final bool isEndLocation = cell.id == endLocationId;
      final backgroundPaint = Paint()
        ..color = cellColor.withOpacity(isStartLocation || isEndLocation ? 0.9 : 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
        backgroundPaint,
      );
      final borderPaint = Paint()
        ..color = cellColor.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isStartLocation || isEndLocation ? 2.0 : 1.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
        borderPaint,
      );
      // 绘制shelfId文本
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
      // 特殊标记
      if (isStartLocation || isEndLocation) {
        final double iconSize = rect.width * 0.3;
        final double iconX = rect.left + (rect.width - iconSize) / 2;
        final double iconY = rect.top + (rect.height - iconSize) / 2;
        final Paint iconPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        if (isStartLocation) {
          final Path startPath = Path();
          startPath.moveTo(iconX + iconSize / 2, iconY);
          startPath.lineTo(iconX, iconY + iconSize);
          startPath.lineTo(iconX + iconSize, iconY + iconSize);
          startPath.close();
          canvas.drawPath(startPath, iconPaint);
        } else if (isEndLocation) {
          final Paint flagPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;
          canvas.drawRect(
            Rect.fromLTWH(iconX + iconSize * 0.4, iconY, iconSize * 0.1, iconSize),
            flagPaint,
          );
          final Path flagPath = Path();
          flagPath.moveTo(iconX + iconSize * 0.5, iconY);
          flagPath.lineTo(iconX + iconSize, iconY + iconSize * 0.3);
          flagPath.lineTo(iconX + iconSize * 0.5, iconY + iconSize * 0.6);
          flagPath.close();
          canvas.drawPath(flagPath, flagPaint);
        }
      }
    }
    // 优化刻度步进，最多渲染20个刻度
    var textStyle = const TextStyle(color: Colors.black, fontSize: 12);
    int xStep = (xUnits ~/ 20 + 1).clamp(1, xUnits);
    int yStep = (yUnits ~/ 20 + 1).clamp(1, yUnits);
    for (int i = 0; i <= xUnits; i += xStep) {
      final int label = xMax - i;
      final textSpan = TextSpan(text: '$label', style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(size.width + 2, i * cellHeight + (cellHeight - tp.height) / 2),
      );
    }
    for (int j = 0; j <= yUnits; j += yStep) {
      final int label = yMax - j;
      final textSpan = TextSpan(text: '$label', style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(j * cellWidth + (cellWidth - tp.width) / 2, size.height + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
