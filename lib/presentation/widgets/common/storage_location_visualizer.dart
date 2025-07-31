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
  State<StorageLocationVisualizer> createState() =>
      _StorageLocationVisualizerState();
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
  static const int _maxRenderPoints = 10000;

  // 自适应布局参数
  static const double _minPointSpacing = 25.0; // 最小点位间距
  static const double _pointSize = 20.0; // 点位大小（网格的一半）
  static const double _padding = 60.0; // 画布边距

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
    }
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

  // 智能数据采样算法：优先保留重要点位
  List<Map<String, dynamic>> _sampleData(
      List<Map<String, dynamic>> data, int maxPoints) {
    if (data.length <= maxPoints) return data;

    // 优先保留起始点和终点
    List<Map<String, dynamic>> importantPoints = [];
    List<Map<String, dynamic>> normalPoints = [];

    for (var point in data) {
      final String pointId = point['id'] as String;
      if (pointId == widget.startLocationId ||
          pointId == widget.endLocationId) {
        importantPoints.add(point);
      } else {
        normalPoints.add(point);
      }
    }

    // 计算剩余可用点数
    final remainingPoints = maxPoints - importantPoints.length;
    if (remainingPoints <= 0) {
      return importantPoints;
    }

    // 对普通点位进行均匀采样
    List<Map<String, dynamic>> sampledNormalPoints = [];
    if (normalPoints.length <= remainingPoints) {
      sampledNormalPoints = normalPoints;
    } else {
      final step = normalPoints.length / remainingPoints;
      for (int i = 0; i < remainingPoints; i++) {
        final index = (i * step).floor();
        if (index < normalPoints.length) {
          sampledNormalPoints.add(normalPoints[index]);
        }
      }
    }

    List<Map<String, dynamic>> result = [
      ...importantPoints,
      ...sampledNormalPoints
    ];
    if (result.length > maxPoints) {
      result = result.take(maxPoints).toList();
    }

    return result;
  }

  // 自适应布局算法：根据坐标密度智能调整点位分布
  void _adaptiveLayout(List<Map<String, dynamic>> points, Size canvasSize) {
    if (points.length <= 1) return;

    // 过滤有效的数据点
    final validPoints = points
        .where((point) =>
            point['xplace'] != null &&
            point['yplace'] != null &&
            point['id'] != null)
        .toList();

    if (validPoints.isEmpty) return;

    // 计算坐标范围
    final xList = validPoints
        .map((e) => num.tryParse(e['xplace'].toString()) ?? 0.0)
        .toList();
    final yList = validPoints
        .map((e) => num.tryParse(e['yplace'].toString()) ?? 0.0)
        .toList();

    if (xList.isEmpty || yList.isEmpty) return;

    final minX = xList.reduce((a, b) => a < b ? a : b);
    final maxX = xList.reduce((a, b) => a > b ? a : b);
    final minY = yList.reduce((a, b) => a < b ? a : b);
    final maxY = yList.reduce((a, b) => a > b ? a : b);

    // 计算可用画布区域
    final usableWidth = canvasSize.width - _padding * 2;
    final usableHeight = canvasSize.height - _padding * 2;

    // 处理坐标范围相同的情况
    double xRange = (maxX - minX).toDouble();
    double yRange = (maxY - minY).toDouble();

    // 如果X或Y坐标范围太小，使用默认间距
    if (xRange < 0.1) {
      xRange = 1.0; // 使用默认范围
    }
    if (yRange < 0.1) {
      yRange = 1.0; // 使用默认范围
    }

    // 确保点位在画布上有足够的分布
    if (validPoints.length == 1) {
      // 单个点位居中显示
      final point = validPoints.first;
      point['offset'] = Offset(canvasSize.width / 2, canvasSize.height / 2);
      return;
    }

    // 检查是否有大量相同Y坐标的点
    final yValues = validPoints
        .map((p) => num.tryParse(p['yplace'].toString()) ?? 0.0)
        .toSet();
    if (yValues.length == 1 && validPoints.length > 3) {
      // 相同Y坐标的点，使用水平滑动布局
      _layoutHorizontalScroll(
          validPoints, canvasSize, usableWidth, usableHeight);
      return;
    }

    // 第一遍：根据实际坐标映射到画布
    for (int i = 0; i < validPoints.length; i++) {
      final point = validPoints[i];
      final x = num.tryParse(point['xplace'].toString()) ?? 0.0;
      final y = num.tryParse(point['yplace'].toString()) ?? 0.0;

      double canvasX = ((x - minX) / xRange) * usableWidth + _padding;
      double canvasY =
          canvasSize.height - _padding - (((y - minY) / yRange) * usableHeight);

      point['offset'] = Offset(canvasX, canvasY);
    }

    // 第二遍：处理重叠点位
    _resolveOverlaps(validPoints, canvasSize);
  }

  // 计算画布宽度，支持水平滑动
  double _calculateCanvasWidth(
      double baseWidth, List<Map<String, dynamic>> points) {
    // 检查是否有相同Y坐标的点
    final yValues = points
        .where((p) => p['offset'] != null)
        .map((p) => (p['offset'] as Offset).dy)
        .toSet();

    if (yValues.length == 1 && points.length > 3) {
      // 相同Y坐标的点，需要水平滑动
      final requiredWidth = points.length * _minPointSpacing + _padding * 2;
      return requiredWidth > baseWidth ? requiredWidth : baseWidth;
    }

    return baseWidth;
  }

  // 水平滑动布局：处理相同Y坐标的点
  void _layoutHorizontalScroll(List<Map<String, dynamic>> points,
      Size canvasSize, double usableWidth, double usableHeight) {
    // 按X坐标排序
    points.sort((a, b) {
      final xA = num.tryParse(a['xplace'].toString()) ?? 0.0;
      final xB = num.tryParse(b['xplace'].toString()) ?? 0.0;
      return xA.compareTo(xB);
    });

    // 计算需要的总宽度
    final totalWidth = points.length * _minPointSpacing;

    // 垂直居中位置
    final centerY = canvasSize.height / 2;

    // 如果总宽度超过可用宽度，从左侧开始布局，允许水平滑动
    final startX = _padding;

    for (int i = 0; i < points.length; i++) {
      final x = startX + i * _minPointSpacing + _minPointSpacing / 2;
      points[i]['offset'] = Offset(x, centerY);
    }
  }

  // 解决点位重叠问题
  void _resolveOverlaps(List<Map<String, dynamic>> points, Size canvasSize) {
    const int maxIterations = 50;
    const double repulsionForce = 0.8;

    for (int iteration = 0; iteration < maxIterations; iteration++) {
      bool hasMovement = false;

      for (int i = 0; i < points.length; i++) {
        Offset currentPos = points[i]['offset'] as Offset;
        Offset totalMove = Offset.zero;

        for (int j = 0; j < points.length; j++) {
          if (i == j) continue;

          Offset otherPos = points[j]['offset'] as Offset;
          double distance = (currentPos - otherPos).distance;

          // 如果点位重叠或距离太近
          if (distance < _minPointSpacing) {
            if (distance == 0) {
              // 完全重叠时，随机移动
              final randomAngle = (i * 137.5) * pi / 180; // 黄金角
              final randomOffset = Offset(
                cos(randomAngle) * _minPointSpacing,
                sin(randomAngle) * _minPointSpacing,
              );
              totalMove += randomOffset;
            } else {
              // 计算排斥力
              Offset direction = (currentPos - otherPos) / distance;
              double force = (_minPointSpacing - distance) / _minPointSpacing;
              totalMove += direction * force * repulsionForce;
            }
          }
        }

        if (totalMove != Offset.zero) {
          Offset newPos = currentPos + totalMove;

          // 确保点位在画布范围内
          newPos = Offset(
            newPos.dx.clamp(_padding, canvasSize.width - _padding),
            newPos.dy.clamp(_padding, canvasSize.height - _padding),
          );

          points[i]['offset'] = newPos;
          hasMovement = true;
        }
      }

      if (!hasMovement) break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    // 数据处理：智能采样
    List<Map<String, dynamic>> processedData = _data;
    if (_data.length > _maxRenderPoints) {
      processedData =
          _sampleData(_data, _maxRenderPoints).cast<Map<String, dynamic>>();
    }

    // 数据统计
    final validDataCount = processedData
        .where((point) =>
            point['xplace'] != null &&
            point['yplace'] != null &&
            point['id'] != null)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          final canvasWidth = widget.canvasWidth ?? constraints.maxWidth;
          final canvasHeight = widget.canvasHeight ?? constraints.maxHeight;

          // 检查画布尺寸是否有效
          if (canvasWidth <= 0 || canvasHeight <= 0) {
            return const Center(child: Text('画布尺寸无效'));
          }

          // 缓存优化：只在必要时重新计算
          if (_needsRecalculation || _cachedPointsWithOffset.isEmpty) {
            // 应用自适应布局
            _adaptiveLayout(processedData, Size(canvasWidth, canvasHeight));
            _cachedPointsWithOffset = List.from(processedData);
            _needsRecalculation = false;
          }

          final pointsWithOffset = _cachedPointsWithOffset;
          return Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.1,
                  maxScale: 50.0,
                  constrained: false,
                  child: GestureDetector(
                    behavior: kIsWeb
                        ? HitTestBehavior.translucent
                        : HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final localPos = details.localPosition;
                      for (var point in pointsWithOffset) {
                        if (point['offset'] == null) continue;
                        final Offset offset = point['offset'] as Offset;
                        double halfSize = _pointSize / 2;

                        if ((localPos.dx >= offset.dx - halfSize &&
                                localPos.dx <= offset.dx + halfSize) &&
                            (localPos.dy >= offset.dy - halfSize &&
                                localPos.dy <= offset.dy + halfSize)) {
                          if (widget.onTapPoint != null)
                            widget.onTapPoint!(point);
                          break;
                        }
                      }
                    },
                    child: CustomPaint(
                      size: Size(
                        _calculateCanvasWidth(
                            canvasWidth.toDouble(), pointsWithOffset),
                        canvasHeight,
                      ),
                      painter: _StorageLocationPainter(
                        points: pointsWithOffset,
                        scale: _currentScale,
                        startLocationId: widget.startLocationId,
                        endLocationId: widget.endLocationId,
                        pointSize: _pointSize,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        } catch (e) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('渲染错误: $e'),
              ],
            ),
          );
        }
      },
    );
  }

  // 构建图例项
  Widget _buildLegendItem(String text, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageLocationPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;
  final double scale;
  final String? startLocationId;
  final String? endLocationId;
  final double pointSize;

  // 缓存预计算的渲染数据
  final Map<Color, List<Rect>> _cachedRects = {};
  final Map<Color, Paint> _cachedPaints = {};

  _StorageLocationPainter({
    required this.points,
    required this.scale,
    this.startLocationId,
    this.endLocationId,
    required this.pointSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // 绘制简约背景网格
      // _drawMinimalGrid(canvas, size);

      // 性能优化：预计算渲染数据
      _prepareRenderData();

      // 批量渲染点位
      _cachedPaints.forEach((color, paint) {
        final rects = _cachedRects[color];
        if (rects != null) {
          for (final rect in rects) {
            // 检查矩形是否有效
            if (rect.width > 0 && rect.height > 0) {
              // 绘制方形库位
              canvas.drawRRect(
                RRect.fromRectAndRadius(rect, Radius.circular(2.0)),
                paint,
              );

              // 绘制简约边框
              final borderPaint = Paint()
                ..color = color.withOpacity(0.3)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.0;
              canvas.drawRRect(
                RRect.fromRectAndRadius(rect, Radius.circular(2.0)),
                borderPaint,
              );
            }
          }
        }
      });

      // 绘制起始点和终点的特殊标记
      _drawStartEndMarkers(canvas, size);

      // 绘制托盘编号标记
      _drawShelfMarkers(canvas, size);
    } catch (e) {
      // 如果绘制出错，绘制一个错误提示
      final errorPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      final errorRect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawRect(errorRect, errorPaint);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: '绘制错误',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
    }
  }

  void _prepareRenderData() {
    _cachedRects.clear();
    _cachedPaints.clear();

    for (var point in points) {
      // 安全检查：确保必要的数据存在
      if (point['offset'] == null || point['id'] == null) {
        continue;
      }

      final Offset offset = point['offset'] as Offset;
      final int statusCode =
          int.tryParse(point['status']?.toString() ?? '0') ?? 0;
      final String pointId = point['id'] as String;

      // 确定点位颜色 - 使用LandmarkStatus枚举
      Color color;
      if (pointId == startLocationId) {
        color = const Color(0xFF64B5F6); // 起始点 - 淡蓝色
      } else if (pointId == endLocationId) {
        color = const Color(0xFFEF5350); // 终点 - 淡红色
      } else {
        // 根据LandmarkStatus枚举获取颜色
        final landmarkStatus = LandmarkStatus.fromCode(statusCode);
        color = Util.hexToColor(landmarkStatus.color);
      }

      // 缓存Paint对象
      _cachedPaints.putIfAbsent(
          color,
          () => Paint()
            ..color = color
            ..style = PaintingStyle.fill);

      // 缓存矩形
      _cachedRects.putIfAbsent(color, () => []).add(
            Rect.fromCenter(
              center: offset,
              width: pointSize,
              height: pointSize,
            ),
          );
    }
  }

  // 绘制起始点和终点的特殊标记
  void _drawStartEndMarkers(Canvas canvas, Size size) {
    const double labelOffset = 15;
    const double fontSize = 10;

    for (var point in points) {
      // 安全检查：确保必要的数据存在
      if (point['offset'] == null || point['id'] == null) {
        continue;
      }

      final Offset offset = point['offset'] as Offset;
      final String pointId = point['id'] as String;

      if (pointId == startLocationId || pointId == endLocationId) {
        final isStart = pointId == startLocationId;
        final color =
            isStart ? const Color(0xFF64B5F6) : const Color(0xFFEF5350);
        final text = isStart ? '起' : '终';

        // 绘制简约标签背景
        final bgPaint = Paint()
          ..color = Colors.white.withOpacity(0.95)
          ..style = PaintingStyle.fill;
        final bgRect = Rect.fromCenter(
          center: Offset(offset.dx, offset.dy - labelOffset),
          width: 24,
          height: 14,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
          bgPaint,
        );

        // 绘制简约边框
        final borderPaint = Paint()
          ..color = color.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
          borderPaint,
        );

        // 绘制简约文字
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            offset.dx - textPainter.width / 2, // 文字居中
            offset.dy - labelOffset - textPainter.height / 2,
          ),
        );
      }
    }
  }

  // 绘制简约背景网格
  void _drawMinimalGrid(Canvas canvas, Size size) {
    const double gridSize = 40.0;
    const double gridOpacity = 0.05;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(gridOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // 绘制垂直线
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // 绘制水平线
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  // 绘制托盘编号标记
  void _drawShelfMarkers(Canvas canvas, Size size) {
    for (var point in points) {
      // 安全检查：确保必要的数据存在
      if (point['offset'] == null) {
        continue;
      }

      final Offset offset = point['offset'] as Offset;

      String? shelfId;
      if (point['shelfId'] != null) {
        shelfId = point['shelfId'] as String;
      } else {
        final Map<String, dynamic>? storageShelfDTO =
            point['storageShelfDTO'] as Map<String, dynamic>?;
        if (storageShelfDTO != null && storageShelfDTO['shelfId'] != null) {
          shelfId = storageShelfDTO['shelfId'] as String;
        }
      }

      if (shelfId != null && shelfId.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: shelfId,
            style: const TextStyle(
              fontSize: 5,
              color: Color.fromARGB(255, 61, 61, 61),
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        // 在方形中心绘制托盘编号
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

  @override
  bool shouldRepaint(covariant _StorageLocationPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;

    for (int i = 0; i < points.length; i++) {
      if (i >= oldDelegate.points.length) return true;

      final oldPoint = oldDelegate.points[i];
      final newPoint = points[i];

      if (oldPoint['offset'] != newPoint['offset'] ||
          oldPoint['status'] != newPoint['status'] ||
          oldPoint['shelfId'] != newPoint['shelfId']) {
        return true;
      }
    }

    return oldDelegate.scale != scale ||
        oldDelegate.startLocationId != startLocationId ||
        oldDelegate.endLocationId != endLocationId ||
        oldDelegate.pointSize != pointSize;
  }
}
