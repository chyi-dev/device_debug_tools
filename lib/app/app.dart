import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../i18n/i18n.dart';
import 'cubit/app_cubit.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, appState) {
        return MaterialApp.router(
          onGenerateTitle: (context) => Translations.of(context).app.title,
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: appState.themeMode,
          locale: appState.locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: EasyLoading.init(),
        );
      },
    );
  }
}
