#!/bin/bash

echo "正在重新生成启动屏资源..."

# 清理之前的启动屏资源
flutter clean

# 重新生成启动屏
flutter pub get
flutter pub run flutter_native_splash:create

# 重新构建项目
flutter build apk --debug
flutter build ios --debug

echo "启动屏资源重新生成完成！" 