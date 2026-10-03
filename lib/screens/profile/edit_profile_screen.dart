import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_app_bar.dart';

/// PBI-08: As a citizen, I want to edit my profile
/// so that I can keep my account information up to date.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.user,
    required this.service,
  });

  final AppUser user;
  final ProfileService service;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

/// Returns an Arabic error message, or null when the name is valid.
String? validateFullName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'الرجاء إدخال الاسم';
  if (name.length < 3) return 'الاسم قصير جداً';
  if (name.length > 50) return 'الاسم طويل جداً';
  if (!RegExp(r'^[؀-ۿa-zA-Z\s]+$').hasMatch(name)) {
    return 'الاسم يجب أن يحتوي على حروف فقط';
  }
  return null;
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.user.fullName);
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final updated = await widget.service.updateName(_nameController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التغييرات')),
      );
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('تعذّر حفظ التغييرات، حاول مرة أخرى'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const GradientAppBar(title: 'تعديل البيانات'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'الاسم الكامل',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              validator: validateFullName,
              enabled: !_saving,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.name],
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                hintText: 'أدخل اسمك الكامل',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'البريد الإلكتروني (غير قابل للتعديل)',
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.indigo.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.user.email,
              enabled: false,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    );
  }
}
