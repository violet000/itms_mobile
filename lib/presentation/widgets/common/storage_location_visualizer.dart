import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:itms_mobile/core/utils/util.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';

class StorageLocationVisualizer extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final void Function(Map<String, dynamic>)? onTapPoint;
  final double? canvasWidth;
  final double? canvasHeight;
  final String? startLocationId;
  final String? endLocationId;

  const StorageLocationVisualizer({
    Key? key,
    required this.data,
    this.onTapPoint,
    this.canvasWidth,
    this.canvasHeight,
    this.startLocationId,
    this.endLocationId,
  }) : super(key: key);

  @override
  State<StorageLocationVisualizer> createState() => _StorageLocationVisualizerState();
}

class _StorageLocationVisualizerState extends State<StorageLocationVisualizer> {
  List<Map<String, dynamic>> _data = [];
  late TransformationController _transformationController;
  double _currentScale = 1.0;
  
  // 缓存优化
  List<Map<String, dynamic>> _cachedPointsWithOffset = [];
  bool _needsRecalculation = true;
  Rect _lastViewport = Rect.zero;
  
  // 性能优化：限制最大渲染点数
  static const int _maxRenderPoints = 1000;
  
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
  void didUpdateWidget(StorageLocationVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _data = widget.data;
      _needsRecalculation = true;
      
      // 调试信息：检查接收到的数据
      for (var item in _data) {
        final shelfId = item['shelfId'] as String?;
        if (shelfId != null && shelfId.isNotEmpty) {
          print('可视化组件接收到 - 库位: ${item['id']}, shelfId: $shelfId');
        }
      }
    }
    // 如果起始点或终点发生变化，需要重新渲染
    if (oldWidget.startLocationId != widget.startLocationId ||
        oldWidget.endLocationId != widget.endLocationId) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // 数据采样算法：当点数过多时进行采样
  List<Map<String, dynamic>> _sampleData(List<Map<String, dynamic>> data, int maxPoints) {
    if (data.length <= maxPoints) return data;
    
    // 简单的均匀采样
    final step = data.length / maxPoints;
    List<Map<String, dynamic>> sampledData = [];
    
    for (int i = 0; i < maxPoints; i++) {
      final index = (i * step).floor();
      if (index < data.length) {
        sampledData.add(data[index]);
      }
    }
    
    return sampledData;
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
    
    // 性能优化：数据采样
    List<Map<String, dynamic>> processedData = _data;
    if (_data.length > _maxRenderPoints) {
      processedData = _sampleData(_data, _maxRenderPoints).cast<Map<String, dynamic>>();
    }
    
    // 计算x、y的最小最大值
    final xList = processedData.map((e) => num.parse(e['xplace'].toString())).toList();
    final yList = processedData.map((e) => num.parse(e['yplace'].toString())).toList();
    final minX = xList.reduce((a, b) => a < b ? a : b);
    final maxX = xList.reduce((a, b) => a > b ? a : b);
    final minY = yList.reduce((a, b) => a < b ? a : b);
    final maxY = yList.reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = widget.canvasWidth ?? constraints.maxWidth;
        final canvasHeight = widget.canvasHeight ?? constraints.maxHeight;
        
        // 缓存优化：只在必要时重新计算
        if (_needsRecalculation || _cachedPointsWithOffset.isEmpty) {
          // 计算所有点的画布坐标
          List<Map<String, dynamic>> pointsWithOffset = processedData.map((point) {
            final offset = _mapToCanvas(
              num.parse(point['xplace'].toString()),
              num.parse(point['yplace'].toString()),
              minX, maxX, minY, maxY, canvasWidth, canvasHeight, padding: 80,
            );
            return <String, dynamic>{...point, 'offset': offset};
          }).toList();
          
          // 点排斥处理，避免重叠
          _resolveOverlap(pointsWithOffset, 16, Size(canvasWidth, canvasHeight));
          
          _cachedPointsWithOffset = pointsWithOffset;
          _needsRecalculation = false;
        }
        
        final pointsWithOffset = _cachedPointsWithOffset;
        return Row(
          children: [
            Expanded(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.01,
                maxScale: 100.0,
                constrained: false,
                child: GestureDetector(
                  // Web端禁用点击反馈
                  behavior: kIsWeb ? HitTestBehavior.translucent : HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final localPos = details.localPosition;
                    for (var point in pointsWithOffset) {
                      final Offset offset = point['offset'] as Offset;
                      double halfSize = 4; // 圆角矩形边长的一半
                      // 检查点击位置是否在圆角矩形范围内
                      if ((localPos.dx >= offset.dx - halfSize && localPos.dx <= offset.dx + halfSize) &&
                          (localPos.dy >= offset.dy - halfSize && localPos.dy <= offset.dy + halfSize)) {
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
                      startLocationId: widget.startLocationId,
                      endLocationId: widget.endLocationId,
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
    
    // 修复Y坐标映射，确保点不会出现在X轴下方
    // 将Y坐标映射到画布的有效区域，X轴在底部
    final dy = height - padding - (((y - minY) / (maxY - minY)) * usableHeight);
    
    // 确保点不会超出有效区域
    final clampedDx = dx.clamp(padding, width - padding);
    final clampedDy = dy.clamp(padding, height - padding);
    
    return Offset(clampedDx, clampedDy);
  }

  /// 力导向点排斥处理，避免重叠，增强分离效果
  void _resolveOverlap(List<Map<String, dynamic>> points, double minDist, Size canvasSize, {int maxIter = 50}) {
    for (int iter = 0; iter < maxIter; iter++) {
      bool changed = false;
      
      // 按X坐标分组处理相同X坐标的点
      Map<double, List<Map<String, dynamic>>> xGroups = {};
      for (var point in points) {
        final Offset offset = point['offset'] as Offset;
        final double x = offset.dx;
        xGroups.putIfAbsent(x, () => []).add(point);
      }
      
      // 处理相同X坐标的点，确保Y距离至少为1.2倍圆直径
      xGroups.forEach((x, xPoints) {
        if (xPoints.length > 1) {
          // 按Y坐标排序
          xPoints.sort((a, b) {
            final Offset offsetA = a['offset'] as Offset;
            final Offset offsetB = b['offset'] as Offset;
            return offsetA.dy.compareTo(offsetB.dy);
          });
          
          // 调整Y坐标，确保相邻点间距为2.5倍圆角矩形边长（矩形之间有间隔）
          double minYDistance = minDist * 2.5; // 2.5倍圆角矩形边长
          for (int i = 1; i < xPoints.length; i++) {
            final Offset prevOffset = xPoints[i - 1]['offset'] as Offset;
            final Offset currentOffset = xPoints[i]['offset'] as Offset;
            final double currentDistance = (currentOffset.dy - prevOffset.dy).abs();
            
            if (currentDistance < minYDistance) {
              // 计算需要移动的距离
              final double moveDistance = minYDistance - currentDistance;
              
              // 向下移动当前点及之后的所有点
              for (int j = i; j < xPoints.length; j++) {
                final Offset pointOffset = xPoints[j]['offset'] as Offset;
                final Offset newOffset = Offset(pointOffset.dx, pointOffset.dy + moveDistance);
                
                // 确保点不出界，并且不会出现在X轴下方
                final Offset clampedOffset = Offset(
                  newOffset.dx.clamp(40.0, canvasSize.width - 40.0),
                  newOffset.dy.clamp(40.0, canvasSize.height - 40.0), // 留出padding空间
                );
                
                xPoints[j]['offset'] = clampedOffset;
              }
              changed = true;
            }
          }
        }
      });
      
      // 原有的全局排斥处理
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
          // 保证点不出界，并且不会出现在X轴下方
          newOffset = Offset(
            newOffset.dx.clamp(40.0, canvasSize.width - 40.0),
            newOffset.dy.clamp(40.0, canvasSize.height - 40.0), // 留出padding空间
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
  final String? startLocationId;
  final String? endLocationId;
  
  // 缓存预计算的渲染数据
  final Map<Color, List<Rect>> _cachedRects = {};
  final Map<Color, Paint> _cachedPaints = {};

  _StorageLocationPainter({
    required this.points,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.scale,
    this.startLocationId,
    this.endLocationId,
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
    final textStyle = const TextStyle(
      fontSize: 10,
      color: Colors.black,
      fontWeight: FontWeight.w500,
    );
    
    // 画坐标轴
    // canvas.drawLine(
    //   Offset(padding, size.height - padding),
    //   Offset(size.width - padding, size.height - padding),
    //   axisPaint,
    // );
    // canvas.drawLine(
    //   Offset(padding, size.height - padding),
    //   Offset(padding, padding),
    //   axisPaint,
    // );
    
    // 绘制X轴刻度
    // _drawXAxisTicks(canvas, size, tickPaint, textStyle);
    
    // 绘制Y轴刻度
    // _drawYAxisTicks(canvas, size, tickPaint, textStyle);
    
    // 性能优化：预计算渲染数据
    _prepareRenderData();
    
    // 批量渲染圆角矩形
    _cachedPaints.forEach((color, paint) {
      final rects = _cachedRects[color];
      if (rects != null) {
        // 使用批量绘制方法
        for (final rect in rects) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            paint,
          );
        }
      }
    });
    
    // 绘制起始点和终点的文字标记
    _drawStartEndLabels(canvas, size);
    
    // 绘制有货架库位的特殊标记
    _drawShelfMarkers(canvas, size);
  }
  
  void _prepareRenderData() {
    _cachedRects.clear();
    _cachedPaints.clear();
    
    const double size = 8; // 矩形边长
    const double radius = 2; // 圆角半径
    
    // 按颜色分组并预计算圆角矩形
    for (var point in points) {
      final Offset offset = point['offset'] as Offset;
      final int statusCode = int.tryParse(point['status'].toString()) ?? 0;
      final String pointId = point['id'] as String;
      final String? shelfId = point['shelfId'] as String?;
      
      // 检查是否为起始点或终点
      Color color;
      if (pointId == startLocationId) {
        color = Colors.blue; // 起始点用蓝色
      } else if (pointId == endLocationId) {
        color = Colors.red; // 终点用红色
      } else {
        color = Util.getStatusColor(statusCode);
      }
      
      // 缓存Paint对象
      _cachedPaints.putIfAbsent(color, () => Paint()
        ..color = color
        ..style = PaintingStyle.fill);
      
      // 缓存圆角矩形
      _cachedRects.putIfAbsent(color, () => []).add(
        Rect.fromCenter(
          center: offset,
          width: size,
          height: size,
        ),
      );
    }
  }
  
  // 绘制起始点和终点的文字标记
  void _drawStartEndLabels(Canvas canvas, Size size) {
    const double labelOffset = 15; // 文字偏移量
    const double fontSize = 12;
    
    for (var point in points) {
      final Offset offset = point['offset'] as Offset;
      final String pointId = point['id'] as String;
      
      if (pointId == startLocationId) {
        // 绘制起始点标记
        final textPainter = TextPainter(
          text: const TextSpan(
            text: '起点',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        // 绘制背景圆
        final bgPaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;
        final bgRect = Rect.fromCenter(
          center: Offset(offset.dx, offset.dy - labelOffset),
          width: textPainter.width + 8,
          height: textPainter.height + 4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
          bgPaint,
        );
        
        // 绘制边框
        final borderPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
          borderPaint,
        );
        
        // 绘制文字
        textPainter.paint(
          canvas,
          Offset(
            offset.dx - textPainter.width / 2,
            offset.dy - labelOffset - textPainter.height / 2,
          ),
        );
      } else if (pointId == endLocationId) {
        // 绘制终点标记
        final textPainter = TextPainter(
          text: const TextSpan(
            text: '终点',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        // 绘制背景圆
        final bgPaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;
        final bgRect = Rect.fromCenter(
          center: Offset(offset.dx, offset.dy - labelOffset),
          width: textPainter.width + 8,
          height: textPainter.height + 4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
          bgPaint,
        );
        
        // 绘制边框
        final borderPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
          borderPaint,
        );
        
        // 绘制文字
        textPainter.paint(
          canvas,
          Offset(
            offset.dx - textPainter.width / 2,
            offset.dy - labelOffset - textPainter.height / 2,
          ),
        );
      }
    }
  }
  
  // 绘制有货架库位的特殊标记
  void _drawShelfMarkers(Canvas canvas, Size size) {
    print('开始绘制货架标记，总点数: ${points.length}');
    
    for (var point in points) {
      final Offset offset = point['offset'] as Offset;
      final String? shelfId = point['shelfId'] as String?;
      
      // 调试信息：打印有货架的库位
      if (shelfId != null && shelfId.isNotEmpty) {
        print('发现有货架的库位: ${point['id']}, shelfId: $shelfId');
      }
      
      // 如果有货架ID，在矩形中间绘制小字体
      if (shelfId != null && shelfId.isNotEmpty) {
        // 创建文本绘制器
        final textPainter = TextPainter(
          text: TextSpan(
            text: shelfId,
            style: const TextStyle(
              fontSize: 2, // 更小的字体
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        // 布局文本
        textPainter.layout();
        
        // 在矩形中心绘制文本
        textPainter.paint(
          canvas,
          Offset(
            offset.dx - textPainter.width / 2,
            offset.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }
  
  // 绘制X轴刻度
  void _drawXAxisTicks(Canvas canvas, Size size, Paint tickPaint, TextStyle textStyle) {
    final usableWidth = size.width - padding * 2;
    final tickCount = 10; // 刻度数量
    
    for (int i = 0; i <= tickCount; i++) {
      final x = padding + (usableWidth * i / tickCount);
      final value = minX + (maxX - minX) * i / tickCount;
      
      // 绘制刻度线
      canvas.drawLine(
        Offset(x, size.height - padding),
        Offset(x, size.height - padding + 5),
        tickPaint,
      );
      
      // 绘制刻度值
      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(1),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - padding + 8),
      );
    }
  }
  
  // 绘制Y轴刻度
  void _drawYAxisTicks(Canvas canvas, Size size, Paint tickPaint, TextStyle textStyle) {
    final usableHeight = size.height - padding * 2;
    final tickCount = 8; // 刻度数量
    
    for (int i = 0; i <= tickCount; i++) {
      final y = size.height - padding - (usableHeight * i / tickCount);
      final value = minY + (maxY - minY) * i / tickCount;
      
      // 绘制刻度线
      canvas.drawLine(
        Offset(padding - 5, y),
        Offset(padding, y),
        tickPaint,
      );
      
      // 绘制刻度值
      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(1),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(padding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StorageLocationPainter oldDelegate) {
    // 性能优化：只在数据真正变化时才重绘
    if (oldDelegate.points.length != points.length) return true;
    
    // 检查关键数据是否变化
    for (int i = 0; i < points.length; i++) {
      if (i >= oldDelegate.points.length) return true;
      
      final oldPoint = oldDelegate.points[i];
      final newPoint = points[i];
      
      // 检查offset、status和shelfId是否变化
      if (oldPoint['offset'] != newPoint['offset'] ||
          oldPoint['status'] != newPoint['status'] ||
          oldPoint['shelfId'] != newPoint['shelfId']) {
        return true;
      }
    }
    
    return oldDelegate.scale != scale ||
           oldDelegate.minX != minX ||
           oldDelegate.maxX != maxX ||
           oldDelegate.minY != minY ||
           oldDelegate.maxY != maxY ||
           oldDelegate.startLocationId != startLocationId ||
           oldDelegate.endLocationId != endLocationId;
  }
}
