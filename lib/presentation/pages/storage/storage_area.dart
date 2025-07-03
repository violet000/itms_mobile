import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/material.dart';

class StorageArea extends StatefulWidget {
  const StorageArea({super.key});

  @override
  State<StorageArea> createState() => _StorageAreaState();
}

class _StorageAreaState extends State<StorageArea> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    print(args);

    return Container(
      child: Text('StorageArea'),
    );
  }
}