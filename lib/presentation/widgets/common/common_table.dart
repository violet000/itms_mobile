import 'package:flutter/material.dart';

/// 通用表格组件
class CommonTable extends StatefulWidget {
  final List<String> headers; // 表头文字
  final Color headerColor; // 表头背景色
  final TextStyle headerTextStyle; // 表头文字样式
  final List<List<String>> data; // 表格数据
  final TextStyle cellTextStyle; // 单元格文字样式
  final List<Widget Function(int rowIndex)> actionBuilders; // 操作按钮生成器（每行）
  final bool paginated; // 是否分页
  final int rowsPerPage; // 每页行数（分页时有效）

  const CommonTable({
    Key? key,
    required this.headers,
    required this.headerColor,
    required this.headerTextStyle,
    required this.data,
    required this.cellTextStyle,
    required this.actionBuilders,
    this.paginated = false,
    this.rowsPerPage = 10,
  }) : super(key: key);

  @override
  State<CommonTable> createState() => _CommonTableState();
}

class _CommonTableState extends State<CommonTable> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final int totalRows = widget.data.length;
    final int totalPages = (totalRows / widget.rowsPerPage).ceil();

    List<TableRow> buildRows(List<List<String>> rows) {
      return List.generate(rows.length, (rowIdx) {
        final row = rows[rowIdx];
        return TableRow(
          children: [
            ...row.map((cell) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Text(cell, style: widget.cellTextStyle),
                )),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.actionBuilders.map((builder) => builder(rowIdx)).toList(),
              ),
            ),
          ],
        );
      });
    }

    Widget buildTable(List<List<String>> rows) {
      return Table(
        columnWidths: {
          for (int i = 0; i < widget.headers.length; i++) i: const FlexColumnWidth(),
          widget.headers.length: const IntrinsicColumnWidth(),
        },
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          TableRow(
            decoration: BoxDecoration(color: widget.headerColor),
            children: [
              ...widget.headers.map((h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Text(h, style: widget.headerTextStyle),
                  )),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text('操作'),
              ),
            ],
          ),
          ...buildRows(rows),
        ],
      );
    }

    if (widget.paginated) {
      // 分页模式
      int start = _currentPage * widget.rowsPerPage;
      int end = (_currentPage + 1) * widget.rowsPerPage;
      end = end > totalRows ? totalRows : end;
      final pageRows = widget.data.sublist(start, end);
      return Column(
        children: [
          buildTable(pageRows),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Text('第 ${_currentPage + 1} / $totalPages 页'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      );
    } else {
      // 滚动模式
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: buildTable(widget.data),
        ),
      );
    }
  }
} 