import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../services/http_service.dart';
import 'package:provider/provider.dart';
import '../../services/http_service_provider.dart';

class LightControlWidget extends StatefulWidget {
  const LightControlWidget({super.key});

  @override
  State<LightControlWidget> createState() => _LightControlWidgetState();
}

class _LightControlWidgetState extends State<LightControlWidget> {
  double _brightness = 0.5;
  Color _selectedColor = Colors.blue;
  late final HttpService _hyperhdr;

  @override
  void initState() {
    super.initState();
    _hyperhdr = context.read<HttpServiceProvider>().service;
    fetchLedBrightness();
  }

  Future<void> fetchLedBrightness() async {
    try {
      final res = await _hyperhdr.getLedBrightness();
      print("fetchLedBrightness ${_hyperhdr.baseUrl}");
      print("fetchLedBrightness $res");

      final brightnessValue = (res?['data']?['brightness'] ?? 0) / 100;
      setState(() => _brightness = brightnessValue);
    } catch (error) {
      print("error in fetchLedBrightness: $error");
    }
  }

  Future<void> handleBrightnessChange(brightness) async {
    try {
      final res = await _hyperhdr.adjustLedBrightness(brightness);
      print("handleBrightnessChange $res");
    } catch (error) {
      print("error in fetchLedBrightness: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
            Container(
              // decoration: BoxDecoration(color: Colors.yellow),
              child: Slider(
                value: _brightness,
                activeColor: Theme.of(context).primaryColor, // Main theme color
                inactiveColor: Theme.of(context).primaryColor.withOpacity(0.3),
                onChanged: (value) {
                  setState(() => _brightness = value);
                  handleBrightnessChange(value);
                },
                min: 0,
                max: 100,
              ),
            ),
          
          SizedBox(height: 8.0),
          
          Container(
            // decoration: BoxDecoration(color: Colors.yellow),
            child: ColorPicker(
              color: _selectedColor,
              onColorChanged: (Color color) {
                setState(() => _selectedColor = color);
                print(
                  "Selected RGB: (${color.red}, ${color.green}, ${color.blue})",
                );
              },
              wheelDiameter: 250,
              padding : const EdgeInsets.all(0.0),
              columnSpacing: 0,
              pickersEnabled: <ColorPickerType, bool>{
                ColorPickerType.wheel: true, // ✅ Show only the wheel
                ColorPickerType.both: false,
                ColorPickerType.primary: false,
                ColorPickerType.accent: false,
                ColorPickerType.bw: false,
                ColorPickerType.custom: false,
              },
              wheelWidth: 20, // Adjust size if needed
              enableShadesSelection: false, // ❌ No shades
              showColorName: false, // ❌ No name
              showColorCode: false, // ❌ No hex or RGB
              showMaterialName: false,
              showColorValue: false,
              actionButtons: const ColorPickerActionButtons(
                dialogActionButtons: false, // ❌ No "OK" or "Cancel"
              ),
            ),
          ),
          IconButton(
            onPressed: fetchLedBrightness,
            icon: Icon(Icons.ac_unit_outlined),
          ),
        ],
      ),
    );
  }
}
