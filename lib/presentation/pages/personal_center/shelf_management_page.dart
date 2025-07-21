import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/models/shelf_model.dart';
import 'package:itms_mobile/models/landmark_model.dart';
import 'package:itms_mobile/data/dataview/shelf_data_source.dart';
import 'package:itms_mobile/presentation/widgets/common/custom_dialog.dart';
import 'package:itms_mobile/presentation/widgets/common/message_toast.dart';
import 'package:itms_mobile/data/datasources/api/9087/service_9087.dart';
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ShelfManagementPage extends StatefulWidget {
  const ShelfManagementPage({super.key});

  @override
  State<ShelfManagementPage> createState() => _ShelfManagementPageState();
}

class _ShelfManagementPageState extends State<ShelfManagementPage> {
  late ShelfDataSource _shelfDataSource;
  final TextEditingController _shelfIdController = TextEditingController();
  PalletStatus? _selectedStatus;
  List<ShelfModel> _allShelves = [];
  List<ShelfModel> _filteredShelves = [];
  List<LandmarkModel> _availableLandmarks = [];
  Service9087? _service9087;

  // 分页参数
  int _currentPage = 0;
  int _pageSize = 10;
  int _totalRows = 0;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initService();
    _loadData();
    _loadLandmarks();
  }

  void _initService() async {
    _service9087 = await Service9087.create();
  }

  /// 加载托盘数据
  Future<void> _loadData() async {
    _service9087 ??= await Service9087.create();
    EasyLoading.show(status: '正在加载数据...');
    try {
      final response = await _service9087!.qryPageByParams(<String, dynamic>{
        'shelfId':
            _shelfIdController.text.isEmpty ? null : _shelfIdController.text,
        'status': _selectedStatus?.code,
        'curPage': _currentPage + 1, // 接口从1开始，UI从0开始
        'pageSize': _pageSize
      });

      if (response['retCode'] == HTTPCode.success.code) {
        final List<dynamic> retList =
            (response['retList'] as List<dynamic>?) ?? <dynamic>[];
        final int total = (response['totalRow'] as int?) ?? 0;

        _allShelves = retList.map<ShelfModel>((dynamic record) {
          final recordMap = record as Map<String, dynamic>;
          return ShelfModel.fromJson(recordMap);
        }).toList();

        setState(() {
          _filteredShelves = List.from(_allShelves);
          _shelfDataSource = ShelfDataSource(
            shelves: _filteredShelves,
            onEdit: _onEditShelf,
            onDelete: _onDeleteShelf,
          );
          _totalRows = total;
        });
      } else {
        setState(() {
          _errorMessage = (response['retMsg'] as String?) ?? '获取数据失败';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络请求失败: $e';
      });
    } finally {
      EasyLoading.dismiss();
    }
  }

  /// 加载地标数据
  Future<void> _loadLandmarks() async {
    _service9087 ??= await Service9087.create();
    try {
      final response = await _service9087!.qryAllByParams(<String, dynamic>{
        'status': 1, // 只查询空闲状态的地标
        'locationType': 2, // 只查询固定货架
      });

      if (response['retCode'] == HTTPCode.success.code) {
        final List<dynamic> retList =
            (response['retList'] as List<dynamic>?) ?? <dynamic>[];

        setState(() {
          _availableLandmarks = retList.map<LandmarkModel>((dynamic record) {
            final recordMap = record as Map<String, dynamic>;
            return LandmarkModel.fromJson(recordMap);
          }).toList();
        });
      }
    } catch (e) {
      print('加载地标数据失败: $e');
    }
  }

  void _filterData() {
    _currentPage = 0;
    _loadData();
  }

  void _onEditShelf(ShelfModel shelf) {
    _showShelfDialog(shelf: shelf);
  }

  void _onDeleteShelf(ShelfModel shelf) {
    CustomDialog.showConfirm(
      context: context,
      title: '确认删除',
      content: '确定要删除托盘 ${shelf.shelfId} 吗？',
      confirmText: '删除',
      cancelText: '取消',
      confirmColor: Colors.red,
    ).then((result) async {
      if (result == ConfirmResult.confirm) {
        _service9087 ??= await Service9087.create();
        EasyLoading.show(status: '正在删除...');
        try {
          // 构建删除托盘的参数，将locationId设置为空，其他参数保持正常
          final deleteParams = <String, dynamic>{
            'shelfId': shelf.shelfId,
            'shelfType': shelf.shelfType,
            'status': shelf.status,
            'clrCenterNo': shelf.clrCenterNo,
            'locationId': '', // 设置为空字符串
            'note': shelf.note, // 备注设置为空
          };
          final response = await _service9087!.updateShelf(deleteParams);
          EasyLoading.dismiss();
          EasyLoading.showSuccess('删除成功');
          _loadData(); // 重新加载数据
        } catch (e) {
          EasyLoading.dismiss();
          EasyLoading.showError('删除失败: $e');
        }
      }
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _loadData();
    });
  }

  void _onRowsPerPageChanged(int? newRowsPerPage) {
    if (newRowsPerPage != null) {
      setState(() {
        _pageSize = newRowsPerPage;
        _currentPage = 0;
        _loadData();
      });
    }
  }

  void _showShelfDialog({ShelfModel? shelf}) {
    final isEdit = shelf != null;
    final title = isEdit ? '编辑托盘' : '新增托盘';

    final shelfIdController = TextEditingController(text: shelf?.shelfId ?? '');
    final landmarkNameController = TextEditingController(text: shelf?.locationId ?? '');
    PalletStatus selectedStatus = shelf != null ? PalletStatus.fromCode(shelf.status) : PalletStatus.idle;
    LandmarkType selectedShelfType = shelf != null ? LandmarkType.values.firstWhere((e) => e.index == shelf.shelfType, orElse: () => LandmarkType.values.first) : LandmarkType.values.first;
    final clrCenterNoController = TextEditingController(text: shelf?.clrCenterNo ?? '海康模拟仓');
    final remarkController = TextEditingController();

    LandmarkModel? selectedLandmark;
    if (isEdit && shelf != null && _availableLandmarks.isNotEmpty) {
      try {
        selectedLandmark = _availableLandmarks.firstWhere(
          (landmark) => landmark.id.toString() == shelf.locationId.toString(),
        );
      } catch (e) {
        selectedLandmark = null;
      }
    } else {
      selectedLandmark = null;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 57, 57, 57),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 托盘编号
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          '托盘编号',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color.fromARGB(255, 75, 75, 75),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          controller: shelfIdController,
                          enabled: !isEdit, // 编辑模式下禁用托盘编号输入
                          style: TextStyle(
                            fontSize: 14,
                            color: isEdit ? Colors.grey[600] : Colors.black87, // 编辑模式下显示灰色
                          ),
                          decoration: InputDecoration(
                            hintText: isEdit ? '托盘编号不可修改' : '请输入托盘编号',
                            // prefixIcon: const Icon(Icons.confirmation_number, color: Colors.blue, size: 18), // 移除图标
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color.fromARGB(255, 215, 215, 215)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)), // 保持淡灰色
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: isEdit, // 编辑模式下填充背景色
                            fillColor: isEdit ? Colors.grey[100] : null, // 编辑模式下填充灰色背景
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 托盘类型
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          '托盘类型',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color.fromARGB(255, 75, 75, 75),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: DropdownButtonFormField<LandmarkType>(
                          value: selectedShelfType,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          decoration: InputDecoration(
                            // prefixIcon: const Icon(Icons.category, color: Colors.blue, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: LandmarkType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.displayName, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedShelfType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 托盘状态
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          '托盘状态',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color.fromARGB(255, 75, 75, 75),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: DropdownButtonFormField<PalletStatus>(
                          value: selectedStatus,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          decoration: InputDecoration(
                            // prefixIcon: const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: PalletStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.displayName, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStatus = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 所属地标
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          '所属地标',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color.fromARGB(255, 75, 75, 75),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: DropdownButtonFormField<LandmarkModel?>(
                          value: selectedLandmark,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: [
                            const DropdownMenuItem<LandmarkModel?>(
                              value: null,
                              child: Text('请选择'),
                            ),
                            ..._availableLandmarks.map((landmark) {
                              return DropdownMenuItem(
                                value: landmark,
                                child: Text('${landmark.id}', style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedLandmark = value;
                              if (value != null) {
                                landmarkNameController.text = value.id;
                              } else {
                                landmarkNameController.text = '';
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 所属仓库
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          '所属仓库',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color.fromARGB(255, 75, 75, 75),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: DropdownButtonFormField<StorageCenter>(
                          value: StorageCenter.values.firstWhere(
                            (center) => center.clrCenterNo == clrCenterNoController.text,
                            orElse: () => StorageCenter.haikang,
                          ),
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          decoration: InputDecoration(
                            // prefixIcon: const Icon(Icons.warehouse, color: Colors.blue, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: StorageCenter.values.map((center) {
                            return DropdownMenuItem(
                              value: center,
                              child: Text(center.clrCenterName, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              if (value != null) {
                                clrCenterNoController.text = value.clrCenterNo;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 备注
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          '备注',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color.fromARGB(255, 75, 75, 75),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          controller: remarkController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '请输入备注',
                            // prefixIcon: const Icon(Icons.note, color: Colors.blue, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          textStyle: const TextStyle(fontSize: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (shelfIdController.text.isEmpty) {
                            context.showErrorMessage('请填写完整信息');
                            return;
                          }
                          _service9087 ??= await Service9087.create();
                          EasyLoading.show(status: isEdit ? '正在修改...' : '正在新增...');
                          try {
                            final params = <String, dynamic>{
                              'shelfId': shelfIdController.text,
                              'shelfType': selectedShelfType.index,
                              'status': selectedStatus.code,
                              'clrCenterNo': clrCenterNoController.text,
                              'clrCenterName': StorageCenter.fromCode(clrCenterNoController.text).clrCenterName,
                              'locationId': selectedLandmark?.id ?? '', 
                              'note': remarkController.text,
                            };
                            Map<String, dynamic> response;
                            if (isEdit) {
                              response = await _service9087!.updateShelf(params);
                            } else {
                              response = await _service9087!.addShelf(params);
                            }
                            if (response['retCode'] == HTTPCode.success.code) {
                              context.showSuccessMessage(isEdit ? '修改成功' : '新增成功');
                              Navigator.of(context).pop();
                              _loadData();
                            } else {
                              context.showErrorMessage((response['retMsg'] as String?) ?? (isEdit ? '修改失败' : '新增失败'));
                            }
                          } catch (e) {
                            context.showErrorMessage('${isEdit ? '修改' : '新增'}失败: $e');
                          } finally {
                            EasyLoading.dismiss();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: Text(isEdit ? '修改' : '新增'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth;
    final shelfIdWidth = availableWidth * 0.26;
    final statusWidth = availableWidth * 0.18;
    final landmarkWidth = availableWidth * 0.28;
    final actionsWidth = availableWidth * 0.30;

    return PageScaffold(
      title: '托盘管理',
      showBackButton: true,
      onBackPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'selectedTab': 2},
        );
      },
      child: Column(
        children: [
          // 搜索区域
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: const Color(0xFFE0E3E8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _shelfIdController,
                          decoration: InputDecoration(
                            labelText: '托盘编号',
                            labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color.fromARGB(255, 55, 55, 55)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          style: const TextStyle(
                              fontSize: 13, color: Color.fromARGB(221, 92, 92, 92)),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<PalletStatus?>(
                          value: _selectedStatus,
                          items: [
                            const DropdownMenuItem<PalletStatus?>(
                              value: null,
                              child: Text('全部'),
                            ),
                            ...PalletStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.displayName),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                              _filterData();
                            });
                          },
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: '托盘状态',
                            labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color.fromARGB(255, 55, 55, 55)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E3E8)),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧按钮组
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _shelfIdController.clear();
                          _selectedStatus = null;
                          _filterData();
                        });
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const SizedBox(
                        width: 30,
                        height: 24,
                        child: Center(child: Text('重置')),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueGrey,
                        minimumSize: const Size(30, 24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        side: const BorderSide(color: Color(0xFF90CAF9)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _filterData,
                      icon: const Icon(Icons.search, size: 16),
                      label: const SizedBox(
                        width: 30,
                        height: 24,
                        child: Center(child: Text('搜索')),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(30, 24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 错误信息显示
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                    icon: Icon(Icons.close, color: Colors.red[600], size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // 操作按钮区域
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showShelfDialog(),
                icon: const Icon(Icons.add),
                label: const Text('新增托盘'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 表格区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: _filteredShelves.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('暂无数据',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: availableWidth,
                        child: SfDataGrid(
                          source: _shelfDataSource,
                          gridLinesVisibility: GridLinesVisibility.both,
                          headerGridLinesVisibility: GridLinesVisibility.both,
                          columnWidthMode: ColumnWidthMode.none,
                          headerRowHeight: 50,
                          rowHeight: 50,
                          columns: [
                            GridColumn(
                              columnName: 'shelfId',
                              label: Container(
                                alignment: Alignment.center,
                                decoration:
                                    const BoxDecoration(color: Colors.blue),
                                child: const Text(
                                  '托盘编号',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                              width: shelfIdWidth,
                            ),
                            GridColumn(
                              columnName: 'status',
                              label: Container(
                                alignment: Alignment.center,
                                decoration:
                                    const BoxDecoration(color: Colors.blue),
                                child: const Text(
                                  '托盘状态',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                              width: statusWidth,
                            ),
                            GridColumn(
                              columnName: 'landmarkName',
                              label: Container(
                                alignment: Alignment.center,
                                decoration:
                                    const BoxDecoration(color: Colors.blue),
                                child: const Text(
                                  '所属地标',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                              width: landmarkWidth,
                            ),
                            GridColumn(
                              columnName: 'actions',
                              label: Container(
                                alignment: Alignment.center,
                                decoration:
                                    const BoxDecoration(color: Colors.blue),
                                child: const Text(
                                  '操作',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                              width: actionsWidth,
                              allowSorting: false,
                              allowFiltering: false,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // 分页控件
          if (_filteredShelves.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  // 每页行数选择
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('每页',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black87)),
                      const SizedBox(width: 4),
                      DropdownButton<int>(
                        value: _pageSize,
                        underline: const SizedBox(),
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                        items: [5, 10, 20, 50].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          );
                        }).toList(),
                        onChanged: _onRowsPerPageChanged,
                      ),
                      const SizedBox(width: 4),
                      const Text('条',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black87)),
                      const SizedBox(width: 10),
                      Text('共 $_totalRows 条',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                  // 分页按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 0
                            ? () => _onPageChanged(_currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        color: Colors.blue,
                        splashRadius: 20,
                        tooltip: '上一页',
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Text(
                          '${_currentPage + 1} / ${(_totalRows / _pageSize).ceil()}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _currentPage < (_totalRows / _pageSize).ceil() - 1
                                ? () => _onPageChanged(_currentPage + 1)
                                : null,
                        icon: const Icon(Icons.chevron_right),
                        color: Colors.blue,
                        splashRadius: 20,
                        tooltip: '下一页',
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shelfIdController.dispose();
    super.dispose();
  }
}
