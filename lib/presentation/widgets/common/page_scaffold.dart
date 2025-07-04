import 'package:flutter/material.dart';
import 'package:flutter/material.dart' show NoSplash;
import 'package:flutter_svg/flutter_svg.dart';

/// 通用页面脚手架组件
/// 提供统一的渐变背景和基础布局结构
class PageScaffold extends StatelessWidget {
  /// 页面标题
  final String? title;
  
  /// 页面主体内容
  final Widget child;
  
  /// 是否显示返回按钮
  final bool showBackButton;
  
  /// 返回按钮点击回调
  final VoidCallback? onBackPressed;

  /// 返回按钮点击回调
  final VoidCallback? onWillPop;
  
  /// 自定义标题组件
  final Widget? titleWidget;
  
  /// 页面底部组件
  final Widget? bottomWidget;
  
  /// 自定义背景装饰
  final BoxDecoration? backgroundDecoration;

  const PageScaffold({
    Key? key,
    this.title,
    required this.child,
    this.showBackButton = false,
    this.onBackPressed,
    this.titleWidget,
    this.bottomWidget,
    this.onWillPop,
    this.backgroundDecoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: backgroundDecoration ?? _getDefaultBackgroundDecoration(),
        child: Column(
          children: [
            // 标题区域
            if (title != null || titleWidget != null)
              _buildHeader(),
            
            // 主体内容
            Expanded(
              child: child,
            ),
            
            // 底部组件
            if (bottomWidget != null)
              bottomWidget!,
          ],
        ),
      ),
    );
  }

  /// 构建标题区域
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed,
              color: const Color.fromARGB(255, 60, 80, 120),
              style: IconButton.styleFrom(
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
              ),
            ),
          if (onWillPop != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onWillPop,
              color: const Color.fromARGB(255, 60, 80, 120),
              style: IconButton.styleFrom(
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
              ),
            ),
          Expanded(
            child: titleWidget ?? Text(
              title ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 60, 80, 120),
              ),
            ),
          ),
          if (showBackButton)
            const SizedBox(width: 48), // 为了保持标题居中
        ],
      ),
    );
  }

  /// 获取默认背景装饰
  BoxDecoration _getDefaultBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color.fromARGB(255, 154, 185, 240).withOpacity(0.8), // 右上角淡蓝色
          Color.fromARGB(255, 255, 255, 255), // 左下角白色
        ],
      ),
    );
  }
}

/// 带标题的页面脚手架
class TitledPageScaffold extends StatelessWidget {
  /// 页面标题
  final String title;
  
  /// 页面主体内容
  final Widget child;
  
  /// 是否显示返回按钮
  final bool showBackButton;
  
  /// 返回按钮点击回调
  final VoidCallback? onBackPressed;

  /// 返回按钮点击回调
  final VoidCallback? onWillPop;
  
  /// 页面底部组件
  final Widget? bottomWidget;
  
  /// 自定义背景装饰
  final BoxDecoration? backgroundDecoration;

  const TitledPageScaffold({
    Key? key,
    required this.title,
    required this.child,
    this.showBackButton = false,
    this.onBackPressed,
    this.bottomWidget,
    this.onWillPop,
    this.backgroundDecoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: title,
      child: child,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
      bottomWidget: bottomWidget,
      onWillPop: onWillPop,
      backgroundDecoration: backgroundDecoration,
    );
  }
}
