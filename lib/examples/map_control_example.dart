import 'package:flutter/material.dart';
import 'package:itms_mobile/presentation/widgets/common/map_control.dart';
import 'package:itms_mobile/core/utils/grid_cell.dart';

class MapControlExample extends StatefulWidget {
  const MapControlExample({super.key});

  @override
  State<MapControlExample> createState() => _MapControlExampleState();
}

class _MapControlExampleState extends State<MapControlExample> {
  final List<GridCell> _cells = [];

  @override
  void initState() {
    super.initState();
    _generateSampleCells();
  }

  void _generateSampleCells() {
    _cells.clear();
    
    // 生成示例库位数据
    for (int x = 0; x < 9; x++) {
      for (int y = 0; y < 10; y++) {
        Color cellColor;
        String status;
        
        // 根据位置设置不同的颜色和状态
        if (x < 3 && y < 4) {
          cellColor = const Color.fromARGB(255, 213, 213, 213); // 空闲
          status = '空闲';
        } else if (x >= 3 && x < 6 && y >= 4 && y < 7) {
          cellColor = const Color.fromARGB(255, 238, 137, 4); // 占用
          status = '占用';
        } else if (x >= 6 && y >= 7) {
          cellColor = Colors.red; // 锁定
          status = '锁定';
        } else {
          cellColor = const Color.fromARGB(255, 213, 213, 213); // 空闲
          status = '空闲';
        }
        
        _cells.add(GridCell(
          x: x.toDouble(),
          y: y.toDouble(),
          id: 'A${x + 1}-${y + 1}',
          color: cellColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('库位地图示例'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MapControl(
                  xUnits: 9,
                  yUnits: 10,
                  xStart: 0,
                  yStart: 0,
                  cells: _cells,
                  onCellTap: (cell) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('点击了库位: ${cell.id}'),
                        backgroundColor: cell.color,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(
                    '空闲',
                    const Color.fromARGB(255, 213, 213, 213),
                  ),
                  _buildLegendItem(
                    '占用',
                    const Color.fromARGB(255, 238, 137, 4),
                  ),
                  _buildLegendItem(
                    '锁定',
                    Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建图例项（凹陷效果）
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: color.withOpacity(0.6),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.4),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 