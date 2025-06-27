import 'package:flutter/material.dart';
import 'dart:ui';

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


  @override
  void initState() {
    super.initState();
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
            Color.fromARGB(255, 6, 76, 162),
            Color.fromARGB(255, 26, 128, 245),
            Color.fromARGB(255, 60, 154, 255),
          ],
          stops: [0.3, 0.8, 1.0],
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
            color:  _labelColor,
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
            color:  _labelColor,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 112, 195, 240).withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                )
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
        ],
      ),
    );
  }

  // 登录方法的实现
  Future<void> _handleLogin() async {
    // 注释掉用户名和密码的校验
    // if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('请输入用户名和密码'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    //   return;
    // }

    setState(() {
      _isLoading = true;
    });

    try {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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

  // 注册方法的实现
  void _handleRegister() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('注册功能开发中...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
