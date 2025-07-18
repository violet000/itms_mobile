/// 全局枚举和常量定义文件

// 任务状态枚举
/// 状态码：1-未执行，2-执行中，3-执行完成，4-已取消，5-作业异常
enum JobStatus {
  pending(1, 'PENDING'),
  running(2, 'RUNNING'),
  completed(3, 'COMPLETED'),
  cancelled(4, 'CANCELLED'),
  failed(5, 'FAILED');

  const JobStatus(this.code, this.value);
  final int code;
  final String value;

  @override
  String toString() => value;

  /// 根据状态码获取枚举值
  static JobStatus fromCode(int code) {
    return JobStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => JobStatus.pending,
    );
  }

  /// 根据字符串值获取枚举值
  static JobStatus fromValue(String value) {
    return JobStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => JobStatus.pending,
    );
  }

  /// 获取状态的中文描述
  String get displayName {
    switch (this) {
      case JobStatus.pending:
        return '未执行';
      case JobStatus.running:
        return '执行中';
      case JobStatus.completed:
        return '执行完成';
      case JobStatus.cancelled:
        return '已取消';
      case JobStatus.failed:
        return '作业异常';
    }
  }

  /// 获取状态的颜色代码
  String get colorCode {
    switch (this) {
      case JobStatus.pending:
        return '#FFA07A'; // 橙色
      case JobStatus.running:
        return '#87CEFA'; // 蓝色
      case JobStatus.completed:
        return '#90EE90'; // 绿色
      case JobStatus.cancelled:
        return '#D3D3D3'; // 灰色
      case JobStatus.failed:
        return '#CD5C5C'; // 红色
    }
  }
}

// 作业类型枚举
enum OperateType {
  location2location('location2location'),
  location2container('location2container');

  const OperateType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case OperateType.location2location:
        return '库位到库位搬运';
      case OperateType.location2container:
        return '库位到容器搬运';
    }
  }

  @override
  String toString() => value;
}

// 容器类型枚举
enum ContainerType {
  pallet('PALLET'),
  bin('BIN'),
  shelf('SHELF');

  const ContainerType(this.value);
  final String value;

  @override
  String toString() => value;
}

// 接口返回码枚举
enum HTTPCode {
  success('000000'),
  error('999999');

  const HTTPCode(this.code);
  final String code;
}


/// 地标状态 0-禁用 1-空闲 2-锁定 3-占用
enum LandmarkStatus {
  disabled(0, '禁用', '#708090'),
  idle(1, '空闲', '#32CD32'),
  locked(2, '锁定', '#DC143C'),
  occupied(3, '占用', '#FFA500');

  const LandmarkStatus(this.code, this.displayName, this.color);
  final int code;
  final String displayName;
  final String color;

  static LandmarkStatus fromCode(int code) {
    return LandmarkStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => LandmarkStatus.disabled,
    );
  }
}

/// 地标类型 0-NULL(空) 1-FIXED_SHELF（固定货架) 2-MOVE_SHELF(移动货架) 3-虚拟库位(潜伏式AGV) 4-CHARGER(充电桩)
enum LandmarkType {
  none(0, '空'),
  fixedShelf(1, '固定货架'),
  moveShelf(2, '移动货架'),
  virtualLocation(3, '虚拟库位'),
  charger(4, '充电桩');

  const LandmarkType(this.code, this.displayName);
  final int code;
  final String displayName;

  static LandmarkType fromCode(int code) {
    return LandmarkType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => LandmarkType.none,
    );
  }
}

/// 托盘状态 0-禁用 1-空闲 2-锁定 3-占用 4-满载
enum PalletStatus {
  disabled(0, '禁用', '#708090'),
  idle(1, '空闲', '#32CD32'),
  locked(2, '锁定', '#DC143C'),
  occupied(3, '占用', '#FFA500'),
  full(4, '满载', '#8B0000');

  const PalletStatus(this.code, this.displayName, this.color);
  final int code;
  final String displayName;
  final String color;

  static PalletStatus fromCode(int code) {
    return PalletStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => PalletStatus.disabled,
    );
  }
}


