import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-app accessibility settings. They are saved on the device
/// and applied on top of the phone's own accessibility settings.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _textScaleKey = 'text_scale';
  static const _boldTextKey = 'bold_text';

  /// The font size steps shown on the slider.
  static const List<double> textScaleSteps = [0.9, 1.0, 1.15, 1.3];
  static const List<String> textScaleLabels = [
    'صغير',
    'افتراضي',
    'كبير',
    'كبير جداً',
  ];

  double _textScale = 1.0;
  bool _boldText = false;

  double get textScale => _textScale;
  bool get boldText => _boldText;

  int get textScaleIndex {
    final i = textScaleSteps.indexOf(_textScale);
    return i < 0 ? 1 : i;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _textScale = prefs.getDouble(_textScaleKey) ?? 1.0;
      _boldText = prefs.getBool(_boldTextKey) ?? false;
    } catch (_) {
      // If saved settings cannot be read, keep the defaults.
    }
    notifyListeners();
  }

  Future<void> setTextScaleIndex(int index) async {
    _textScale = textScaleSteps[index];
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_textScaleKey, _textScale);
    } catch (_) {}
  }

  Future<void> setBoldText(bool value) async {
    _boldText = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_boldTextKey, value);
    } catch (_) {}
  }
}
