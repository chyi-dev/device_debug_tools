///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$en app = _Translations$app$en._(_root);
	@override late final _Translations$nav$en nav = _Translations$nav$en._(_root);
	@override late final _Translations$home$en home = _Translations$home$en._(_root);
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$serial$en serial = _Translations$serial$en._(_root);
}

// Path: app
class _Translations$app$en extends Translations$app$zh {
	_Translations$app$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Device Debug Tools';
}

// Path: nav
class _Translations$nav$en extends Translations$nav$zh {
	_Translations$nav$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get home => 'Home';
	@override String get serial => 'Serial';
}

// Path: home
class _Translations$home$en extends Translations$home$zh {
	_Translations$home$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get welcome => 'Welcome to Device Debug Tools';
	@override String get placeholder => 'Add feature modules under lib/features';
}

// Path: common
class _Translations$common$en extends Translations$common$zh {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get confirm => 'Confirm';
	@override String get cancel => 'Cancel';
	@override String get retry => 'Retry';
	@override String get empty => 'No data';
	@override String get error => 'Failed to load';
	@override String get loading => 'Loading…';
	@override String get save => 'Save';
	@override String get delete => 'Delete';
	@override String get close => 'Close';
	@override String get add => 'Add';
	@override String get edit => 'Edit';
}

// Path: serial
class _Translations$serial$en extends Translations$serial$zh {
	_Translations$serial$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$serial$menu$en menu = _Translations$serial$menu$en._(_root);
	@override late final _Translations$serial$kbd$en kbd = _Translations$serial$kbd$en._(_root);
	@override String get compact => 'Compact';
	@override String get toolsPanel => 'Tools';
	@override String get compactTip => 'Hide or show the left settings panel';
	@override String get toolsTip => 'Show or hide the tools panel';
	@override late final _Translations$serial$port$en port = _Translations$serial$port$en._(_root);
	@override late final _Translations$serial$parityOpt$en parityOpt = _Translations$serial$parityOpt$en._(_root);
	@override late final _Translations$serial$flowOpt$en flowOpt = _Translations$serial$flowOpt$en._(_root);
	@override late final _Translations$serial$mark$en mark = _Translations$serial$mark$en._(_root);
	@override late final _Translations$serial$rx$en rx = _Translations$serial$rx$en._(_root);
	@override late final _Translations$serial$tx$en tx = _Translations$serial$tx$en._(_root);
	@override late final _Translations$serial$checksum$en checksum = _Translations$serial$checksum$en._(_root);
	@override late final _Translations$serial$log$en log = _Translations$serial$log$en._(_root);
	@override late final _Translations$serial$sendBox$en sendBox = _Translations$serial$sendBox$en._(_root);
	@override late final _Translations$serial$tab$en tab = _Translations$serial$tab$en._(_root);
	@override late final _Translations$serial$quick$en quick = _Translations$serial$quick$en._(_root);
	@override late final _Translations$serial$batch$en batch = _Translations$serial$batch$en._(_root);
	@override late final _Translations$serial$reply$en reply = _Translations$serial$reply$en._(_root);
	@override late final _Translations$serial$history$en history = _Translations$serial$history$en._(_root);
	@override late final _Translations$serial$calc$en calc = _Translations$serial$calc$en._(_root);
	@override late final _Translations$serial$status$en status = _Translations$serial$status$en._(_root);
	@override late final _Translations$serial$dialog$en dialog = _Translations$serial$dialog$en._(_root);
	@override late final _Translations$serial$validate$en validate = _Translations$serial$validate$en._(_root);
	@override late final _Translations$serial$notice$en notice = _Translations$serial$notice$en._(_root);
}

// Path: serial.menu
class _Translations$serial$menu$en extends Translations$serial$menu$zh {
	_Translations$serial$menu$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get file => 'File';
	@override String get settings => 'Settings';
	@override String get tools => 'Tools';
	@override String get help => 'Help';
	@override String get saveRecv => 'Save received data…';
	@override String get exportQuick => 'Export quick commands';
	@override String get importQuick => 'Import quick commands…';
	@override String get exportRules => 'Export auto-reply rules';
	@override String get importRules => 'Import auto-reply rules…';
	@override String get themeLight => 'Classic light';
	@override String get themeDark => 'Classic dark';
	@override String get compact => 'Compact (hide left panel)';
	@override String get toolsPanel => 'Show tools panel';
	@override String get keys => 'Keyboard shortcuts';
	@override String get about => 'About';
}

// Path: serial.kbd
class _Translations$serial$kbd$en extends Translations$serial$kbd$zh {
	_Translations$serial$kbd$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get ctrlS => 'Ctrl+S';
	@override String get f12 => 'F12';
}

