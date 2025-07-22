import 'dart:io';
import 'package:dio/dio.dart';
import 'package:itms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:itms_mobile/core/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 9087服务接口部分
class Service9087 {
  static const String vmsKey = 'network_vms_ip';

  final DioService _dioService;
  final String _baseUrl;

  Service9087._(this._dioService, this._baseUrl);

  static Future<Service9087> create() async {
    final prefs = await SharedPreferences.getInstance();
    final vmsIp = prefs.getString(vmsKey) ?? '${Env.config.apiBaseUrl}:9087';
    final baseUrl = vmsIp.startsWith('http') ? vmsIp : 'http://$vmsIp';
    return Service9087._(
      DioServiceManager().getService(baseUrl),
      baseUrl,
    );
  }

  /// 上传地标文件
  Future<Map<String, dynamic>> addLocationByFile(File file) async {
    FormData formData = FormData.fromMap(<String, dynamic>{
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
    });
    // 用构造时保存的_baseUrl
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    final response = await dio.post<Map<String, dynamic>>(
      '/storage/v2/location/addLocationByFile',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data ?? <String, dynamic>{};
  }

  /// 通用FormData上传（Web/移动端）
  Future<Map<String, dynamic>> addLocationByFormData(FormData formData) async {
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    final response = await dio.post<Map<String, dynamic>>(
      '/storage/v2/location/addLocationByFile',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data ?? <String, dynamic>{};
  }

  /// 查询地标信息
  /// id - 库区编号
  /// locationType - 地标类型 :1-障碍物（详情见库区类型文档）
  /// status - 地标状态 0-禁用 1-空闲 2-锁定 3-占用
  /// areaId - 所属库区ID
  // Future<Map<String, dynamic>> qryAllByParams(Map<String, dynamic> params) async {
  //   return _dioService.get('/storage/v2/location/qryAllByParams', queryParameters: params);
  // }

  /// 新增地标
  // id - 地标编号
  // areaId - 所属库区id
  // areaName - 所属库区名称
  // clrCenterNo - 所属库编号（默认AA）
  // locationType - 地标类型 :1-障碍物（详情见库区类型文档）
  // status - 状态
  // note - 备注
  // length - 长度
  // width - 宽度
  // xplace - x坐标
  // yplace - y坐标
  // zplace - z坐标
  Future<Map<String, dynamic>> addLocation(Map<String, dynamic> params) async {
    return _dioService.post('/storage/v2/location/addLocation', body: params);
  }

  /// 修改地标
  // id - 地标编号
  // areaId - 所属库区id
  // areaName - 所属库区名称
  // clrCenterNo - 所属库编号（默认AA）
  // locationType - 地标类型 :1-障碍物（详情见库区类型文档）
  // status - 状态
  // note - 备注
  // length - 长度
  // width - 宽度
  // xplace - x坐标
  // yplace - y坐标
  // zplace - z坐标
  Future<Map<String, dynamic>> updateLocation(Map<String, dynamic> params) async {
    return _dioService.post('/storage/v2/location/updateLocation', body: params);
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
    return _dioService.get('/storage/v2/shelf/qryPageByParams',
        queryParameters: <String, dynamic>{
          'shelfId': params['shelfId'],
          'shelfType': params['shelfType'],
          if (params['status'] is int) 'status': params['status'],
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
    return _dioService.post('/storage/v2/shelf/addShelfInfo', body: params);
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
