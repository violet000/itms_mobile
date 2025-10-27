import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itms_mobile/data/datasources/interceptor/dio_service.dart';

class NetworkSettingsPage extends StatefulWidget {
  const NetworkSettingsPage({Key? key}) : super(key: key);

  @override
  State<NetworkSettingsPage> createState() => _NetworkSettingsPageState();
}

class _NetworkSettingsPageState extends State<NetworkSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vmsIpController = TextEditingController();
  final TextEditingController _vpsIpController = TextEditingController();
  final TextEditingController _websocketUrlController = TextEditingController();

  static const String vmsKey = 'network_vms_ip';
  static const String vpsKey = 'network_vps_ip';
  static const String websocketKey = 'websocket_url';

  @override
  void initState() {
    super.initState();
    // 设置默认值，让页面立即显示
    _vmsIpController.text = '10.34.12.130:9087';
    _vpsIpController.text = '10.34.12.130:8062';
    _websocketUrlController.text = 'ws://10.34.12.130:9087/websocket';
    // 异步加载保存的配置
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _vmsIpController.text = prefs.getString(vmsKey) ?? '10.34.12.130:9087';
      _vpsIpController.text = prefs.getString(vpsKey) ?? '10.34.12.130:8062';
      _websocketUrlController.text = prefs.getString(websocketKey) ?? 'ws://10.34.12.130:9087/websocket';
    });
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState?.validate() ?? false) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(vmsKey, _vmsIpController.text);
      await prefs.setString(vpsKey, _vpsIpController.text);
      
      // 保存 WebSocket URL（如果填写了）
      final websocketUrl = _websocketUrlController.text.trim();
      if (websocketUrl.isNotEmpty) {
        await prefs.setString(websocketKey, websocketUrl);
      }
      
      DioServiceManager().clearAllServices();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
    }
  }

  void _backToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '网络设置',
      showBackButton: true,
      onBackPressed: _backToLogin,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _vmsIpController,
                decoration: const InputDecoration(
                  labelText: 'VMS系统IP',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入VMS系统IP';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vpsIpController,
                decoration: const InputDecoration(
                  labelText: 'CPS系统IP',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入CPS系统IP';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websocketUrlController,
                decoration: const InputDecoration(
                  labelText: 'WebSocket 推送地址（可选）',
                  hintText: '例如: 10.34.12.130:8080 或 ws://10.34.12.130:8080',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveConfig,
                      child: const Text('保存'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _backToLogin,
                      child: const Text('返回登录'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vmsIpController.dispose();
    _vpsIpController.dispose();
    _websocketUrlController.dispose();
    super.dispose();
  }
}
