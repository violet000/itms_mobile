import 'package:flutter/material.dart';
import 'package:flutter/material.dart' show NoSplash;
import 'package:flutter_svg/flutter_svg.dart';
import '../storage/map_control.dart';
import 'dart:ui';

// 菜单项接口定义
class MenuItem {
  final String name;
  final int index;
  final String? imagePath;
  final String? iconPath;
  final String? unselectedIcon;
  final String? selectedIcon;
  final IconData? icon;
  final List<MenuItem>? children;
  final String? route;
  final Color? color;

  MenuItem({
    required this.name,
    required this.index,
    this.imagePath,
    this.iconPath,
    this.unselectedIcon,
    this.selectedIcon,
    this.icon,
    this.children,
    this.route,
    this.color,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<MenuItem> menus = [
    MenuItem(
      name: '仓储',
      index: 0,
      unselectedIcon: 'assets/storage/storage_unselected.svg',
      selectedIcon: 'assets/storage/storage_selected.svg',
      color: const Color.fromARGB(255, 255, 255, 255),
      children: [
        MenuItem(
          name: '仓储一区',
          index: 0,
          imagePath: 'assets/storage/storage_1.svg',
          iconPath: 'assets/images/storage_1.svg',
          route: '/outlets/box-scan',
          color: const Color(0xFF0DBC95),
        ),
        MenuItem(
          name: '仓储二区',
          index: 1,
          imagePath: 'assets/storage/storage_2.svg',
          iconPath: 'assets/images/storage_2.svg',
          route: '/outlets/box-handover',
          color: const Color(0xFFAE673A),
        ),
        MenuItem(
          name: '仓储三区',
          index: 2,
          imagePath: 'assets/storage/storage_3.svg',
          iconPath: 'assets/images/storage_3.svg',
          route: '/outlets/box-handover',
          color: const Color(0xFF16A8FA),
        )
      ],
    ),
    MenuItem(
      name: '库内作业',
      index: 1,
      unselectedIcon: 'assets/storage/inner_unselected.svg',
      selectedIcon: 'assets/storage/inner_selected.svg',
      route: '/inner_work',
      children: [
        MenuItem(
          name: '点到点搬运',
          index: 0,
          imagePath: 'assets/icons/handover_circle.svg',
          iconPath: 'assets/icons/net_handover_icon.svg',
          route: '/inner_work/inbound',
          color: const Color.fromARGB(255, 115, 190, 240).withOpacity(0.1),
        ),
        MenuItem(
          name: '搬运任务管理',
          index: 1,
          imagePath: 'assets/icons/treasury_reat.svg',
          iconPath: 'assets/icons/treasury_handover_icon.svg',
          route: '/inner_work/outbound',
          color: const Color.fromARGB(255, 134, 221, 245).withOpacity(0.1),
        )
      ],
      color: const Color(0xFF0489FE),
    ),
    MenuItem(
      name: '厂商模式',
      index: 2,
      icon: Icons.business,
      route: '/vendor_mode',
      color: const Color(0xFF0489FE),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePages();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 初始化页面
  void _initializePages() {
    setState(() {
      for (var menu in menus) {
        if (menu.children != null) {
          _pages.add(_buildSubMenuPage(menu));
        } else if (menu.route != null) {
          // 为有路由的菜单项创建占位页面
          _pages.add(_buildPlaceholderPage(menu));
        } else {
          // 为没有路由的菜单项创建空页面
          _pages.add(_buildEmptyPage(menu));
        }
      }
    });
  }

  // 顶部标题
  Widget _buildHeader(MenuItem menu) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 246, 250),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 221, 218, 218).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            menu.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 3, 3, 3),
            ),
          ),
        ],
      ),
    );
  }

  // 构建子菜单页面
  Widget _buildSubMenuPage(MenuItem menu) {
    return Scaffold(
        body: Container(
            decoration:
                const BoxDecoration(color: Color.fromARGB(255, 245, 246, 250)),
            child: Column(children: [
              _buildHeader(menu),
              Expanded(
                  child: FadeTransition(
                      opacity: _fadeAnimation,
                      // 将仓储菜单和库内作业菜单分开
                      child: menu.name == '仓储'
                          ? Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16.0),
                                    itemCount: menu.children?.length ?? 0,
                                    itemBuilder: (context, index) {
                                      if (index < menu.children!.length) {
                                        final child = menu.children![index];
                                        return SizedBox(
                                          height: 90,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: _buildStorageMenuCard(child),
                                          ),
                                        );
                                      }
                                      return Container();
                                    },
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 12.0),
                                  child: TextButton(
                                    onPressed: () {
                                      // 图例按钮点击事件
                                      _showLegendDialog(context);
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                    ),
                                    child: Text(
                                      "图例",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(8.0),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                              ),
                              itemCount: menu.children?.length ?? 0,
                              itemBuilder: (context, index) {
                                final child = menu.children![index];
                                return _buildInnerWorkMenuCard(child);
                              },
                            )))
            ])));
  }

  // 卡片背景
  Widget _buildCardBackground(MenuItem menu) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: menu.imagePath != null
            ? Container(
                width: double.infinity,
                height: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SvgPicture.asset(
                    menu.imagePath!,
                    fit: BoxFit.fill,
                  ),
                ),
              )
            : Container(
                color: menu.color ?? Colors.grey[200],
                child: const Center(
                  child: Text('无背景'),
                ),
              ),
      ),
    );
  }

  // 卡片图标
  Widget _buildCardIcon(MenuItem menu) {
    return Positioned(
      right: 20,
      top: 0,
      bottom: 0,
      child: Center(
        child: SvgPicture.asset(
          menu.iconPath!,
          width: 50,
          height: 50,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // 箭头图标
  Widget _buildArrowIcon(MenuItem menu) {
    return Positioned(
      top: 12,
      left: 8,
      child: Icon(Icons.play_arrow, size: 16, color: menu.color),
    );
  }

  // 左侧文字内容
  Widget _buildLeftText(MenuItem menu) {
    return Positioned(
      left: 50,
      top: 0,
      bottom: 0,
      child: Center(
        child: Text(
          menu.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: menu.color,
          ),
        ),
      ),
    );
  }

  // 仓储菜单卡片
  Widget _buildStorageMenuCard(MenuItem menu) {
    return Hero(
      tag: menu.name,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            if (menu.route != null) {
              Navigator.pushNamed(context, menu.route!);
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 背景PNG - 覆盖整个容器
                _buildCardBackground(menu),
                // 右侧PNG图标
                if (menu.iconPath != null) _buildCardIcon(menu),
                // 左上角箭头
                _buildArrowIcon(menu),
                // 卡片文字内容
                _buildLeftText(menu),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 库内作业菜单卡片
  Widget _buildInnerWorkMenuCard(MenuItem menu) {
    return Hero(
      tag: menu.name,
      child: Card(
        elevation: 2, // 阴影
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          splashColor: Colors.transparent, // 点击时没有水波纹效果
          highlightColor: Colors.transparent, // 点击时没有高亮效果
          onTap: () {
            if (menu.route != null) {
              Navigator.pushNamed(context, menu.route!);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 90, // 添加高度约束
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: menu.color,
              boxShadow: [
                BoxShadow(
                  color:
                      const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 背景SVG - 放大并定位到右下区域
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter:
                          ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // 模糊效果
                      child: SvgPicture.asset(
                        menu.imagePath!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // 右下角居中图标
                if (menu.iconPath != null)
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: SvgPicture.asset(
                      menu.iconPath!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      color: Colors.white,
                    ),
                  ),
                // 右上角放置一个箭头角标 - 放在最后确保在最上层
                Positioned(
                  top: 12,
                  right: 12,
                  child: SvgPicture.asset(
                    'assets/icons/arrow_right_icon.svg',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
                // 文字内容
                Positioned(
                  top: 12,
                  left: 12,
                  child: Text(
                    menu.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建占位页面（用于有路由的菜单项）
  Widget _buildPlaceholderPage(MenuItem menu) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 245, 246, 250),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                menu.icon ?? Icons.home,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                menu.name,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点击底部导航栏的"${menu.name}"进入对应功能',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建空页面（用于没有路由的菜单项）
  Widget _buildEmptyPage(MenuItem menu) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 245, 246, 250),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                menu.icon ?? Icons.home,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                menu.name,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '暂未开发...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示图例弹窗
  void _showLegendDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '缩略图',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 图例内容 - 这里可以展示外部widget
                Container(
                  width: double.infinity,
                  height: 100,
                  child: const MapControlExample(),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF29A8FF)),
              ),
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 226, 224, 224).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF29A8FF),
              unselectedItemColor: Colors.grey,
              selectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
              elevation: 0,
              enableFeedback: false,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: menus
                  .map((menu) => BottomNavigationBarItem(
                        icon: menu.unselectedIcon != null
                            ? SvgPicture.asset(
                                menu.unselectedIcon!,
                                width: 18,
                                height: 18,
                                color: Colors.grey,
                              )
                            : Icon(menu.icon),
                        activeIcon: menu.selectedIcon != null
                            ? SvgPicture.asset(
                                menu.selectedIcon!,
                                width: 18,
                                height: 18,
                                color: const Color(0xFF29A8FF),
                              )
                            : Icon(menu.icon),
                        label: menu.name,
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
