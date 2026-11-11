import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/serial_metrics.dart';
import '../cubit/mcp_cubit.dart';
import '../cubit/mcp_state.dart';
import 'mcp_messages_dialog.dart';

/// 顶栏右上角消息入口；有待处理项时显示条数。
class McpMessagesButton extends StatelessWidget {
  const McpMessagesButton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<McpCubit, McpState>(
      buildWhen: (a, b) => a.pendingCount != b.pendingCount,
      builder: (context, state) {
        final count = state.pendingCount;
        return Tooltip(
          message: t.mcp.messagesTip,
          child: InkWell(
            onTap: () => showMcpMessagesDialog(context),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              height: SerialMetrics.menuBar,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.mcp.messages,
                      style: AppTextStyles.caption(cs).copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.accent,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: AppTextStyles.caption(cs).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
