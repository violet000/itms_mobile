import 'package:flutter/material.dart';

class GridCell {
  final int x;
  final int y;
  final Color color;
  GridCell({required this.x, required this.y, required this.color});
}

class MapControl extends StatelessWidget {
  const MapControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: GridPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final int xUnits = 9;
  final int yUnits = 10;
  final double axisWidth = 2.0;
  final Color axisColor = Colors.black;
  // final Color gridColor = Colors.grey;
  final Color gridColor = Colors.transparent;
  final List<GridCell> cells;

  GridPainter({this.cells = const []});

  @override
  void paint(Canvas canvas, Size size) {
    // 坐标原点定位到左下角，X轴从左往右，Y轴从下往上
    canvas.save();
    canvas.translate(0, size.height);
    canvas.scale(1, -1);

    final double dx = size.width / xUnits;
    final double dy = size.height / yUnits;

    // 根据父级控件传入的数据进行填充
    for (final cell in cells) {
      if (cell.x >= 0 && cell.x < xUnits && cell.y >= 0 && cell.y < yUnits) {
        final double padding = 5.0; // 格子的间距距离
        final rect = Rect.fromLTWH(
          cell.x * dx + padding,
          cell.y * dy + padding,
          dx - 2 * padding,
          dy - 2 * padding,
        );
        final paint = Paint()..color = cell.color;
        canvas.drawRect(rect, paint);
      }
    }

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final Paint axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = axisWidth;

    // 绘制网格
    for (int i = 0; i <= xUnits; i++) {
      double x = i * dx;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    for (int j = 0; j <= yUnits; j++) {
      double y = j * dy;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // 绘制X轴
    // canvas.drawLine(
    //   Offset(0, 0),
    //   Offset(size.width, 0),
    //   axisPaint,
    // );
    // // 绘制Y轴
    // canvas.drawLine(
    //   Offset(0, 0),
    //   Offset(0, size.height),
    //   axisPaint,
    // );

    // 画布坐标系
    canvas.restore();
    final textStyle = TextStyle(color: Colors.black, fontSize: 12);
    // X轴刻度
    for (int i = 0; i <= xUnits; i++) {
      final textSpan = TextSpan(text: '$i', style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      // x轴
      // tp.paint(canvas, Offset(i * size.width / xUnits - tp.width / 2, size.height + 2));
    }
    // Y轴刻度
    for (int j = 0; j <= yUnits; j++) {
      final textSpan = TextSpan(text: '$j', style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      // y轴
      // tp.paint(canvas, Offset(2, size.height - j * size.height / yUnits - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
