import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../common/color_extension.dart';

class ValueTile extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color? color;

  const ValueTile({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: TColor.secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? TColor.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: TColor.secondaryText,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}