import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/logger.dart';

class StorageArea extends StatefulWidget {
  const StorageArea({super.key});

  @override
  State<StorageArea> createState() => _StorageAreaState();
}

class _StorageAreaState extends State<StorageArea> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    AppLogger.info('args: $args');

    return Scaffold(
      appBar: AppBar(
        title: Text('${args?['name']}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 跳转到主页
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
          },
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
