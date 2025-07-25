import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/models/landmark_model.dart';
import 'package:itms_mobile/data/dataview/landmark_data_source.dart';
import 'package:itms_mobile/presentation/widgets/common/custom_dialog.dart';
import 'package:itms_mobile/presentation/widgets/common/message_toast.dart';
import 'package:itms_mobile/data/datasources/api/9087/service_9087.dart';
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:collection/collection.dart';
import 'package:itms_mobile/models/area_model.dart';

class LocationManagementPage extends StatefulWidget {
  const LocationManagementPage({super.key});

  @override
  State<LocationManagementPage> createState() => _LocationManagementPageState();
}

class _LocationManagementPageState extends State<LocationManagementPage> {
  late LandmarkDataSource _landmarkDataSource;
  final TextEditingController _landmarkIdController = TextEditingController();
  LandmarkStatus? _selectedStatus;
  List<LandmarkModel> _allLandmarks = [];
  List<LandmarkModel> _filteredLandmarks = [];
  List<AreaModel> _areas = [];
  AreaModel? _selectedArea;
  Service9087? _service9087;

  // 分页参数
  int _currentPage = 0;
  int _pageSize = 8;
  int _totalRows = 0;

  String? _errorMessage;

  List<String> _selectedLandmarkIds = [];

  @override
  void initState() {
    super.initState();
    _initService();
    _loadData();
    _fetchAreas();
  }

  void _initService() async {
    _service9087 = await Service9087.create();
  }

