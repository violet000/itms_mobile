import 'package:flutter/material.dart';
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/data/datasources/api/9087/service_9087.dart';

class DevUrlManagementPage extends StatefulWidget {
  const DevUrlManagementPage({Key? key}) : super(key: key);

  @override
  State<DevUrlManagementPage> createState() => _DevUrlManagementPageState();
}

class _DevUrlManagementPageState extends State<DevUrlManagementPage> {
  List<Map<String, dynamic>> _devList = [];
  bool _loading = true;
  int? _editingIndex;
  final Map<int, Map<String, TextEditingController>> _controllers = {};
  Service9087? _service9087;

  @override
  void initState() {
    super.initState();
    _initServiceAndFetch();
  }

  Future<void> _initServiceAndFetch() async {
    _service9087 = await Service9087.create();
    await _fetchDevList();
  }

  /// 获取设备URL
  Future<void> _fetchDevList() async {
    if (_service9087 == null) return;
    setState(() => _loading = true);
    try {
      final res = await _service9087!.getAllUrlInfoList();

      if (res['retCode'] == HTTPCode.success.code) {
        if (res['retList'] is List) {
          _devList = List<Map<String, dynamic>>.from(res['retList'] as List);
          // 初始化控制器
          for (int i = 0; i < _devList.length; i++) {
            _controllers[i] = <String, TextEditingController>{
              'devName': TextEditingController(
                  text: (_devList[i]['devName'] ?? '').toString()),
              'devIp': TextEditingController(
                  text: (_devList[i]['devIp'] ?? '').toString()),
              'devPort': TextEditingController(
                  text: (_devList[i]['devPort'] ?? '').toString()),
            };
          }
        }
      }
    } catch (e) {}
    setState(() => _loading = false);
  }

  Future<void> _saveDev(int index) async {
    if (_service9087 == null) return;
    final dev = _devList[index];
    final ctrls = _controllers[index]!;
    final params = <String, dynamic>{
      'devId': dev['devId'],
      'devName': ctrls['devName']!.text,
      'devIp': ctrls['devIp']!.text,
      'devPort': ctrls['devPort']!.text,
    };
    try {
      final res = await _service9087!.updateDevInfo(params);
      if (res['retCode'] == HTTPCode.success.code) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存成功')));
        setState(() => _editingIndex = null);
        _fetchDevList();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败: ${res['msg'] ?? ''}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('保存异常: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '设备URL管理',
      showBackButton: true,
      onBackPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'selectedTab': 2},
        );
      },
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _devList.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final dev = _devList[index];
                final editing = _editingIndex == index;
                final ctrls = _controllers[index]!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: ctrls['devName'],
                                enabled: editing,
                                decoration: const InputDecoration(
                                  labelText: '设备名称',
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 2),
                                ),
                                style: const TextStyle(fontSize: 13),
                                textAlignVertical: TextAlignVertical.top,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: ctrls['devIp'],
                                enabled: editing,
                                decoration: const InputDecoration(
                                  labelText: '设备IP',
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 2),
                                ),
                                style: const TextStyle(fontSize: 13),
                                textAlignVertical: TextAlignVertical.top,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: ctrls['devPort'],
                                enabled: editing,
                                decoration: const InputDecoration(
                                  labelText: '端口号',
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 2),
                                ),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 13),
                                textAlignVertical: TextAlignVertical.top,
                              ),
                            ),
                            const SizedBox(width: 12),
                            editing
                                ? Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.save,
                                            color: Colors.green),
                                        onPressed: () => _saveDev(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel,
                                            color: Colors.red),
                                        onPressed: () {
                                          // 恢复原始内容
                                          ctrls['devName']!.text =
                                              (dev['devName'] ?? '').toString();
                                          ctrls['devIp']!.text =
                                              (dev['devIp'] ?? '').toString();
                                          ctrls['devPort']!.text =
                                              (dev['devPort'] ?? '').toString();
                                          setState(() => _editingIndex = null);
                                        },
                                      ),
                                    ],
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() => _editingIndex = index);
                                    },
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
