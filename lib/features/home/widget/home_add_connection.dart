import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_dialog.dart';
import '../cubit/home_tabs_cubit.dart';
import '../model/connection_kind.dart';

Future<void> showHomeAddConnection(
  BuildContext context, {
  required HomeTabsCubit cubit,
}) {
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: const _HomeAddConnection(),
    ),
  );
}

class _HomeAddConnection extends StatelessWidget {
  const _HomeAddConnection();

  void _pick(BuildContext context, ConnectionKind kind) {
    final cubit = context.read<HomeTabsCubit>();
    Navigator.of(context).pop();
    cubit.add(kind);
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return SerialDialogFrame(
      title: t.home.addConnectionTitle,
      maxWidth: 400,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kind in ConnectionKind.values)
            _KindRow(
              kind: kind,
              onTap: () => _pick(context, kind),
            ),
        ],
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _KindRow extends StatelessWidget {
  const _KindRow({required this.kind, required this.onTap});

  final ConnectionKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final color = homeKindColor(context, kind);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text(
                    homeKindBadge(t, kind),
                    style: AppTextStyles.mono(
                      Theme.of(context).colorScheme,
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  homeKindName(context, kind),
                  style: AppTextStyles.body(
                    Theme.of(context).colorScheme,
                  ).copyWith(color: palette.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String homeKindName(BuildContext context, ConnectionKind kind) {
  final t = Translations.of(context);
  return switch (kind) {
    ConnectionKind.serial => t.home.kindSerial,
    ConnectionKind.ble => t.home.kindBle,
    ConnectionKind.mqtt => t.home.kindMqtt,
    ConnectionKind.tcp => t.home.kindTcp,
    ConnectionKind.udp => t.home.kindUdp,
  };
}

String homeKindBadge(Translations t, ConnectionKind kind) {
  return switch (kind) {
    ConnectionKind.serial => t.home.badgeSerial,
    ConnectionKind.ble => t.home.badgeBle,
    ConnectionKind.mqtt => t.home.badgeMqtt,
    ConnectionKind.tcp => t.home.badgeTcp,
    ConnectionKind.udp => t.home.badgeUdp,
  };
}

Color homeKindColor(BuildContext context, ConnectionKind kind) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (kind) {
    ConnectionKind.serial =>
      dark ? AppColors.protocolSerialDark : AppColors.protocolSerial,
    ConnectionKind.ble =>
      dark ? AppColors.protocolBleDark : AppColors.protocolBle,
    ConnectionKind.mqtt =>
      dark ? AppColors.protocolMqttDark : AppColors.protocolMqtt,
    ConnectionKind.tcp =>
      dark ? AppColors.protocolTcpDark : AppColors.protocolTcp,
    ConnectionKind.udp =>
      dark ? AppColors.protocolUdpDark : AppColors.protocolUdp,
  };
}
