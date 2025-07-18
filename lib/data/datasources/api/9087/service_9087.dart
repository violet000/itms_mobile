import 'package:itms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:itms_mobile/core/config/env.dart';

/// 9087服务接口部分
class Service9087 {
  Service9087()
      : _dioService =
            DioServiceManager().getService('${Env.config.apiBaseUrl}:9087');

  final DioService _dioService;

  Service9087._(this._dioService);

  static Future<Service9087> create() async {
    final config = await Env.config;
    return Service9087._(
        DioServiceManager().getService('${config.apiBaseUrl}:9087'));
  }

  ///  TODO: 本地接口测试 查询仓储库位信息
  Future<Map<String, dynamic>> getStorageAreas() async {
    return _dioService.get('/storage/data/storage-areas');
  }

  /// 仓储库区库位查询
  Future<Map<String, dynamic>> qryWarehousing(String areaId) async {
    return _dioService.get('/storage/v2/area/qryWarehousing',
        queryParameters: <String, String>{'areaId': areaId});
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

  /// 托盘管理查询
  /// 参数：
  /// shelfId - 托盘编号
  /// shelfType - 货架类型 0-固定货架 1-笼车 2-托盘 3-虚拟货架(侧推位,工作位,排队位,抱夹式AGV位置)
  /// status - 货架状态 0-禁用 1-空闲 2-锁定 3-占用 4 - 满载
  /// clrCenterNo - 所属仓库编号
  /// locationId - 所在地标ID
  /// note - 备注
  /// curPage - 当前页
  /// pageSize - 页面大小
  Future<Map<String, dynamic>> qryPageByParams(
      Map<String, dynamic> params) async {
    return _dioService.get('/warehousing/v2/shelf/qryPageByParams',
        queryParameters: <String, dynamic>{
          'shelfId': params['shelfId'],
          'shelfType': params['shelfType'],
          'status': params['status'],
          'clrCenterNo': params['clrCenterNo'],
          'locationId': params['locationId'],
          'note': params['note'],
          'curPage': params['curPage'],
          'pageSize': params['pageSize']
        });
  }


  /// 新增托盘
  /// 参数：
  /// shelfId - 托盘编号
  /// shelfType - 货架类型 0-固定货架 1-笼车 2-托盘 3-虚拟货架(侧推位,工作位,排队位,抱夹式AGV位置)
  /// status - 货架状态 0-禁用 1-空闲 2-锁定 3-占用 4 - 满载
  /// clrCenterNo - 所属仓库编号
  /// locationId - 所在地标ID
  /// note - 备注
  Future<Map<String, dynamic>> addShelf(Map<String, dynamic> params) async {
    return _dioService.post('/warehousing/v2/shelf/addShelfInfo', body: params);
  }

  /// 修改托盘
  /// 参数：
  /// shelfId - 托盘编号
  /// shelfType - 货架类型 0-固定货架 1-笼车 2-托盘 3-虚拟货架(侧推位,工作位,排队位,抱夹式AGV位置)
  /// status - 货架状态 0-禁用 1-空闲 2-锁定 3-占用 4 - 满载
  /// clrCenterNo - 所属仓库编号
  /// locationId - 所在地标ID
  /// note - 备注
  /// 
  Future<Map<String, dynamic>> updateShelf(Map<String, dynamic> params) async {
    return _dioService.post('/storage/v2/shelf/updateShelfInfo', body: params);
  }

  /// 地标管理查询
  /// 参数：
  /// id - 库区编号
  /// locationType - 地标类型 0-NULL(空) 1-FIXED_SHELF（固定货架) 2-MOVE_SHELF(移动货架) 3-虚拟库位(潜伏式AGV) 4-CHARGER(充电桩))
  /// status - 地标状态 0-禁用 1-空闲 2-锁定 3-占用
  /// areaId - 所属库区ID
  Future<Map<String, dynamic>> qryAllByParams(Map<String, dynamic> params) async {
    return _dioService.get('/storage/v2/location/qryAllByParams', queryParameters: params);
  }

}
