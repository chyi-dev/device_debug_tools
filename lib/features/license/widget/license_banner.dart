import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/serial_metrics.dart';
import '../cubit/license_cubit.dart';
import '../cubit/license_state.dart';
import 'license_dialogs.dart';

/// 页签栏下方的未激活提示；试用中或已授权时不占位。
class LicenseBanner extends StatelessWidget {
  const LicenseBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LicenseCubit, LicenseState>(
      buildWhen: (a, b) =>
          a.showUnlicensedBanner != b.showUnlicensedBanner ||
          a.ready != b.ready,
      builder: (context, state) {
        if (!state.ready || !state.showUnlicensedBanner) {
          return const SizedBox.shrink();
        }
        final t = Translations.of(context);
        final palette = SerialPalette.of(context);
        final cs = Theme.of(context).colorScheme;
        return Material(
          color: palette.panel,
          child: InkWell(
            onTap: () => showLicenseActivateDialog(context),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.line)),
              ),
              child: SizedBox(
                height: SerialMetrics.logHead,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.license.banner,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(cs).copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
