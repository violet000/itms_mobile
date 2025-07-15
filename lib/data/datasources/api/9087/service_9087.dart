import 'package:itms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:itms_mobile/core/config/env.dart';

/// 9087服务接口部分
class Service9087 {
  Service9087()
      : _dioService =
            DioServiceManager().getService('${Env.config.apiBaseUrl}:18082');

  final DioService _dioService;

  Service9087._(this._dioService);

  static Future<Service9087> create() async {
    final config = await Env.config;
    return Service9087._(
        DioServiceManager().getService('${config.apiBaseUrl}:18082'));
  }

  ///  TODO: 本地接口测试 查询仓储库位信息
  Future<Map<String, dynamic>> getStorageAreas() async {
    return _dioService.get('/storage/data/storage-areas');
  }

  /// 仓储库区库位查询
  Future<Map<String, dynamic>> qryWarehousing(String areaId) async {
    return _dioService.get('/storage/v2/area/qryWarehousing', queryParameters: <String, String>{'areaId': areaId});
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
}
