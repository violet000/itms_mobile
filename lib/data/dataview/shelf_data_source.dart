import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:itms_mobile/models/shelf_model.dart';
import 'package:itms_mobile/core/constants/constant.dart';

class ShelfDataSource extends DataGridSource {
  final List<ShelfModel> _shelves;
  final Function(ShelfModel)? onEdit;
  final Function(ShelfModel)? onDelete;

  ShelfDataSource({
    required List<ShelfModel> shelves,
    this.onEdit,
    this.onDelete,
  }) : _shelves = shelves {
    _shelfRows = shelves
        .map<DataGridRow>((shelf) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'shelfId', value: shelf.shelfId),
              DataGridCell<int>(columnName: 'status', value: shelf.status),
              DataGridCell<String>(columnName: 'locationId', value: shelf.locationId),
              DataGridCell<String>(columnName: 'actions', value: ''),
            ]))
        .toList();
  }

  List<DataGridRow> _shelfRows = [];

  @override
  List<DataGridRow> get rows => _shelfRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        if (cell.columnName == 'status') {
          final statusInt = cell.value as int;
          final status = PalletStatus.fromCode(statusInt);
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              status.displayName,
              style: TextStyle(
                fontSize: 12,
                color: _hexToColor(status.color),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        } else if (cell.columnName == 'actions') {
          final shelfIndex = row.getCells().indexWhere((c) => c.columnName == 'shelfId');
          if (shelfIndex != -1) {
            final shelfId = row.getCells()[shelfIndex].value.toString();
            final shelf = _shelves.firstWhere((s) => s.shelfId == shelfId);
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  onPressed: () => onEdit?.call(shelf),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => onDelete?.call(shelf),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        } else {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              cell.value.toString(),
              style: const TextStyle(fontSize: 12),
            ),
          );
        }
      }).toList(),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
} 