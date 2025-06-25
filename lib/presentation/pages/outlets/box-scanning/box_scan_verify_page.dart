import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:itms_mobile/presentation/widgets/common/blue_polygon_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itms_mobile/presentation/widgets/common/face_scan_widget.dart';
import 'package:itms_mobile/data/datasources/api/18082/service_18082.dart';

class BoxScanVerifyPage extends StatefulWidget {
  final Map<String, dynamic> point;
  final List<String> boxCodes;

  const BoxScanVerifyPage({
    super.key,
    required this.point,
    required this.boxCodes,
  });

  @override
  State<BoxScanVerifyPage> createState() => _BoxScanVerifyPageState();
}

class _BoxScanVerifyPageState extends State<BoxScanVerifyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Uint8List? _faceImage;
  bool _isLoading = false;
  final Service18082 _service = Service18082();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 自定义appBar
  PreferredSizeWidget appCustomBar(BuildContext context) {
    return AppBar(
      title: const Text(
        '交接复核',
        textAlign: TextAlign.left,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333)),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      leading: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        },
      ),
    );
  }

    // 自定义内容体的头部
  Widget customBodyHeader(int boxCount, String pointCode) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.transparent,
      child: BluePolygonBackground(
          width: 900,
          height: 150,
          child: Column(
            children: [
              // 顶部信息区和下方内容区完整布局
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部信息行
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              "押运线路信息",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  // 下方白色内容区
                  Container(
                    margin: const EdgeInsets.only(left: 16, right: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                "assets/icons/line_name.svg",
                                width: 40,
                                height: 40,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                children: [
                                  const Text(
                                    "线路编号",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromARGB(255, 61, 61, 61),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("${widget.point['lineName']}", style: const TextStyle(color: Color.fromARGB(255, 2, 164, 245))),
                                ],
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                "assets/icons/handover_cashbox_count.svg",
                                width: 40,
                                height: 40,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                children: [
                                  const Text(
                                    "交接款箱个数",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromARGB(255, 61, 61, 61),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("$boxCount个", style: const TextStyle(color: Color.fromARGB(255, 2, 164, 245)),),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          )),
    );
  }

  // 人脸拍照
  Future<void> _takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 50,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _faceImage = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    }
  }

  // 提交复核
  Future<void> _handleSubmit() async {
    if (_tabController.index == 0) {
      // 账号密码验证
      if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入账号和密码')),
        );
        return;
      }
    } else {
      // 人脸验证
      if (_faceImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请拍摄人脸照片')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_tabController.index == 0) {
        // 账号密码验证
        final hashedPassword = md5.convert(utf8.encode(_passwordController.text)).toString();
        await _service.updatePointStatus(_usernameController.text, hashedPassword, widget.point['pointCode'].toString());
      } else {
        // 人脸验证
        final String base64Image = base64Encode(_faceImage!);
        await _service.login(_usernameController.text, null, base64Image);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color.fromARGB(255, 2, 189, 83), content: Text('复核成功', style: TextStyle(color: Colors.white))),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/outlets/box-scan',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('复核失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: appCustomBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 押运线路信息
            customBodyHeader(widget.boxCodes.length, widget.point['pointCode'].toString()),
            // 账号密码以及人脸验证切换栏
            Container(
              margin: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF29A8FF),
                unselectedLabelColor: const Color(0xFF666666),
                indicatorColor: const Color(0xFF29A8FF),
                tabs: const [
                  Tab(text: '账号密码验证'),
                  Tab(text: '人脸验证'),
                ],
              ),
            ),
            // Tab内容
            Container(
              height: 200, // 固定高度避免布局问题
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 账号密码验证
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: '账号',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF29A8FF), width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF29A8FF), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF29A8FF), width: 1.0),
                            ),
                            labelStyle: TextStyle(color: Color(0xFF666666)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: '密码',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF29A8FF), width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF29A8FF), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF29A8FF), width: 1.0),
                            ),
                            labelStyle: TextStyle(color: Color(0xFF666666)),
                          ),
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),
                  // 人脸验证
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          FaceScanWidget(
                            onTap: _takePicture,
                            width: 300,
                            height: 200,
                            frameColor: Colors.blue,
                            iconColor: Colors.blue,
                            iconSize: 120,
                            hintText: '点击进行人脸拍照',
                            imageBase64: _faceImage != null ? base64Encode(_faceImage!) : null,
                            onDelete: () {
                              setState(() {
                                _faceImage = null;
                              });
                            },
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 底部留白，确保键盘弹起时有足够空间
            // const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF29A8FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('提交复核'),
        ),
      ),
    );
  }
} 