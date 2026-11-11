import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/data/serial_stamp.dart';
import '../../serial/widget/serial_dialog.dart';
import '../cubit/mcp_cubit.dart';
import '../cubit/mcp_state.dart';
import '../model/mcp_models.dart';

Future<void> showMcpMessagesDialog(BuildContext context) {
  final cubit = context.read<McpCubit>();
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: const _McpMessagesDialog(),
    ),
  );
}

class _McpMessagesDialog extends StatelessWidget {
  const _McpMessagesDialog();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<McpCubit, McpState>(
      builder: (context, state) {
        return SerialDialogFrame(
          title: t.mcp.messagesTitle,
          maxWidth: 560,
          body: SizedBox(
            height: 360,
            child: state.pending.isEmpty
                ? Center(
                    child: Text(
                      t.mcp.messagesEmpty,
                      style: AppTextStyles.body(
                        cs,
                      ).copyWith(color: palette.muted),
                    ),
                  )
                : ListView.separated(
                    itemCount: state.pending.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: palette.line),
                    itemBuilder: (context, index) {
                      final item = state.pending[index];
                      final kind = switch (item.kind) {
                        McpMessageKind.script => t.mcp.kindScript,
                        McpMessageKind.reply => t.mcp.kindReply,
                        McpMessageKind.quick => t.mcp.kindQuick,
                      };
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '$kind · ${item.name}',
                          style: AppTextStyles.body(cs).copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${item.tabName} · ${fullStamp(item.enqueuedAt)}',
                          style: AppTextStyles.caption(
                            cs,
                          ).copyWith(color: palette.muted),
                        ),
                        onTap: () async {
                          await showMcpMessageDetailDialog(context, item);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.common.close),
            ),
          ],
        );
      },
    );
  }
}

Future<void> showMcpMessageDetailDialog(
  BuildContext context,
  McpPendingMessage item,
) {
  final cubit = context.read<McpCubit>();
  final t = Translations.of(context);
  final title = switch (item.kind) {
    McpMessageKind.script => item.name,
    McpMessageKind.reply => t.mcp.replyTitle(name: item.name),
    McpMessageKind.quick => t.mcp.quickTitle(name: item.name),
  };
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: SerialDialogFrame(
        title: title,
        maxWidth: 640,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.mcp.targetTab(name: item.tabName),
              style: AppTextStyles.caption(
                Theme.of(context).colorScheme,
              ).copyWith(color: SerialPalette.of(context).muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: SelectableText(
                  item.body,
                  style: AppTextStyles.mono(
                    Theme.of(context).colorScheme,
                  ).copyWith(fontSize: 14, height: 1.6),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await cubit.resolveMessage(item.id, enable: false);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await cubit.resolveMessage(item.id, enable: true);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: Text(t.mcp.enableItem),
          ),
        ],
      ),
    ),
  );
}
