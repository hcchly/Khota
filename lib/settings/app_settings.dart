import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-app accessibility settings. They are saved on the device
/// and applied on top of the phone's own accessibility settings.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _textScaleKey = 'text_scale';
  static const _boldTextKey = 'bold_text';
  static const _themeModeKey = 'theme_mode';

  /// Appearance choices, in the order shown in settings.
  static const List<ThemeMode> themeModes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];
  static const List<String> themeModeLabels = ['حسب الجهاز', 'فاتح', 'داكن'];

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
  ThemeMode _themeMode = ThemeMode.system;

  double get textScale => _textScale;
  bool get boldText => _boldText;
  ThemeMode get themeMode => _themeMode;

  int get textScaleIndex {
    final i = textScaleSteps.indexOf(_textScale);
    return i < 0 ? 1 : i;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedScale = prefs.getDouble(_textScaleKey);
      _textScale = textScaleSteps.contains(savedScale) ? savedScale! : 1.0;
      _boldText = prefs.getBool(_boldTextKey) ?? false;
      final savedMode = prefs.getString(_themeModeKey);
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => ThemeMode.system,
      );
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

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (_) {}
  }
}
