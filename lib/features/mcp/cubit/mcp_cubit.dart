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
  var _licenseActive = false;

  bool get licenseActive => _licenseActive;

  void bindWorkbench(McpWorkbench workbench) => _repo.bindWorkbench(workbench);

  void unbindWorkbench() => _repo.unbindWorkbench();

  /// 授权就绪后调用；未激活时不监听本机端口，激活后按已存开关拉起。
  Future<void> setLicenseActive(bool active) async {
    _licenseActive = active;
    try {
      if (!active) {
        await _repo.suspendListening();
      } else {
        await _repo.startIfNeeded();
      }
    } catch (e, s) {
      AppLogger.i.error(
        'MCP license gate failed',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
    }
    _sync();
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled && !_licenseActive) {
      _sync();
      return;
    }
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
    if (settings.enabled && !_licenseActive) {
      settings = settings.copyWith(enabled: false);
    }
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
