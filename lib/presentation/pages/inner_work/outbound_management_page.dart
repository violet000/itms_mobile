import 'package:flutter/material.dart';

class OutboundManagementPage extends StatefulWidget {
  const OutboundManagementPage({super.key});

  @override
  State<OutboundManagementPage> createState() => _OutboundManagementPageState();
}

class _OutboundManagementPageState extends State<OutboundManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('出库管理'),
        backgroundColor: const Color(0xFF0489FE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0489FE),
              Color(0xFF0366CC),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '出库管理功能',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildFunctionCard(
                        '扫描出库',
                        Icons.qr_code_scanner,
                        Colors.orange,
                        () {
                          // TODO: 实现扫描出库功能
                          _showComingSoonDialog(context, '扫描出库');
                        },
                      ),
                      _buildFunctionCard(
                        '手动出库',
                        Icons.edit,
                        Colors.green,
                        () {
                          // TODO: 实现手动出库功能
                          _showComingSoonDialog(context, '手动出库');
                        },
                      ),
                      _buildFunctionCard(
                        '出库记录',
                        Icons.history,
                        Colors.blue,
                        () {
                          // TODO: 实现出库记录查看功能
                          _showComingSoonDialog(context, '出库记录');
                        },
                      ),
                      _buildFunctionCard(
                        '出库统计',
                        Icons.analytics,
                        Colors.purple,
                        () {
                          // TODO: 实现出库统计功能
                          _showComingSoonDialog(context, '出库统计');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String featureName) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$featureName'),
          content: Text('$featureName 功能正在开发中，敬请期待！'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                splashFactory: NoSplash.splashFactory,
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
} 