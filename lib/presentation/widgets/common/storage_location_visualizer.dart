import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:itms_mobile/core/utils/util.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';

// 安全的类型转换工具函数
class SafeTypeConverter {
  static Offset? safeOffset(dynamic data) {
    if (data is Offset) return data;
    return null;
  }
  
  static String? safeString(dynamic data) {
    if (data is String) return data;
    return null;
  }
  
  // 安全地获取点位数据
  static Map<String, dynamic>? safePointData(Map<String, dynamic> point) {
    try {
      final offset = safeOffset(point['offset']);
      final id = safeString(point['id']);
      if (offset != null && id != null) {
        return <String, dynamic>{
          'offset': offset,
          'id': id,
          'status': point['status'],
          'xplace': point['xplace'],
          'yplace': point['yplace'],
          'shelfId': point['shelfId'],
          'storageShelfDTO': point['storageShelfDTO'],
        };
      }
    } catch (e) {
      // 忽略类型转换错误
    }
    return null;
  }
}

class StorageLocationVisualizer extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final void Function(Map<String, dynamic>)? onTapPoint;
  final double? canvasWidth;
  final double? canvasHeight;
  final String? startLocationId;
  final String? endLocationId;
  final bool preserveCoordinateAccuracy; // 是否保持坐标精度
  final double? coordinatePrecision; // 自定义坐标精度
  final double? canvasScaleFactor; // 画布缩放因子
  final double? pointSpacingMultiplier; // 点位间距倍数
  final double? initialCellPixelSize; // 初始时单个库位在屏幕上的期望像素尺寸

  const StorageLocationVisualizer({
    Key? key,
    required this.data,
    this.onTapPoint,
    this.canvasWidth,
    this.canvasHeight,
    this.startLocationId,
    this.endLocationId,
    this.preserveCoordinateAccuracy = true, // 默认保持坐标精度
    this.coordinatePrecision,
    this.canvasScaleFactor, // 画布缩放因子
    this.pointSpacingMultiplier, // 点位间距倍数
    this.initialCellPixelSize,
  }) : super(key: key);

  @override
  State<StorageLocationVisualizer> createState() =>
      _StorageLocationVisualizerState();
}

class _StorageLocationVisualizerState extends State<StorageLocationVisualizer> {
  List<Map<String, dynamic>> _data = [];
  late TransformationController _transformationController;
  double _currentScale = 1.0;
  bool _hasAppliedInitialFit = false; // 是否已应用初始自适应缩放

  // 缓存优化
  List<Map<String, dynamic>> _cachedPointsWithOffset = [];
  bool _needsRecalculation = true;
  Rect _lastViewport = Rect.zero;

  // 性能优化：限制最大渲染点数
  static const int _maxRenderPoints = 20000;

  // 自适应布局参数
  static const double _minPointSpacing = 28.0; // 最小点位间距（确保不重叠）
  static const double _pointSize = 24.0; // 点位大小
  static const double _pointPadding = 4.0; // 点位内部填充边距
  static const double _padding = 20.0; // 画布边距（减少边距）
  
  // 坐标精度控制参数
  static const double _minCoordinateRange = 0.01; // 最小坐标范围阈值
  static const double _coordinatePrecision = 0.001; // 坐标精度
  static const double _maxOverlapAdjustment = 5.0; // 最大重叠调整距离
  
  // 画布缩放和间距控制参数
  static const double _defaultCanvasScaleFactor = 2.0; // 默认画布缩放因子
  static const double _defaultPointSpacingMultiplier = 1.5; // 默认点位间距倍数
  static const double _minCanvasScaleFactor = 1.0; // 最小画布缩放因子
  static const double _maxCanvasScaleFactor = 5.0; // 最大画布缩放因子

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

