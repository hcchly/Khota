import 'package:flutter/services.dart';

/// Converts Arabic-Indic digits (٠-٩ and ۰-۹) to English digits (0-9).
///
/// Used for email and password fields so that numbers typed on an Arabic
/// keyboard still work. Other characters are left as typed; the validators
/// show a clear message if non-English letters are used.
class LatinInputFormatter extends TextInputFormatter {
  const LatinInputFormatter();

  static String _convert(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final converted = _convert(newValue.text);
    if (converted == newValue.text) return newValue;
    // Each digit is replaced by exactly one character, so the cursor
    // position and composing range stay valid.
    return newValue.copyWith(text: converted);
  }
}
