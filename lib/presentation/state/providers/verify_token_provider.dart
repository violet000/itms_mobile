// 存储/获取token
import 'package:flutter/foundation.dart';
import 'package:itms_mobile/data/datasources/interceptor/dio_service.dart';

class VerifyTokenProvider extends ChangeNotifier {
  String? access_token;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userInfo; // 添加用户详细信息
  final DioServiceManager _dioManager = DioServiceManager();
  
  VerifyTokenProvider({required this.access_token});

  // 设置token
  void setToken(String token) {
    access_token = token;
    // 自动更新所有 DioService 实例的 access_token
    _dioManager.setAccessTokenForAll(token);
    notifyListeners();
  }

  // 获取token
  String? getToken() => access_token;

  // 清除token
  void clearToken() {
    access_token = '';
    _userData = null;
    _userInfo = null; // 清除用户详细信息
    // 清除所有 DioService 实例的 access_token
    _dioManager.clearAccessTokenForAll();
    notifyListeners();
  }

  // 设置用户数据
  void setUserData(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  // 获取用户数据
  Map<String, dynamic>? getUserData() => _userData;

  // 设置用户详细信息
  void setUserInfo(Map<String, dynamic> userInfo) {
    _userInfo = userInfo;
    notifyListeners();
  }

  // 获取用户详细信息
  Map<String, dynamic>? getUserInfo() => _userInfo;

  // 获取 DioServiceManager 实例
  DioServiceManager get dioManager => _dioManager;
}