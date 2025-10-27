package com.example.itms_mobile

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.ServiceConnection
import android.os.Bundle
import android.os.IBinder
import android.os.RemoteException
import android.text.TextUtils
import android.util.Log
import android.view.View
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import com.hikvision.scannerservice.IScannerInterface

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    
    // Flutter方法通道
    private val CHANNEL = "com.example.itms_mobile/hikvision_scanner"
    private val EVENT_CHANNEL = "com.example.itms_mobile/hikvision_scanner_events"
    
    // 设备扫码广播相关
    private val SCAN_OUTPUT_ACTION = "com.service.scanner.data"
    private val SCAN_START_ACTION = "com.service.scanner.start.scanning"
    private val SCAN_STOP_ACTION = "com.service.scanner.stop.scanning"
    private val BARCODE_KEY = "ScanCode"
    private val BARCODE_BYTES_KEY = "ScanCodeBytes"
    private val CODE_TYPE_KEY = "ScanCodeType"
    
    private var eventSink: EventChannel.EventSink? = null
    private var isScannerInitialized = false
    private var initResultCallback: MethodChannel.Result? = null
    
    // 扫码广播接收器
    private val mScanBroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action
            Log.i(TAG, "收到广播: $action")
            
            if (action == SCAN_OUTPUT_ACTION) {
                val bundle = intent.extras
                if (bundle != null) {
                    val barcode = bundle.getString(BARCODE_KEY)
                    val barcodeBytes = bundle.getByteArray(BARCODE_BYTES_KEY)
                    val codeType = bundle.getString(CODE_TYPE_KEY, "Unknown")
                    
                    Log.i(TAG, "扫码结果: barcode=$barcode, codeType=$codeType, barcodeBytes=${barcodeBytes?.size} bytes")
                    
                    // 发送扫码结果到Flutter
                    if (!barcode.isNullOrEmpty()) {
                        eventSink?.success(barcode)
                    }
                }
            }
        }
    }
    

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate")
        
        // 隐藏底部导航栏
        hideNavigationBar()
        
        // 注册扫码广播接收器
        registerScanBroadcastReceiver()
    }
    
    override fun onResume() {
        super.onResume()
        // 每次恢复时重新隐藏导航栏
        hideNavigationBar()
    }
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            // 当窗口获得焦点时重新隐藏导航栏
            hideNavigationBar()
        }
    }
    
    /// 隐藏底部导航栏
    private fun hideNavigationBar() {
        window?.decorView?.let { decorView ->
            // 使用新的 WindowInsets API
            WindowCompat.setDecorFitsSystemWindows(window!!, false)
            val controller = WindowInsetsControllerCompat(window!!, decorView)
            
            // 隐藏系统UI栏，但保持状态栏可见
            controller.hide(WindowInsetsCompat.Type.navigationBars())
            controller.systemBarsBehavior = 
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            
            // 设置全屏标志（向后兼容）
            decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_FULLSCREEN 
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            )
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 设置方法通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initScanner" -> {
                    initScanner(result)
                }
                "startScan" -> {
                    startScan(result)
                }
                "stopScan" -> {
                    stopScan(result)
                }
                "setScanSwitch" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    setScanSwitch(enabled, result)
                }
                "isScanSwitch" -> {
                    isScanSwitch(result)
                }
                "setTone" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    setTone(enabled, result)
                }
                "setVibrate" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    setVibrate(enabled, result)
                }
                "setContinuousScan" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    setContinuousScan(enabled, result)
                }
                "getBroadcastAction" -> {
                    getBroadcastAction(result)
                }
                "getBroadcastDataLabel" -> {
                    getBroadcastDataLabel(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // 设置事件通道
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    Log.i(TAG, "事件通道监听开始")
                }
                
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.i(TAG, "事件通道监听取消")
                }
            }
        )
    }
    
    private fun registerScanBroadcastReceiver() {
        try {
            val intentFilter = IntentFilter()
            intentFilter.addAction(SCAN_OUTPUT_ACTION)
            registerReceiver(mScanBroadcastReceiver, intentFilter)
            Log.i(TAG, "扫码广播接收器注册成功")
        } catch (e: Exception) {
            Log.e(TAG, "注册扫码广播接收器失败", e)
        }
    }
    
    
    // Flutter方法实现
    private fun initScanner(result: MethodChannel.Result) {
        try {
            Log.i(TAG, "开始初始化扫码器")
            
            // 使用设备扫码广播，无需绑定服务
            isScannerInitialized = true
            Log.i(TAG, "扫码器初始化成功（使用设备扫码广播）")
            result.success(true)
            
        } catch (e: Exception) {
            Log.e(TAG, "初始化扫码器异常", e)
            result.error("INIT_ERROR", "初始化扫码器失败: ${e.message}", null)
        }
    }
    
    private fun startScan(result: MethodChannel.Result) {
        try {
            val intent = Intent(SCAN_START_ACTION)
            sendBroadcast(intent)
            Log.i(TAG, "发送开始扫码广播")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "开始扫码失败", e)
            result.error("SCAN_ERROR", "开始扫码失败: ${e.message}", null)
        }
    }
    
    private fun stopScan(result: MethodChannel.Result) {
        try {
            val intent = Intent(SCAN_STOP_ACTION)
            sendBroadcast(intent)
            Log.i(TAG, "发送停止扫码广播")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "停止扫码失败", e)
            result.error("STOP_ERROR", "停止扫码失败: ${e.message}", null)
        }
    }
    
    private fun setScanSwitch(enabled: Boolean, result: MethodChannel.Result) {
        try {
            val intent = Intent(if (enabled) SCAN_START_ACTION else SCAN_STOP_ACTION)
            sendBroadcast(intent)
            Log.i(TAG, "设置扫码开关: $enabled")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "设置扫码开关失败", e)
            result.error("SET_SWITCH_ERROR", "设置扫码开关失败: ${e.message}", null)
        }
    }
    
    private fun isScanSwitch(result: MethodChannel.Result) {
        try {
            // 设备扫码广播模式下，无法直接获取开关状态，返回true表示可用
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "获取扫码开关状态失败", e)
            result.error("GET_SWITCH_ERROR", "获取扫码开关状态失败: ${e.message}", null)
        }
    }
    
    private fun setTone(enabled: Boolean, result: MethodChannel.Result) {
        try {
            // 设备扫码广播模式下，提示音由系统控制，这里直接返回成功
            Log.i(TAG, "设置提示音: $enabled (由系统控制)")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "设置提示音失败", e)
            result.error("SET_TONE_ERROR", "设置提示音失败: ${e.message}", null)
        }
    }
    
    private fun setVibrate(enabled: Boolean, result: MethodChannel.Result) {
        try {
            // 设备扫码广播模式下，震动由系统控制，这里直接返回成功
            Log.i(TAG, "设置震动: $enabled (由系统控制)")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "设置震动失败", e)
            result.error("SET_VIBRATE_ERROR", "设置震动失败: ${e.message}", null)
        }
    }
    
    private fun setContinuousScan(enabled: Boolean, result: MethodChannel.Result) {
        try {
            // 设备扫码广播模式下，连续扫码由系统控制，这里直接返回成功
            Log.i(TAG, "设置连续扫码: $enabled (由系统控制)")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "设置连续扫码失败", e)
            result.error("SET_CONTINUOUS_ERROR", "设置连续扫码失败: ${e.message}", null)
        }
    }
    
    private fun getBroadcastAction(result: MethodChannel.Result) {
        try {
            result.success(SCAN_OUTPUT_ACTION)
        } catch (e: Exception) {
            Log.e(TAG, "获取广播动作失败", e)
            result.error("GET_ACTION_ERROR", "获取广播动作失败: ${e.message}", null)
        }
    }
    
    private fun getBroadcastDataLabel(result: MethodChannel.Result) {
        try {
            result.success(BARCODE_KEY)
        } catch (e: Exception) {
            Log.e(TAG, "获取广播标签失败", e)
            result.error("GET_LABEL_ERROR", "获取广播标签失败: ${e.message}", null)
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(mScanBroadcastReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "清理资源失败", e)
        }
        super.onDestroy()
    }
}