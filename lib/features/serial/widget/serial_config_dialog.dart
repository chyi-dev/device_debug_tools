import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../cubit/serial_console_cubit.dart';
import '../model/config_pack.dart';
import 'serial_chrome.dart';
import 'serial_dialog.dart';
import 'serial_l10n.dart';

Future<void> showConfigExport(BuildContext context) {
  final cubit = context.read<SerialConsoleCubit>();
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: const _ConfigDialog(),
    ),
  );
}

/// 先选文件；取消或格式不对（Cubit 已提示）时不弹清单。
Future<void> showConfigImport(BuildContext context) async {
  final cubit = context.read<SerialConsoleCubit>();
  final pack = await cubit.pickConfig();
  if (pack == null || !context.mounted) return;
  await showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: _ConfigDialog(incoming: pack),
    ),
  );
}

/// [incoming] 为空是导出清单，否则是导入清单。
class _ConfigDialog extends StatefulWidget {
  const _ConfigDialog({this.incoming});

  final ConfigPack? incoming;

  @override
  State<_ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<_ConfigDialog> {
  late final Set<ConfigPart> _checked = {
    ...widget.incoming?.parts ?? ConfigPart.values,
  };
  String _error = '';

  void _toggle(ConfigPart part, bool on) {
    setState(() {
      on ? _checked.add(part) : _checked.remove(part);
      _error = '';
    });
  }

  void _submit() {
    if (_checked.isEmpty) {
      setState(() => _error = Translations.of(context).serial.config.needOne);
      return;
    }
    final cubit = context.read<SerialConsoleCubit>();
    final incoming = widget.incoming;
    Navigator.of(context).pop();
    if (incoming == null) {
      cubit.exportConfig({..._checked});
    } else {
      cubit.applyConfig(incoming, {..._checked});
    }
  }

  List<String> _warnings(Translations t) {
    final incoming = widget.incoming;
    if (incoming == null) return const [];
    final c = t.serial.config;
    final live = incoming.enabledScripts;
    final running = context.read<SerialConsoleCubit>().state.batchRun != null;
    return [
      if (_checked.contains(ConfigPart.scripts) && live > 0)
        c.scriptsLive(count: live),
      if (_checked.contains(ConfigPart.batch) && running) c.batchStops,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final c = t.serial.config;
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final incoming = widget.incoming;
    final current = context.read<SerialConsoleCubit>().currentConfig();
    final muted = AppTextStyles.body(
      cs,
    ).copyWith(color: palette.muted, fontSize: 13, height: 1.6);
    final warnings = _warnings(t);
    return SerialDialogFrame(
      title: incoming == null ? c.exportTitle : c.importTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (incoming != null && incoming.legacy) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: palette.line),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm - 2,
                  ),
                  child: Text(
                    c.legacy,
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(incoming == null ? c.exportLead : c.importLead, style: muted),
          const SizedBox(height: AppSpacing.sm + 2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.field,
              border: Border.all(color: palette.line),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Column(
              children: [
                for (final part in ConfigPart.values)
                  _PartRow(
                    first: part == ConfigPart.values.first,
                    name: configPartName(t, part),
                    detail: _detail(t, part, current, incoming),
                    enabled: incoming == null || incoming.parts.contains(part),
                    checked: _checked.contains(part),
                    onChanged: (on) => _toggle(part, on),
                  ),
              ],
            ),
          ),
          for (final line in warnings) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(line, style: muted.copyWith(color: palette.accent)),
          ],
          const SizedBox(height: AppSpacing.sm),
          SerialDialogError(message: _error),
        ],
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SerialButton(
          label: incoming == null ? c.export : c.import,
          primary: true,
          onPressed: _submit,
        ),
      ],
    );
  }

  String _detail(
    Translations t,
    ConfigPart part,
    ConfigPack current,
    ConfigPack? incoming,
  ) {
    final now = configCountText(t, part, current.count(part) ?? 0);
    if (incoming == null) return now;
    final next = incoming.count(part);
    if (next == null) return t.serial.config.keep(current: now);
    return t.serial.config.replace(
      incoming: configCountText(t, part, next),
      current: now,
    );
  }
}

class _PartRow extends StatelessWidget {
  const _PartRow({
    required this.first,
    required this.name,
    required this.detail,
    required this.enabled,
    required this.checked,
    required this.onChanged,
  });

  final bool first;
  final String name;
  final String detail;
  final bool enabled;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final row = DecoratedBox(
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(top: BorderSide(color: palette.line2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 1,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: enabled && checked,
                onChanged: enabled ? (next) => onChanged(next ?? false) : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            SizedBox(
              width: 96,
              child: Text(
                name,
                style: AppTextStyles.body(cs).copyWith(
                  color: enabled ? palette.text : palette.muted,
                  fontWeight: enabled ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              child: Text(
                detail,
                textAlign: TextAlign.right,
                style: AppTextStyles.body(cs).copyWith(
                  color: palette.muted,
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!enabled) return row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!checked),
        child: row,
      ),
    );
  }
}
