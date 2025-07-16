import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:flutter/services.dart'; // 顶部引入

class PersonalCenterPage extends StatelessWidget {
  const PersonalCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '厂商模式',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部渐变信息区
          _buildTopProfile(context),
          const SizedBox(height: 28),
          // 功能区块
          ..._buildMenuList(context),
          const Spacer(),
          // 退出登录按钮
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildTopProfile(BuildContext context) {
    return Stack(
      children: [
        // 渐变背景
        Container(
          height: 140,
        ),
        // 头像和信息
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  child: const CircleAvatar(
                    radius: 38,
                    backgroundColor: Color.fromARGB(255, 128, 189, 243),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'admin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 106, 106),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '角色: 超级管理员',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 107, 106, 106),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMenuList(BuildContext context) {
    final List<_MenuItemData> menuItems = [
      _MenuItemData(
        icon: Icons.settings,
        iconBg: const Color(0xFF4FC3F7),
        title: '设置图例库位宽高',
        onTap: () {
          // TODO: 跳转到设置图例库位宽高页面
        },
      ),
      _MenuItemData(
        icon: Icons.devices,
        iconBg: const Color(0xFF81C784),
        title: '设备管理',
        onTap: () {
          // TODO: 跳转到设备管理页面
        },
      ),
      _MenuItemData(
        icon: Icons.widgets,
        iconBg: const Color(0xFFFFB74D),
        title: '托盘管理',
        onTap: () {
          // TODO: 跳转到托盘管理页面
        },
      ),
      _MenuItemData(
        icon: Icons.place,
        iconBg: const Color(0xFFBA68C8),
        title: '地标管理',
        onTap: () {
          // TODO: 跳转到地标管理页面
        },
      ),
    ];
    return menuItems
        .map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4), // 左右间距24，上下间距8
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 54,
                      decoration: BoxDecoration(
                        color: item.iconBg.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(item.icon, size: 20, color: item.iconBg),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: item.onTap,
                  ),
                ),
              ),
            ))
        .toList();
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18), // 底部留白
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 200, 199, 199),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: () {
          SystemNavigator.pop(); // 退出APP
        },
        child: const Text('退出登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;
  const _MenuItemData({required this.icon, required this.iconBg, required this.title, required this.onTap});
} 