// Path: serial.port
class _Translations$serial$port$en extends Translations$serial$port$zh {
	_Translations$serial$port$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Port';
	@override String get name => 'Port';
	@override String get baud => 'Baud';
	@override String get parity => 'Parity';
	@override String get dataBits => 'Data';
	@override String get stopBits => 'Stop';
	@override String get flow => 'Flow';
	@override String get refresh => 'Refresh';
	@override String get refreshTip => 'Scan serial ports again';
	@override String get open => 'Open';
	@override String get close => 'Close';
	@override String get empty => 'No ports';
	@override String get pinsTip => 'Pin status';
}

// Path: serial.parityOpt
class _Translations$serial$parityOpt$en extends Translations$serial$parityOpt$zh {
	_Translations$serial$parityOpt$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get none => 'NONE';
	@override String get odd => 'ODD';
	@override String get even => 'EVEN';
	@override String get mark => 'MARK';
	@override String get space => 'SPACE';
}

// Path: serial.flowOpt
class _Translations$serial$flowOpt$en extends Translations$serial$flowOpt$zh {
	_Translations$serial$flowOpt$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get none => 'NONE';
	@override String get rtsCts => 'RTS/CTS';
	@override String get dtrDsr => 'DTR/DSR';
	@override String get xonXoff => 'XON/XOFF';
}

// Path: serial.mark
class _Translations$serial$mark$en extends Translations$serial$mark$zh {
	_Translations$serial$mark$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get opened => 'OPENED';
	@override String get closed => 'CLOSED';
	@override String get recv => 'RECV';
	@override String get send => 'SEND';
	@override String get hex => 'HEX';
	@override String get ascii => 'ASCII';
}

// Path: serial.rx
class _Translations$serial$rx$en extends Translations$serial$rx$zh {
	_Translations$serial$rx$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Receive';
	@override String get logMode => 'Log mode';
	@override String get wrap => 'Wrap received text';
	@override String get hide => 'Hide received data';
	@override String get save => 'Save receive to file';
	@override String get scroll => 'Auto scroll';
	@override String get timeout => 'Packet timeout';
	@override String get saveData => 'Save data';
	@override String get clear => 'Clear';
}

// Path: serial.tx
class _Translations$serial$tx$en extends Translations$serial$tx$zh {
	_Translations$serial$tx$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Transmit';
	@override String get escape => 'Parse escape sequences';
	@override String get at => 'Append CR to AT commands';
	@override String get crlf => 'Append CR LF';
	@override String get checksum => 'Append checksum';
	@override String get clear => 'Clear after send';
	@override String get file => 'Open file source…';
	@override String get loop => 'Repeat every';
	@override String get quick => 'Quick commands';
	@override String get history => 'Send history';
}

// Path: serial.checksum
class _Translations$serial$checksum$en extends Translations$serial$checksum$zh {
	_Translations$serial$checksum$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get sum => 'SUM8';
	@override String get xor => 'XOR/BCC';
	@override String get lrc => 'LRC';
	@override String get crc8 => 'CRC8';
	@override String get crc16 => 'CRC16';
	@override String get crc32 => 'CRC32';
}

// Path: serial.log
class _Translations$serial$log$en extends Translations$serial$log$zh {
	_Translations$serial$log$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Data log';
	@override String get search => 'Search received data';
	@override String get waiting => 'Waiting for data…';
	@override String get closed => 'Port is closed. Choose a port on the left, then open it.';
	@override String matches({required Object count}) => '${count} matches';
	@override String records({required Object count}) => '${count} records';
	@override String get rxHidden => 'receive hidden';
	@override String opened({required Object port, required Object baud, required Object frame}) => '${port} opened · ${baud} ${frame}';
	@override String closedPort({required Object port}) => '${port} closed';
	@override String autoReply({required Object name, required Object count}) => 'Auto-reply "${name}" matched, sending ${count} replies';
	@override String batchStart({required Object name, required Object steps, required Object extra}) => 'Batch "${name}" started, ${steps} steps${extra}';
	@override String batchRounds({required Object rounds}) => ' × ${rounds} rounds';
	@override String batchDone({required Object name}) => 'Batch "${name}" finished';
	@override String batchFail({required Object step}) => 'Step ${step} failed, batch stopped';
	@override String get batchStopped => 'Batch stopped';
}

// Path: serial.sendBox
class _Translations$serial$sendBox$en extends Translations$serial$sendBox$zh {
	_Translations$serial$sendBox$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get send => 'Send';
	@override String get stopLoop => 'Stop';
	@override String get clear => 'Clear';
	@override String preview({required Object count, required Object hex}) => '${count} bytes: ${hex}';
	@override String get foot => 'Ctrl+Enter send · Esc stops repeat and batch';
	@override String get badHex => 'Invalid HEX: characters must form pairs';
	@override String get empty => 'Nothing to send';
}

