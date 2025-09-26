import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// 海康威视扫码组件
class HikvisionScannerWidget extends StatefulWidget {
  /// 扫描结果回调函数
  final Function(String) onScanResult;
  
  /// 扫描错误回调函数
  final Function(String)? onScanError;
  
  /// 是否自动开始扫描
  final bool autoStart;
  
  /// 是否在扫描成功后自动开始下一次扫描
  final bool autoRestart;
  
  /// 是否开启提示音
  final bool enableTone;
  
  /// 是否开启震动
  final bool enableVibrate;
  
  /// 是否开启连续扫码
  final bool enableContinuousScan;
  
  /// 自定义扫描按钮
  final Widget? scanButton;
  
  /// 自定义结果显示组件
  final Widget Function(String)? resultBuilder;
  
  /// 自定义错误显示组件
  final Widget Function(String)? errorBuilder;
  
  /// 自定义加载状态显示组件
  final Widget? loadingBuilder;
  
  /// 是否显示“开关”按钮（某些场景不需要暴露）
  final bool showSwitchButton;

  const HikvisionScannerWidget({
    Key? key,
    required this.onScanResult,
    this.onScanError,
    this.autoStart = false,
    this.autoRestart = true,
    this.enableTone = true,
    this.enableVibrate = true,
    this.enableContinuousScan = false,
    this.scanButton,
    this.resultBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.showSwitchButton = true,
  }) : super(key: key);

  @override
  State<HikvisionScannerWidget> createState() => _HikvisionScannerWidgetState();
}

class _HikvisionScannerWidgetState extends State<HikvisionScannerWidget> {
  static const platform = MethodChannel('com.example.itms_mobile/hikvision_scanner');
  static const eventChannel = EventChannel('com.example.itms_mobile/hikvision_scanner_events');
  
