import 'package:flutter/material.dart';
import './control_widgets/hyperhdr_toggle.dart'; // Adjust the path as per your structure

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: EdgeInsets.all(16.0), child: HyperhdrToggle()),
    );
  }
}
