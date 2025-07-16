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
          const SizedBox(height: 24),
          // 个人信息卡片
          _buildProfileCard(),
          const SizedBox(height: 24),
          // 功能区块
          ..._buildMenuList(context),
          const Spacer(),
          // 退出登录按钮
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: const AssetImage('assets/icon/icon.png'),
                backgroundColor: Colors.white,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '角色: 超级管理员',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuList(BuildContext context) {
    final List<_MenuItemData> menuItems = [
      _MenuItemData(
        icon: Icons.settings,
        title: '设置图例库位宽高',
        onTap: () {
          // TODO: 跳转到设置图例库位宽高页面
        },
      ),
      _MenuItemData(
        icon: Icons.devices,
        title: '设备管理',
        onTap: () {
          // TODO: 跳转到设备管理页面
        },
      ),
      _MenuItemData(
        icon: Icons.widgets,
        title: '托盘管理',
        onTap: () {
          // TODO: 跳转到托盘管理页面
        },
      ),
      _MenuItemData(
        icon: Icons.place,
        title: '地标管理',
        onTap: () {
          // TODO: 跳转到地标管理页面
        },
      ),
    ];
    return menuItems
        .map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: Icon(item.icon, size: 32, color: const Color(0xFF0489FE)),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: item.onTap,
                ),
              ),
            ))
        .toList();
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22), // 底部留白
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 200, 199, 199),
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
        child: const Text('退出登录', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuItemData({required this.icon, required this.title, required this.onTap});
} 