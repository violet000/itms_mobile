import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';
import 'package:itms_mobile/services/storage_service.dart';
import 'package:itms_mobile/core/utils/storage_utils.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart';
import 'package:itms_mobile/presentation/widgets/common/custom_dialog.dart';
import 'package:itms_mobile/presentation/pages/storage/storage_area.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';

class PointToPointPage extends StatefulWidget {
  const PointToPointPage({super.key});

  @override
  State<PointToPointPage> createState() => _PointToPointPageState();
}

class _PointToPointPageState extends State<PointToPointPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StorageArea> _storageAreas = [];
  List<Map<String, dynamic>> itemList = [];

  @override
  void initState() {
    super.initState();
    _getStorageAreas();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 获取仓储库位信息
  Future<void> _getStorageAreas() async {
    try {
      Map<String, dynamic>? response = StorageService.getCachedStorageAreas();

      if (response == null || !response.containsKey('retList')) {
        return print('仓储数据错误或为空');
      }
      final retList = response['retList'] as List<dynamic>;

      StorageDataManager().clearAllData();

      for (var item in retList) {
        final map = item as Map<String, dynamic>;
        itemList.add(map);
      }
      AppLogger.info('itemList: $itemList');
    } catch (e) {
      AppLogger.error('获取仓储库位信息失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '点到点搬运',
      showBackButton: true,
      rightWidget: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () async {
          String? selectedId = await CustomDialog.showCustom<String>(
            context: context,
            title: const Text(
              '选择库位',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color.fromARGB(255, 252, 249, 249),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 36,
                offset: Offset(0, 16),
              ),
            ],
            child: StatefulBuilder(
              builder: (context, setState) {
                String? tempSelectedId = '';
                return StatefulBuilder(
                  builder: (context, setStateInner) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...itemList.map((item) {
                          final isSelected = tempSelectedId?.toString() ==
                              item['id']?.toString();
                          final ValueNotifier<bool> isHovered =
                              ValueNotifier(false);
                          return ValueListenableBuilder<bool>(
                            valueListenable: isHovered,
                            builder: (context, hovered, _) {
                              return MouseRegion(
                                onEnter: (_) => isHovered.value = true,
                                onExit: (_) => isHovered.value = false,
                                child: Card(
                                  elevation: isSelected || hovered ? 8 : 1,
                                  shadowColor: Colors.blue.withOpacity(0.25),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: isSelected
                                        ? const BorderSide(
                                            color: Colors.blue, width: 1)
                                        : BorderSide.none,
                                  ),
                                  color: isSelected
                                      ? const Color(0xFFE3F2FD)
                                      : Colors.white,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 0),
                                  child: RadioListTile<String>(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    title: Text(
                                      item['name']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    value: item['id']?.toString() ?? '',
                                    groupValue: tempSelectedId?.toString(),
                                    activeColor: Colors.blue,
                                    onChanged: (value) {
                                      setStateInner(() {
                                        AppLogger.info('value: $value');
                                        tempSelectedId = value;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('确定'),
              ),
            ],
          );
          if (selectedId != null) {
            AppLogger.info('选中的库位id: $selectedId');
          }
        },
      ),
      onBackPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'selectedTab': 1},
        );
      },
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '起始库位'),
              Tab(text: '目标库位'),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.blue,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Container(child: Text('起始库位')),
                Container(child: Text('目标库位')),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 12, 124, 235),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  print('取消任务');
                },
                child: const Text('取消任务'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
