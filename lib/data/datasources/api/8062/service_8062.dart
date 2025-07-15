import 'package:itms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:itms_mobile/core/utils/password_encrypt.dart';
import 'package:itms_mobile/core/config/env.dart';

/// 8062服务接口部分
class Service8062 {
  Service8062()
      : _dioService =
            DioServiceManager().getService('${Env.config.apiBaseUrl}:18082');

  final DioService _dioService;

  Service8062._(this._dioService);

  static Future<Service8062> create() async {
    final config = await Env.config;
    return Service8062._(
        DioServiceManager().getService('${config.apiBaseUrl}:18082'));
  }

  /// 用户登陆
  /// @param username 用户名
  /// @param password 密码
  /// @param faceImage 人脸图片（可选）
  Future<Map<String, dynamic>> login(String username, String? password,
      [String? faceImage]) async {
    return _dioService.post(
      '/auth/callback/login/mobile',
      body: <String, dynamic>{
        'username': username,
        'password': password != null
            ? passwordEncrypt(password, ENCRYPT_ENUM['MD5_SALT']!)
            : '',
        if (faceImage != null) 'faceImage': faceImage,
      },
    );
  }

  /// 老的登录方式
  Future<Map<String, dynamic>> accountLogin(
      String username, String? password) async {
    return _dioService.post(
      '/auth/callback/login',
      body: <String, dynamic>{'username': username, 'password': password},
    );
  }

  /// TODO: 本地接口测试 查询搬运任务
  Future<Map<String, dynamic>> qryJobStatus() async {
    return _dioService.get('/storage/data/job-page');
  }

  /// 仓储库区库位查询
  Future<Map<String, dynamic>> qryWarehousing(String areaId) async {
    return _dioService.get('/storage/v2/area/qryWarehousing',
        queryParameters: <String, String>{'areaId': areaId});
  }

  /// 分页查询搬运任务信息
  Future<Map<String, dynamic>> qryJobByParams(
      Map<String, dynamic> params) async {
    return _dioService
        .get('/job/v2/job/qryJobByParams', queryParameters: <String, dynamic>{
      if (params['status'] != '') 'status': params['status'],
      if (params['operateType'] != '') 'operateType': params['operateType'],
      'curPage': params['curPage'],
      'pageSize': params['pageSize']
    });
  }

  /// 下发搬运指令
  Future<Map<String, dynamic>> qryLineByEscortNo(
      Map<String, dynamic> params) async {
    return _dioService
        .post('/storage/v2/workJob/launchCarry', body: <String, dynamic>{
      'operateType': params['operateType'], // 作业类型：location2location-库位到库位搬运
      'origCell': params['origCell'], // 起始库位
      'destCell': params['destCell'], // 终点库位
      'carryContainerType': params['carryContainerType'], // 搬运容器类型
      'carryContainerId': params['carryContainerId'] // 搬运容器编号
    });
  }

  /// 取消搬运任务
  Future<Map<String, dynamic>> getEscortInfo(String jobId) async {
    return _dioService.get('/job/v2Inner/device/cancelJob',
        queryParameters: <String, String>{'jobId': jobId});
  }

  /// 重试搬运任务
  Future<Map<String, dynamic>> retryJob(String jobId) async {
    return _dioService.get('/job/v2Inner/device/retryJob',
        queryParameters: <String, String>{'jobId': jobId});
  }

  /// 人工完成
  Future<Map<String, dynamic>> manualCompleteJob(
      Map<String, dynamic> params) async {
    return _dioService
        .post('/job/v2Inner/device/manualCompleteJob', body: <String, dynamic>{
      'jobId': params['jobId'],
      'origCell': params['origCell'],
      'destCell': params['destCell']
    });
  }
}