// Path: serial.tab
class _Translations$serial$tab$en extends Translations$serial$tab$zh {
	_Translations$serial$tab$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get quick => 'Quick';
	@override String get batch => 'Batch';
	@override String get reply => 'Auto-reply';
	@override String get history => 'History';
	@override String get calc => 'Checksum';
}

// Path: serial.quick
class _Translations$serial$quick$en extends Translations$serial$quick$zh {
	_Translations$serial$quick$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get note => 'Send now. These do not enter history';
	@override String get send => 'Send';
	@override String get empty => 'No quick commands yet. Add one you send often.';
	@override String get newTitle => 'New quick command';
	@override String get editTitle => 'Edit quick command';
	@override String get name => 'Name';
	@override String get format => 'Format';
	@override String get data => 'Payload';
	@override String get key => 'Shortcut';
	@override String get noKey => 'None';
}

// Path: serial.batch
class _Translations$serial$batch$en extends Translations$serial$batch$zh {
	_Translations$serial$batch$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get kNew => 'New';
	@override String get edit => 'Edit';
	@override String get delete => 'Delete';
	@override String get repeat => 'Repeat';
	@override String get rounds => 'rounds';
	@override String get stopOnFail => 'Stop on failure';
	@override String get start => 'Start';
	@override String get stop => 'Stop';
	@override String commands({required Object count}) => '${count} commands';
	@override String progress({required Object round, required Object rounds, required Object step, required Object total}) => 'Round ${round}/${rounds} · step ${step}/${total}';
	@override String get colIndex => '#';
	@override String get colDelay => 'Delay';
	@override String get colData => 'Payload';
	@override String get colNote => 'Note';
	@override String get explain => 'Delay is the wait before sending that step. The first step sends immediately.';
	@override String get empty => 'No batch jobs yet.';
	@override String get newTitle => 'New batch job';
	@override String get editTitle => 'Edit batch job';
	@override String get name => 'Name';
	@override String get sequence => 'Steps (delay ms / data / note)';
	@override String get addStep => 'Add step';
	@override String get delayHint => 'Delay ms';
	@override String get dataHint => 'HEX payload';
	@override String get noteHint => 'Note';
}

// Path: serial.reply
class _Translations$serial$reply$en extends Translations$serial$reply$zh {
	_Translations$serial$reply$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String note({required Object enabled, required Object total}) => '${enabled} / ${total} enabled, matched in list order';
	@override String get add => 'Add rule';
	@override String get fire => 'Run';
	@override String hits({required Object count}) => '${count} hits';
	@override String get explain => 'When received data matches, replies are sent in order. Each delay starts after the previous reply.';
	@override String get newTitle => 'New auto-reply rule';
	@override String get editTitle => 'Edit auto-reply rule';
	@override String get name => 'Name';
	@override String get match => 'Match';
	@override String get pattern => 'Pattern';
	@override String get patternHint => 'HEX, e.g. A5 5A 03';
	@override String get list => 'Replies';
	@override String get addReply => 'Add reply';
	@override String get enable => 'Enable this rule';
	@override String get delayHint => 'Delay ms';
	@override String get dataHint => 'Reply HEX';
	@override String get prefix => 'Prefix';
	@override String get frame => 'Full frame';
	@override String get contains => 'Contains';
	@override String get toggleOn => 'Enable / disable';
}

// Path: serial.history
class _Translations$serial$history$en extends Translations$serial$history$zh {
	_Translations$serial$history$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get note => 'Only data sent with the Send button is recorded';
	@override String get clear => 'Clear';
	@override String get resendTip => 'Send again';
	@override String get beforeStart => 'Earlier';
	@override String get fillHint => 'Time sends again · Fill puts it back in the box';
	@override String get fill => 'Fill';
	@override String get empty => 'No send history yet.';
}

// Path: serial.calc
class _Translations$serial$calc$en extends Translations$serial$calc$zh {
	_Translations$serial$calc$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get fromTx => 'Use send box';
	@override String get bytes => 'Bytes';
	@override String get sum => 'SUM8';
	@override String get xor => 'XOR / BCC';
	@override String get lrc => 'LRC';
	@override String get crc8 => 'CRC8';
	@override String get crc16 => 'CRC16 MODBUS';
	@override String get crc32 => 'CRC32';
	@override String get append => 'Append';
	@override String get badHex => 'Enter hex characters in pairs';
	@override String get empty => 'Enter some data';
	@override String get explain => 'CRC16 is MODBUS (low byte first). CRC32 is IEEE (big-endian). Append writes the checksum into the send box.';
}

