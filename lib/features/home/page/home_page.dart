import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/i18n.dart';

/// 首页占位，后续由业务模块替换。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    return AppScaffold(
      title: t.nav.home,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.home.welcome, style: AppTextStyles.titleLarge(cs)),
            const SizedBox(height: AppSpacing.sm),
            Text(t.home.placeholder, style: AppTextStyles.caption(cs)),
          ],
        ),
      ),
    );
  }
}
