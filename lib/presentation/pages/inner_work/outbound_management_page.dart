import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/page_scaffold.dart';

class OutboundManagementPage extends StatefulWidget {
  const OutboundManagementPage({super.key});

  @override
  State<OutboundManagementPage> createState() => _OutboundManagementPageState();
}

class _OutboundManagementPageState extends State<OutboundManagementPage> {
  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '出库管理',
      child: Container(),
    );
  }
} 