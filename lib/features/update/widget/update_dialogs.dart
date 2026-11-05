import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../i18n/i18n.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_dialog.dart';
import '../cubit/update_cubit.dart';
import '../cubit/update_state.dart';
import '../model/app_release.dart';

/// 监听 [UpdateCubit]：手动结果用 SnackBar，有更新/下载用对话框。
class UpdateHost extends StatefulWidget {
  const UpdateHost({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateHost> createState() => _UpdateHostState();
}

class _UpdateHostState extends State<UpdateHost> {
  bool _started = false;
  bool _dialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UpdateCubit>().checkOnStartup();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdateCubit, UpdateState>(
      listener: _onState,
      child: widget.child,
    );
  }

  Future<void> _onState(BuildContext context, UpdateState state) async {
    final t = Translations.of(context);
    final cubit = context.read<UpdateCubit>();
    switch (state) {
      case UpdateIdle() || UpdateChecking():
        return;
      case UpdateUpToDate(:final version, :final manual):
        if (manual) {
          AppSnackBar.success(
            context,
            t.update.upToDate(version: version),
          );
          cubit.clearFeedback();
        }
      case UpdateFailed(:final message, :final manual):
        if (manual) {
          AppSnackBar.error(context, message);
          cubit.clearFeedback();
        }
      case UpdateAvailable(
        :final currentVersion,
        :final release,
        :final canInstall,
      ):
        if (_dialogOpen) return;
        _dialogOpen = true;
        await _showAvailableDialog(
          context,
          currentVersion: currentVersion,
          release: release,
          canInstall: canInstall,
        );
        _dialogOpen = false;
        // 点「下载并安装」会在关闭本对话框后立刻进入 downloading，补开进度框。
        if (mounted &&
            context.read<UpdateCubit>().state is UpdateDownloading) {
          _dialogOpen = true;
          await _showDownloadingDialog(context);
          _dialogOpen = false;
        }
      case UpdateDownloading():
        if (_dialogOpen) return;
        _dialogOpen = true;
        await _showDownloadingDialog(context);
        _dialogOpen = false;
    }
  }
}

Future<void> _showAvailableDialog(
  BuildContext context, {
  required String currentVersion,
  required AppRelease release,
  required bool canInstall,
}) {
  final t = Translations.of(context);
  final cubit = context.read<UpdateCubit>();
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) {
      final palette = SerialPalette.of(dialogContext);
      final cs = Theme.of(dialogContext).colorScheme;
      final notes = release.body;
      return SerialDialogFrame(
        title: t.update.availableTitle,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.update.versionLine(
                current: currentVersion,
                latest: release.version,
              ),
              style: AppTextStyles.body(cs).copyWith(color: palette.text),
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                t.update.releaseNotes,
                style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
              ),
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: SelectableText(
                    notes,
                    style: AppTextStyles.mono(
                      cs,
                      fontSize: 12,
                      color: palette.text,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          SerialButton(
            label: t.common.close,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.dismissAvailable(release);
            },
          ),
          if (canInstall)
            SerialButton(
              label: t.update.downloadInstall,
              primary: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                cubit.downloadAndInstall(release);
              },
            )
          else
            SerialButton(
              label: t.update.openReleasePage,
              primary: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                cubit.openReleasePage(release);
              },
            ),
        ],
      );
    },
  );
}

Future<void> _showDownloadingDialog(BuildContext context) {
  final t = Translations.of(context);
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) {
      return BlocConsumer<UpdateCubit, UpdateState>(
        listener: (context, state) {
          if (state is! UpdateDownloading) {
            Navigator.of(dialogContext).maybePop();
          }
        },
        builder: (context, state) {
          final palette = SerialPalette.of(context);
          final cs = Theme.of(context).colorScheme;
          final downloading = state is UpdateDownloading ? state : null;
          final progress = downloading?.progress;
          final received = downloading?.received ?? 0;
          final total = downloading?.total;
          final detail = total != null && total > 0
              ? t.update.downloadProgress(
                  received: _formatBytes(received),
                  total: _formatBytes(total),
                )
              : t.update.downloading;
          return SerialDialogFrame(
            title: t.update.downloadingTitle,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail,
                  style: AppTextStyles.body(cs).copyWith(color: palette.text),
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ],
            ),
            actions: const [],
          );
        },
      );
    },
  );
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}
