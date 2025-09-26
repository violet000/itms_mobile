import 'package:flutter/material.dart';
import '../../widgets/common/hikvision_scanner_widget.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../../core/config/scanner_settings.dart';

/// 海康威视扫码器配置页面
class HikvisionScannerPage extends StatefulWidget {
  const HikvisionScannerPage({Key? key}) : super(key: key);

  @override
  State<HikvisionScannerPage> createState() => _HikvisionScannerPageState();
}

class _HikvisionScannerPageState extends State<HikvisionScannerPage> {
  final List<String> _scanResults = [];
  bool _enableTone = true;
  bool _enableVibrate = true;
  bool _enableContinuousScan = false;
  bool _autoStart = false;
  bool _autoRestart = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ScannerSettings.load();
    setState(() {
      _enableTone = settings.enableTone;
      _enableVibrate = settings.enableVibrate;
      _enableContinuousScan = settings.enableContinuousScan;
      _autoStart = settings.autoStart;
      _autoRestart = settings.autoRestart;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    final settings = ScannerSettings(
      enableTone: _enableTone,
      enableVibrate: _enableVibrate,
      enableContinuousScan: _enableContinuousScan,
      autoStart: _autoStart,
      autoRestart: _autoRestart,
    );
    await settings.save();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '海康威视扫码器配置',
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('提示音'),
              subtitle: const Text('扫码成功时播放提示音'),
              value: _enableTone,
              onChanged: (value) {
                setState(() {
                  _enableTone = value;
                });
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('震动'),
              subtitle: const Text('扫码成功时震动'),
              value: _enableVibrate,
              onChanged: (value) {
                setState(() {
                  _enableVibrate = value;
                });
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('连续扫码'),
              subtitle: const Text('开启后可以连续扫描多个条码'),
              value: _enableContinuousScan,
              onChanged: (value) {
                setState(() {
                  _enableContinuousScan = value;
                });
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('自动开始'),
              subtitle: const Text('页面加载时自动开始扫描'),
              value: _autoStart,
              onChanged: (value) {
                setState(() {
                  _autoStart = value;
                });
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('自动重启'),
              subtitle: const Text('扫码成功后自动开始下一次扫描'),
              value: _autoRestart,
              onChanged: (value) {
                setState(() {
                  _autoRestart = value;
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  // void _onScanResult(String result) {
  //   setState(() {
  //     _scanResults.insert(0, result); // 最新的结果放在最前面
  //   });

  //   // 显示成功提示
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('扫码成功: $result'),
  //       backgroundColor: Colors.green,
  //       duration: const Duration(seconds: 2),
  //     ),
  //   );
  // }

  // void _onScanError(String error) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('扫码错误: $error'),
  //       backgroundColor: Colors.red,
  //       duration: const Duration(seconds: 3),
  //     ),
  //   );
  // }

  // void _clearResults() {
  //   setState(() {
  //     _scanResults.clear();
  //   });
  // }

  // void _copyToClipboard(String text) {
  //   // 这里可以添加复制到剪贴板的功能
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('已复制: $text'),
  //       duration: const Duration(seconds: 1),
  //     ),
  //   );
  // }
}
