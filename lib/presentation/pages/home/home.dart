import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 菜单项接口定义
class MenuItem {
  final String name;
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
      unselectedIcon: 'assets/storage/storage_unselected.svg',
      selectedIcon: 'assets/storage/storage_selected.svg',
      color: const Color.fromARGB(255, 255, 255, 255),
      children: [
        MenuItem(
          name: '仓储一区',
          imagePath: 'assets/storage/storage_1.svg',
          iconPath: 'assets/images/storage_1.svg',
          route: '/outlets/box-scan',
          color: const Color(0xFF0DBC95),
        ),
        MenuItem(
          name: '仓储二区',
          imagePath: 'assets/storage/storage_2.svg',
          iconPath: 'assets/images/storage_2.svg',
          route: '/outlets/box-handover',
          color: const Color(0xFFAE673A),
        ),
        MenuItem(
          name: '仓储三区',
          imagePath: 'assets/storage/storage_3.svg',
          iconPath: 'assets/images/storage_3.svg',
          route: '/outlets/box-handover',
          color: const Color(0xFF16A8FA),
        )
      ],
    ),
    MenuItem(
      name: '库内作业',
      unselectedIcon: 'assets/storage/inner_unselected.svg',
      selectedIcon: 'assets/storage/inner_selected.svg',
      route: '/plugin-test',
      color: const Color(0xFF0489FE),
    ),
    MenuItem(
      name: '厂商模式',
      icon: Icons.business,
      route: '/plugin-test',
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
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: menu.children?.length ?? 0,
                  itemBuilder: (context, index) {
                    final child = menu.children![index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildMenuCard(child),
                    );
                  },
                ),
              ))
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
      left: 15,
      child: Icon(Icons.play_arrow, size: 16, color: menu.color),
    );
  }

  // 左侧文字内容
  Widget _buildLeftText(MenuItem menu) {
    return Positioned(
      left: 80,
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

  // 菜单卡片
  Widget _buildMenuCard(MenuItem menu) {
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
                if (menu.iconPath != null)
                  _buildCardIcon(menu),
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
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF29A8FF),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                              width: 24,
                              height: 24,
                              color: Colors.grey,
                            )
                          : Icon(menu.icon),
                      activeIcon: menu.selectedIcon != null
                          ? SvgPicture.asset(
                              menu.selectedIcon!,
                              width: 24,
                              height: 24,
                              color: const Color(0xFF29A8FF),
                            )
                          : Icon(menu.icon),
                      label: menu.name,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
