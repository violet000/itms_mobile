import 'package:flutter/material.dart';
import 'package:flutter/material.dart' show NoSplash;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:itms_mobile/presentation/widgets/common/map_control.dart';
import 'package:itms_mobile/presentation/widgets/common/dash_border.dart';
import 'package:itms_mobile/services/storage_service.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/presentation/widgets/common/error_page.dart';
import 'package:itms_mobile/core/utils/storage_utils.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart';

class _LegendData {
  final String name;
  final List<GridCell> cells;
  final Map<String, int> rangeInfo;

  const _LegendData({
    required this.name,
    required this.cells,
    required this.rangeInfo,
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
  List<MenuItem> menus = [];
  bool _isInitialized = false; // 初始化状态

  // 常量定义
  static const double _legendItemHeight = 200.0;
  static const double _legendItemWidth = 190.0;
  static const double _legendItemMargin = 8.0;
  static const double _legendPadding = 10.0;
  static const double _borderStrokeWidth = 2.0;
  static const double _borderDashWidth = 6.0;
  static const double _borderGap = 4.0;
  static const Color _borderColor = Color.fromARGB(255, 221, 221, 221);
  static const Color _textColor = Color.fromARGB(255, 64, 64, 64);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    
    // 延迟初始化，避免阻塞UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAsync();
    });
  }

  // 异步初始化
  Future<void> _initializeAsync() async {
    _initializeBasicUI();

    await _getStorageAreas();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _animationController.forward();
    }
  }

  // 初始化
  void _initializeBasicUI() {
    setState(() {
      menus = [
        MenuItem(
          name: '仓储',
          index: 0,
          unselectedIcon: 'assets/storage/storage_unselected.svg',
          selectedIcon: 'assets/storage/storage_selected.svg',
          color: const Color.fromARGB(255, 255, 255, 255),
          children: [], // 初始为空，后续异步加载
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
              color:
                  const Color.fromARGB(255, 115, 190, 240).withOpacity(0.1),
            ),
            MenuItem(
              name: '搬运任务管理',
              index: 1,
              imagePath: 'assets/icons/treasury_reat.svg',
              iconPath: 'assets/icons/treasury_handover_icon.svg',
              route: '/inner_work/outbound',
              color:
                  const Color.fromARGB(255, 134, 221, 245).withOpacity(0.1),
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
      _initializePages();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializePages() {
    setState(() {
      _pages.clear();
      for (var menu in menus) {
        if (menu.children != null) {
          _pages.add(_buildSubMenuPage(menu));
        } else if (menu.route != null) {
          _pages.add(buildPlaceholderPage(menu));
        } else {
          _pages.add(buildEmptyPage(menu));
        }
      }
    });
  }

  /// 判断svg图片是否存在
  Future<bool> assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 获取仓储库位信息，根据仓储信息动态的生成仓储区域菜单
  Future<void> _getStorageAreas() async {
    try {
      Map<String, dynamic>? response = StorageService.getCachedStorageAreas();
      
      if (response == null) {
        response = await StorageService.instance.getStorageAreas();
      }

      if (response == null || !response.containsKey('retList')) {
        return print('仓储数据错误或为空');
      }

      final retList = response['retList'] as List<dynamic>;
      List<MenuItem> storageChildren = [];

      StorageDataManager().clearAllData();

      for (var item in retList) {
        final map = item as Map<String, dynamic>;
        String imagePath = 'assets/storage/storage_${map['x']}.svg';
        bool exists = await assetExists(imagePath);

        String areaId = map['id'] as String? ?? '';
        String areaName = map['name'] as String? ?? '';

        if (areaId.isEmpty || areaName.isEmpty) {
          print('区域数据不完整: $map');
          continue;
        }

        List<GridCell> areaCells = [];

        final storageLocationDTOS =
            map['storageLocationDTOS'] as List<dynamic>?;
        if (storageLocationDTOS != null) {
          for (var location in storageLocationDTOS) {
            try {
              final x = double.parse(location['xplace'].toString());
              final y = double.parse(location['yplace'].toString());
              final status = location['status'] as int? ?? 0;

              areaCells.add(GridCell(
                x: x,
                y: y,
                id: location['id'].toString(),
                color: status == 1 ? Colors.blue : Colors.grey,
              ));
            } catch (e) {
              print('处理库位数据失败: $location, 错误: $e');
            }
          }
        }

        StorageDataManager().updateAreaData(areaId, areaName, areaCells);

        storageChildren.add(MenuItem(
          name: areaName,
          index: int.tryParse(map['x'].toString()) ?? 0,
          imagePath: exists ? imagePath : null,
          iconPath: 'assets/images/storage_${map['x']}.svg',
          route: '/storage/storage-area',
          params: item,
        ));
      }

      if (mounted) {
        setState(() {
          menus = [
            MenuItem(
              name: '仓储',
              index: 0,
              unselectedIcon: 'assets/storage/storage_unselected.svg',
              selectedIcon: 'assets/storage/storage_selected.svg',
              color: const Color.fromARGB(255, 255, 255, 255),
              children: storageChildren,
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
                  color:
                      const Color.fromARGB(255, 115, 190, 240).withOpacity(0.1),
                ),
                MenuItem(
                  name: '搬运任务管理',
                  index: 1,
                  imagePath: 'assets/icons/treasury_reat.svg',
                  iconPath: 'assets/icons/treasury_handover_icon.svg',
                  route: '/inner_work/outbound',
                  color:
                      const Color.fromARGB(255, 134, 221, 245).withOpacity(0.1),
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
          _initializePages();
        });
      }
    } catch (e) {
      print('获取仓储库位信息失败: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _animationController.forward();
      }
    }
  }

  // 构建子菜单页面
  Widget _buildSubMenuPage(MenuItem menu) {
    return PageScaffold(
      title: menu.name,
      bottomWidget: menu.name == '仓储'
          ? Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: TextButton(
                onPressed: () {
                  _showLegendDialog(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  splashFactory: NoSplash.splashFactory,
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
            )
          : null,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: menu.name == '仓储'
            ? Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: menu.children?.length ?? 0,
                      itemBuilder: (context, index) {
                        if (index < menu.children!.length) {
                          final child = menu.children![index];
                          return SizedBox(
                            height: 90,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildStorageMenuCard(child),
                            ),
                          );
                        }
                        return Container();
                      },
                      padding: const EdgeInsets.all(16.0),
                    ),
                  ),
                ],
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                padding: const EdgeInsets.all(8.0),
              ),
      ),
    );
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
                color: Colors.white,
                child: const Center(
                  child: Text(''),
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
              // 根据菜单获取对应的storageAreas数据
              final storageAreas = _getStorageAreasByMenuParams(menu.params);
              Navigator.pushNamed(context, menu.route!,
                  arguments: <String, dynamic>{
                    ...menu.params ?? <String, dynamic>{},
                    if (storageAreas != null) 'storageAreas': storageAreas,
                  });
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
              // // 根据菜单名称获取对应的storageAreas数据
              // final storageAreas = _getStorageAreasByMenuName(menu.name);
              // Navigator.pushNamed(
              //   context,
              //   menu.route!,
              //   arguments: <String, dynamic>{
              //     ...menu.params ?? <String, dynamic>{},
              //     if (storageAreas != null) 'storageAreas': storageAreas,
              //   }
              // );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 90,
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

  // 显示图例弹窗
  void _showLegendDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => _buildLegendDialog(),
    );
  }

  // 创建图例弹窗
  Widget _buildLegendDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.95,
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(),
              ..._buildLegendItems().reversed,
            ],
          ),
        ),
      ),
    );
  }

  // 弹窗标题
  Widget _buildDialogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.grey),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          style: IconButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
          ),
        ),
      ],
    );
  }

  // 仓储区域
  List<Widget> _buildLegendItems() {
    return _getLegendData()
        .map((data) => _buildLegendItem(
              name: data.name,
              cells: data.cells,
              rangeInfo: data.rangeInfo,
            ))
        .toList();
  }

  // 仓储区域库位列表
  List<_LegendData> _getLegendData() {
    final storageManager = StorageDataManager();
    final areaIds = storageManager.areaIds;
    print('areaIds: ${storageManager.getAllCells()}');

    return areaIds.map((areaId) {
      final cells = storageManager.getCellsByAreaId(areaId);
      final areaName = storageManager.getAreaName(areaId);
      final rangeInfo = StorageUtils.calculateAreaRange(cells, storageManager.getAllCells().cast<GridCell>());
      return _LegendData(
        name: areaName,
        cells: cells,
        rangeInfo: rangeInfo,
      );
    }).toList();
  }

  // 仓储区域控件封装
  Widget _buildLegendItem({
    required String name,
    required List<GridCell> cells,
    required Map<String, int> rangeInfo,
  }) {
    
    return Container(
      // margin: const EdgeInsets.only(bottom: _legendItemMargin),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: _borderColor,
          strokeWidth: _borderStrokeWidth,
          dashWidth: _borderDashWidth,
          gap: _borderGap,
        ),
        child: Padding(
          padding: const EdgeInsets.all(_legendPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              SizedBox(
                  width: _legendItemWidth,
                  height: _legendItemHeight,
                  child: MapControl(
                    // 使用计算出的范围，确保每个区域显示正确的格子数量
                    xUnits: (rangeInfo['xUnits'] as int) - (rangeInfo['xStart'] as int) + 1,
                    yUnits: (rangeInfo['yUnits'] as int) - (rangeInfo['yStart'] as int) + 1,
                    xStart: (rangeInfo['xStart'] as int) - 1,
                    yStart: (rangeInfo['yStart'] as int) - 1,
                    cells: cells
                  ))
            ],
          ),
        ),
      ),
    );
  }

  // 根据菜单参数获取对应的storageAreas数据
  Map<String, dynamic>? _getStorageAreasByMenuParams(
      Map<String, dynamic>? params) {
    if (params == null) return null;

    final areaId = params['id'] as String?;
    if (areaId == null) return null;

    final storageManager = StorageDataManager();
    final cells = storageManager.getCellsByAreaId(areaId);
    final areaName = storageManager.getAreaName(areaId);

    if (cells.isEmpty) return null;

    return <String, dynamic>{
      areaId: <String, dynamic>{
        'name': areaName,
        'cells': cells,
        'rangeInfo': StorageUtils.calculateAreaRange(cells, storageManager.getAllCells().cast<GridCell>()),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF29A8FF)),
              ),
              const SizedBox(height: 16),
              Text(
                '正在加载...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
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
