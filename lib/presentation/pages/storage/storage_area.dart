import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';

/// 仓储库位控件封装
class StorageArea extends StatefulWidget {
  const StorageArea({super.key});

  @override
  State<StorageArea> createState() => _StorageAreaState();
}

class _StorageAreaState extends State<StorageArea> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?; // 获取父控件传递下来的参数(库位坐标以及库位详细信息)
    AppLogger.info('args: $args');

    return PageScaffold(
      showBackButton: true,
      title: '${args?['name']}',
      onBackPressed: () {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      },
      child: Container(
        child: Text('${args?['name']}'),
      ),
    );
  }
}