  /// 查询库区
  Future<void> _fetchAreas() async {
    _service9087 ??= await Service9087.create();
    final response = await _service9087!.qryAreaByParams(<String, dynamic>{});

    if (response['retCode'] == HTTPCode.success.code) {
      setState(() {
        _areas = (response['retList'] as List)
            .map((dynamic json) =>
                AreaModel.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    }
  }

  /// 加载地标数据
  Future<void> _loadData() async {
    _service9087 ??= await Service9087.create();
    EasyLoading.show(status: '正在加载数据...');
    try {
      final response = await _service9087!.qryByPage(<String, dynamic>{
        'status': LandmarkStatus.idle.code,
        'id': _landmarkIdController.text,
        'curPage': _currentPage + 1, // 接口从1开始，UI从0开始
        'pageSize': _pageSize
      });

      if (response['retCode'] == HTTPCode.success.code) {
        final List<dynamic> retList =
            (response['retList'] as List<dynamic>?) ?? <dynamic>[];
        final int total = (response['totalRow'] as int?) ?? 0;

        _allLandmarks = retList.map<LandmarkModel>((dynamic record) {
          final recordMap = record as Map<String, dynamic>;
          return LandmarkModel.fromJson(recordMap);
        }).toList();

        setState(() {
          _filteredLandmarks = List.from(_allLandmarks);
          _selectedLandmarkIds.clear();
          _updateLandmarkDataSource();
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

  void _filterData() {
    _currentPage = 0;
    _loadData();
  }

  void _onDeleteShelf(LandmarkModel landmark) {
    CustomDialog.showConfirm(
      context: context,
      title: '确认删除',
      content: '确定要删除地标 ${landmark.id} 吗？',
      confirmText: '删除',
      cancelText: '取消',
      confirmColor: Colors.red,
    ).then((result) async {
      if (result == ConfirmResult.confirm) {
        _service9087 ??= await Service9087.create();
        EasyLoading.show(status: '正在删除...');
        try {
          final List<String> deleteList = [landmark.id];
          final response = await _service9087!.deleteBatch(deleteList);
          EasyLoading.dismiss();
          EasyLoading.showSuccess('删除成功');
          _loadData();
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

  void _onEditLandmark(LandmarkModel landmark) {
    _showShelfDialog(landmark: landmark);
  }

  void _showShelfDialog({LandmarkModel? landmark}) {
    final isEdit = landmark != null;
    final title = isEdit ? '修改地标' : '新增地标';

    if (isEdit && landmark?.areaId != null) {
      _selectedArea =
          _areas.firstWhereOrNull((area) => area.id == landmark!.areaId);
    } else if (!isEdit) {
      _selectedArea = null;
    }

    final idController = TextEditingController(text: landmark?.id ?? '');
    final areaIdController =
        TextEditingController(text: landmark?.areaId ?? '');
    final areaNameController =
        TextEditingController(text: landmark?.areaName ?? '');
    final clrCenterNoController =
        TextEditingController(text: landmark?.clrCenterNo ?? 'AA');
    final locationTypeController = TextEditingController(
      text: landmark?.locationType.toString() ?? '9',
    );
    final statusController =
        TextEditingController(text: landmark?.status.toString() ?? '1');
    final noteController = TextEditingController(text: landmark?.note ?? '');
    final lengthController =
        TextEditingController(text: landmark?.length ?? '');
    final widthController = TextEditingController(text: landmark?.width ?? '');
    final xplaceController =
        TextEditingController(text: landmark?.xplace ?? '');
    final yplaceController =
        TextEditingController(text: landmark?.yplace ?? '');
    final zplaceController =
        TextEditingController(text: landmark?.zplace ?? '');

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...[
                    // 字段分组
                    _buildFormRow(
                      '地标编号',
                      idController,
                    ),
                    _buildDropdownRow<AreaModel>(
                      label: '所属库区',
                      value: _selectedArea,
                      items: _areas,
                      onChanged: (AreaModel? newValue) {
                        setState(() {
                          _selectedArea = newValue;
                        });
                      },
                      display: (area) => area.name,
                    ),
                    _buildFormRow('所属库编号', clrCenterNoController),
                    _buildDropdownRow<LocationType>(
                      label: '类型',
                      value: LocationType.values.firstWhereOrNull((e) =>
                          e.code == int.tryParse(locationTypeController.text)),
                      items: LocationType.values,
                      onChanged: (val) {
                        setState(() {
                          locationTypeController.text =
                              val?.code.toString() ?? '';
                        });
                      },
                      display: (e) => e.displayName,
                    ),
                    _buildDropdownRow<LandmarkStatus>(
                      label: '状态',
                      value: LandmarkStatus.values.firstWhereOrNull(
                          (e) => e.code == int.tryParse(statusController.text)),
                      items: LandmarkStatus.values,
                      onChanged: (val) {
                        setState(() {
                          statusController.text = val?.code.toString() ?? '';
                        });
                      },
                      display: (e) => e.displayName,
                    ),
                    // _buildFormRow('长度', lengthController),
                    // _buildFormRow('宽度', widthController),
                    _buildFormRow('xplace', xplaceController),
                    _buildFormRow('yplace', yplaceController),
                    _buildFormRow('zplace', zplaceController),
                    _buildFormRow('备注', noteController),
                  ].expand((w) => [w, const SizedBox(height: 8)]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          textStyle: const TextStyle(fontSize: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (idController.text.isEmpty) {
                            context.showErrorMessage('请填写完整信息');
                            return;
                          }
                          _service9087 ??= await Service9087.create();
                          EasyLoading.show(
                              status: isEdit ? '正在修改...' : '正在新增...');
                          try {
                            final Map<String, dynamic> params =
                                <String, dynamic>{};
                            if (!isEdit) {
                              params['id'] = idController.text;
                            }
                            if (isEdit) {
                              params['newId'] = idController.text;
                              params['oldId'] = landmark?.id;
                            }
                            params['areaId'] = _selectedArea?.id;
                            params['areaName'] = _selectedArea?.name;
                            params['clrCenterNo'] = clrCenterNoController.text;
                            params['locationType'] =
                                int.tryParse(locationTypeController.text) ?? 9;
                            params['status'] =
                                int.tryParse(statusController.text) ?? 1;
                            params['note'] = noteController.text;
                            params['length'] = lengthController.text;
                            params['width'] = widthController.text;
                            params['xplace'] = xplaceController.text;
                            params['yplace'] = yplaceController.text;
                            params['zplace'] = zplaceController.text;
                            Map<String, dynamic> response;
                            if (isEdit) {
                              response =
                                  await _service9087!.updateLocation(params);
                            } else {
                              response =
                                  await _service9087!.addLocation(params);
                            }
                            if (response['retCode'] == HTTPCode.success.code) {
                              context
                                  .showSuccessMessage(isEdit ? '修改成功' : '新增成功');
                              Navigator.of(context).pop();
                              _loadData();
                            } else {
                              context.showErrorMessage(
                                  (response['retMsg'] as String?) ??
                                      (isEdit ? '修改失败' : '新增失败'));
                            }
                          } catch (e) {
                            context.showErrorMessage(
                                '${isEdit ? '修改' : '新增'}失败: $e');
                          } finally {
                            EasyLoading.dismiss();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
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

  Widget _buildFormRow(String label, TextEditingController controller,
      {bool enabled = false}) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !enabled, // 编辑模式下禁用托盘编号输入
            style: TextStyle(
              fontSize: 14,
              color: enabled ? Colors.grey[600] : Colors.black87, // 编辑模式下显示灰色
            ),
            decoration: InputDecoration(
              hintText: enabled ? '${label}不可修改' : '请输入${label}',
              hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
              // prefixIcon: const Icon(Icons.confirmation_number, color: Colors.blue, size: 18), // 移除图标
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color.fromARGB(255, 215, 215, 215)),
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
              filled: enabled, // 编辑模式下填充背景色
              fillColor: enabled ? Colors.grey[100] : null, // 编辑模式下填充灰色背景
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) display,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<T>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem<T>(
                      value: e,
                      child: Text(display(e),
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF90CAF9)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
              ),
              fillColor: null,
              filled: false,
              hintText: '请选择$label',
              hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
            ),
          ),
        ),
      ],
    );
  }

  // 更新地标数据源
  void _updateLandmarkDataSource() {
    _landmarkDataSource = LandmarkDataSource(
      landmarks: _filteredLandmarks,
      onEdit: _onEditLandmark,
      onDelete: _onDeleteShelf,
      selectedIds: _selectedLandmarkIds,
      onSelect: (String id, bool selected) {
        setState(() {
          if (selected) {
            _selectedLandmarkIds.add(id);
          } else {
            _selectedLandmarkIds.remove(id);
          }
          _updateLandmarkDataSource();
        });
      },
    );
  }

  void _deleteLandmarks() async {
    if (_selectedLandmarkIds.isEmpty) {
      context.showErrorMessage('请选择要删除的地标');
      return;
    }
    final result = await CustomDialog.showConfirm(
      context: context,
      title: '确认删除',
      content: '确定要删除选中的${_selectedLandmarkIds.length}个地标吗？',
      confirmText: '删除',
      cancelText: '取消',
      confirmColor: Colors.red,
    );
    if (result == ConfirmResult.confirm) {
      _service9087 ??= await Service9087.create();
      EasyLoading.show(status: '正在删除...');
      try {
        final response = await _service9087!.deleteBatch(_selectedLandmarkIds);
        EasyLoading.dismiss();
        if (response['retCode'] == HTTPCode.success.code) {
          context.showSuccessMessage('删除成功');
          _selectedLandmarkIds.clear();
          _loadData();
        } else {
          context.showErrorMessage(response['retMsg'] as String? ?? '删除失败');
        }
      } catch (e) {
        EasyLoading.dismiss();
        context.showErrorMessage('删除失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth;
    final selectWidth = availableWidth * 0.10;
    final idWidth = availableWidth * 0.18;
    final areaNameWidth = availableWidth * 0.18;
    final typeWidth = availableWidth * 0.15;
    final statusWidth = availableWidth * 0.14;
    final actionsWidth = availableWidth * 0.24;

    return PageScaffold(
      title: '地标管理',
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
                          controller: _landmarkIdController,
                          decoration: InputDecoration(
                            labelText: '地标编号',
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
                              fontSize: 13,
                              color: Color.fromARGB(221, 92, 92, 92)),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<LandmarkStatus?>(
                          value: _selectedStatus,
                          items: [
                            const DropdownMenuItem<LandmarkStatus?>(
                              value: null,
                              child: Text('全部'),
                            ),
                            ...LandmarkStatus.values.map((status) {
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
                            labelText: '地标状态',
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
                          _landmarkIdController.clear();
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
                        child: Center(child: Text('查询')),
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
                onPressed: () => _deleteLandmarks(),
                icon: const Icon(Icons.delete),
                label: const Text('批量删除'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 201, 2, 58),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showShelfDialog(),
                icon: const Icon(Icons.add),
                label: const Text('新增地标'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              )
            ],
          ),
          const SizedBox(height: 12),

          // 表格区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: _filteredLandmarks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.inbox_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('暂无数据', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: availableWidth,
                        child: SfDataGrid(
                          source: _landmarkDataSource,
                          gridLinesVisibility: GridLinesVisibility.both,
                          headerGridLinesVisibility: GridLinesVisibility.both,
                          columnWidthMode: ColumnWidthMode.none,
                          headerRowHeight: 50,
                          rowHeight: 50,
                          // 表格columns定义
                          columns: [
                            GridColumn(
                              columnName: 'select',
                              label: Container(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Transform.scale(
                                    scale: 0.75,
                                    child: Checkbox(
                                      value: _selectedLandmarkIds.length ==
                                              _filteredLandmarks.length &&
                                          _filteredLandmarks.isNotEmpty,
                                      onChanged: (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedLandmarkIds =
                                                _filteredLandmarks
                                                    .map((e) => e.id)
                                                    .toList();
                                          } else {
                                            _selectedLandmarkIds.clear();
                                          }
                                          _updateLandmarkDataSource();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              width: selectWidth,
                            ),
                            GridColumn(
                              columnName: 'id',
                              label: Container(
                                alignment: Alignment.center,
                                decoration:
                                    const BoxDecoration(color: Colors.blue),
                                child: const Text('地标编号',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                              width: idWidth,
                            ),
                            GridColumn(
                              columnName: 'areaName',
                              label: Container(
                                alignment: Alignment.center,
                                decoration:
                                    const BoxDecoration(color: Colors.blue),
                                child: const Text('库区名称',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                              width: areaNameWidth,
                            ),
                            GridColumn(
                              columnName: 'locationType',
                              label: Container(
                                alignment: Alignment.center,
                                decoration:
                                    const BoxDecoration(color: Colors.blue),
                                child: const Text('类型',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                              width: typeWidth,
                            ),
                            GridColumn(
                              columnName: 'status',
                              label: Container(
                                alignment: Alignment.center,
                                decoration:
                                    const BoxDecoration(color: Colors.blue),
                                child: const Text('状态',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                              width: statusWidth,
                            ),
                            GridColumn(
                              columnName: 'actions',
                              label: Container(
                                alignment: Alignment.center,
                                decoration:
                                    const BoxDecoration(color: Colors.blue),
                                child: const Text('操作',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
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
          if (_filteredLandmarks.isNotEmpty)
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
                        items: [8, 16, 24, 32].map((int value) {
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
    _landmarkIdController.dispose();
    super.dispose();
  }
}
