import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/data/serial_session_factory.dart';
import '../../serial/page/serial_console_page.dart';
import '../cubit/home_tabs_cubit.dart';
import '../data/home_tab_store.dart';
import '../widget/home_connection_bar.dart';

/// 首页：连接页签 + 当前页签的调试台。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeTabsCubit(
        sessions: context.read<SerialSessionFactory>(),
        tabs: context.read<HomeTabStore>(),
      )..start(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabsCubit>().state;
    final palette = SerialPalette.of(context);
    if (state.tabs.isEmpty) {
      final t = Translations.of(context);
      return ColoredBox(
        color: palette.win,
        child: Column(
          children: [
            const HomeConnectionBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    t.home.emptyConnections,
                    style: AppTextStyles.body(
                      Theme.of(context).colorScheme,
                    ).copyWith(color: palette.muted),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final index = state.tabs.indexWhere((tab) => tab.id == state.activeId);
    return IndexedStack(
      index: index < 0 ? 0 : index,
      sizing: StackFit.expand,
      children: [
        for (final tab in state.tabs)
          _SerialPane(
            key: ValueKey(tab.id),
            tabId: tab.id,
            active: tab.id == state.activeId,
          ),
      ],
    );
  }
}

class _SerialPane extends StatelessWidget {
  const _SerialPane({super.key, required this.tabId, required this.active});

  final String tabId;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final console = context.read<HomeTabsCubit>().consoleFor(tabId);
    if (console == null) return const SizedBox.shrink();
    return BlocProvider.value(
      value: console,
      child: SerialConsoleView(
        shortcutsEnabled: active,
        belowMenu: active ? const HomeConnectionBar() : null,
      ),
    );
  }
}
