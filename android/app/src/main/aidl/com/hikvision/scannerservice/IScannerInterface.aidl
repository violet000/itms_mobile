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
         *                  2-广播
         *                  3-剪贴板
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
}
