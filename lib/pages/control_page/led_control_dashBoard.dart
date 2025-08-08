import 'dart:async';
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
  double _brightness = 0.0;
  Color _selectedColor = Colors.blue;
  late final HttpService _hyperhdr;
  List<Map<String, String>> effectList = [];

  Timer? _brightnessDebouncer;

  @override
  void initState() {
    super.initState();
    _hyperhdr = context.read<HttpServiceProvider>().service;
    fetchLedBrightness();
    fetchLedEffects();
  }

  Future<void> fetchLedBrightness() async {
    try {
      final res = await _hyperhdr.getLedBrightness();
      final double brightnessValue = (res?['data']?['brightness'] ?? 0).toDouble() ?? 0.0;
      setState(() => _brightness = brightnessValue);

    } catch (error) {
      print("error in fetchLedBrightness: $error");
    }
  }
  
  Future<void> fetchLedEffects() async {
    try {
      final res = await _hyperhdr.getLedEffects();
      final List<dynamic> data = res?['data'] ?? [];

      setState(() {
        effectList = data.map<Map<String, String>>((item) {
          return {
            'name': item['name']?.toString() ?? '',
          };
        }).toList();
      });
    } catch (error) {
      print("error in fetchLedEffects: $error");
    }
  }

  Future<void> handleBrightnessChange(double brightness) async {
    _brightnessDebouncer?.cancel();

    _brightnessDebouncer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final res = await _hyperhdr.adjustLedBrightness(brightness.toInt());
        print("handleBrightnessChange $res");
      } catch (error) {
        print("error in handleBrightnessChange: $error");
      }
    });
  }

  @override
  void dispose() {
    _brightnessDebouncer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return 
      SingleChildScrollView(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brightness Slider
          Container(
            decoration: const BoxDecoration(color: Colors.yellow),
            child: Slider(
              value: _brightness,
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: Theme.of(context).primaryColor.withOpacity(0.3),
              onChanged: (value) {
                setState(() => _brightness = value);
                handleBrightnessChange(value);
              },
              min: 0,
              max: 100,
            ),
          ),

          const SizedBox(height: 8.0),

          // First Color Picker
          Container(
            decoration: const BoxDecoration(color: Colors.yellow),
            child: ColorPicker(
              color: _selectedColor,
              onColorChanged: (color) {
                setState(() => _selectedColor = color);
                print("Selected RGB: (${color.red}, ${color.green}, ${color.blue})");
              },
              wheelDiameter: 250,
              padding: EdgeInsets.zero,
              columnSpacing: 0,
              pickersEnabled: const {
                ColorPickerType.wheel: true,
                ColorPickerType.primary: false,
                ColorPickerType.both: false,
                ColorPickerType.accent: false,
                ColorPickerType.bw: false,
                ColorPickerType.custom: false,
              },
              wheelWidth: 20,
              enableShadesSelection: false,
              showColorName: false,
              showColorCode: false,
              showMaterialName: false,
              showColorValue: false,
              actionButtons: const ColorPickerActionButtons(
                dialogActionButtons: false,
              ),
            ),
          ),

          const SizedBox(height: 8.0),

          // Second Color Picker
          Container(
            decoration: const BoxDecoration(color: Colors.yellow),
            child: ColorPicker(
              color: _selectedColor,
              onColorChanged: (color) {
                setState(() => _selectedColor = color);
                print("Selected RGB: (${color.red}, ${color.green}, ${color.blue})");
              },
              wheelDiameter: 250,
              padding: EdgeInsets.zero,
              columnSpacing: 0,
              pickersEnabled: const {
                ColorPickerType.wheel: false,
                ColorPickerType.primary: true,
                ColorPickerType.both: false,
                ColorPickerType.accent: false,
                ColorPickerType.bw: false,
                ColorPickerType.custom: false,
              },
              wheelWidth: 20,
              enableShadesSelection: false,
              showColorName: false,
              showColorCode: false,
              showMaterialName: false,
              showColorValue: false,
              actionButtons: const ColorPickerActionButtons(
                dialogActionButtons: false,
              ),
            ),
          ),

          const SizedBox(height: 8.0),

          // Effects List
          ListView.builder(
            shrinkWrap: true, // ✅ let it size itself inside scroll
            physics: const NeverScrollableScrollPhysics(), // ✅ disable inner scroll
            itemCount: effectList.length,
            itemBuilder: (context, index) {
              final item = effectList[index];
                return ListTile(
                  title: Text(item['name']!),
                  onTap: () {
                    print('Tapped on ${item['name']}');
                  },
                );
            },
          ),
        ],
      ),
    );
}
}
