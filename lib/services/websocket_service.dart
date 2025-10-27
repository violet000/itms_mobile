import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart' as web_socket;

/// WebSocket 服务类
/// 提供 WebSocket 连接的封装和管理
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  web_socket.WebSocketChannel? _webSocket;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _currentUrl;
  
  // 监听器列表
  final List<Function(String message)> _messageListeners = [];
  
  // 连接状态监听器列表
  final List<Function(bool isConnected)> _connectionStateListeners = [];
  
  /// 添加消息监听器
  void addMessageListener(Function(String message) listener) {
    _messageListeners.add(listener);
  }
  
  /// 移除消息监听器
  void removeMessageListener(Function(String message) listener) {
    _messageListeners.remove(listener);
  }
  
  /// 添加连接状态监听器
  void addConnectionStateListener(Function(bool isConnected) listener) {
    _connectionStateListeners.add(listener);
  }
  
  /// 移除连接状态监听器
  void removeConnectionStateListener(Function(bool isConnected) listener) {
    _connectionStateListeners.remove(listener);
  }
  
  /// 获取 WebSocket 地址
  Future<String?> getWebSocketUrl() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('websocket_url');
  }
  
  /// 设置 WebSocket 地址
  Future<void> setWebSocketUrl(String url) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('websocket_url', url);
  }
  
  /// 获取当前连接状态
  bool get isConnected => _isConnected;
  
  /// 连接 WebSocket
  Future<bool> connect([String? url]) async {
    if (_isConnecting || (_isConnected && _webSocket != null)) {
      if (kDebugMode) {
        print('WebSocket 正在连接或已连接');
      }
      return _isConnected;
    }
    
    try {
      _isConnecting = true;
      
      // 获取 WebSocket URL，如果没有配置则使用默认值
      String wsUrl = url ?? await getWebSocketUrl() ?? 'ws://10.34.12.130:9087/websocket';
      if (wsUrl.isEmpty) {
        if (kDebugMode) {
          print('WebSocket URL 未配置');
        }
        _isConnecting = false;
        return false;
      }
      
      // 确保 URL 格式正确
      if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) {
        wsUrl = 'ws://$wsUrl';
      }
      
      _currentUrl = wsUrl;
      
      if (kDebugMode) {
        print('正在连接 WebSocket: $wsUrl');
      }
      
      final webSocket = web_socket.WebSocketChannel.connect(Uri.parse(wsUrl));
      _webSocket = webSocket;
      
      _subscription = _webSocket!.stream.listen(
        (dynamic message) => _handleMessage(message),
        onError: (dynamic error) => _handleError(error),
        onDone: () => _handleDone(),
        cancelOnError: true,
      );
      
      _isConnected = true;
      _isConnecting = false;
      
      // 通知连接状态变化
      _notifyConnectionState(true);
      
      // 启动心跳
      _startHeartbeat();
      
      if (kDebugMode) {
        print('WebSocket 连接成功');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('WebSocket 连接失败: $e');
      }
      _isConnecting = false;
      _isConnected = false;
      _notifyConnectionState(false);
      
      // 启动自动重连
      _scheduleReconnect();
      
      return false;
    }
  }
  
  /// 处理接收到的消息
  void _handleMessage(dynamic message) {
    try {
      String messageStr;
      if (message is String) {
        messageStr = message;
      } else if (message is List<int>) {
        messageStr = utf8.decode(message);
      } else {
        messageStr = message.toString();
      }
      
      if (kDebugMode) {
        print('收到 WebSocket 消息: $messageStr');
      }
      
      // 通知所有监听器
      for (var listener in _messageListeners) {
        try {
          listener(messageStr);
        } catch (e) {
          if (kDebugMode) {
            print('处理 WebSocket 消息时出错: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('解析 WebSocket 消息时出错: $e');
      }
    }
  }
  
  /// 处理错误
  void _handleError(dynamic error) {
    if (kDebugMode) {
      print('WebSocket 错误: $error');
    }
    
    _isConnected = false;
    _notifyConnectionState(false);
    
    // 启动自动重连
    _scheduleReconnect();
  }
  
  /// 处理连接关闭
  void _handleDone() {
    if (kDebugMode) {
      print('WebSocket 连接已关闭');
    }
    
    _isConnected = false;
    _notifyConnectionState(false);
    
    // 停止心跳
    _stopHeartbeat();
    
    // 启动自动重连
    _scheduleReconnect();
  }
  
  /// 发送消息
  Future<void> sendMessage(String message) async {
    if (!_isConnected || _webSocket == null) {
      if (kDebugMode) {
        print('WebSocket 未连接，无法发送消息');
      }
      return;
    }
    
    try {
      _webSocket!.sink.add(message);
      if (kDebugMode) {
        print('发送 WebSocket 消息: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('发送 WebSocket 消息失败: $e');
      }
    }
  }
  
  /// 关闭连接
  Future<void> disconnect() async {
    if (kDebugMode) {
      print('关闭 WebSocket 连接');
    }
    
    _stopReconnect();
    _stopHeartbeat();
    
    await _subscription?.cancel();
    _subscription = null;
    
    await _webSocket?.sink.close();
    _webSocket = null;
    
    _isConnected = false;
    _isConnecting = false;
    _notifyConnectionState(false);
  }
  
  /// 启动心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _webSocket != null) {
        sendMessage(jsonEncode({'type': 'ping', 'timestamp': DateTime.now().millisecondsSinceEpoch}));
      } else {
        _stopHeartbeat();
      }
    });
  }
  
  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  /// 计划重连
  void _scheduleReconnect() {
    if (_isConnecting) {
      return;
    }
    
    _stopReconnect();
    
    int reconnectCount = 0;
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      reconnectCount++;
      
      if (reconnectCount > 60) {
        // 最多重连 5 分钟
        _stopReconnect();
        return;
      }
      
      if (!_isConnected && !_isConnecting) {
        if (kDebugMode) {
          print('尝试重连 WebSocket ($reconnectCount)');
        }
        connect();
      } else {
        _stopReconnect();
      }
    });
  }
  
  /// 停止重连
  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  /// 通知连接状态变化
  void _notifyConnectionState(bool isConnected) {
    for (var listener in _connectionStateListeners) {
      try {
        listener(isConnected);
      } catch (e) {
        if (kDebugMode) {
          print('通知连接状态时出错: $e');
        }
      }
    }
  }
}