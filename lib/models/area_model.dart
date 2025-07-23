class AreaModel {
  final String id;
  final String name;
  final String type;
  final String clrCenterNo;
  final int status;

  AreaModel({required this.id, required this.name, required this.type, required this.clrCenterNo, required this.status});

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      clrCenterNo: json['clrCenterNo']?.toString() ?? '',
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type,
      'clrCenterNo': clrCenterNo,
      'status': status,
    };
  }
}