  String _scanResult = '未扫描';
  bool _isScanning = false;
  bool _isInitialized = false;
  String _errorMessage = '';
  StreamSubscription? _eventSubscription;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  /// 初始化扫码器
  Future<void> _initializeScanner() async {
    try {
      developer.log('开始初始化设备扫码器（使用广播模式）...', name: 'HikvisionScanner');
      
      final bool? result = await platform.invokeMethod('initScanner');
      if (result == true) {
        setState(() {
          _isInitialized = true;
          _errorMessage = '';
        });
        
        // 设置扫码器配置
        await _configureScanner();
        
        // 设置事件监听
        _setupEventChannel();
        
        // 如果设置了自动开始，则开始扫描
        if (widget.autoStart) {
          _startScan();
        }
        
        developer.log('设备扫码器初始化成功（使用广播模式）', name: 'HikvisionScanner');
      } else {
        setState(() {
          _errorMessage = '扫码器初始化失败：广播接收器未响应';
        });
        widget.onScanError?.call(_errorMessage);
        developer.log('扫码器初始化失败：广播接收器未响应', name: 'HikvisionScanner');
      }
    } on PlatformException catch (e) {
      String errorMsg = '初始化扫码器失败';
      
      switch (e.code) {
        case 'INIT_ERROR':
          errorMsg = '初始化扫码器失败：${e.message}';
          break;
        default:
          errorMsg = '初始化扫码器失败：${e.message}';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isRetrying = false;
      });
      widget.onScanError?.call(_errorMessage);
      developer.log('初始化扫码器失败: $errorMsg', name: 'HikvisionScanner');
    } catch (e) {
      setState(() {
        _errorMessage = '初始化扫码器失败: $e';
        _isRetrying = false;
      });
      widget.onScanError?.call(_errorMessage);
      developer.log('初始化扫码器失败: $e', name: 'HikvisionScanner');
    }
  }

  /// 配置扫码器
  Future<void> _configureScanner() async {
    try {
      // 在广播模式下，这些配置由系统控制，但仍调用以保持接口一致性
      await platform.invokeMethod<bool>('setTone', {'enabled': widget.enableTone});
      await platform.invokeMethod<bool>('setVibrate', {'enabled': widget.enableVibrate});
      await platform.invokeMethod<bool>('setContinuousScan', {'enabled': widget.enableContinuousScan});
      
      developer.log('扫码器配置完成（广播模式，由系统控制）', name: 'HikvisionScanner');
    } catch (e) {
      developer.log('配置扫码器失败: $e', name: 'HikvisionScanner');
    }
  }

  /// 设置事件通道监听
  void _setupEventChannel() {
    _eventSubscription = eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (mounted) {
          setState(() {
            _scanResult = event.toString();
            _errorMessage = '';
            _isScanning = false;
          });
          
          // 调用回调函数
          widget.onScanResult(_scanResult);
          
          // 如果设置了自动重启且不是连续扫码模式，则开始新的扫描
          if (widget.autoRestart && !widget.enableContinuousScan) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _startScan();
              }
            });
          }
          
          developer.log('扫码结果: $_scanResult', name: 'HikvisionScanner');
        } else {
          developer.log('组件未挂载，忽略扫码结果', name: 'HikvisionScanner');
        }
      },
      onError: (dynamic error) {
        if (mounted) {
          setState(() {
            _errorMessage = "扫码错误: $error";
            _isScanning = false;
          });
          widget.onScanError?.call(_errorMessage);
          developer.log('扫码错误: $error', name: 'HikvisionScanner');
        }
      },
      cancelOnError: false,
    );
  }

  /// 开始扫描
  Future<void> _startScan() async {
    if (!mounted || _isScanning || !_isInitialized) return;
    
    try {
      await platform.invokeMethod<bool>('startScan');
      if (mounted) {
        setState(() {
          _isScanning = true;
          _errorMessage = '';
        });
        developer.log('开始扫码', name: 'HikvisionScanner');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "开始扫描失败: $e";
          _isScanning = false;
        });
        widget.onScanError?.call(_errorMessage);
        developer.log('开始扫描失败: $e', name: 'HikvisionScanner');
      }
    }
  }

  /// 停止扫描
  Future<void> _stopScan() async {
    if (!_isScanning) return;
    
    try {
      await platform.invokeMethod<bool>('stopScan');
      if (mounted) {
        setState(() {
          _isScanning = false;
          _errorMessage = '';
        });
        developer.log('停止扫码', name: 'HikvisionScanner');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "停止扫描失败: $e";
        });
        widget.onScanError?.call(_errorMessage);
        developer.log('停止扫描失败: $e', name: 'HikvisionScanner');
      }
    }
  }

  /// 切换扫描状态
  Future<void> _toggleScan() async {
    if (_isScanning) {
      await _stopScan();
    } else {
      await _startScan();
    }
  }

  /// 设置扫码开关
  Future<void> _setScanSwitch(bool enabled) async {
    try {
      await platform.invokeMethod<bool>('setScanSwitch', {'enabled': enabled});
      developer.log('设置扫码开关: $enabled', name: 'HikvisionScanner');
    } catch (e) {
      developer.log('设置扫码开关失败: $e', name: 'HikvisionScanner');
    }
  }

  /// 重试初始化扫码器
  Future<void> _retryInitialize() async {
    if (_isRetrying) return;
    
    setState(() {
      _isRetrying = true;
      _errorMessage = '';
      _isInitialized = false;
    });
    
    developer.log('重试初始化海康威视扫码器...', name: 'HikvisionScanner');
    
    // 等待一段时间后重试
    await Future<void>.delayed(const Duration(seconds: 1));
    await _initializeScanner();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 状态显示
        if (!_isInitialized && _errorMessage.isEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                _isRetrying ? '正在重试初始化扫码器...' : '正在初始化设备扫码器...',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          )
        else if (_errorMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  '设备扫码器初始化失败',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _retryInitialize,
                  icon: _isRetrying 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                  label: Text(_isRetrying ? '重试中...' : '重试'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else if (_isScanning && widget.loadingBuilder != null)
          widget.loadingBuilder!
        else if (widget.resultBuilder != null)
          widget.resultBuilder!(_scanResult)
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, size: 48, color: Colors.blue),
                const SizedBox(height: 8),
                Text(
                  _scanResult,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _isScanning ? '正在扫描...' : '点击按钮开始扫描',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        // 扫描按钮
        if (widget.scanButton != null)
          widget.scanButton!
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isInitialized ? _toggleScan : null,
                icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
                label: Text(_isScanning ? '停止扫描' : '开始扫描'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              if (_isInitialized && widget.showSwitchButton)
                ElevatedButton.icon(
                  onPressed: () => _setScanSwitch(!_isScanning),
                  icon: const Icon(Icons.settings),
                  label: const Text('开关'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// 海康威视扫码服务类
class HikvisionScannerService {
  static const platform = MethodChannel('com.example.itms_mobile/hikvision_scanner');
  
  /// 初始化扫码器
  static Future<bool> init() async {
    try {
      final bool? result = await platform.invokeMethod('initScanner');
      return result ?? false;
    } catch (e) {
      developer.log('初始化扫码器失败: $e', name: 'HikvisionScannerService');
      return false;
    }
  }
  
  /// 开始扫描
  static Future<bool> startScan() async {
    try {
      final bool? result = await platform.invokeMethod('startScan');
      return result ?? false;
    } catch (e) {
      developer.log('开始扫描失败: $e', name: 'HikvisionScannerService');
      return false;
    }
  }
  
  /// 停止扫描
  static Future<bool> stopScan() async {
    try {
      final bool? result = await platform.invokeMethod('stopScan');
      return result ?? false;
    } catch (e) {
      developer.log('停止扫描失败: $e', name: 'HikvisionScannerService');
      return false;
    }
  }
  
  /// 设置扫码开关
  static Future<bool> setScanSwitch(bool enabled) async {
    try {
      final bool? result = await platform.invokeMethod('setScanSwitch', {'enabled': enabled});
      return result ?? false;
    } catch (e) {
      developer.log('设置扫码开关失败: $e', name: 'HikvisionScannerService');
      return false;
    }
  }
  
  /// 获取扫码开关状态
  static Future<bool> isScanSwitch() async {
    try {
      final bool? result = await platform.invokeMethod('isScanSwitch');
      return result ?? false;
    } catch (e) {
      developer.log('获取扫码开关状态失败: $e', name: 'HikvisionScannerService');
      return false;
    }
  }
  
  /// 设置提示音
  static Future<bool> setTone(bool enabled) async {
    try {
      final bool? result = await platform.invokeMethod('setTone', {'enabled': enabled});
      return result ?? false;
    } catch (e) {
      developer.log('设置提示音失败: $e', name: 'HikvisionScannerService');
      return false;
    }
  }
  
  /// 设置震动
  static Future<bool> setVibrate(bool enabled) async {
    try {
      final bool? result = await platform.invokeMethod('setVibrate', {'enabled': enabled});
      return result ?? false;
    } catch (e) {
      developer.log('设置震动失败: $e', name: 'HikvisionScannerService');
      return false;
    }
  }
  
  /// 设置连续扫码
  static Future<bool> setContinuousScan(bool enabled) async {
    try {
      final bool? result = await platform.invokeMethod('setContinuousScan', {'enabled': enabled});
      return result ?? false;
    } catch (e) {
      developer.log('设置连续扫码失败: $e', name: 'HikvisionScannerService');
      return false;
    }
  }
  
  /// 获取广播动作
  static Future<String> getBroadcastAction() async {
    try {
      final String? result = await platform.invokeMethod('getBroadcastAction');
      return result ?? '';
    } catch (e) {
      developer.log('获取广播动作失败: $e', name: 'HikvisionScannerService');
      return '';
    }
  }
  
  /// 获取广播数据标签
  static Future<String> getBroadcastDataLabel() async {
    try {
      final String? result = await platform.invokeMethod('getBroadcastDataLabel');
      return result ?? '';
    } catch (e) {
      developer.log('获取广播数据标签失败: $e', name: 'HikvisionScannerService');
      return '';
    }
  }
}