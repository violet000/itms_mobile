// IScannerInterface.aidl
package com.hikvision.scannerservice;

// Declare any non-default types here with import statements

interface IScannerInterface {

        /**
         * 设置扫码开关
         * @param scanSwitch true-开启  false-关闭
         * @return 0-成功  -1-失败
         */
        int setScanSwitch(boolean scanSwitch);

        /**
         * 获取扫码开关
         * @return true-开启  false-关闭
         */
        boolean isScanSwitch();

        /**
         * 设置是否开启提示音
         * @param tone true-开启  false-关闭
         * @return 0-成功  -1-失败
         */
        int setTone(boolean tone);

        /**
         * 获取是否打开提示音
         * @return true-开启  false-关闭
         */
        boolean isTone();

        /**
         * 设置是否开启震动
         * @param vibrate true-开启  false-关闭
         * @return 0-成功  -1-失败
         */
        int setVibrate(boolean vibrate);

        /**
         * 获取是否开启震动
         * @return  true-开启  false-关闭
         */
        boolean isVibrate();

        /**
         * 设置是否开启连续扫码
         * @param continuousScan true-开启  false-关闭
         * @return 0-成功  -1-失败
         */
        int setContinuousScan(boolean continuousScan);

        /**
         * 获取是否开启连续扫码
         * @return true-开启  false-关闭
         */
        boolean isContinuousScan();

        /**
         * 设置扫码超时(连续扫码无效)
         * @param scanTimeout 超时时间，取值范围1~9（s）
         * @return 0-成功  -1-失败
         */
        int setScanTimeout(String scanTimeout);

        /**
         * 获取扫码超时
         * @return 超时时间
         */
        String getScanTimeout();

        /**
         * 设置扫码间隔
         * @param scanInterval 扫码间隔，取值范围10~2000（ms）
         * @return 0-成功  -1-失败
         */
        int setScanInterval(String scanInterval);

        /**
         * 获取扫码间隔
         * @return 扫码间隔
         */
        String getScanInterval();

        /**
         * 设置输出模式
         * @param outputMode 输出模式
         *                  0-焦点
         *                  1-覆盖
         * @return 0-成功  -1-失败
         */
        int setOutputMode(String outputMode);

        /**
         * 获取输出模式
         * @return 输出模式
         */
        String getOutputMode();

        /**
         * 设置广播动作
         * @param broadcastAction 广播动作
         * @return 0-成功  -1-失败
         */
        int setBroadcastAction(String broadcastAction);

        /**
         * 获取广播动作
         * @return 广播动作
         */
        String getBroadcastAction();

        /**
         * 设置广播数据标签
         * @param broadcastDataLabel 广播数据标签
         * @return 0-成功  -1-失败
         */
        int setBroadcastDataLabel(String broadcastDataLabel);

        /**
         * 获取广播数据标签
         * @return 广播数据标签
         */
        String getBroadcastDataLabel();

        /**
         * 设置结束补充符
         * @param endSupplement 结束补充符
         *                  0-无
         *                  1-回车
         *                  2-制表
         *                  3-空格
         * @return 0-成功  -1-失败
         */
        int setEndSupplement(String endSupplement);

        /**
         * 获取结束补充符
         * @return 结束补充符
         */
        String getEndSupplement();

        /**
         * 设置补充模式
         * @param supplementMode 补充模式
         *                  0-键盘
         *                  1-符号
         *                  2-键盘
         * @return 0-成功  -1-失败
         */
        int setSupplementMode(String supplementMode);

        /**
         * 获取补充模式
         * @return 补充模式
         */
        String getSupplementMode();

        /**
         * 设置过滤前缀
         * @param filterPrefix 过滤前缀
         * @return 0-成功  -1-失败
         */
        int setFilterPrefix(String filterPrefix);

        /**
         * 获取过滤前缀
         * @return 过滤前缀
         */
        String getFilterPrefix();

        /**
         * 设置过滤后缀
         * @param filterSuffix 过滤后缀
         * @return 0-成功  -1-失败
         */
        int setFilterSuffix(String filterSuffix);

        /**
         * 获取过滤后缀
         * @return 过滤后缀
         */
        String getFilterSuffix();

        /**
         * 设置最短条码数
         * @param minCodeLength 最短条码数，取值范围0~4096
         * @return 0-成功  -1-失败
         */
        int setMinCodeLength(String minCodeLength);

        /**
         * 获取最短条码数
         * @return 最短条码数
         */
        String getMinCodeLength();

        /**
         * 设置最长条码数
         * @param maxCodeLength 最长条码数，取值范围0~4096
         * @return 最长条码数
         */
        int setMaxCodeLength(String maxCodeLength);

        /**
         * 获取最长条码数
         * @return 最长条码数
         */
        String getMaxCodeLength();

        /**
         * 设置重复过滤超时
         * @param filterTimeout 重复过滤超时，取值范围0~9（s），其中0代表关闭
         * @return 0-成功  -1-失败
         */
        int setFilterTimeout(String filterTimeout);

        /**
         * 获取重复过滤超时
         * @return 重复过滤超时
         */
        String getFilterTimeout();

        /**
         * 开始/结束扫码
         */
        void scan();

        /**
         * 设置条码
         * @param list 条码列表
         * @return 0-成功  -1-失败
         */
        int setBarCode(in List<String> list);

        /**
         * 获取条码列表
         * @return 条码列表
         */
        List<String> getBarCode();

