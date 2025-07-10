import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';

class HandTaskPage extends StatefulWidget {
  const HandTaskPage({super.key});

  @override
  State<HandTaskPage> createState() => _HandTaskPageState();
}

class _HandTaskPageState extends State<HandTaskPage> {
  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '搬运任务',
      showBackButton: true,
      onBackPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/home', 
          (route) => false,
          arguments: {'selectedTab': 1}
        );
      },
      child: Container(),
    );
  }
} 