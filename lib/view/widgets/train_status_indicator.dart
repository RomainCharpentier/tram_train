import 'package:flutter/material.dart';
import '../../domain/models/train.dart';
import '../utils/train_status_colors.dart';

class TrainStatusIndicator extends StatelessWidget {
  final Train? train;
  final double size;
  final double iconSize;
  final double borderWidth;

  const TrainStatusIndicator({
    super.key,
    required this.train,
    this.size = 48,
    this.iconSize = 24,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (train == null) {
      return _buildIndicator(
        color: TrainStatusColors.unknownColor,
        icon: Icons.help_outline,
        size: size,
        iconSize: iconSize,
        borderWidth: borderWidth,
      );
    }

    final presentation = TrainStatusColors.buildPresentation(train!, context);

    return _buildIndicator(
      color: presentation.primaryColor,
      icon: presentation.primaryIcon,
      size: size,
      iconSize: iconSize,
      borderWidth: borderWidth,
    );
  }

  Widget _buildIndicator({
    required Color color,
    required IconData icon,
    required double size,
    required double iconSize,
    required double borderWidth,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: borderWidth),
      ),
      child: Icon(
        icon,
        color: color,
        size: iconSize,
      ),
    );
  }
}

