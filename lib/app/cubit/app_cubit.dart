import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/storage/user_prefs_storage.dart';
import '../../i18n/i18n.dart';

/// 全局应用状态 Cubit，管理主题和语言。
class AppCubit extends Cubit<AppState> {
  AppCubit({required UserPrefsStorage userPrefsStorage})
      : _userPrefsStorage = userPrefsStorage,
        super(AppState(
          themeMode: userPrefsStorage.readThemeMode(),
          locale: localeFromTag(userPrefsStorage.readLocale()),
        ));

  final UserPrefsStorage _userPrefsStorage;

  static AppLocale localeFromTag(String tag) =>
      tag == AppLocale.en.languageCode ? AppLocale.en : AppLocale.zh;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _userPrefsStorage.saveThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setLocale(AppLocale locale) async {
    await LocaleSettings.setLocale(locale);
    await _userPrefsStorage.saveLocale(locale.languageCode);
    emit(state.copyWith(locale: locale));
  }
}

class AppState {
  const AppState({
    required this.themeMode,
    required this.locale,
  });

  final ThemeMode themeMode;
  final AppLocale locale;

  AppState copyWith({
    ThemeMode? themeMode,
    AppLocale? locale,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}