    // 对普通点位进行智能采样
    List<Map<String, dynamic>> sampledNormalPoints = [];
    if (normalPoints.length <= remainingPoints) {
      sampledNormalPoints = normalPoints;
    } else {
      // 使用空间分布采样，保持数据的空间代表性
      sampledNormalPoints = _spatialSampling(normalPoints, remainingPoints);
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

  // 空间分布采样：保持数据的空间代表性
  List<Map<String, dynamic>> _spatialSampling(
      List<Map<String, dynamic>> points, int targetCount) {
    if (points.length <= targetCount) return points;

    // 按坐标分组，确保不同区域都有代表
    final Map<String, List<Map<String, dynamic>>> spatialGroups = {};
    
    for (var point in points) {
      final x = num.tryParse(point['xplace']?.toString() ?? '0') ?? 0.0;
      final y = num.tryParse(point['yplace']?.toString() ?? '0') ?? 0.0;
      
      // 创建空间网格键
      final gridX = (x / 10).floor(); // 每10个单位一个网格
      final gridY = (y / 10).floor();
      final key = '${gridX}_$gridY';
      
      spatialGroups.putIfAbsent(key, () => []).add(point);
    }

    // 从每个空间组中采样
    List<Map<String, dynamic>> sampledPoints = [];
    final pointsPerGroup = (targetCount / spatialGroups.length).ceil();
    
    for (var group in spatialGroups.values) {
      if (sampledPoints.length >= targetCount) break;
      
      if (group.length <= pointsPerGroup) {
        sampledPoints.addAll(group);
      } else {
        // 均匀采样该组
        final step = group.length / pointsPerGroup;
        for (int i = 0; i < pointsPerGroup && sampledPoints.length < targetCount; i++) {
          final index = (i * step).floor();
          if (index < group.length) {
            sampledPoints.add(group[index]);
          }
        }
      }
    }

    // 如果采样点数不够，补充剩余的点
    if (sampledPoints.length < targetCount) {
      final remaining = targetCount - sampledPoints.length;
      final usedIds = sampledPoints
          .map<String?>((p) => SafeTypeConverter.safeString(p['id']))
          .where((id) => id != null)
          .cast<String>()
          .toSet();
      final availablePoints = points.where((p) => !usedIds.contains(p['id'])).toList();
      
      final step = availablePoints.length / remaining;
      for (int i = 0; i < remaining && i < availablePoints.length; i++) {
        final index = (i * step).floor();
        if (index < availablePoints.length) {
          sampledPoints.add(availablePoints[index]);
        }
      }
    }

    return sampledPoints.take(targetCount).toList();
  }

  // 自适应布局算法：根据坐标密度智能调整点位分布
  void _adaptiveLayout(List<Map<String, dynamic>> points, Size canvasSize) {
    if (points.length <= 1) {
      AppLogger.debug('点位数量不足，跳过布局计算');
      return;
    }

    // 过滤有效的数据点
    final validPoints = points
        .where((point) =>
            point['xplace'] != null &&
            point['yplace'] != null &&
            point['id'] != null)
        .toList();

    if (validPoints.isEmpty) {
      AppLogger.error('没有有效的库位数据点进行布局');
      return;
    }
    
    AppLogger.debug('开始布局计算，有效点数: ${validPoints.length}');

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

    // 处理坐标范围相同的情况 - 改进算法保持原始坐标精度
    double xRange = (maxX - minX).toDouble();
    double yRange = (maxY - minY).toDouble();

    // 改进的坐标范围处理：保持原始坐标的相对精度
    final precision = widget.coordinatePrecision ?? _coordinatePrecision;
    if (xRange < _minCoordinateRange) {
      // 如果X坐标范围太小，基于点数计算合理的范围
      xRange = max(_minCoordinateRange, validPoints.length * precision);
    }
    if (yRange < _minCoordinateRange) {
      // 如果Y坐标范围太小，基于点数计算合理的范围
      yRange = max(_minCoordinateRange, validPoints.length * precision);
    }

    // 确保点位在画布上有足够的分布
    if (validPoints.length == 1) {
      // 单个点位居中显示
      final point = validPoints.first;
      point['offset'] = Offset(canvasSize.width / 2, canvasSize.height / 2);
      return;
    }

    // 检查数据密度，决定布局策略 - 优先保持原始坐标
    final dataDensity = validPoints.length / (xRange * yRange);
    final isHighDensity = dataDensity > 50; // 提高高密度数据阈值，更多情况使用原始坐标

    if (isHighDensity && validPoints.length > 1000) {
      // 只有在数据量非常大且密度极高时才使用网格布局
      _layoutGridBased(validPoints, canvasSize);
    } else {
      // 优先使用原始坐标映射，保持坐标还原度
      _layoutCoordinateBased(validPoints, canvasSize, minX.toDouble(), maxX.toDouble(), minY.toDouble(), maxY.toDouble(), xRange, yRange);
    }

    // 根据设置决定是否处理重叠点位
    if (widget.preserveCoordinateAccuracy) {
      // 保持坐标精度模式：只处理严重重叠，减少位置调整
      _resolveOverlapsMinimal(validPoints, canvasSize);
    } else {
      // 标准模式：完整处理重叠
      _resolveOverlaps(validPoints, canvasSize);
    }
  }

  // 基于坐标的布局方法 - 改进算法保持更高精度并支持画布缩放
  void _layoutCoordinateBased(List<Map<String, dynamic>> validPoints, Size canvasSize,
      double minX, double maxX, double minY, double maxY, double xRange, double yRange) {
    
    try {
      // 获取缩放参数
      final canvasScaleFactor = widget.canvasScaleFactor ?? _defaultCanvasScaleFactor;
      final pointSpacingMultiplier = widget.pointSpacingMultiplier ?? _defaultPointSpacingMultiplier;
      
      // 应用画布缩放因子
      final scaledCanvasWidth = canvasSize.width * canvasScaleFactor;
      final scaledCanvasHeight = canvasSize.height * canvasScaleFactor;
      
      // 计算可用画布区域（使用缩放后的尺寸）
      final usableWidth = scaledCanvasWidth - _padding * 2;
      final usableHeight = scaledCanvasHeight - _padding * 2;
      
      AppLogger.debug('坐标布局参数: canvasSize=$canvasSize, xRange=$xRange, yRange=$yRange');

    // 检查是否有大量相同Y坐标的点
    final yValues = validPoints
        .map((p) => num.tryParse(p['yplace'].toString()) ?? 0.0)
        .toSet();
    if (yValues.length == 1 && validPoints.length > 3) {
      // 相同Y坐标的点，使用水平滑动布局
      _layoutHorizontalScroll(validPoints, Size(scaledCanvasWidth, scaledCanvasHeight), usableWidth, usableHeight);
      return;
    }

    // 改进的坐标映射算法：保持原始坐标的相对精度并应用间距控制
    for (int i = 0; i < validPoints.length; i++) {
      final point = validPoints[i];
      final x = num.tryParse(point['xplace'].toString()) ?? 0.0;
      final y = num.tryParse(point['yplace'].toString()) ?? 0.0;

      // 使用高精度映射，保持原始坐标的相对关系
      double canvasX = ((x - minX) / xRange) * usableWidth + _padding;
      double canvasY = scaledCanvasHeight - _padding - (((y - minY) / yRange) * usableHeight);

      // 保存原始坐标信息，用于后续精度恢复
      point['originalOffset'] = Offset(canvasX, canvasY);
      point['offset'] = Offset(canvasX, canvasY);
      point['canvasScaleFactor'] = canvasScaleFactor; // 记录画布缩放因子
      point['pointSpacingMultiplier'] = pointSpacingMultiplier; // 记录间距倍数
    }
    
    AppLogger.debug('坐标布局完成，处理了${validPoints.length}个点');
    } catch (e, stackTrace) {
      AppLogger.error('坐标布局计算失败', e, stackTrace);
      // 使用简单的网格布局作为后备方案
      _layoutGridBased(validPoints, canvasSize);
    }
  }

  // 基于网格的布局方法（用于高密度数据）
  void _layoutGridBased(List<Map<String, dynamic>> validPoints, Size canvasSize) {
    final pointCount = validPoints.length;
    
    // 获取缩放参数
    final canvasScaleFactor = widget.canvasScaleFactor ?? _defaultCanvasScaleFactor;
    final pointSpacingMultiplier = widget.pointSpacingMultiplier ?? _defaultPointSpacingMultiplier;
    
    // 应用画布缩放因子
    final scaledCanvasWidth = canvasSize.width * canvasScaleFactor;
    final scaledCanvasHeight = canvasSize.height * canvasScaleFactor;
    
    // 计算网格参数 - 优化大数据量处理
    final aspectRatio = scaledCanvasWidth / scaledCanvasHeight;
    final cols = (sqrt(pointCount * aspectRatio)).ceil();
    
    // 使用固定间距，确保性能，并应用间距倍数
    final actualCellWidth = _minPointSpacing * pointSpacingMultiplier;
    final actualCellHeight = _minPointSpacing * pointSpacingMultiplier;
    
    // 按原始坐标排序，保持相对位置
    validPoints.sort((a, b) {
      final xA = num.tryParse(a['xplace'].toString()) ?? 0.0;
      final yA = num.tryParse(a['yplace'].toString()) ?? 0.0;
      final xB = num.tryParse(b['xplace'].toString()) ?? 0.0;
      final yB = num.tryParse(b['yplace'].toString()) ?? 0.0;
      
      if ((yA - yB).abs() < 0.1) {
        return xA.compareTo(xB); // Y坐标相近时按X坐标排序
      }
      return yA.compareTo(yB); // 否则按Y坐标排序
    });
    
    // 分配网格位置 - 允许超出原始画布大小
    for (int i = 0; i < validPoints.length; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      
      final x = _padding + col * actualCellWidth + actualCellWidth / 2;
      final y = _padding + row * actualCellHeight + actualCellHeight / 2;
      
      validPoints[i]['offset'] = Offset(x, y);
      validPoints[i]['canvasScaleFactor'] = canvasScaleFactor; // 记录画布缩放因子
      validPoints[i]['pointSpacingMultiplier'] = pointSpacingMultiplier; // 记录间距倍数
    }
  }

  // 计算画布宽度，完全自适应，无边界限制
  double _calculateCanvasWidth(
      double baseWidth, List<Map<String, dynamic>> points) {
    if (points.isEmpty) return baseWidth;

    // 计算所有有效点位的边界
    final validPoints = points.where((p) => p['offset'] != null).toList();
    if (validPoints.isEmpty) return baseWidth;

    double minX = double.infinity;
    double maxX = double.negativeInfinity;

    for (var point in validPoints) {
      final offset = point['offset'] as Offset;
      minX = minX < offset.dx ? minX : offset.dx;
      maxX = maxX > offset.dx ? maxX : offset.dx;
    }

    // 计算实际需要的宽度，完全自适应
    final requiredWidth = (maxX - minX) + _padding * 2 + _pointSize;
    
    // 返回实际需要的宽度，完全无限制
    return requiredWidth;
  }

  // 计算画布高度，完全自适应，无边界限制
  double _calculateCanvasHeight(
      double baseHeight, List<Map<String, dynamic>> points) {
    if (points.isEmpty) return baseHeight;

    // 计算所有有效点位的边界
    final validPoints = points.where((p) => p['offset'] != null).toList();
    if (validPoints.isEmpty) return baseHeight;

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var point in validPoints) {
      final offset = point['offset'] as Offset;
      minY = minY < offset.dy ? minY : offset.dy;
      maxY = maxY > offset.dy ? maxY : offset.dy;
    }

    // 计算实际需要的高度，完全自适应
    final requiredHeight = (maxY - minY) + _padding * 2 + _pointSize;
    
    // 返回实际需要的高度，完全无限制
    return requiredHeight;
  }

