import 'package:flutter/material.dart';
import 'package:itms_mobile/core/utils/util.dart';
import 'package:itms_mobile/core/constants/constant.dart';

class StorageLocationDetailDialog extends StatelessWidget {
  final Map<String, dynamic> locationData;

  const StorageLocationDetailDialog({
    Key? key,
    required this.locationData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 500,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '库位详情',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // 基本信息
              _buildInfoSection('基本信息', [
                _buildInfoRow('库位ID', locationData['id']?.toString() ?? ''),
                _buildInfoRow('库位类型', _getLocationTypeText(locationData['locationType'])),
                _buildInfoRow('状态', _getStatusText(locationData['status'])),
                _buildInfoRow('库区ID', locationData['areaId']?.toString() ?? ''),
              ]),
              
              const SizedBox(height: 16),
              
              // 位置信息
              _buildInfoSection('位置信息', [
                _buildInfoRow('X坐标', locationData['xplace']?.toString() ?? ''),
                _buildInfoRow('Y坐标', locationData['yplace']?.toString() ?? ''),
                _buildInfoRow('Z坐标', locationData['zplace']?.toString() ?? ''),
              ]),
              
              // 货架信息（如果有）
              if (locationData['shelfId'] != null && locationData['shelfId'].toString().isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildInfoSection('货架信息', [
                      _buildInfoRow('货架ID', locationData['shelfId']?.toString() ?? ''),
                    ]),
                  ],
                ),
              
              const SizedBox(height: 20),
              
              // 状态颜色指示
              _buildStatusIndicator(locationData['status']),
              
              const SizedBox(height: 20),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '暂无' : value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocationTypeText(dynamic locationType) {
    if (locationType == null) return '未知';
    try {
      final int code = int.parse(locationType.toString());
      return LocationType.fromCode(code).displayName;
    } catch (e) {
      return '未知类型';
    }
  }

  String _getStatusText(dynamic status) {
    if (status == null) return '未知';
    try {
      final int code = int.parse(status.toString());
      return LandmarkStatus.fromCode(code).displayName;
    } catch (e) {
      return '未知状态';
    }
  }

  Widget _buildStatusIndicator(dynamic status) {
    Color statusColor;
    String statusText;
    
    try {
      final int code = int.parse(status.toString());
      final landmarkStatus = LandmarkStatus.fromCode(code);
      statusColor = Util.hexToColor(landmarkStatus.color);
      statusText = landmarkStatus.displayName;
    } catch (e) {
      statusColor = Colors.grey;
      statusText = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 