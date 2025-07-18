import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:itms_mobile/core/constants/constant.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:itms_mobile/presentation/widgets/common/message_toast.dart';
import 'package:itms_mobile/services/color_settings_service.dart';

class LandmarkColorSettingsPage extends StatefulWidget {
  const LandmarkColorSettingsPage({Key? key}) : super(key: key);

  @override
  State<LandmarkColorSettingsPage> createState() =>
      _LandmarkColorSettingsPageState();
}

class _LandmarkColorSettingsPageState extends State<LandmarkColorSettingsPage> {
  // 存储修改后的颜色值
  Map<LandmarkStatus, String> _colorValues = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentColors();
  }

  // 加载当前颜色值
  Future<void> _loadCurrentColors() async {
    final colorSettings = await ColorSettingsService.getColorSettings();
    setState(() {
      _colorValues = colorSettings;
    });
  }

  // 验证颜色格式
  bool _isValidColor(String color) {
    // 检查是否为有效的十六进制颜色格式
    final colorRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return colorRegex.hasMatch(color);
  }

  // 显示颜色选择器
  void _showColorPicker(LandmarkStatus status) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择${status.displayName}颜色'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 预设颜色选项
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildColorOption(status, '#D3D3D3', '灰色'),
                  _buildColorOption(status, '#90EE90', '绿色'),
                  _buildColorOption(status, '#CD5C5C', '红色'),
                  _buildColorOption(status, '#FFD700', '金色'),
                  _buildColorOption(status, '#87CEFA', '蓝色'),
                  _buildColorOption(status, '#FFA07A', '橙色'),
                  _buildColorOption(status, '#DDA0DD', '紫色'),
                  _buildColorOption(status, '#F0E68C', '黄色'),
                ],
              ),
              const SizedBox(height: 16),
              // 自定义颜色输入
              TextField(
                decoration: InputDecoration(
                  labelText: '自定义颜色 (如: #FF0000)',
                  border: OutlineInputBorder(),
                  hintText: '输入十六进制颜色值',
                ),
                onChanged: (value) {
                  if (_isValidColor(value)) {
                    setState(() {
                      _colorValues[status] = value;
                      _hasChanges = true;
                    });
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
          ],
        );
      },
    );
  }

  // 构建颜色选项
  Widget _buildColorOption(LandmarkStatus status, String color, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _colorValues[status] = color;
          _hasChanges = true;
        });
        Navigator.of(context).pop();
      },
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hexToColor(color),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 十六进制颜色转换为 Color
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // 保存颜色设置
  void _saveColors() async {
    try {
      final success =
          await ColorSettingsService.saveColorSettings(_colorValues);
      if (success) {
        context.showSuccessMessage('颜色设置已保存');
        setState(() {
          _hasChanges = false;
        });
      } else {
        context.showErrorMessage('保存失败');
      }
    } catch (e) {
      context.showErrorMessage('保存失败: $e');
    }
  }

  // 重置颜色设置
  void _resetColors() async {
    try {
      final success = await ColorSettingsService.resetColorSettings();
      if (success) {
        await _loadCurrentColors();
        setState(() {
          _hasChanges = false;
        });
        context.showSuccessMessage('颜色设置已重置');
      } else {
        context.showErrorMessage('重置失败');
      }
    } catch (e) {
      context.showErrorMessage('重置失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '库位色块值设置',
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
          const SizedBox(height: 16),
          // 颜色设置列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: LandmarkStatus.values.length,
              itemBuilder: (context, index) {
                final status = LandmarkStatus.values[index];
                final currentColor = _colorValues[status] ?? status.color;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _hexToColor(currentColor),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    title: Text(
                      status.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('状态码: ${status.code}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentColor,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showColorPicker(status),
                        ),
                      ],
                    ),
                    onTap: () => _showColorPicker(status),
                  ),
                );
              },
            ),
          ),

          // 底部按钮
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetColors,
                      child: Text('重置'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveColors,
                      child: Text('保存'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 显示未保存更改对话框
  void _showUnsavedChangesDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('未保存的更改'),
          content: Text('您有未保存的颜色设置更改，确定要离开吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('离开'),
            ),
          ],
        );
      },
    );
  }
}
