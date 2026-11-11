import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../license/cubit/license_cubit.dart';
import '../../serial/data/serial_stamp.dart';
import '../../serial/widget/serial_chrome.dart';
import '../cubit/mcp_cubit.dart';
import '../cubit/mcp_state.dart';
import 'mcp_license_gate.dart';

/// 右栏 MCP 日志页：样式对齐数据日志系统行。
class McpLogPanel extends StatefulWidget {
  const McpLogPanel({super.key});

  @override
  State<McpLogPanel> createState() => _McpLogPanelState();
}

class _McpLogPanelState extends State<McpLogPanel> {
  final _searchFocus = FocusNode();
  final _scroll = ScrollController();
  var _query = '';

  @override
  void dispose() {
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final licensed = context.select<LicenseCubit, bool>(
      (c) => c.state.isActivated,
    );
    if (!licensed) {
      return const _McpLockedPanel();
    }
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return BlocConsumer<McpCubit, McpState>(
      listenWhen: (a, b) => a.logs.length != b.logs.length,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scroll.hasClients) return;
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        });
      },
      builder: (context, state) {
        final q = _query.trim().toLowerCase();
        final rows = q.isEmpty
            ? state.logs
            : state.logs
                  .where(
                    (e) =>
                        '${fullStamp(e.time)} ${e.body}'.toLowerCase().contains(
                          q,
                        ),
                  )
                  .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    t.mcp.logTitle,
                    style: AppTextStyles.body(cs).copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    t.mcp.logCount(count: rows.length),
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted),
                  ),
                  const Spacer(),
                  SerialSearchField(
                    focusNode: _searchFocus,
                    hint: t.mcp.logSearch,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.line),
            Expanded(
              child: rows.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        t.mcp.logEmpty,
                        style: AppTextStyles.body(
                          cs,
                        ).copyWith(color: palette.muted),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            '[${fullStamp(row.time)}]# ${row.body}',
                            style: AppTextStyles.mono(cs).copyWith(
                              color: palette.logSys,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _McpLockedPanel extends StatelessWidget {
  const _McpLockedPanel();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.mcp.logTitle,
            style: AppTextStyles.body(cs).copyWith(
              color: palette.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            t.mcp.requiresLicense,
            style: AppTextStyles.body(cs).copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => ensureMcpLicensed(context),
            child: Text(t.mcp.openSupport),
          ),
        ],
      ),
    );
  }
}
