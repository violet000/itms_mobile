import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:itms_mobile/core/utils/util.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';

class StorageLocationVisualizer extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final void Function(Map<String, dynamic>)? onTapPoint;
  final double? canvasWidth;
  final double? canvasHeight;

  const StorageLocationVisualizer({
    Key? key,
    required this.data,
    this.onTapPoint,
    this.canvasWidth,
    this.canvasHeight,
  }) : super(key: key);

  @override
  State<StorageLocationVisualizer> createState() => _StorageLocationVisualizerState();
}

class _StorageLocationVisualizerState extends State<StorageLocationVisualizer> {
  List<Map<String, dynamic>> _data = [];
  late TransformationController _transformationController;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    setState(() {
      _currentScale = _transformationController.value.getMaxScaleOnAxis();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // 点聚合算法
  List<List<Map<String, dynamic>>> _clusterPoints(List<Map<String, dynamic>> points, double threshold) {
    List<List<Map<String, dynamic>>> clusters = [];
    Set<int> visited = {};
    for (int i = 0; i < points.length; i++) {
      if (visited.contains(i)) continue;
      List<Map<String, dynamic>> cluster = [points[i]];
      visited.add(i);
      for (int j = i + 1; j < points.length; j++) {
        if (visited.contains(j)) continue;
        final Offset oi = points[i]['offset'] as Offset;
        final Offset oj = points[j]['offset'] as Offset;
        double dist = (oi - oj).distance;
        if (dist < threshold) {
          cluster.add(points[j]);
          visited.add(j);
        }
      }
      clusters.add(cluster);
    }
    return clusters;
  }

  @override
  Widget build(BuildContext context) {
    if (_data.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    // 计算x、y的最小最大值
    final xList = _data.map((e) => num.parse(e['xplace'].toString())).toList();
    final yList = _data.map((e) => num.parse(e['yplace'].toString())).toList();
    final minX = xList.reduce((a, b) => a < b ? a : b);
    final maxX = xList.reduce((a, b) => a > b ? a : b);
    final minY = yList.reduce((a, b) => a < b ? a : b);
    final maxY = yList.reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = widget.canvasWidth ?? constraints.maxWidth;
        final canvasHeight = widget.canvasHeight ?? constraints.maxHeight * 3;
        // 计算所有点的画布坐标
        List<Map<String, dynamic>> pointsWithOffset = _data.map((point) {
          final offset = _mapToCanvas(
            num.parse(point['xplace'].toString()),
            num.parse(point['yplace'].toString()),
            minX, maxX, minY, maxY, canvasWidth, canvasHeight, padding: 80, // padding由40改为80
          );
          return <String, dynamic>{...point, 'offset': offset};
        }).toList();
        // 点排斥处理，避免重叠
        _resolveOverlap(pointsWithOffset, 8, Size(canvasWidth, canvasHeight)); // 8 = 2*radius
        return Row(
          children: [
            Expanded(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.01,
                maxScale: 100.0,
                constrained: false,
                child: GestureDetector(
                  onTapUp: (details) {
                    final localPos = details.localPosition;
                    for (var point in pointsWithOffset) {
                      final Offset offset = point['offset'] as Offset;
                      double dist = (offset - localPos).distance;
                      double radius = 4;
                      if (dist < radius) {
                        if (widget.onTapPoint != null) widget.onTapPoint!(point);
                        break;
                      }
                    }
                  },
                  child: CustomPaint(
                    size: Size(canvasWidth, canvasHeight),
                    painter: _StorageLocationPainter(
                      points: pointsWithOffset,
                      minX: minX,
                      maxX: maxX,
                      minY: minY,
                      maxY: maxY,
                      scale: _currentScale,
                    ),
                  ),
                ),
              ),
            ),
            // 图例已移除
          ],
        );
      },
    );
  }

  /// 数据坐标映射到画布坐标
  Offset _mapToCanvas(
    num x,
    num y,
    num minX,
    num maxX,
    num minY,
    num maxY,
    double width,
    double height, {
    double padding = 40,
  }) {
    final usableWidth = width - padding * 2;
    final usableHeight = height - padding * 2;
    final dx = ((x - minX) / (maxX - minX)) * usableWidth + padding;
    final dy = height - (((y - minY) / (maxY - minY)) * usableHeight + padding);
    return Offset(dx, dy);
  }

  /// 力导向点排斥处理，避免重叠，增强分离效果
  void _resolveOverlap(List<Map<String, dynamic>> points, double minDist, Size canvasSize, {int maxIter = 50}) {
    for (int iter = 0; iter < maxIter; iter++) {
      bool changed = false;
      for (int i = 0; i < points.length; i++) {
        Offset oi = points[i]['offset'] as Offset;
        Offset totalMove = Offset.zero;
        for (int j = 0; j < points.length; j++) {
          if (i == j) continue;
          Offset oj = points[j]['offset'] as Offset;
          double dist = (oi - oj).distance;
          if (dist < minDist && dist > 0) {
            // 斥力与距离成反比
            Offset dir = (oi - oj) / dist;
            double force = (minDist - dist) / minDist;
            totalMove += dir * force * minDist * 0.5; // 0.5可调节分开速度
          }
        }
        if (totalMove != Offset.zero) {
          Offset newOffset = oi + totalMove;
          // 保证点不出界
          newOffset = Offset(
            newOffset.dx.clamp(0.0, canvasSize.width),
            newOffset.dy.clamp(0.0, canvasSize.height),
          );
          points[i]['offset'] = newOffset;
          changed = true;
        }
      }
      if (!changed) break;
    }
  }
}

class _StorageLocationPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;
  final num minX, maxX, minY, maxY;
  final double scale;
  final double padding = 40;

  _StorageLocationPainter({
    required this.points,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final usableWidth = size.width - padding * 2;
    final usableHeight = size.height - padding * 2;
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    final tickPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    final textStyle = const TextStyle(fontSize: 12, color: Colors.black);
    double radius = 4;
    // 画x轴
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );
    // 画y轴
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(padding, padding),
      axisPaint,
    );
    // 批量渲染点，按颜色分组
    Map<Color, List<Offset>> colorGroups = {};
    for (var point in points) {
      final Offset offset = point['offset'] as Offset;
      final int statusCode = int.tryParse(point['status'].toString()) ?? 0;
      final Color color = Util.getStatusColor(statusCode);
      colorGroups.putIfAbsent(color, () => []).add(offset);
    }
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    colorGroups.forEach((color, offsets) {
      paint.color = color;
      paint.strokeWidth = radius * 2;
      canvas.drawPoints(PointMode.points, offsets, paint);
    });
  }

  @override
  bool shouldRepaint(covariant _StorageLocationPainter oldDelegate) {
    return oldDelegate.points != points ||
           oldDelegate.scale != scale ||
           oldDelegate.minX != minX ||
           oldDelegate.maxX != maxX ||
           oldDelegate.minY != minY ||
           oldDelegate.maxY != maxY;
  }
}
