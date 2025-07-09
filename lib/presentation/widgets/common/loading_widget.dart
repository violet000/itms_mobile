import 'package:flutter/material.dart';

/// Loading类型枚举
enum LoadingType {
  circular,    // 圆形加载
  linear,      // 线性加载
  dots,        // 点状加载
  custom,      // 自定义加载
}

/// Loading大小枚举
enum LoadingSize {
  small,       // 小尺寸
  medium,      // 中等尺寸
  large,       // 大尺寸
}

/// 公共Loading组件
class LoadingWidget extends StatefulWidget {
  /// Loading类型
  final LoadingType type;
  
  /// Loading大小
  final LoadingSize size;
  
  /// 加载文字
  final String? text;
  
  /// 文字颜色
  final Color? textColor;
  
  /// 加载颜色
  final Color? color;
  
  /// 背景颜色
  final Color? backgroundColor;
  
  /// 是否显示背景遮罩
  final bool showBackground;
  
  /// 背景遮罩颜色
  final Color? barrierColor;
  
  /// 是否可点击背景关闭
  final bool barrierDismissible;
  
  /// 自定义加载组件
  final Widget? customWidget;
  
  /// 加载完成回调
  final VoidCallback? onComplete;

  const LoadingWidget({
    super.key,
    this.type = LoadingType.circular,
    this.size = LoadingSize.medium,
    this.text,
    this.textColor,
    this.color,
    this.backgroundColor,
    this.showBackground = true,
    this.barrierColor,
    this.barrierDismissible = false,
    this.customWidget,
    this.onComplete,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 获取尺寸大小
  double _getSize() {
    switch (widget.size) {
      case LoadingSize.small:
        return 24.0;
      case LoadingSize.medium:
        return 32.0;
      case LoadingSize.large:
        return 48.0;
    }
  }

  /// 构建圆形加载
  Widget _buildCircularLoading() {
    return SizedBox(
      width: _getSize(),
      height: _getSize(),
      child: CircularProgressIndicator(
        strokeWidth: widget.size == LoadingSize.small ? 2.0 : 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.color ?? Colors.blue,
        ),
      ),
    );
  }

  /// 构建线性加载
  Widget _buildLinearLoading() {
    return SizedBox(
      width: _getSize() * 2,
      child: LinearProgressIndicator(
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.color ?? Colors.blue,
        ),
      ),
    );
  }

  /// 构建点状加载
  Widget _buildDotsLoading() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: _animation.value > index * 0.3 && _animation.value < (index + 1) * 0.3
                    ? 1.2
                    : 1.0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.color ?? Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// 构建加载内容
  Widget _buildLoadingContent() {
    Widget loadingWidget;
    
    switch (widget.type) {
      case LoadingType.circular:
        loadingWidget = _buildCircularLoading();
        break;
      case LoadingType.linear:
        loadingWidget = _buildLinearLoading();
        break;
      case LoadingType.dots:
        loadingWidget = _buildDotsLoading();
        break;
      case LoadingType.custom:
        loadingWidget = widget.customWidget ?? _buildCircularLoading();
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        loadingWidget,
        if (widget.text != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.text!,
            style: TextStyle(
              color: widget.textColor ?? const Color.fromARGB(221, 237, 235, 235),
              decoration: TextDecoration.none,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.transparent,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _buildLoadingContent(),
    );

    if (widget.showBackground) {
      return GestureDetector(
        onTap: widget.barrierDismissible ? () => Navigator.of(context).pop() : null,
        child: Container(
          color: widget.barrierColor ?? Colors.black.withOpacity(0.5),
          child: Center(child: content),
        ),
      );
    }

    return Center(child: content);
  }
}

/// Loading工具类
class LoadingUtils {
  static Future<void> showLoading({
    required BuildContext context,
    LoadingType type = LoadingType.circular,
    LoadingSize size = LoadingSize.medium,
    String? text,
    Color? textColor,
    Color? color,
    Color? backgroundColor,
    Color? barrierColor,
    bool barrierDismissible = false,
    Widget? customWidget,
  }) async {
    return await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return LoadingWidget(
          type: type,
          size: size,
          text: text,
          textColor: textColor,
          color: color,
          backgroundColor: backgroundColor,
          barrierColor: barrierColor,
          barrierDismissible: barrierDismissible,
          customWidget: customWidget,
        );
      },
    );
  }

  static void hideLoading(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  static Future<void> showSimpleLoading({
    required BuildContext context,
    String? text,
  }) async {
    return await showLoading(
      context: context,
      type: LoadingType.circular,
      size: LoadingSize.medium,
      text: text ?? '加载中...',
    );
  }

  static Future<void> showFullScreenLoading({
    required BuildContext context,
    String? text,
    Color? color,
  }) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: LoadingWidget(
                type: LoadingType.circular,
                size: LoadingSize.large,
                text: text ?? '加载中...',
                color: color,
                backgroundColor: Colors.transparent,
                showBackground: false,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 可复用的Loading状态管理
class LoadingState extends ChangeNotifier {
  bool _isLoading = false;
  String? _loadingText;

  bool get isLoading => _isLoading;
  String? get loadingText => _loadingText;

  /// 开始加载
  void startLoading([String? text]) {
    _isLoading = true;
    _loadingText = text;
    notifyListeners();
  }

  /// 结束加载
  void stopLoading() {
    _isLoading = false;
    _loadingText = null;
    notifyListeners();
  }

  /// 更新加载文字
  void updateLoadingText(String text) {
    _loadingText = text;
    notifyListeners();
  }
} 