  // 水平滑动布局：处理相同Y坐标的点
  void _layoutHorizontalScroll(List<Map<String, dynamic>> points,
      Size canvasSize, double usableWidth, double usableHeight) {
    // 获取缩放参数
    final canvasScaleFactor = widget.canvasScaleFactor ?? _defaultCanvasScaleFactor;
    final pointSpacingMultiplier = widget.pointSpacingMultiplier ?? _defaultPointSpacingMultiplier;
    
    // 按X坐标排序
    points.sort((a, b) {
      final xA = num.tryParse(a['xplace'].toString()) ?? 0.0;
      final xB = num.tryParse(b['xplace'].toString()) ?? 0.0;
      return xA.compareTo(xB);
    });

    // 垂直居中位置
    final centerY = canvasSize.height / 2;

    // 从左侧开始布局，允许水平滑动，应用间距倍数
    const startX = _padding;
    final actualSpacing = _minPointSpacing * pointSpacingMultiplier;

    for (int i = 0; i < points.length; i++) {
      final x = startX + i * actualSpacing + actualSpacing / 2;
      points[i]['offset'] = Offset(x, centerY);
      points[i]['canvasScaleFactor'] = canvasScaleFactor; // 记录画布缩放因子
      points[i]['pointSpacingMultiplier'] = pointSpacingMultiplier; // 记录间距倍数
    }
  }

