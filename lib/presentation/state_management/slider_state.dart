import 'package:flutter/foundation.dart';

class SliderState extends ChangeNotifier {
  final Map<String, bool> _sliderStates = {};
  final Map<String, double> _sliderPositions = {};
  
  bool getSliderState(String pageId) => _sliderStates[pageId] ?? false;
  double getSliderPosition(String pageId) => _sliderPositions[pageId] ?? 0.0;
  
  void setSliderState(String pageId, bool state, {double position = 0.0}) {
    _sliderStates[pageId] = state;
    _sliderPositions[pageId] = position;
    notifyListeners();
  }
  
  void resetSliderPosition(String pageId) {
    _sliderPositions[pageId] = 0.0;
    _sliderStates[pageId] = false;
    notifyListeners();
  }
  
  void resetAllSliders() {
    _sliderStates.clear();
    _sliderPositions.clear();
    notifyListeners();
  }
}