/// Form validators. Each returns an Arabic error message, or null if valid.
class Validators {
  Validators._();

  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'الرجاء إدخال الاسم';
    if (name.length < 3) return 'الاسم قصير جداً';
    if (name.length > 50) return 'الاسم طويل جداً';
    if (!RegExp(r'^[؀-ۿa-zA-Z\s]+$').hasMatch(name)) {
      return 'الاسم يجب أن يحتوي على حروف فقط';
    }
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  /// Used when creating an account (PBI: at least 8 characters).
  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'الرجاء إدخال كلمة المرور';
    if (password.length < 8) return 'كلمة المرور يجب أن تكون ٨ أحرف على الأقل';
    return null;
  }

  /// Used on the login screen.
  static String? password(String? value) {
    if ((value ?? '').isEmpty) return 'الرجاء إدخال كلمة المرور';
    return null;
  }
}