  // 解决点位重叠问题 - 改进算法减少对原始坐标的干扰
  void _resolveOverlaps(List<Map<String, dynamic>> points, Size canvasSize) {
    const int maxIterations = 50; // 减少迭代次数，避免过度调整
    const double repulsionForce = 1.0; // 降低排斥力，减少位置偏移
    const double dampingFactor = 0.8; // 增加阻尼，更快收敛

    // 获取间距倍数
    final pointSpacingMultiplier = widget.pointSpacingMultiplier ?? _defaultPointSpacingMultiplier;
    final actualMinSpacing = _minPointSpacing * pointSpacingMultiplier;

    // 为每个点位添加速度向量
    final velocities = List<Offset>.filled(points.length, Offset.zero);

    for (int iteration = 0; iteration < maxIterations; iteration++) {
      bool hasMovement = false;
      double maxMovement = 0.0;

      for (int i = 0; i < points.length; i++) {
        Offset currentPos = points[i]['offset'] as Offset;
        Offset totalForce = Offset.zero;

        // 计算与其他点位的排斥力
        for (int j = 0; j < points.length; j++) {
          if (i == j) continue;

          Offset otherPos = points[j]['offset'] as Offset;
          double distance = (currentPos - otherPos).distance;

          // 如果点位重叠或距离太近
          if (distance < actualMinSpacing) {
            if (distance == 0) {
              // 完全重叠时，使用黄金角分布，但距离更小
              final angle = (i * 137.5) * pi / 180;
              final force = actualMinSpacing * 1.5; // 减少分离距离
              totalForce += Offset(
                cos(angle) * force,
                sin(angle) * force,
              );
            } else {
              // 计算排斥力（使用线性反比，更温和）
              Offset direction = (currentPos - otherPos) / distance;
              double force = (actualMinSpacing - distance) * repulsionForce;
              totalForce += direction * force;
            }
          }
        }

        // 更新速度（考虑阻尼）
        velocities[i] = (velocities[i] + totalForce) * dampingFactor;

        // 限制最大速度，减少位置偏移
        final maxVelocity = actualMinSpacing * 0.3; // 降低最大速度
        if (velocities[i].distance > maxVelocity) {
          velocities[i] = velocities[i] / velocities[i].distance * maxVelocity;
        }

        // 更新位置 - 限制最大调整距离
        if (velocities[i] != Offset.zero) {
          Offset newPos = currentPos + velocities[i];
          
          // 限制最大调整距离，保持原始坐标精度
          final movement = (newPos - currentPos).distance;
          if (movement > _maxOverlapAdjustment) {
            newPos = currentPos + (velocities[i] / velocities[i].distance) * _maxOverlapAdjustment;
          }

          if (movement > 0.1) {
            points[i]['offset'] = newPos;
            hasMovement = true;
            maxMovement = max(maxMovement, movement);
          }
        }
      }

      // 如果最大移动距离很小，认为已经收敛
      if (!hasMovement || maxMovement < 0.1) break;
    }

    // 最终检查：如果仍有重叠，使用温和的强制分离
    _forceSeparation(points, canvasSize);
  }

