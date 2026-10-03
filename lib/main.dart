import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/shell/main_shell.dart';
import 'settings/app_settings.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  runApp(const KhotaApp());
}

class KhotaApp extends StatelessWidget {
  const KhotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'خُطى',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),

          // Arabic only, right-to-left for the whole app.
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Apply the in-app font size and bold text on top of the
          // phone's own accessibility settings (up to 200%).
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final systemScale = media.textScaler.scale(1);
            final scale =
                (systemScale * settings.textScale).clamp(0.8, 2.0).toDouble();
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(scale),
                boldText: media.boldText || settings.boldText,
              ),
              child: child!,
            );
          },

          // TEMPORARY: opens the main app directly.
          // When login is ready, show the login screen first and
          // open MainShell after a successful login.
          home: const MainShell(),
        );
      },
    );
  }
}
