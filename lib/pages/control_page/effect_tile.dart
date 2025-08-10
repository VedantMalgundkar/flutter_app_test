import 'package:flutter/material.dart';
import 'dart:math';

class EffectTile extends StatefulWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const EffectTile({
    super.key,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<EffectTile> createState() => _RainbowBorderTileState();
}

class _RainbowBorderTileState extends State<EffectTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double shift = _controller.value * 2 * pi;

        // Decide border decoration
        final BoxDecoration borderDecoration = widget.isActive
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: SweepGradient(
                  colors: const [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.indigo,
                    Color(0xFF8F00FF),
                    Colors.red,
                  ],
                  transform: GradientRotation(shift),
                ),
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.blueGrey.shade50,
              );

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: borderDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Material(
              color: Colors.white,
              child: ListTile(
                title: Text(widget.title),
                onTap: widget.onTap,
              ),
            ),
          ),
        );
      },
    );
  }
}
