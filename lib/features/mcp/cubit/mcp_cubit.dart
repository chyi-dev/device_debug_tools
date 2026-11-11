import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../model/mcp_models.dart';
import '../repository/mcp_repository.dart';
import 'mcp_state.dart';

class McpCubit extends Cubit<McpState> {
  McpCubit({required McpRepository repository})
    : _repo = repository,
      super(McpState.initial(repository.settings)) {
    _repo.addListener(_sync);
    _sync();
  }

  final McpRepository _repo;

  void bindWorkbench(McpWorkbench workbench) => _repo.bindWorkbench(workbench);

  void unbindWorkbench() => _repo.unbindWorkbench();

  Future<void> start() async {
    try {
      await _repo.startIfNeeded();
      _sync();
    } catch (e, s) {
      AppLogger.i.error(
        'MCP cubit start failed',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
      _sync();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      await _repo.setEnabled(enabled);
    } catch (e, s) {
      AppLogger.i.error(
        'MCP toggle failed',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
    }
    _sync();
  }

  Future<void> saveSettings(McpSettings settings) async {
    try {
      await _repo.updateSettings(settings);
    } catch (e, s) {
      AppLogger.i.error(
        'MCP settings failed',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
    }
    _sync();
  }

  Future<void> resolveMessage(String id, {required bool enable}) async {
    await _repo.resolveMessage(id, enable: enable);
    _sync();
  }

  void _sync() {
    if (isClosed) return;
    emit(
      McpState(
        settings: _repo.settings,
        listening: _repo.listening,
        clientConnected: _repo.clientConnected,
        boundPort: _repo.boundPort,
        pending: _repo.pending,
        logs: _repo.logs,
      ),
    );
  }

  @override
  Future<void> close() async {
    _repo.removeListener(_sync);
    await _repo.dispose();
    return super.close();
  }
}