// Path: serial.status
class _Translations$serial$status$en extends Translations$serial$status$zh {
	_Translations$serial$status$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get reset => 'Reset counts';
	@override String reply({required Object enabled, required Object total}) => 'Auto-reply ${enabled}/${total}';
	@override String saving({required Object name, required Object count}) => 'Saving ${name} · ${count} lines';
	@override String fileMeta({required Object name, required Object count}) => '${name} · ${count} bytes';
}

// Path: serial.dialog
class _Translations$serial$dialog$en extends Translations$serial$dialog$zh {
	_Translations$serial$dialog$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get deleteTitle => 'Delete';
	@override String deleteQuick({required Object name}) => 'Delete quick command "${name}"? This cannot be undone.';
	@override String deleteRule({required Object name}) => 'Delete rule "${name}"? This cannot be undone.';
	@override String deleteBatch({required Object name}) => 'Delete batch "${name}"? This cannot be undone.';
	@override String deleteHistory({required Object count}) => 'Delete all ${count} history entries? This cannot be undone.';
	@override String get keysTitle => 'Keyboard shortcuts';
	@override String get know => 'OK';
	@override String get aboutTitle => 'About';
	@override String get aboutBody => 'Device Debug Tools · serial console. Open a port to send and receive.';
	@override String get aboutDetail => 'Quick commands, batch send, and auto-reply do nothing while the port is closed. Incoming bytes are merged by the packet timeout. Checksums: SUM8, XOR/BCC, LRC, CRC8, CRC16 (MODBUS, low byte first), CRC32 (IEEE, big-endian).';
	@override String get keySend => 'Send (while the send box is focused)';
	@override String get keyQuick => 'Send the quick command bound to that key';
	@override String get keyStop => 'Stop repeat send and batch send';
	@override String get keySave => 'Save received data';
	@override String get keyClear => 'Clear the receive log';
	@override String get keySearch => 'Focus search';
	@override String get keyHelp => 'Open this list';
	@override String get ctrlEnter => 'Ctrl+Enter';
	@override String get fKeys => 'F1–F8';
	@override String get esc => 'Esc';
	@override String get ctrlL => 'Ctrl+L';
	@override String get ctrlF => 'Ctrl+F';
	@override String get remove => 'Remove';
}

// Path: serial.validate
class _Translations$serial$validate$en extends Translations$serial$validate$zh {
	_Translations$serial$validate$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get needName => 'Enter a name';
	@override String get needData => 'Enter the payload';
	@override String get badHex => 'HEX must be pairs of hex characters';
	@override String get needRuleName => 'Enter a rule name';
	@override String get badPattern => 'Pattern must be HEX';
	@override String get needReply => 'Add at least one reply';
	@override String badReply({required Object n}) => 'Reply ${n} must be HEX';
	@override String badDelay({required Object n}) => 'Delay ${n} must be zero or greater';
	@override String get needTask => 'Enter a task name';
	@override String get needStep => 'Add at least one command';
	@override String badStep({required Object n}) => 'Step ${n} must be HEX';
	@override String badStepDelay({required Object n}) => 'Delay ${n} must be zero or greater';
}

