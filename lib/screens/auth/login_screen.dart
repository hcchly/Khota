import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/labeled_field.dart';
import '../shell/main_shell.dart';
import 'register_screen.dart';

/// PBI-05: As an authorized user, I want to log in
/// so that I can securely access the system.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _auth = widget.auth ?? MockAuthService.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
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

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RegisterScreen(auth: _auth)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with logo and name.
          GradientHeader(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 72),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/khota_logo.png',
                    width: 140,
                    semanticLabel: 'شعار خُطى',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'خُطى',
                    style: text.headlineLarge?.copyWith(
                      color: AppColors.warmWhite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Card overlapping the header.
          Transform.translate(
            offset: const Offset(0, -48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo.withValues(alpha: 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'تسجيل الدخول',
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 24),
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
                              hintText: 'example@khota.sa',
                            ),
                          ),
                        ),
                        LabeledField(
                          label: 'كلمة المرور',
                          child: PasswordField(
                            controller: _passwordController,
                            validator: Validators.password,
                            enabled: !_loading,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signIn(),
                            autofillHints: const [AutofillHints.password],
                          ),
                        ),
                        if (_error != null) ErrorBox(_error!),
                        LoadingButton(
                          label: 'دخول',
                          loading: _loading,
                          onPressed: _signIn,
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'ليس لديك حساب؟',
                              style: text.bodyLarge?.copyWith(
                                color: AppColors.indigo.withValues(alpha: 0.7),
                              ),
                            ),
                            TextButton(
                              onPressed: _loading ? null : _openRegister,
                              child: Text(
                                'إنشاء حساب',
                                style: text.bodyLarge?.copyWith(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // TEMPORARY: remove when Firebase is connected.
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.tealLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.tealLight.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            'للتجربة: test@khota.sa / 12345678',
                            textAlign: TextAlign.center,
                            style: text.bodyMedium
                                ?.copyWith(color: AppColors.teal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
