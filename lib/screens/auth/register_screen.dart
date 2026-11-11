import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/input_formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/brand_surface.dart';
import '../../theme/app_colors.dart';
import '../info/privacy_screen.dart';
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
  late final AuthService _auth = widget.auth ?? FirebaseAuthService.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _accepted = false;
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم إنشاء الحساب بنجاح')));
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
              const BrandIntro(
                title: 'أول خطوة تبدأ هنا',
                description: 'أنشئ حسابك وشارك في تحسين أرصفة الرياض.',
                icon: Icons.person_add_alt_1_outlined,
              ),
              const SizedBox(height: 24),
              LabeledField(
                label: 'الاسم الكامل',
                child: TextFormField(
                  controller: _nameController,
                  validator: Validators.fullName,
                  enabled: !_loading,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
              ),
              LabeledField(
                label: 'البريد الإلكتروني',
                child: TextFormField(
                  controller: _emailController,
                  validator: Validators.email,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: const [LatinInputFormatter()],
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    hintText: 'name@example.com',
                  ),
                ),
              ),
              LabeledField(
                label: 'كلمة المرور',
                child: PasswordField(
                  controller: _passwordController,
                  validator: Validators.newPassword,
                  enabled: !_loading,
                  helperText: '8 أحرف على الأقل',
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
              _ConsentField(
                value: _accepted,
                enabled: !_loading,
                onChanged: (value) => setState(() => _accepted = value),
              ),
              const SizedBox(height: 12),
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

/// "I agree to the privacy policy" — required before an account is created.
class _ConsentField extends StatelessWidget {
  const _ConsentField({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FormField<bool>(
      initialValue: value,
      validator: (_) => value
          ? null
          : 'يجب الموافقة على سياسة الخصوصية لإنشاء الحساب',
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: value,
                activeColor: AppColors.greenDeep,
                side: BorderSide(
                  color: field.hasError ? AppColors.error : AppColors.slate,
                  width: 1.5,
                ),
                onChanged: enabled
                    ? (checked) {
                        onChanged(checked ?? false);
                        field.didChange(checked);
                      }
                    : null,
              ),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('أوافق على ', style: text.bodyMedium),
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      ),
                      child: Text(
                        'سياسة الخصوصية وشروط الاستخدام',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.greenDeep,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.greenDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12),
              child: Text(
                field.errorText!,
                style: text.bodySmall?.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}