// Path: serial.notice
class _Translations$serial$notice$en extends Translations$serial$notice$zh {
	_Translations$serial$notice$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get ready => 'Ready';
	@override String get portOpened => 'Port opened';
	@override String get portClosed => 'Port closed';
	@override String get portClosedSend => 'Port is closed. Send was blocked';
	@override String get portClosedRule => 'Port is closed. The rule will not run';
	@override String get portClosedBatch => 'Port is closed. Batch was not started';
	@override String get noPort => 'Choose a port first';
	@override String get portBusy => 'Close the current port before switching';
	@override String openFailed({required Object detail}) => 'Could not open the port: ${detail}';
	@override String configFailed({required Object detail}) => 'Settings were not applied: ${detail}';
	@override String get configPartial => 'Port opened; some line settings may not match the UI (Windows driver limit)';
	@override String get baudInvalid => 'Baud rate must be a positive integer';
	@override String get timeoutInvalid => 'Packet timeout must be zero or greater';
	@override String get periodInvalid => 'Repeat interval must be at least 10 ms';
	@override String get repeatInvalid => 'Repeat count must be a positive integer';
	@override String scanDone({required Object count}) => 'Scan finished, ${count} ports found';
	@override String paramsApplied({required Object conn}) => 'Settings applied: ${conn}';
	@override String timeoutHint({required Object ms}) => 'Packet timeout ${ms} ms';
	@override String get timeoutSplitHint => 'Timeout is under 8 ms, so a burst may show as several records';
	@override String get saveStarted => 'Recording received data. Uncheck to write the file';
	@override String saveWritten({required Object name, required Object count}) => 'Wrote ${name} (${count} lines)';
	@override String get logSaved => 'Received data saved as text';
	@override String get recvCleared => 'Receive log cleared';
	@override String loopStarted({required Object period}) => 'Repeating every ${period} ms';
	@override String get loopStopped => 'Repeat stopped';
	@override String batchRunning({required Object step, required Object total}) => 'Batch running · step ${step}/${total}';
	@override String get batchEnded => 'Batch finished';
	@override String ruleOn({required Object name}) => '${name} enabled';
	@override String ruleOff({required Object name}) => '${name} disabled';
	@override String get deleted => 'Deleted';
	@override String get quickSaved => 'Quick command saved';
	@override String get ruleSaved => 'Rule saved';
	@override String get batchSaved => 'Batch saved';
	@override String checksumFilled({required Object text}) => 'Filled the send box: ${text}';
	@override String get exportedQuick => 'Quick commands exported';
	@override String get exportedRules => 'Rules exported';
	@override String imported({required Object count}) => 'Imported ${count} items';
	@override String get importInvalid => 'This file is not an exported JSON list';
	@override String fileLoaded({required Object name}) => 'Loaded ${name}';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Device Debug Tools',
			'nav.home' => 'Home',
			'nav.serial' => 'Serial',
			'home.welcome' => 'Welcome to Device Debug Tools',
			'home.placeholder' => 'Add feature modules under lib/features',
			'common.confirm' => 'Confirm',
			'common.cancel' => 'Cancel',
			'common.retry' => 'Retry',
			'common.empty' => 'No data',
			'common.error' => 'Failed to load',
			'common.loading' => 'Loading…',
			'common.save' => 'Save',
			'common.delete' => 'Delete',
			'common.close' => 'Close',
			'common.add' => 'Add',
			'common.edit' => 'Edit',
			'serial.menu.file' => 'File',
			'serial.menu.settings' => 'Settings',
			'serial.menu.tools' => 'Tools',
			'serial.menu.help' => 'Help',
			'serial.menu.saveRecv' => 'Save received data…',
			'serial.menu.exportQuick' => 'Export quick commands',
			'serial.menu.importQuick' => 'Import quick commands…',
			'serial.menu.exportRules' => 'Export auto-reply rules',
			'serial.menu.importRules' => 'Import auto-reply rules…',
			'serial.menu.themeLight' => 'Classic light',
			'serial.menu.themeDark' => 'Classic dark',
			'serial.menu.compact' => 'Compact (hide left panel)',
			'serial.menu.toolsPanel' => 'Show tools panel',
			'serial.menu.keys' => 'Keyboard shortcuts',
			'serial.menu.about' => 'About',
			'serial.kbd.ctrlS' => 'Ctrl+S',
			'serial.kbd.f12' => 'F12',
			'serial.compact' => 'Compact',
			'serial.toolsPanel' => 'Tools',
			'serial.compactTip' => 'Hide or show the left settings panel',
			'serial.toolsTip' => 'Show or hide the tools panel',
			'serial.port.title' => 'Port',
			'serial.port.name' => 'Port',
			'serial.port.baud' => 'Baud',
			'serial.port.parity' => 'Parity',
			'serial.port.dataBits' => 'Data',
			'serial.port.stopBits' => 'Stop',
			'serial.port.flow' => 'Flow',
			'serial.port.refresh' => 'Refresh',
			'serial.port.refreshTip' => 'Scan serial ports again',
			'serial.port.open' => 'Open',
			'serial.port.close' => 'Close',
			'serial.port.empty' => 'No ports',
			'serial.port.pinsTip' => 'Pin status',
			'serial.parityOpt.none' => 'NONE',
			'serial.parityOpt.odd' => 'ODD',
			'serial.parityOpt.even' => 'EVEN',
			'serial.parityOpt.mark' => 'MARK',
			'serial.parityOpt.space' => 'SPACE',
			'serial.flowOpt.none' => 'NONE',
			'serial.flowOpt.rtsCts' => 'RTS/CTS',
			'serial.flowOpt.dtrDsr' => 'DTR/DSR',
			'serial.flowOpt.xonXoff' => 'XON/XOFF',
			'serial.mark.opened' => 'OPENED',
			'serial.mark.closed' => 'CLOSED',
			'serial.mark.recv' => 'RECV',
			'serial.mark.send' => 'SEND',
			'serial.mark.hex' => 'HEX',
			'serial.mark.ascii' => 'ASCII',
			'serial.rx.title' => 'Receive',
			'serial.rx.logMode' => 'Log mode',
			'serial.rx.wrap' => 'Wrap received text',
			'serial.rx.hide' => 'Hide received data',
			'serial.rx.save' => 'Save receive to file',
			'serial.rx.scroll' => 'Auto scroll',
			'serial.rx.timeout' => 'Packet timeout',
			'serial.rx.saveData' => 'Save data',
			'serial.rx.clear' => 'Clear',
			'serial.tx.title' => 'Transmit',
			'serial.tx.escape' => 'Parse escape sequences',
			'serial.tx.at' => 'Append CR to AT commands',
			'serial.tx.crlf' => 'Append CR LF',
			'serial.tx.checksum' => 'Append checksum',
			'serial.tx.clear' => 'Clear after send',
			'serial.tx.file' => 'Open file source…',
			'serial.tx.loop' => 'Repeat every',
			'serial.tx.quick' => 'Quick commands',
			'serial.tx.history' => 'Send history',
			'serial.checksum.sum' => 'SUM8',
			'serial.checksum.xor' => 'XOR/BCC',
			'serial.checksum.lrc' => 'LRC',
			'serial.checksum.crc8' => 'CRC8',
			'serial.checksum.crc16' => 'CRC16',
			'serial.checksum.crc32' => 'CRC32',
			'serial.log.title' => 'Data log',
			'serial.log.search' => 'Search received data',
			'serial.log.waiting' => 'Waiting for data…',
			'serial.log.closed' => 'Port is closed. Choose a port on the left, then open it.',
			'serial.log.matches' => ({required Object count}) => '${count} matches',
			'serial.log.records' => ({required Object count}) => '${count} records',
			'serial.log.rxHidden' => 'receive hidden',
			'serial.log.opened' => ({required Object port, required Object baud, required Object frame}) => '${port} opened · ${baud} ${frame}',
			'serial.log.closedPort' => ({required Object port}) => '${port} closed',
			'serial.log.autoReply' => ({required Object name, required Object count}) => 'Auto-reply "${name}" matched, sending ${count} replies',
			'serial.log.batchStart' => ({required Object name, required Object steps, required Object extra}) => 'Batch "${name}" started, ${steps} steps${extra}',
			'serial.log.batchRounds' => ({required Object rounds}) => ' × ${rounds} rounds',
			'serial.log.batchDone' => ({required Object name}) => 'Batch "${name}" finished',
			'serial.log.batchFail' => ({required Object step}) => 'Step ${step} failed, batch stopped',
			'serial.log.batchStopped' => 'Batch stopped',
			'serial.sendBox.send' => 'Send',
			'serial.sendBox.stopLoop' => 'Stop',
			'serial.sendBox.clear' => 'Clear',
			'serial.sendBox.preview' => ({required Object count, required Object hex}) => '${count} bytes: ${hex}',
			'serial.sendBox.foot' => 'Ctrl+Enter send · Esc stops repeat and batch',
			'serial.sendBox.badHex' => 'Invalid HEX: characters must form pairs',
			'serial.sendBox.empty' => 'Nothing to send',
			'serial.tab.quick' => 'Quick',
			'serial.tab.batch' => 'Batch',
			'serial.tab.reply' => 'Auto-reply',
			'serial.tab.history' => 'History',
			'serial.tab.calc' => 'Checksum',
			'serial.quick.note' => 'Send now. These do not enter history',
			'serial.quick.send' => 'Send',
			'serial.quick.empty' => 'No quick commands yet. Add one you send often.',
			'serial.quick.newTitle' => 'New quick command',
			'serial.quick.editTitle' => 'Edit quick command',
			'serial.quick.name' => 'Name',
			'serial.quick.format' => 'Format',
			'serial.quick.data' => 'Payload',
			'serial.quick.key' => 'Shortcut',
			'serial.quick.noKey' => 'None',
			'serial.batch.kNew' => 'New',
			'serial.batch.edit' => 'Edit',
			'serial.batch.delete' => 'Delete',
			'serial.batch.repeat' => 'Repeat',
			'serial.batch.rounds' => 'rounds',
			'serial.batch.stopOnFail' => 'Stop on failure',
			'serial.batch.start' => 'Start',
			'serial.batch.stop' => 'Stop',
			'serial.batch.commands' => ({required Object count}) => '${count} commands',
			'serial.batch.progress' => ({required Object round, required Object rounds, required Object step, required Object total}) => 'Round ${round}/${rounds} · step ${step}/${total}',
			'serial.batch.colIndex' => '#',
			'serial.batch.colDelay' => 'Delay',
			'serial.batch.colData' => 'Payload',
			'serial.batch.colNote' => 'Note',
			'serial.batch.explain' => 'Delay is the wait before sending that step. The first step sends immediately.',
			'serial.batch.empty' => 'No batch jobs yet.',
			'serial.batch.newTitle' => 'New batch job',
			'serial.batch.editTitle' => 'Edit batch job',
			'serial.batch.name' => 'Name',
			'serial.batch.sequence' => 'Steps (delay ms / data / note)',
			'serial.batch.addStep' => 'Add step',
			'serial.batch.delayHint' => 'Delay ms',
			'serial.batch.dataHint' => 'HEX payload',
			'serial.batch.noteHint' => 'Note',
			'serial.reply.note' => ({required Object enabled, required Object total}) => '${enabled} / ${total} enabled, matched in list order',
			'serial.reply.add' => 'Add rule',
			'serial.reply.fire' => 'Run',
			'serial.reply.hits' => ({required Object count}) => '${count} hits',
			'serial.reply.explain' => 'When received data matches, replies are sent in order. Each delay starts after the previous reply.',
			'serial.reply.newTitle' => 'New auto-reply rule',
			'serial.reply.editTitle' => 'Edit auto-reply rule',
			'serial.reply.name' => 'Name',
			'serial.reply.match' => 'Match',
			'serial.reply.pattern' => 'Pattern',
			'serial.reply.patternHint' => 'HEX, e.g. A5 5A 03',
			'serial.reply.list' => 'Replies',
			'serial.reply.addReply' => 'Add reply',
			'serial.reply.enable' => 'Enable this rule',
			'serial.reply.delayHint' => 'Delay ms',
			'serial.reply.dataHint' => 'Reply HEX',
			'serial.reply.prefix' => 'Prefix',
			'serial.reply.frame' => 'Full frame',
			'serial.reply.contains' => 'Contains',
			'serial.reply.toggleOn' => 'Enable / disable',
			'serial.history.note' => 'Only data sent with the Send button is recorded',
			'serial.history.clear' => 'Clear',
			'serial.history.resendTip' => 'Send again',
			'serial.history.beforeStart' => 'Earlier',
			'serial.history.fillHint' => 'Time sends again · Fill puts it back in the box',
			'serial.history.fill' => 'Fill',
			'serial.history.empty' => 'No send history yet.',
			'serial.calc.fromTx' => 'Use send box',
			'serial.calc.bytes' => 'Bytes',
			'serial.calc.sum' => 'SUM8',
			'serial.calc.xor' => 'XOR / BCC',
			'serial.calc.lrc' => 'LRC',
			'serial.calc.crc8' => 'CRC8',
			'serial.calc.crc16' => 'CRC16 MODBUS',
			'serial.calc.crc32' => 'CRC32',
			'serial.calc.append' => 'Append',
			'serial.calc.badHex' => 'Enter hex characters in pairs',
			'serial.calc.empty' => 'Enter some data',
			'serial.calc.explain' => 'CRC16 is MODBUS (low byte first). CRC32 is IEEE (big-endian). Append writes the checksum into the send box.',
			'serial.status.reset' => 'Reset counts',
			'serial.status.reply' => ({required Object enabled, required Object total}) => 'Auto-reply ${enabled}/${total}',
			'serial.status.saving' => ({required Object name, required Object count}) => 'Saving ${name} · ${count} lines',
			'serial.status.fileMeta' => ({required Object name, required Object count}) => '${name} · ${count} bytes',
			'serial.dialog.deleteTitle' => 'Delete',
			'serial.dialog.deleteQuick' => ({required Object name}) => 'Delete quick command "${name}"? This cannot be undone.',
			'serial.dialog.deleteRule' => ({required Object name}) => 'Delete rule "${name}"? This cannot be undone.',
			'serial.dialog.deleteBatch' => ({required Object name}) => 'Delete batch "${name}"? This cannot be undone.',
			'serial.dialog.deleteHistory' => ({required Object count}) => 'Delete all ${count} history entries? This cannot be undone.',
			'serial.dialog.keysTitle' => 'Keyboard shortcuts',
			'serial.dialog.know' => 'OK',
			'serial.dialog.aboutTitle' => 'About',
			'serial.dialog.aboutBody' => 'Device Debug Tools · serial console. Open a port to send and receive.',
			'serial.dialog.aboutDetail' => 'Quick commands, batch send, and auto-reply do nothing while the port is closed. Incoming bytes are merged by the packet timeout. Checksums: SUM8, XOR/BCC, LRC, CRC8, CRC16 (MODBUS, low byte first), CRC32 (IEEE, big-endian).',
			'serial.dialog.keySend' => 'Send (while the send box is focused)',
			'serial.dialog.keyQuick' => 'Send the quick command bound to that key',
			'serial.dialog.keyStop' => 'Stop repeat send and batch send',
			'serial.dialog.keySave' => 'Save received data',
			'serial.dialog.keyClear' => 'Clear the receive log',
			'serial.dialog.keySearch' => 'Focus search',
			'serial.dialog.keyHelp' => 'Open this list',
			'serial.dialog.ctrlEnter' => 'Ctrl+Enter',
			'serial.dialog.fKeys' => 'F1–F8',
			'serial.dialog.esc' => 'Esc',
			'serial.dialog.ctrlL' => 'Ctrl+L',
			'serial.dialog.ctrlF' => 'Ctrl+F',
			'serial.dialog.remove' => 'Remove',
			'serial.validate.needName' => 'Enter a name',
			'serial.validate.needData' => 'Enter the payload',
			'serial.validate.badHex' => 'HEX must be pairs of hex characters',
			'serial.validate.needRuleName' => 'Enter a rule name',
			'serial.validate.badPattern' => 'Pattern must be HEX',
			'serial.validate.needReply' => 'Add at least one reply',
			'serial.validate.badReply' => ({required Object n}) => 'Reply ${n} must be HEX',
			'serial.validate.badDelay' => ({required Object n}) => 'Delay ${n} must be zero or greater',
			'serial.validate.needTask' => 'Enter a task name',
			'serial.validate.needStep' => 'Add at least one command',
			'serial.validate.badStep' => ({required Object n}) => 'Step ${n} must be HEX',
			'serial.validate.badStepDelay' => ({required Object n}) => 'Delay ${n} must be zero or greater',
			'serial.notice.ready' => 'Ready',
			'serial.notice.portOpened' => 'Port opened',
			'serial.notice.portClosed' => 'Port closed',
			'serial.notice.portClosedSend' => 'Port is closed. Send was blocked',
			'serial.notice.portClosedRule' => 'Port is closed. The rule will not run',
			'serial.notice.portClosedBatch' => 'Port is closed. Batch was not started',
			'serial.notice.noPort' => 'Choose a port first',
			'serial.notice.portBusy' => 'Close the current port before switching',
			'serial.notice.openFailed' => ({required Object detail}) => 'Could not open the port: ${detail}',
			'serial.notice.configFailed' => ({required Object detail}) => 'Settings were not applied: ${detail}',
			'serial.notice.configPartial' => 'Port opened; some line settings may not match the UI (Windows driver limit)',
			'serial.notice.baudInvalid' => 'Baud rate must be a positive integer',
			'serial.notice.timeoutInvalid' => 'Packet timeout must be zero or greater',
			'serial.notice.periodInvalid' => 'Repeat interval must be at least 10 ms',
			'serial.notice.repeatInvalid' => 'Repeat count must be a positive integer',
			'serial.notice.scanDone' => ({required Object count}) => 'Scan finished, ${count} ports found',
			'serial.notice.paramsApplied' => ({required Object conn}) => 'Settings applied: ${conn}',
			'serial.notice.timeoutHint' => ({required Object ms}) => 'Packet timeout ${ms} ms',
			'serial.notice.timeoutSplitHint' => 'Timeout is under 8 ms, so a burst may show as several records',
			'serial.notice.saveStarted' => 'Recording received data. Uncheck to write the file',
			'serial.notice.saveWritten' => ({required Object name, required Object count}) => 'Wrote ${name} (${count} lines)',
			'serial.notice.logSaved' => 'Received data saved as text',
			'serial.notice.recvCleared' => 'Receive log cleared',
			'serial.notice.loopStarted' => ({required Object period}) => 'Repeating every ${period} ms',
			'serial.notice.loopStopped' => 'Repeat stopped',
			'serial.notice.batchRunning' => ({required Object step, required Object total}) => 'Batch running · step ${step}/${total}',
			'serial.notice.batchEnded' => 'Batch finished',
			'serial.notice.ruleOn' => ({required Object name}) => '${name} enabled',
			'serial.notice.ruleOff' => ({required Object name}) => '${name} disabled',
			'serial.notice.deleted' => 'Deleted',
			'serial.notice.quickSaved' => 'Quick command saved',
			'serial.notice.ruleSaved' => 'Rule saved',
			'serial.notice.batchSaved' => 'Batch saved',
			'serial.notice.checksumFilled' => ({required Object text}) => 'Filled the send box: ${text}',
			'serial.notice.exportedQuick' => 'Quick commands exported',
			'serial.notice.exportedRules' => 'Rules exported',
			'serial.notice.imported' => ({required Object count}) => 'Imported ${count} items',
			'serial.notice.importInvalid' => 'This file is not an exported JSON list',
			'serial.notice.fileLoaded' => ({required Object name}) => 'Loaded ${name}',
			_ => null,
		};
	}
}
