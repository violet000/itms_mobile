import 'package:flutter/material.dart';

class InboundManagementPage extends StatefulWidget {
  const InboundManagementPage({super.key});

  @override
  State<InboundManagementPage> createState() => _InboundManagementPageState();
}

class _InboundManagementPageState extends State<InboundManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('入库管理'),
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
                  '入库管理功能',
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
                        '扫描入库',
                        Icons.qr_code_scanner,
                        Colors.orange,
                        () {
                          // TODO: 实现扫描入库功能
                          _showComingSoonDialog(context, '扫描入库');
                        },
                      ),
                      _buildFunctionCard(
                        '手动入库',
                        Icons.edit,
                        Colors.green,
                        () {
                          // TODO: 实现手动入库功能
                          _showComingSoonDialog(context, '手动入库');
                        },
                      ),
                      _buildFunctionCard(
                        '入库记录',
                        Icons.history,
                        Colors.blue,
                        () {
                          // TODO: 实现入库记录查看功能
                          _showComingSoonDialog(context, '入库记录');
                        },
                      ),
                      _buildFunctionCard(
                        '入库统计',
                        Icons.analytics,
                        Colors.purple,
                        () {
                          // TODO: 实现入库统计功能
                          _showComingSoonDialog(context, '入库统计');
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
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
} 