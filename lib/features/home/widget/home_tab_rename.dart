import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_dialog.dart';
import '../cubit/home_tabs_cubit.dart';

Future<void> showHomeTabRename(
  BuildContext context, {
  required HomeTabsCubit cubit,
  required String id,
  required String initial,
}) {
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: _HomeTabRename(id: id, initial: initial),
    ),
  );
}

class _HomeTabRename extends StatefulWidget {
  const _HomeTabRename({required this.id, required this.initial});

  final String id;
  final String initial;

  @override
  State<_HomeTabRename> createState() => _HomeTabRenameState();
}

class _HomeTabRenameState extends State<_HomeTabRename> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    context.read<HomeTabsCubit>().rename(widget.id, _name.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    return SerialDialogFrame(
      title: t.home.renameTitle,
      body: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              child: Text(
                t.home.renameName,
                style: AppTextStyles.caption(
                  Theme.of(context).colorScheme,
                ).copyWith(color: palette.muted, fontSize: 13),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: SerialField(
                controller: _name,
                onSubmitted: (_) => _save(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SerialButton(label: t.common.save, primary: true, onPressed: _save),
      ],
    );
  }
}
