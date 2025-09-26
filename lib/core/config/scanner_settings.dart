import 'package:shared_preferences/shared_preferences.dart';

/// 全局扫码配置
class ScannerSettings {
  static const String _keyEnableTone = 'scanner_enable_tone';
  static const String _keyEnableVibrate = 'scanner_enable_vibrate';
  static const String _keyEnableContinuous = 'scanner_enable_continuous';
  static const String _keyAutoStart = 'scanner_auto_start';
  static const String _keyAutoRestart = 'scanner_auto_restart';

  bool enableTone;
  bool enableVibrate;
  bool enableContinuousScan;
  bool autoStart;
  bool autoRestart;

  ScannerSettings({
    this.enableTone = true,
    this.enableVibrate = true,
    this.enableContinuousScan = false,
    this.autoStart = false,
    this.autoRestart = true,
  });

  static Future<ScannerSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ScannerSettings(
      enableTone: prefs.getBool(_keyEnableTone) ?? true,
      enableVibrate: prefs.getBool(_keyEnableVibrate) ?? true,
      enableContinuousScan: prefs.getBool(_keyEnableContinuous) ?? false,
      autoStart: prefs.getBool(_keyAutoStart) ?? false,
      autoRestart: prefs.getBool(_keyAutoRestart) ?? true,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableTone, enableTone);
    await prefs.setBool(_keyEnableVibrate, enableVibrate);
    await prefs.setBool(_keyEnableContinuous, enableContinuousScan);
    await prefs.setBool(_keyAutoStart, autoStart);
    await prefs.setBool(_keyAutoRestart, autoRestart);
  }
}

