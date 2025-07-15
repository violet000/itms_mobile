import 'package:flutter/material.dart';

class GridCell {
  final double x;
  final double y;
  final String id;
  final Color color;
  final String? shelfId; 

  GridCell({
    required this.x,
    required this.y,
    required this.id,
    required this.color,
    this.shelfId,
  });
}