  // 移除边界排斥力计算（不再需要）
  // 现在点位可以自由扩展到画布边界之外

  // 强制分离重叠的点位 - 改进算法减少对原始坐标的干扰
  void _forceSeparation(List<Map<String, dynamic>> points, Size canvasSize) {
    const int maxAttempts = 10; // 减少尝试次数
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      bool hasOverlap = false;
      
      for (int i = 0; i < points.length; i++) {
        for (int j = i + 1; j < points.length; j++) {
          Offset pos1 = points[i]['offset'] as Offset;
          Offset pos2 = points[j]['offset'] as Offset;
          double distance = (pos1 - pos2).distance;
          
          if (distance < _minPointSpacing) {
            hasOverlap = true;
            
            // 计算分离方向
            Offset direction;
            if (distance == 0) {
              // 完全重叠，使用黄金角分布
              final angle = (i + j) * 137.5 * pi / 180;
              direction = Offset(cos(angle), sin(angle));
            } else {
              direction = (pos1 - pos2) / distance;
            }
            
            // 温和的分离距离，减少对原始坐标的干扰
            final separationDistance = _minPointSpacing - distance + 2.0; // 减少额外分离距离
            final moveDistance = min(separationDistance / 2, _maxOverlapAdjustment / 2); // 限制移动距离
            
            // 移动两个点位，限制最大调整距离
            Offset newPos1 = pos1 + direction * moveDistance;
            Offset newPos2 = pos2 - direction * moveDistance;
            
            points[i]['offset'] = newPos1;
            points[j]['offset'] = newPos2;
          }
        }
      }
      
      if (!hasOverlap) break;
    }
  }

  // 最小化重叠处理 - 保持坐标精度模式
  void _resolveOverlapsMinimal(List<Map<String, dynamic>> points, Size canvasSize) {
    const int maxIterations = 20; // 更少的迭代次数
    const double repulsionForce = 0.5; // 更低的排斥力
    const double dampingFactor = 0.7; // 更高的阻尼

    // 为每个点位添加速度向量
    final velocities = List<Offset>.filled(points.length, Offset.zero);

    for (int iteration = 0; iteration < maxIterations; iteration++) {
      bool hasMovement = false;
      double maxMovement = 0.0;

      for (int i = 0; i < points.length; i++) {
        Offset currentPos = points[i]['offset'] as Offset;
        Offset totalForce = Offset.zero;

        // 只处理严重重叠的情况
        for (int j = 0; j < points.length; j++) {
          if (i == j) continue;

          Offset otherPos = points[j]['offset'] as Offset;
          double distance = (currentPos - otherPos).distance;

          // 只处理严重重叠（距离小于最小间距的一半）
          if (distance < _minPointSpacing * 0.5) {
            if (distance == 0) {
              // 完全重叠时，使用黄金角分布，但距离很小
              final angle = (i * 137.5) * pi / 180;
              final force = _minPointSpacing * 0.8; // 更小的分离距离
              totalForce += Offset(
                cos(angle) * force,
                sin(angle) * force,
              );
            } else {
              // 计算温和的排斥力
              Offset direction = (currentPos - otherPos) / distance;
              double force = (_minPointSpacing * 0.5 - distance) * repulsionForce;
              totalForce += direction * force;
            }
          }
        }

        // 更新速度（考虑阻尼）
        velocities[i] = (velocities[i] + totalForce) * dampingFactor;

        // 限制最大速度，保持坐标精度
        const maxVelocity = _minPointSpacing * 0.1; // 很小的最大速度
        if (velocities[i].distance > maxVelocity) {
          velocities[i] = velocities[i] / velocities[i].distance * maxVelocity;
        }

        // 更新位置 - 严格限制调整距离
        if (velocities[i] != Offset.zero) {
          Offset newPos = currentPos + velocities[i];
          
          // 严格限制最大调整距离
          final movement = (newPos - currentPos).distance;
          if (movement > _maxOverlapAdjustment * 0.3) { // 更严格的限制
            newPos = currentPos + (velocities[i] / velocities[i].distance) * (_maxOverlapAdjustment * 0.3);
          }

          if (movement > 0.05) { // 更小的移动阈值
            points[i]['offset'] = newPos;
            hasMovement = true;
            maxMovement = max(maxMovement, movement);
          }
        }
      }

      // 如果最大移动距离很小，认为已经收敛
      if (!hasMovement || maxMovement < 0.05) break;
    }

    // 最终检查：只处理完全重叠的情况
    _forceSeparationMinimal(points, canvasSize);
  }

  // 最小化强制分离 - 只处理完全重叠
  void _forceSeparationMinimal(List<Map<String, dynamic>> points, Size canvasSize) {
    const int maxAttempts = 5; // 更少的尝试次数
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      bool hasOverlap = false;
      
      for (int i = 0; i < points.length; i++) {
        for (int j = i + 1; j < points.length; j++) {
          Offset pos1 = points[i]['offset'] as Offset;
          Offset pos2 = points[j]['offset'] as Offset;
          double distance = (pos1 - pos2).distance;
          
          // 只处理完全重叠或严重重叠
          if (distance < _minPointSpacing * 0.3) {
            hasOverlap = true;
            
            // 计算分离方向
            Offset direction;
            if (distance == 0) {
              // 完全重叠，使用黄金角分布
              final angle = (i + j) * 137.5 * pi / 180;
              direction = Offset(cos(angle), sin(angle));
            } else {
              direction = (pos1 - pos2) / distance;
            }
            
            // 最小的分离距离
            final separationDistance = _minPointSpacing * 0.3 - distance + 1.0;
            final moveDistance = min(separationDistance / 2, _maxOverlapAdjustment * 0.2);
            
            // 移动两个点位
            Offset newPos1 = pos1 + direction * moveDistance;
            Offset newPos2 = pos2 - direction * moveDistance;
            
            points[i]['offset'] = newPos1;
            points[j]['offset'] = newPos2;
          }
        }
      }
      
      if (!hasOverlap) break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data.isEmpty) {
      AppLogger.warning('StorageLocationVisualizer: 数据为空');
      return const Center(child: Text('暂无数据'));
    }

    // 在Web release模式下，使用简化的渲染逻辑避免类型错误
    // 暂时注释掉，让我们修复根本问题
    // if (kIsWeb && kReleaseMode) {
    //   return _buildSimplifiedVisualizer();
    // }

    try {
      // 数据处理：智能采样
      List<Map<String, dynamic>> processedData = _data;
      if (_data.length > _maxRenderPoints) {
        AppLogger.info('数据量过大(${_data.length})，进行智能采样到$_maxRenderPoints个点');
        final sampledData = _sampleData(_data, _maxRenderPoints);
        processedData = List<Map<String, dynamic>>.from(sampledData);
      }

      // 数据统计
      final validDataCount = processedData
          .where((point) =>
              point['xplace'] != null &&
              point['yplace'] != null &&
              point['id'] != null)
          .length;
      
      AppLogger.debug('有效数据点数量: $validDataCount / ${processedData.length}');
      
      if (validDataCount == 0) {
        AppLogger.error('没有有效的库位数据点');
        return const Center(child: Text('数据格式错误，无法显示库位'));
      }
    
      // 获取缩放和间距信息
      final canvasScaleFactor = widget.canvasScaleFactor ?? _defaultCanvasScaleFactor;
      final pointSpacingMultiplier = widget.pointSpacingMultiplier ?? _defaultPointSpacingMultiplier;

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

            // 计算画布尺寸
            final double effectiveCanvasWidth = _calculateCanvasWidth(
                canvasWidth.toDouble(), pointsWithOffset);
            final double effectiveCanvasHeight = _calculateCanvasHeight(
                canvasHeight.toDouble(), pointsWithOffset);

            // 初始自适应缩放与居中，仅执行一次
            // if (!_hasAppliedInitialFit &&
            //     effectiveCanvasWidth > 0 &&
            //     effectiveCanvasHeight > 0 &&
            //     constraints.maxWidth.isFinite &&
            //     constraints.maxHeight.isFinite &&
            //     constraints.maxWidth > 0 &&
            //     constraints.maxHeight > 0) {
            //   final double scaleX = constraints.maxWidth / effectiveCanvasWidth;
            //   final double scaleY = constraints.maxHeight / effectiveCanvasHeight;
            //   final double fitScale = (scaleX < scaleY ? scaleX : scaleY) * 0.95;

            //   // 如果提供了初始单元像素大小，则优先按单元大小计算目标缩放
            //   double targetScale = fitScale;
            //   final double pointSpacingMultiplier = widget.pointSpacingMultiplier ?? _defaultPointSpacingMultiplier;
            //   final double actualMinSpacing = _minPointSpacing * pointSpacingMultiplier; // 画布坐标系下单元大小
            //   if (widget.initialCellPixelSize != null && actualMinSpacing > 0) {
            //     final double desired = widget.initialCellPixelSize!;
            //     final double scaleByCell = desired / actualMinSpacing;
            //     // 取两者中的较大者，确保单元足够大易读
            //     targetScale = scaleByCell > fitScale ? scaleByCell : fitScale;
            //   }
            //   final double tx = (constraints.maxWidth - effectiveCanvasWidth * fitScale) / 2.0;
            //   final double ty = (constraints.maxHeight - effectiveCanvasHeight * fitScale) / 2.0;
            //   final Matrix4 initialMatrix = Matrix4.identity()
            //     ..translate(tx, ty)
            //     ..scale(targetScale);
            //   _transformationController.value = initialMatrix;
            //   _hasAppliedInitialFit = true;
            // }

            return InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.05,
              maxScale: 20.0,
              constrained: false,
              panEnabled: true,
              scaleEnabled: true,
              boundaryMargin: const EdgeInsets.all(0),
              child: GestureDetector(
                behavior: kIsWeb
                    ? HitTestBehavior.translucent
                    : HitTestBehavior.opaque,
                onTapUp: (details) {
                  final localPos = details.localPosition;
                  for (var point in pointsWithOffset) {
                    final safePoint = SafeTypeConverter.safePointData(point);
                    if (safePoint == null) continue;
                    
                    final Offset offset = safePoint['offset'] as Offset;
                    // 使用完整点位大小进行点击检测
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
                    effectiveCanvasWidth,
                    effectiveCanvasHeight,
                  ),
                  painter: _StorageLocationPainter(
                    points: pointsWithOffset,
                    scale: _currentScale,
                    startLocationId: widget.startLocationId,
                    endLocationId: widget.endLocationId,
                    pointSize: _pointSize,
                    pointPadding: _pointPadding,
                  ),
                ),
              ),
            );
          } catch (e, stackTrace) {
            AppLogger.error('StorageLocationVisualizer渲染错误', e, stackTrace);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('渲染错误: $e'),
                  if (kReleaseMode) ...[
                    const SizedBox(height: 8),
                    const Text('请检查数据格式是否正确', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('StorageLocationVisualizer渲染错误', e, stackTrace);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('渲染错误: $e'),
            if (kReleaseMode) ...[
              const SizedBox(height: 8),
              const Text('请检查数据格式是否正确', style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
      );
    }
  }
}

class _StorageLocationPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;
  final double scale;
  final String? startLocationId;
  final String? endLocationId;
  final double pointSize;
  final double pointPadding;

  // 缓存预计算的渲染数据
  final Map<Color, List<Rect>> _cachedRects = {};
  final Map<Color, Paint> _cachedPaints = {};

  _StorageLocationPainter({
    required this.points,
    required this.scale,
    this.startLocationId,
    this.endLocationId,
    required this.pointSize,
    required this.pointPadding,
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
              // 绘制外边框（完整大小）
              final outerRect = Rect.fromLTRB(
                rect.left - pointPadding,
                rect.top - pointPadding,
                rect.right + pointPadding,
                rect.bottom + pointPadding,
              );
              
              // 绘制外边框
              final borderPaint = Paint()
                ..color = color.withOpacity(0)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.0;
              canvas.drawRRect(
                RRect.fromRectAndRadius(outerRect, Radius.circular(2.0)),
                borderPaint,
              );
              
              // 绘制填充区域（带内边距）
              canvas.drawRRect(
                RRect.fromRectAndRadius(rect, Radius.circular(1.0)),
                paint,
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
      // 使用安全的类型转换
      final safePoint = SafeTypeConverter.safePointData(point);
      if (safePoint == null) continue;
      
      final Offset offset = safePoint['offset'] as Offset;
      final String pointId = safePoint['id'] as String;
      final int statusCode =
          int.tryParse(safePoint['status']?.toString() ?? '0') ?? 0;

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

      // 缓存矩形 - 添加内边距
      final rect = Rect.fromCenter(
        center: offset,
        width: pointSize,
        height: pointSize,
      );
      
      // 应用内边距
      final paddedRect = Rect.fromLTRB(
        rect.left + pointPadding,
        rect.top + pointPadding,
        rect.right - pointPadding,
        rect.bottom - pointPadding,
      );
      
      _cachedRects.putIfAbsent(color, () => []).add(paddedRect);
    }
  }

  // 绘制起始点和终点的特殊标记
  void _drawStartEndMarkers(Canvas canvas, Size size) {
    const double labelOffset = 15;
    const double fontSize = 10;

    for (var point in points) {
      // 使用安全的类型转换
      final safePoint = SafeTypeConverter.safePointData(point);
      if (safePoint == null) continue;
      
      final Offset offset = safePoint['offset'] as Offset;
      final String pointId = safePoint['id'] as String;

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


  // 绘制托盘编号标记
  void _drawShelfMarkers(Canvas canvas, Size size) {
    for (var point in points) {
      // 使用安全的类型转换
      final safePoint = SafeTypeConverter.safePointData(point);
      if (safePoint == null) continue;
      
      final Offset offset = safePoint['offset'] as Offset;

      String? shelfId;
      if (safePoint['shelfId'] != null) {
        shelfId = SafeTypeConverter.safeString(safePoint['shelfId']);
      } else {
        final Map<String, dynamic>? storageShelfDTO =
            safePoint['storageShelfDTO'] as Map<String, dynamic>?;
        if (storageShelfDTO != null && storageShelfDTO['shelfId'] != null) {
          shelfId = SafeTypeConverter.safeString(storageShelfDTO['shelfId']);
        }
      }

      if (shelfId != null && shelfId.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: shelfId,
            style: const TextStyle(
              fontSize: 4,
              color: Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.w700,
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
        oldDelegate.pointSize != pointSize ||
        oldDelegate.pointPadding != pointPadding;
  }
}

