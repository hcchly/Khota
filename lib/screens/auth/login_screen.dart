import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../../utils/input_formatters.dart';
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
  late final AuthService _auth = widget.auth ?? FirebaseAuthService.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _error = null;
      _submitted = true;
    });
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

  Future<void> _forgotPassword() async {
    setState(() => _error = null);
    if (!_emailFieldKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'اكتب بريدك الإلكتروني أولاً ثم اضغط "نسيت كلمة المرور؟"',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.sendPasswordReset(_emailController.text);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'إذا كان البريد مسجلاً لدينا، فسيصلك رابط لإعادة تعيين كلمة المرور',
          ),
        ),
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => RegisterScreen(auth: _auth)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with the logo only.
          GradientHeader(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 88),
              child: Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/khota_logo_mist.png',
                      width: 198,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'شعار خُطى',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'أرصفة أفضل تبدأ بخطوة',
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                  color: context.khota.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: context.khota.isDark
                      ? Border.all(color: context.khota.cardBorder)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: context.khota.isDark
                          ? Colors.transparent
                          : AppColors.ink.withValues(alpha: 0.055),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'أهلًا برجعتك',
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'سجّل دخولك لإرسال بلاغاتك ومتابعتها.',
                          style: text.bodyMedium?.copyWith(
                            color: context.khota.muted(0.68),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        LabeledField(
                          label: 'البريد الإلكتروني',
                          child: TextFormField(
                            key: _emailFieldKey,
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
                            validator: Validators.password,
                            enabled: !_loading,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signIn(),
                            autofillHints: const [AutofillHints.password],
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: _loading ? null : _forgotPassword,
                            child: Text(
                              'نسيت كلمة المرور؟',
                              style: text.bodyMedium?.copyWith(
                                color: context.khota.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_error != null) ErrorBox(_error!),
                        LoadingButton(
                          label: 'تسجيل الدخول',
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
                                color: context.khota.muted(0.7),
                              ),
                            ),
                            TextButton(
                              onPressed: _loading ? null : _openRegister,
                              child: Text(
                                'إنشاء حساب',
                                style: text.bodyLarge?.copyWith(
                                  color: context.khota.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
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
