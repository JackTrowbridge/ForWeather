import 'dart:ui';

import 'package:flutter/material.dart';
class GlassContainer extends StatelessWidget {
  final Widget child;
  final width;
  final bool isSelected;

  const GlassContainer({super.key, required this.child, this.width, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(
          width: width ?? width,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.all(Radius.circular(12)),
            border: isSelected
                ? Border.all(
                    color: Colors.black, width: 2.5)
                :
            Border.all(
                color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
