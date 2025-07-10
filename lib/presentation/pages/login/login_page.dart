import 'package:flutter/material.dart';
import 'package:itms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:itms_mobile/core/utils/hashStr.dart';
import 'package:itms_mobile/presentation/widgets/common/message_toast.dart';
import 'package:itms_mobile/presentation/widgets/common/loading_widget.dart';
import 'dart:ui';
import 'package:itms_mobile/presentation/pages/home/home.dart';
import 'package:itms_mobile/services/storage_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _labelColor = const Color.fromARGB(255, 215, 211, 211).withOpacity(0.5);
  Service18082? _service;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    _usernameController.text = 'admin';
    _passwordController.text = '123456';
    _service = await Service18082.create();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 背景渐变层控件抽取
  Widget _buildBackgroundGradient() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF313AC6), // 顶部 0%
            Color(0xFF04A1F7), // 100%
          ],
          stops: [
            0.0, // #313AC6
            1.0, // #04A1F7
          ],
        ),
      ),
    );
  }

  // 顶部的Logo和APP名称控件抽取
  Widget _buildTopLogoAndAppName() {
    return Expanded(
      flex: 3, // 设置为2，Logo和系统名称占更大的空间
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          // Logo图标
          Image.asset(
            'assets/images/login.png',
            // width: 60, // 移除宽度，以高度为自适应拉伸
            height: 120,
            filterQuality: FilterQuality.high,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          const Text(
            '仓储管理系统',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color.fromARGB(255, 221, 219, 219),
            ),
          ),
          const SizedBox(height: 12)
        ],
      ),
    );
  }

  // 用户名输入框控件抽取
  Widget _buildUsernameInput() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: _labelColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.email_outlined, color: _labelColor, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: '请输入用户名',
                hintStyle: TextStyle(
                  color: _labelColor,
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 14,
                color: _labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 密码输入框控件抽取
  Widget _buildPasswordInput() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: _labelColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.lock_outlined, color: _labelColor, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: '请输入密码',
                hintStyle: TextStyle(
                  color: _labelColor,
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 14,
                color: _labelColor,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: _labelColor,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ],
      ),
    );
  }

  // 忘记密码控件抽取
  Widget _buildForgetPassword() {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
        ),
        child: const Text(
          '忘记密码？',
          style: TextStyle(
            color: Color.fromARGB(255, 230, 228, 228),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // 登录按钮控件抽取
  Widget _buildLoginButton() {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(const Color(0XFFFF86BDFF).withOpacity(0.8)),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                splashFactory: NoSplash.splashFactory,
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '登录',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _handleRegister,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2196F3),
                side: BorderSide(
                  color: _labelColor,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                backgroundColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              child: const Text(
                '注册',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景渐变层
          _buildBackgroundGradient(),
          // 主要内容区域
          SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // 顶部Logo和系统名称
                          _buildTopLogoAndAppName(),
                          // 中间输入框区域
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                // 用户名输入框
                                _buildUsernameInput(),
                                const SizedBox(height: 16),
                                // 密码输入框
                                _buildPasswordInput(),
                                const SizedBox(height: 16),
                                // 忘记密码
                                _buildForgetPassword(),
                              ],
                            ),
                          ),
                          // 底部按钮区域
                          _buildLoginButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 固定在底部的版权信息
          const Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Copyright©深圳市紫金支点技术股份有限公司',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 登录方法的实现
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (mounted) {
        LoadingUtils.showFullScreenLoading(
          context: context,
          text: '登录中...',
        );

        await _service!.accountLogin(
          _usernameController.text,
          MD5Util.generateMd5("${_passwordController.text}messi"),
        );
        LoadingUtils.hideLoading(context);
        if (!mounted) return;
        
        // 登录后，预加载Home数据
        LoadingUtils.showFullScreenLoading(
          context: context,
          text: '正在初始化...',
        );
        
        try {
          // 预加载
          await StorageService.preloadStorageAreas();
        } catch (e) {
          print('预加载仓储数据失败: $e');
        }
        
        if (!mounted) return;
        LoadingUtils.hideLoading(context);
        
        // 页面跳转
        await Navigator.pushReplacement<void, void>(
          context,
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.fastOutSlowIn;
              
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 150),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingUtils.hideLoading(context);
        context.showErrorMessage('登录失败: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 注册方法的实现
  void _handleRegister() {
    context.showErrorMessage('暂时未开发');
  }
}
