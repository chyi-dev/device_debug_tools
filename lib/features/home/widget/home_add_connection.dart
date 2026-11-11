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
      maxWidth: 480,
      body: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.15,
        children: [
          for (final kind in ConnectionKind.values)
            _KindTile(
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

class _KindTile extends StatelessWidget {
  const _KindTile({required this.kind, required this.onTap});

  final ConnectionKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final color = homeKindColor(context, kind);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: palette.line),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(homeKindIcon(kind), size: AppSpacing.xxl, color: color),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  homeKindName(context, kind),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(
                    Theme.of(context).colorScheme,
                  ).copyWith(color: palette.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData homeKindIcon(ConnectionKind kind) {
  return switch (kind) {
    ConnectionKind.serial => Icons.usb,
    ConnectionKind.ble => Icons.bluetooth,
    ConnectionKind.mqtt => Icons.cloud_outlined,
    ConnectionKind.tcp => Icons.settings_ethernet,
    ConnectionKind.udp => Icons.wifi_tethering,
  };
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