        /**
         * 获取SDK版本号
         * @return SDK版本号
         */
        long getSdkVersion();

        /**
         * 设置触发方式
         * @param mode 触发方式
         *             0-左侧扫码键
         *             1-右侧扫码键
         *             2-左右都支持
         * @return 0-成功  -1-失败
         */
        int setTriggerMode(String mode);

        /**
         * 获取触发方式
         * @return 触发方式
         */
        String getTriggerMode();

        /**
         * 设置是否开启指示灯
         * @param lamp true-开启  false-关闭
         * @return 0-成功  -1-失败
         */
        int setLamp(boolean lamp);

        /**
         * 获取是否开启指示灯
         * @return  true-开启  false-关闭
         */
        boolean isLamp();

        /**
         * 设置广播开关
         * @param broadcastSwitch true-开启  false-关闭
         * @return 0-成功  -1-失败
         */
        int setBroadcastSwitch(boolean broadcastSwitch);

        /**
         * 获取广播开关
         * @return true-开启  false-关闭
         */
        boolean isBroadcastSwitch();

        /**
         * 设置原始数据
         * @param broadcastRawData 原始数据
         * @return 0-成功  -1-失败
         */
        int setBroadcastRawData(String broadcastRawData);

        /**
         * 获取原始数据
         * @return 原始数据
         */
        String getBroadcastRawData();

        /**
         * 设置类型
         * @param broadcastCodeType 类型
         * @return 0-成功  -1-失败
         */
        int setBroadcastCodeType(String broadcastCodeType);

        /**
         * 获取类型
         * @return 类型
         */
        String getBroadcastCodeType();

        /**
         * 设置类型名称
         * @param broadcastCodeTypeName 类型名称
         * @return 0-成功  -1-失败
         */
        int setBroadcastCodeTypeName(String broadcastCodeTypeName);

        /**
         * 获取类型名称
         * @return 类型名称
         */
        String getBroadcastCodeTypeName();

        /**
         * 设置开始广播
         * @param broadcastStart 开始广播
         * @return 0-成功  -1-失败
         */
        int setBroadcastStart(String broadcastStart);

        /**
         * 获取开始广播
         * @return 开始广播
         */
        String getBroadcastStart();

        /**
         * 设置结束广播
         * @param broadcastEnd 结束广播
         * @return 0-成功  -1-失败
         */
        int setBroadcastEnd(String broadcastEnd);

        /**
         * 获取结束广播
         * @return 结束广播
         */
        String getBroadcastEnd();

        /**
         * 设置添加前缀
         * @param addPrefix 添加前缀
         * @return 0-成功  -1-失败
         */
        int setAddPrefix(String addPrefix);

        /**
         * 获取添加前缀
         * @return 添加前缀
         */
        String getAddPrefix();

        /**
         * 设置添加后缀
         * @param addSuffix 添加后缀
         * @return 0-成功  -1-失败
         */
        int setAddSuffix(String addSuffix);

        /**
         * 获取添加后缀
         * @return 添加后缀
         */
        String getAddSuffix();

        /**
         * 设置截取方式
         * @param captureMode 截取方式
         *                  0-按位置
         *                  1-字符串
         * @return 0-成功  -1-失败
         */
        int setCaptureMode(String captureMode);

        /**
         * 获取截取方式
         * @return 截取方式
         */
        String getCaptureMode();

        /**
         * 设置开始截取位置
         * @param startPosition 开始截取位置
         * @return 0-成功  -1-失败
         */
        int setCaptureStartPosition(String startPosition);

        /**
         * 获取开始截取位置
         * @return 开始截取位置
         */
        String getCaptureStartPosition();

        /**
         * 设置结束截取位置
         * @param endPosition 结束截取位置
         * @return 0-成功  -1-失败
         */
        int setCaptureEndPosition(String endPosition);

        /**
         * 获取结束截取位置
         * @return 结束截取位置
         */
        String getCaptureEndPosition();

        /**
         * 设置开始截取字符
         * @param startCharacter 开始截取字符
         * @return 0-成功  -1-失败
         */
        int setCaptureStartCharacter(String startCharacter);

        /**
         * 获取开始截取字符
         * @return 开始截取字符
         */
        String getCaptureStartCharacter();

        /**
         * 设置结束截取字符
         * @param endCharacter 结束截取字符
         * @return 0-成功  -1-失败
         */
        int setCaptureEndCharacter(String endCharacter);

        /**
         * 获取结束截取字符
         * @return 结束截取字符
         */
        String getCaptureEndCharacter();

        /**
         * 设置字符替换原始字符
         * @param originalCharacter 字符替换原始字符
         * @return 0-成功  -1-失败
         */
        int setOriginalCharacter(String originalCharacter);

        /**
         * 获取字符替换原始字符
         * @return 字符替换原始字符
         */
        String getOriginalCharacter();

        /**
         * 设置字符替换目标字符
         * @param replacedCharacter 字符替换目标字符
         * @return 0-成功  -1-失败
         */
        int setReplacedCharacter(String replacedCharacter);

        /**
         * 获取字符替换目标字符
         * @return 字符替换目标字符
         */
        String getReplacedCharacter();

        /**
         * 设置编码格式
         * @param codeFormat 编码格式
         *                  1-自动
         *                  2-UTF-8
         *                  4-GB2312
         *                  8-GBK
         * @return 0-成功  -1-失败
         */
        int setCodeFormat(String codeFormat);

        /**
         * 获取编码格式
         * @return 编码格式
         */
        String getCodeFormat();
}
