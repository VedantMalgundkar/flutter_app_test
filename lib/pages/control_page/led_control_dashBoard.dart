import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../services/http_service.dart';
import 'package:provider/provider.dart';
import '../../services/http_service_provider.dart';
import './effect_tile.dart';
import 'package:flutter/foundation.dart';

class LightControlWidget extends StatefulWidget {
  const LightControlWidget({super.key});

  @override
  State<LightControlWidget> createState() => _LightControlWidgetState();
}

class _LightControlWidgetState extends State<LightControlWidget> {
  double _brightness = 0.0;
  Map<String, dynamic> currentRunningInput = {};

  Color _selectedColor = Colors.blue;

  late final HttpService _hyperhdr;
  List<Map<String, String>> effectList = [];

  Timer? _brightnessDebouncer;
  Timer? _colorchangeDebouncer;

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
      final double brightnessValue =
          (res?['data']?['brightness'] ?? 0).toDouble() ?? 0.0;
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
          return {'name': item['name']?.toString() ?? ''};
        }).toList();
      });
      getCurrentInput();
    } catch (error) {
      print("error in fetchLedEffects: $error");
    }
  }

  Future<void> getCurrentInput() async {
    try {
      final res = await _hyperhdr.getCurrentActiveInput();
      print("getCurrentInput >>>>$res");
      setState(() {
        currentRunningInput = res?['data'];
      });
    } catch (error) {
      print("error in getCurrentInput: $error");
    }
  }

  Future<void> handleEffectTileTap(String effect) async {
    try {
      if (currentRunningInput?['value'] != null
          && currentRunningInput?['value'] is String
          && effect == currentRunningInput?['value']) {
        await _hyperhdr.stopEffect(100);
      } else {
        await _hyperhdr.applyEffect(effect);
      }

      final currRes = await _hyperhdr.getCurrentActiveInput();

      setState(() {
        currentRunningInput = currRes?['data'] ?? {};

      });
    } catch (error) {
      print("error in handleEffectTileTap: $error");
    }
  }

  Future<void> handleColorChange(
    List<int> color, {
    bool isToggle = true,
  }) async {

    // print("currentRunningInput >> ${currentRunningInput?['value']} || ${currentRunningInput?['value'] is String} || ${currentRunningInput?['value'] is Map}");

    final isItEffect = currentRunningInput?['value'] is String;

    final isItSameColor = currentRunningInput?['value'] is Map && listEquals(color, currentRunningInput?['value']?['RGB']);

    try {
      if (isToggle && (isItEffect || isItSameColor)) {
        await _hyperhdr.stopEffect(100);
        setState(() => _selectedColor = const Color(0x00000000));
      } 
      
      if(!isItSameColor) {
        await _hyperhdr.applyColor(color);
      }

      final currRes = await _hyperhdr.getCurrentActiveInput();

      setState(() {
        currentRunningInput = currRes?['data'] ?? {};
      });
    } catch (error) {
      print("error in handleColorChange: $error");
    }
  }

  Future<void> handleColorChangeDebounced(
    List<int> color, {
    bool isToggle = true,
  }) async {

    print("handleColorChangeDebounced >>> $color");
    _colorchangeDebouncer?.cancel();

    _colorchangeDebouncer = Timer(const Duration(milliseconds: 300), () async {
      await handleColorChange(color, isToggle: isToggle);
    });
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brightness Slider
          const SizedBox(height: 12.0),

          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey.shade50, width: 3.0),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                valueIndicatorShape:
                    const RectangularSliderValueIndicatorShape(),
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white, // Text color
                  fontSize: 14,
                ),
                showValueIndicator:
                    ShowValueIndicator.always, // Always show above thumb
              ),
              child: Slider(
                value: _brightness,
                activeColor: Theme.of(context).primaryColor,
                inactiveColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.3),
                min: 0,
                max: 100,
                label: _brightness
                    .round()
                    .toString(), // This is what shows in the indicator
                onChanged: (value) {
                  setState(() => _brightness = value);
                  handleBrightnessChange(value);
                },
              ),
            ),
          ),

          const SizedBox(height: 12.0),

          // First Color Picker
          Container(
            padding: EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey.shade50, width: 3.0),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              children: [
                ColorPicker(
                  color: _selectedColor,
                  onColorChanged: (color) {
                    setState(() => _selectedColor = color);

                    handleColorChangeDebounced([
                      (color.r * 255.0).round(),
                      (color.g * 255.0).round(),
                      (color.b * 255.0).round(),
                    ], isToggle: false);
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

                const SizedBox(height: 15.0),

                ColorPicker(
                  color: _selectedColor,
                  onColorChanged: (color) {
                    setState(() => _selectedColor = color);

                    handleColorChangeDebounced([
                      (color.r * 255.0).round(),
                      (color.g * 255.0).round(),
                      (color.b * 255.0).round(),
                    ], isToggle: true);
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
              ],
            ),
          ),

          const SizedBox(height: 12.0),

          // Second Color Picker
          // Container(
          //   decoration: const BoxDecoration(color: Colors.yellow),
          //   child: ColorPicker(
          //     color: _selectedColor,
          //     onColorChanged: (color) {
          //       setState(() => _selectedColor = color);

          //       handleColorChangeDebounced(
          //         [(color.r * 255.0).round(), (color.g * 255.0).round(), (color.b * 255.0).round()],
          //         isToggle: true,
          //       );
          //     },
          //     wheelDiameter: 250,
          //     padding: EdgeInsets.zero,
          //     columnSpacing: 0,
          //     pickersEnabled: const {
          //       ColorPickerType.wheel: false,
          //       ColorPickerType.primary: true,
          //       ColorPickerType.both: false,
          //       ColorPickerType.accent: false,
          //       ColorPickerType.bw: false,
          //       ColorPickerType.custom: false,
          //     },
          //     wheelWidth: 20,
          //     enableShadesSelection: false,
          //     showColorName: false,
          //     showColorCode: false,
          //     showMaterialName: false,
          //     showColorValue: false,
          //     actionButtons: const ColorPickerActionButtons(
          //       dialogActionButtons: false,
          //     ),
          //   ),
          // ),
          const SizedBox(height: 12.0),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Classic Effects", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Container(
                width: 130,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueGrey.shade100.withValues(alpha: 0),
                      Colors.blueGrey.shade100,
                      Colors.blueGrey.shade100.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          // Effects List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: effectList.length,
            itemBuilder: (context, index) {
              final effect = effectList[index];
              final effectName = effect['name']!;
              bool isEffectActive = currentRunningInput['value'] == effectName;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: EffectTile(
                  title: effectName,
                  isActive: isEffectActive,
                  onTap: () {
                    handleEffectTileTap(effectName);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
