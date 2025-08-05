import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Slider(
            value: _brightness,
            activeColor: Theme.of(context).primaryColor, // Main theme color
            inactiveColor: Theme.of(context).primaryColor.withOpacity(0.3), 
            onChanged: (value) {
              setState(() => _brightness = value);
              handleBrightnessChange((value * 100).round());
            },
            min: 0,
            max: 1,
          ),      

          Container(
            decoration: BoxDecoration(
              color: Colors.yellow,
            ),
            padding: EdgeInsets.symmetric(horizontal: 30.0),
            child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
              print("RGB: (${color.red}, ${color.green}, ${color.blue})");
            },
            paletteType: PaletteType.hueWheel,
            enableAlpha: true,
            labelTypes: const [ColorLabelType.rgb],
            showLabel: false,
          ),
          ),
          IconButton(
            onPressed: fetchLedBrightness,
            icon: Icon(Icons.ac_unit_outlined),
          )
        ],
      ),
    );
  }
}
