import 'package:flutter/material.dart';

class MapControl extends StatefulWidget {
  final List<MapPoint> points; // 坐标点列表
  final double scale; // 缩放比例
  final Color backgroundColor; // 背景颜色
  final Color gridColor; // 网格颜色
  final Color pointColor; // 点颜色
  final double blockWidth; // 方块宽度
  final double blockHeight; // 方块高度

  const MapControl({
    Key? key,
    required this.points,
    this.scale = 1.0,
    this.backgroundColor = Colors.white,
    this.gridColor = Colors.grey,
    this.pointColor = Colors.red,
    this.blockWidth = 6.0, // 默认方块宽度
    this.blockHeight = 4.0, // 默认方块高度
  }) : super(key: key);

  @override
  State<MapControl> createState() => _MapControlState();
}

class _MapControlState extends State<MapControl> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RepaintBoundary(
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: MapControlPainter(
              points: widget.points,
              scale: widget.scale,
              backgroundColor: widget.backgroundColor,
              gridColor: widget.gridColor,
              pointColor: widget.pointColor,
              blockWidth: widget.blockWidth,
              blockHeight: widget.blockHeight,
            ),
            isComplex: true,
            willChange: false,
          ),
        );
      },
    );
  }
}

class MapPoint {
  final double x; // X坐标 (0.1为单位)
  final double y; // Y坐标 (0.1为单位)
  final String? label; // 标签
  final Color? color; // 自定义颜色

  MapPoint({
    required this.x,
    required this.y,
    this.label,
    this.color,
  });
}

class MapControlPainter extends CustomPainter {
  final List<MapPoint> points;
  final double scale;
  final Color backgroundColor;
  final Color gridColor;
  final Color pointColor;
  final double blockWidth;
  final double blockHeight;

  MapControlPainter({
    required this.points,
    required this.scale,
    required this.backgroundColor,
    required this.gridColor,
    required this.pointColor,
    required this.blockWidth,
    required this.blockHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // 绘制网格
    _drawGrid(canvas, size);

    // 绘制坐标点
    _drawPoints(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 计算网格间距
    // 0.5个单位 = 方块宽度/高度的一半
    final gridSpacingX = blockWidth / 2 * scale; // 水平网格间距
    final gridSpacingY = blockHeight / 2 * scale; // 垂直网格间距
    
    // 绘制垂直线
    for (double x = 0; x <= size.width; x += gridSpacingX) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // 绘制水平线
    for (double y = 0; y <= size.height; y += gridSpacingY) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  void _drawPoints(Canvas canvas, Size size) {
    for (final point in points) {
      // 将坐标转换为像素位置
      // 左下角为原点，X向右为正，Y向上为正
      // 0.5个单位 = 方块宽度/高度的一半
      final pixelX = point.x * (blockWidth / 2) * scale;
      final pixelY = size.height - (point.y * (blockHeight / 2) * scale); // 翻转Y轴

      // 绘制矩形块
      final rectPaint = Paint()
        ..color = point.color ?? pointColor
        ..style = PaintingStyle.fill;

      final rect = Rect.fromCenter(
        center: Offset(pixelX, pixelY),
        width: blockWidth * scale,
        height: blockHeight * scale,
      );

      canvas.drawRect(rect, rectPaint);

      // 绘制边框
      final borderPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(rect, borderPaint);

      // 绘制标签
      if (point.label != null) {
        _drawLabel(canvas, point.label!, Offset(pixelX, pixelY - (blockHeight * scale) / 2 - 10));
      }
    }
  }

  void _drawLabel(Canvas canvas, String label, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant MapControlPainter oldDelegate) {
    return oldDelegate.points != points ||
           oldDelegate.scale != scale ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.gridColor != gridColor ||
           oldDelegate.pointColor != pointColor ||
           oldDelegate.blockWidth != blockWidth ||
           oldDelegate.blockHeight != blockHeight;
  }
}

// 使用示例
class MapControlExample extends StatelessWidget {
  const MapControlExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final points = [
      MapPoint(x: 1.0, y: 1.0, label: 'A', color: Colors.red),
      MapPoint(x: 3.0, y: 2.0, label: 'B', color: Colors.blue),
      MapPoint(x: 6.0, y: 3.0, label: 'C', color: Colors.green),
      MapPoint(x: 10.0, y: 4.0, label: 'D', color: Colors.orange),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: MapControl(
        points: points,
        scale: 1.0,
        backgroundColor: Colors.white,
        gridColor: Colors.grey.shade300,
        pointColor: Colors.red,
        blockWidth: 30.0, // 方块宽度
        blockHeight: 20.0, // 方块高度
      ),
    );
  }
}