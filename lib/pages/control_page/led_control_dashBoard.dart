import 'package:flutter/material.dart';
import "package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart";

class LightControlWidget extends StatefulWidget {
  const LightControlWidget({super.key});

  @override
  State<LightControlWidget> createState() => _LightControlWidgetState();
}

class _LightControlWidgetState extends State<LightControlWidget> {
  double _brightness = 0.5;
  Color _selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text("Brightness: ${(_brightness * 100).round()}%"),
          Slider(
            value: _brightness,
            onChanged: (value) => setState(() => _brightness = value),
            min: 0,
            max: 1,
          ),
          const SizedBox(height: 16),
          Text("Selected Color: ${_selectedColor.toString()}"),
          const SizedBox(height: 8),
          ColorPicker(
            color: Colors.blue,
            onChanged: (color) {
              setState(() => _selectedColor = color);
            },
            initialPicker: Picker.paletteHue,
          )
        ],
      ),
    );
  }
}
