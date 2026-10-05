import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/labeled_field.dart';
import '../shell/main_shell.dart';

/// PBI-04: As a citizen, I want to create an account
/// so that my submitted reports can be linked to me.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final AuthService _auth = widget.auth ?? MockAuthService.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'الرجاء تأكيد كلمة المرور';
    if (value != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  Future<void> _register() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _auth.register(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on AuthException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'حدث خطأ غير متوقع، حاول مرة أخرى';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'إنشاء حساب'),
      body: Form(
        key: _formKey,
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              LabeledField(
                label: 'الاسم الكامل',
                child: TextFormField(
                  controller: _nameController,
                  validator: Validators.fullName,
                  enabled: !_loading,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    hintText: 'محمد عبدالله الشمري',
                  ),
                ),
              ),
              LabeledField(
                label: 'البريد الإلكتروني',
                child: TextFormField(
                  controller: _emailController,
                  validator: Validators.email,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    hintText: 'example@email.com',
                  ),
                ),
              ),
              LabeledField(
                label: 'كلمة المرور',
                child: PasswordField(
                  controller: _passwordController,
                  validator: Validators.newPassword,
                  enabled: !_loading,
                  hintText: '٨ أحرف على الأقل',
                  autofillHints: const [AutofillHints.newPassword],
                ),
              ),
              LabeledField(
                label: 'تأكيد كلمة المرور',
                child: PasswordField(
                  controller: _confirmController,
                  validator: _validateConfirm,
                  enabled: !_loading,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                ),
              ),
              if (_error != null) ErrorBox(_error!),
              const SizedBox(height: 4),
              LoadingButton(
                label: 'إنشاء الحساب',
                loading: _loading,
                onPressed: _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
