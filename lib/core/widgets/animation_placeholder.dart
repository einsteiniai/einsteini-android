import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimationPlaceholder extends StatelessWidget {
  final String animationPath;
  final double height;
  final double? width;
  final BoxFit fit;

  const AnimationPlaceholder({
    super.key,
    required this.animationPath,
    required this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: Lottie.asset(
          animationPath,
          fit: fit,
        ),
      ),
    );
  }
} 