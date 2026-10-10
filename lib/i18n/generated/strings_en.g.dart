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
	@override late final _Translations$serial$script$en script = _Translations$serial$script$en._(_root);
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
	@override String get name => 'Address';
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
	@override String get fileHelp => 'About data files';
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
	@override String replySkipped({required Object name, required Object step}) => 'Auto-reply "${name}" reply ${step} refers to a missing capture, skipped';
	@override String batchStart({required Object name, required Object steps, required Object extra}) => 'Batch "${name}" started, ${steps} steps${extra}';
	@override String batchRounds({required Object rounds}) => ' × ${rounds} rounds';
	@override String batchDone({required Object name}) => 'Batch "${name}" finished';
	@override String batchFail({required Object step}) => 'Step ${step} failed, batch stopped';
	@override String get batchStopped => 'Batch stopped';
	@override String scriptBlocked({required Object name}) => 'Script "${name}" returned nil; frame blocked, not sent';
	@override String scriptFailed({required Object name}) => 'Script "${name}" failed; frame not sent, see the script run log';
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
	@override String get script => 'Script';
}

// Path: serial.script
class _Translations$serial$script$en extends Translations$serial$script$zh {
	_Translations$serial$script$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String note({required Object enabled, required Object total}) => '${enabled} / ${total} enabled';
	@override String get add => 'New';
	@override String get waiting => 'Waiting';
	@override String get off => 'Disabled';
	@override String outputs({required Object count}) => '${count} outputs';
	@override String get broken => 'Error';
	@override String get noHook => 'No hook';
	@override String get explain => 'Lua scripts. on_receive runs after data arrives; before_send intercepts every outgoing frame (including quick commands, batch and auto reply) and sends what it returns, or nothing if it returns nil.\nClick a row to open the editor and run log below the data log; the log and send box stay visible. The switch only controls automatic runs; Run tries the script once at any time.\nNot sure how to write one? Open Tutorial: six lessons from reading frames to adding a CRC.';
	@override String mine({required Object count}) => 'My scripts ${count}';
	@override String get tutorial => 'Tutorial';
	@override String get lessonNew => 'New script from lesson';
	@override String get lessonTry => 'Try sample';
	@override String lessonSample({required Object hex}) => 'Sample frame ${hex}';
	@override String get tutorialNote => 'Indexes start at 1; 0x literals work as usual; infinite loops are aborted automatically and dangerous functions such as os.execute are removed.\nTry sample feeds this lesson\'s sample frame to the code and writes the output to the run log; nothing is sent.';
	@override String tried({required Object hook, required Object hex}) => 'Sample run · ${hook} ← ${hex}';
	@override late final _Translations$serial$script$lessons$en lessons = _Translations$serial$script$lessons$en._(_root);
	@override String get empty => 'No scripts yet. Click New to write one.';
	@override String get toggle => 'Enable / disable';
	@override String get autoOn => 'Running automatically';
	@override String get autoOff => 'Disabled, manual runs only';
	@override String get editorHint => 'Lua · saved as you type · Tab inserts two spaces';
	@override String get run => 'Run';
	@override String get fold => 'Collapse';
	@override String get rename => 'Rename';
	@override String get renameTitle => 'Rename script';
	@override String get name => 'Name';
	@override String get logTitle => 'Run log';
	@override String logCount({required Object count}) => '${count} entries';
	@override String get clear => 'Clear';
	@override String get logEmpty => 'No output yet. Enabled scripts write here when data is received or sent.';
	@override String changed({required Object from, required Object to}) => '${from} → ${to}';
	@override String blocked({required Object from}) => '${from} → nil, blocked, not sent';
	@override String dryRun({required Object from, required Object to}) => 'Dry run ${from} → ${to} (not sent)';
	@override String dryBlocked({required Object from}) => 'Dry run ${from} → nil, this frame would be blocked (not sent)';
	@override String manualRx({required Object hex}) => 'Manual run · last frame ${hex}';
	@override String get noRx => 'Manual run · nothing received yet';
	@override String get badTx => 'Send box is empty or not valid HEX; cannot dry-run before_send';
	@override String get noHookLog => 'Neither on_receive nor before_send is defined';
	@override String get tooLong => 'Instruction limit exceeded, possibly an infinite loop; aborted';
}

// Path: serial.quick
class _Translations$serial$quick$en extends Translations$serial$quick$zh {
	_Translations$serial$quick$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get note => 'Send now. These do not enter history';
	@override String get send => 'Send';
	@override String get empty => 'No quick commands yet. Add one you send often, or add a folder to group them.';
	@override String get newTitle => 'New quick command';
	@override String get editTitle => 'Edit quick command';
	@override String get name => 'Name';
	@override String get format => 'Format';
	@override String get data => 'Payload';
	@override String get key => 'Shortcut';
	@override String get noKey => 'None';
	@override String get folder => 'Folder';
	@override String get root => 'Top level';
	@override String get newFolder => 'New folder';
	@override String get add => 'Add';
	@override String get rename => 'Rename';
	@override String folderCount({required Object count}) => '${count}';
	@override String get folderEmpty => 'This folder is empty. Click Add to put a command here.';
	@override String get folderNewTitle => 'New folder';
	@override String get folderEditTitle => 'Rename folder';
	@override String get folderName => 'Name';
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
	@override String get kind => 'Syntax';
	@override String get template => 'Template';
	@override String get regex => 'Regex';
	@override String get format => 'Format';
	@override String get ignoreCase => 'Ignore case';
	@override String get ignoreCaseShort => 'Aa';
	@override String get pattern => 'Pattern';
	@override String get patternHint => 'HEX, e.g. A5 5A 03';
	@override String get hintTemplateHex => '?? matches any one byte, * matches any length; use \$1, \$2 in replies for the bytes they matched';
	@override String get hintTemplateAscii => '? matches any one byte, * any length; \\? \\* \\r \\n \\xHH are literals; use \$1, \$2 in replies';
	@override String get hintRegexHex => 'Matched against spaced uppercase HEX (e.g. A5 5A 03); write ^ and \$ yourself; use \$1, \$2 for groups';
	@override String get hintRegexAscii => 'Matched against the raw bytes; write ^ and \$ yourself; use \$1, \$2 for groups';
	@override String get list => 'Replies';
	@override String get addReply => 'Add reply';
	@override String get enable => 'Enable this rule';
	@override String get delayHint => 'Delay ms';
	@override String get dataHint => 'Reply HEX, \$1 allowed';
	@override String get prefix => 'Prefix';
	@override String get frame => 'Full frame';
	@override String get contains => 'Contains';
	@override String get suffix => 'Suffix';
	@override String get toggleOn => 'Enable / disable';
	@override String get tutor => 'Tutorial';
	@override String get tutorNote => 'Four template lessons, three regex lessons. Open one to fill the form.';
	@override String get tutorFill => 'Fill editor';
	@override String get tutorWrote => 'Written on the left. Save to add it to the rule list.';
	@override String get tutorRx => 'Received';
	@override String get tutorTx => 'Will send';
	@override String tutorFrom({required Object from}) => 'from ${from}';
	@override String get tutorHit => 'yes';
	@override String get tutorMiss => 'no';
	@override String get tutorWay => 'Where';
	@override String get tagFixed => 'fixed';
	@override String get tagIgnore => 'skip';
	@override String get tagMatch => 'match';
	@override String get tagBefore => 'before';
	@override String get tagLiteral => 'literal';
	@override late final _Translations$serial$reply$lessons$en lessons = _Translations$serial$reply$lessons$en._(_root);
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
	@override String deleteFolder({required Object name}) => 'Delete folder "${name}"? This cannot be undone.';
	@override String deleteFolderWith({required Object name, required Object count}) => 'Delete folder "${name}" and the ${count} commands in it? This cannot be undone.';
	@override String deleteRule({required Object name}) => 'Delete rule "${name}"? This cannot be undone.';
	@override String deleteBatch({required Object name}) => 'Delete batch "${name}"? This cannot be undone.';
	@override String deleteHistory({required Object count}) => 'Delete all ${count} history entries? This cannot be undone.';
	@override String deleteScript({required Object name}) => 'Delete script "${name}"? This cannot be undone.';
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
	@override String get fileTitle => 'About data files';
	@override String get fileRaw => 'Any file type works (.bin, .dat, .txt, …). The file\'s raw bytes are sent as-is, with no encoding conversion.';
	@override String get fileText => 'Hex characters in a text file are not parsed: a .txt containing "01 02" sends the ASCII codes of those 5 characters. Use a binary file to send HEX data.';
	@override String get fileAppend => 'If "Append checksum" or "Append CR LF" is checked, it is added after the file data. Escape parsing and AT auto-CR do not apply to files.';
	@override String get fileWhole => 'The whole file is read into memory and written in one go, without splitting. Split large files yourself to avoid UI stalls while sending.';
	@override String filePreview({required Object count}) => 'While a file is loaded the send box is read-only and previews only the first ${count} bytes. Click "Remove" or the send box\'s "Clear" to leave file mode.';
	@override String get fileLoop => 'With "Repeat every" checked, the whole file is resent on each period.';
}

// Path: serial.validate
class _Translations$serial$validate$en extends Translations$serial$validate$zh {
	_Translations$serial$validate$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get needName => 'Enter a name';
	@override String get needData => 'Enter the payload';
	@override String get needFolderName => 'Enter a folder name';
	@override String get dupFolder => 'A folder with this name already exists';
	@override String get badHex => 'HEX must be pairs of hex characters';
	@override String get needRuleName => 'Enter a rule name';
	@override String get badPattern => 'Pattern must be HEX; characters other than ?? and * must come in pairs';
	@override String get badAsciiPattern => 'Enter a pattern';
	@override String get badRegex => 'Regular expression cannot be parsed';
	@override String get needReply => 'Add at least one reply';
	@override String badReply({required Object n}) => 'Reply ${n} must be HEX; \$1, \$2 may be inserted';
	@override String badCapture({required Object n, required Object ref, required Object count}) => 'Reply ${n} refers to capture ${ref}, but the pattern has only ${count} wildcards';
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
	@override String get folderSaved => 'Folder saved';
	@override String get ruleSaved => 'Rule saved';
	@override String get batchSaved => 'Batch saved';
	@override String get scriptSaved => 'Script renamed';
	@override String lessonCreated({required Object name, required Object title}) => 'Created ${name} from "${title}"';
	@override String get lessonTried => 'Sample run written to the run log';
	@override String checksumFilled({required Object text}) => 'Filled the send box: ${text}';
	@override String get exportedQuick => 'Quick commands exported';
	@override String get exportedRules => 'Rules exported';
	@override String imported({required Object count}) => 'Imported ${count} items';
	@override String get importInvalid => 'This file is not an exported JSON list';
	@override String fileLoaded({required Object name}) => 'Loaded ${name}';
}

// Path: serial.script.lessons
class _Translations$serial$script$lessons$en extends Translations$serial$script$lessons$zh {
	_Translations$serial$script$lessons$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$serial$script$lessons$hooks$en hooks = _Translations$serial$script$lessons$hooks$en._(_root);
	@override late final _Translations$serial$script$lessons$print$en print = _Translations$serial$script$lessons$print$en._(_root);
	@override late final _Translations$serial$script$lessons$parse$en parse = _Translations$serial$script$lessons$parse$en._(_root);
	@override late final _Translations$serial$script$lessons$checksum$en checksum = _Translations$serial$script$lessons$checksum$en._(_root);
	@override late final _Translations$serial$script$lessons$block$en block = _Translations$serial$script$lessons$block$en._(_root);
	@override late final _Translations$serial$script$lessons$modbus$en modbus = _Translations$serial$script$lessons$modbus$en._(_root);
}

// Path: serial.reply.lessons
class _Translations$serial$reply$lessons$en extends Translations$serial$reply$lessons$zh {
	_Translations$serial$reply$lessons$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$serial$reply$lessons$order$en order = _Translations$serial$reply$lessons$order$en._(_root);
	@override late final _Translations$serial$reply$lessons$place$en place = _Translations$serial$reply$lessons$place$en._(_root);
	@override late final _Translations$serial$reply$lessons$wild$en wild = _Translations$serial$reply$lessons$wild$en._(_root);
	@override late final _Translations$serial$reply$lessons$ascii$en ascii = _Translations$serial$reply$lessons$ascii$en._(_root);
	@override late final _Translations$serial$reply$lessons$reword$en reword = _Translations$serial$reply$lessons$reword$en._(_root);
	@override late final _Translations$serial$reply$lessons$groups$en groups = _Translations$serial$reply$lessons$groups$en._(_root);
	@override late final _Translations$serial$reply$lessons$reascii$en reascii = _Translations$serial$reply$lessons$reascii$en._(_root);
}

// Path: serial.script.lessons.hooks
class _Translations$serial$script$lessons$hooks$en extends Translations$serial$script$lessons$hooks$zh {
	_Translations$serial$script$lessons$hooks$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'When scripts run';
	@override String get brief => 'Two hooks: after receiving, before sending';
	@override String get text => 'Define a function named on_receive and it is called for every packet received; frame holds that packet\'s bytes. Define before_send and it is called before every outgoing frame (send button, quick commands, batch and auto reply), and only the frame it returns is sent. The switch only controls automatic runs; Run dry-runs with the last received frame or the send box, and never sends.';
}

// Path: serial.script.lessons.print
class _Translations$serial$script$lessons$print$en extends Translations$serial$script$lessons$print$zh {
	_Translations$serial$script$lessons$print$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Print a frame';
	@override String get brief => 'log writes to the run log; frames show as HEX';
	@override String get text => 'log writes to the run log, joining arguments with spaces; print is the same function. A frame passed directly shows as HEX, frame:sub(i, j) takes bytes i to j, and frame:str() turns it into ASCII text.';
}

// Path: serial.script.lessons.parse
class _Translations$serial$script$lessons$parse$en extends Translations$serial$script$lessons$parse$zh {
	_Translations$serial$script$lessons$parse$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Match a header, read values';
	@override String get brief => 'starts_with checks the header, u16 reads two bytes';
	@override String get text => 'frame:starts_with(0xA5, 0x5A, 0x03) checks the header; return early for frames you don\'t want. Indexes start at 1: u8(i) reads byte i, u16(i) combines bytes i and i+1 big-endian, and u16le(i) reads little-endian.';
}

// Path: serial.script.lessons.checksum
class _Translations$serial$script$lessons$checksum$en extends Translations$serial$script$lessons$checksum$zh {
	_Translations$serial$script$lessons$checksum$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Add a checksum before sending';
	@override String get brief => 'before_send returns the changed frame; append adds bytes';
	@override String get text => 'before_send receives the frame about to go out and sends whatever it returns. frame:append(...) returns a new frame with bytes added at the end; sum8 is the additive sum and xor8 is XOR (BCC).';
}

// Path: serial.script.lessons.block
class _Translations$serial$script$lessons$block$en extends Translations$serial$script$lessons$block$zh {
	_Translations$serial$script$lessons$block$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Block frames you don\'t want sent';
	@override String get brief => 'Return nil and the frame is not sent';
	@override String get text => 'When before_send returns nil the frame is not sent and the data log records the block. Pass every other frame through with return frame.';
}

// Path: serial.script.lessons.modbus
class _Translations$serial$script$lessons$modbus$en extends Translations$serial$script$lessons$modbus$zh {
	_Translations$serial$script$lessons$modbus$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Modbus CRC16';
	@override String get brief => 'crc16 returns the low byte, then the high byte';
	@override String get text => 'crc16(frame) uses the Modbus algorithm and returns two values, low byte then high byte, which is the order Modbus RTU appends them. frame(...) builds a new frame from numbers, strings or other frames.';
}

// Path: serial.reply.lessons.order
class _Translations$serial$reply$lessons$order$en extends Translations$serial$reply$lessons$order$zh {
	_Translations$serial$reply$lessons$order$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nothing is sent until a packet arrives';
	@override String get brief => 'Replies go out in list order';
	@override String get name => 'Handshake reply';
	@override String get text => 'While the port is open, every received packet is compared with each enabled rule. A hit sends the reply list in order. Each delay starts after the previous reply, not from the moment the packet arrived. Two matching rules both reply. Nothing runs while the port is closed.';
	@override String get rxNote => 'Prefix only looks at the leading A5 5A. The last two bytes are not compared.';
}

// Path: serial.reply.lessons.place
class _Translations$serial$reply$lessons$place$en extends Translations$serial$reply$lessons$place$zh {
	_Translations$serial$reply$lessons$place$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Prefix, full frame, contains, suffix';
	@override String get brief => 'Only templates have these four';
	@override String get name => 'Reply when it appears';
	@override String get text => 'The same pattern A5 5A hits or misses depending on where you look. Full frame must be exactly those bytes. Prefix checks the start, suffix the end, contains anywhere in the middle. Regex has no such menu: write ^ and \$ yourself.';
	@override String get rxNote => 'This packet starts with 00. Prefix misses; contains hits.';
}

// Path: serial.reply.lessons.wild
class _Translations$serial$reply$lessons$wild$en extends Translations$serial$reply$lessons$wild$zh {
	_Translations$serial$reply$lessons$wild$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => '?? takes one byte, * takes a span';
	@override String get brief => 'Wildcards become \$1, \$2 from left to right';
	@override String get name => 'Echo captured bytes';
	@override String get text => 'In a HEX template, ?? is any one byte and must be written as two question marks; a single ? will not save. * is any length, including empty. They become \$1 and \$2 from left to right, and writing \$1 in a reply substitutes the captured bytes. Templates are checked on save: \$3 is rejected when there is no third wildcard.';
	@override String get rxNote => 'Full frame. ?? takes 11, * takes the remaining 22 33.';
}

// Path: serial.reply.lessons.ascii
class _Translations$serial$reply$lessons$ascii$en extends Translations$serial$reply$lessons$ascii$zh {
	_Translations$serial$reply$lessons$ascii$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'In ASCII, one ? is one byte';
	@override String get brief => 'The reply box is still HEX';
	@override String get name => 'Echo the byte after OK';
	@override String get text => 'With ASCII, one ? is any single byte and * is still any length. To match a question mark itself, write a backslash before it; the same for star, carriage return and line feed. A specific byte is backslash, x, and two hex digits, for example \\x0D. Ignore case exists only for ASCII. Replies are always HEX: the character 7 comes back as byte 37.';
	@override String get rxNote => 'Ignore case is on, so ok,7 matches OK,?. The question mark captures the character 7.';
}

// Path: serial.reply.lessons.reword
class _Translations$serial$reply$lessons$reword$en extends Translations$serial$reply$lessons$reword$zh {
	_Translations$serial$reply$lessons$reword$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Regex sees a line of HEX text';
	@override String get brief => '* here does not mean any length';
	@override String get name => 'Byte after the header';
	@override String get text => 'Choosing regex removes the match menu. A HEX regex is not compared byte by byte; it is compared with the spaced hex text, such as A5 5A 03. * means “repeat the previous item”, and ?? is not “any one byte”. To capture one byte, wrap two hex digits: ([0-9A-F]{2}). Write ^ and \$ yourself.';
	@override String get rxNote => 'The engine matches the text “A5 5A 03”. Without \$, extra bytes afterward still hit.';
}

// Path: serial.reply.lessons.groups
class _Translations$serial$reply$lessons$groups$en extends Translations$serial$reply$lessons$groups$zh {
	_Translations$serial$reply$lessons$groups$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Only parentheses become \$1';
	@override String get brief => 'A missing \$n skips that reply';
	@override String get name => 'Split two bytes';
	@override String get text => 'A template’s ?? and * are numbered automatically. In a regex only parentheses become \$1 and \$2, in the order the opening parentheses appear. This lesson anchors the whole frame with \$. If a reply uses \$3 but there are only two groups, that reply is not sent and the log says the capture is missing. A group that catches only one hex digit is skipped the same way. A template would have blocked this at save time.';
	@override String get rxNote => 'Two groups, \$1 then \$2. The final \$ means the frame ends there.';
}

// Path: serial.reply.lessons.reascii
class _Translations$serial$reply$lessons$reascii$en extends Translations$serial$reply$lessons$reascii$zh {
	_Translations$serial$reply$lessons$reascii$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'ASCII regex matches characters';
	@override String get brief => 'Compared as text, not as HEX words';
	@override String get name => 'After the comma';
	@override String get text => 'An ASCII regex walks the received characters, not the spaced hex text. Characters caught by parentheses are filled into the reply as bytes. Ignore case is available only for ASCII. Anchors are still ^ and \$, written by you.';
	@override String get rxNote => 'The characters are OK,42. (.+) puts both characters into the same \$1.';
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
			'serial.port.name' => 'Address',
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
			'serial.tx.fileHelp' => 'About data files',
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
			'serial.log.replySkipped' => ({required Object name, required Object step}) => 'Auto-reply "${name}" reply ${step} refers to a missing capture, skipped',
			'serial.log.batchStart' => ({required Object name, required Object steps, required Object extra}) => 'Batch "${name}" started, ${steps} steps${extra}',
			'serial.log.batchRounds' => ({required Object rounds}) => ' × ${rounds} rounds',
			'serial.log.batchDone' => ({required Object name}) => 'Batch "${name}" finished',
			'serial.log.batchFail' => ({required Object step}) => 'Step ${step} failed, batch stopped',
			'serial.log.batchStopped' => 'Batch stopped',
			'serial.log.scriptBlocked' => ({required Object name}) => 'Script "${name}" returned nil; frame blocked, not sent',
			'serial.log.scriptFailed' => ({required Object name}) => 'Script "${name}" failed; frame not sent, see the script run log',
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
			'serial.tab.script' => 'Script',
			'serial.script.note' => ({required Object enabled, required Object total}) => '${enabled} / ${total} enabled',
			'serial.script.add' => 'New',
			'serial.script.waiting' => 'Waiting',
			'serial.script.off' => 'Disabled',
			'serial.script.outputs' => ({required Object count}) => '${count} outputs',
			'serial.script.broken' => 'Error',
			'serial.script.noHook' => 'No hook',
			'serial.script.explain' => 'Lua scripts. on_receive runs after data arrives; before_send intercepts every outgoing frame (including quick commands, batch and auto reply) and sends what it returns, or nothing if it returns nil.\nClick a row to open the editor and run log below the data log; the log and send box stay visible. The switch only controls automatic runs; Run tries the script once at any time.\nNot sure how to write one? Open Tutorial: six lessons from reading frames to adding a CRC.',
			'serial.script.mine' => ({required Object count}) => 'My scripts ${count}',
			'serial.script.tutorial' => 'Tutorial',
			'serial.script.lessonNew' => 'New script from lesson',
			'serial.script.lessonTry' => 'Try sample',
			'serial.script.lessonSample' => ({required Object hex}) => 'Sample frame ${hex}',
			'serial.script.tutorialNote' => 'Indexes start at 1; 0x literals work as usual; infinite loops are aborted automatically and dangerous functions such as os.execute are removed.\nTry sample feeds this lesson\'s sample frame to the code and writes the output to the run log; nothing is sent.',
			'serial.script.tried' => ({required Object hook, required Object hex}) => 'Sample run · ${hook} ← ${hex}',
			'serial.script.lessons.hooks.title' => 'When scripts run',
			'serial.script.lessons.hooks.brief' => 'Two hooks: after receiving, before sending',
			'serial.script.lessons.hooks.text' => 'Define a function named on_receive and it is called for every packet received; frame holds that packet\'s bytes. Define before_send and it is called before every outgoing frame (send button, quick commands, batch and auto reply), and only the frame it returns is sent. The switch only controls automatic runs; Run dry-runs with the last received frame or the send box, and never sends.',
			'serial.script.lessons.print.title' => 'Print a frame',
			'serial.script.lessons.print.brief' => 'log writes to the run log; frames show as HEX',
			'serial.script.lessons.print.text' => 'log writes to the run log, joining arguments with spaces; print is the same function. A frame passed directly shows as HEX, frame:sub(i, j) takes bytes i to j, and frame:str() turns it into ASCII text.',
			'serial.script.lessons.parse.title' => 'Match a header, read values',
			'serial.script.lessons.parse.brief' => 'starts_with checks the header, u16 reads two bytes',
			'serial.script.lessons.parse.text' => 'frame:starts_with(0xA5, 0x5A, 0x03) checks the header; return early for frames you don\'t want. Indexes start at 1: u8(i) reads byte i, u16(i) combines bytes i and i+1 big-endian, and u16le(i) reads little-endian.',
			'serial.script.lessons.checksum.title' => 'Add a checksum before sending',
			'serial.script.lessons.checksum.brief' => 'before_send returns the changed frame; append adds bytes',
			'serial.script.lessons.checksum.text' => 'before_send receives the frame about to go out and sends whatever it returns. frame:append(...) returns a new frame with bytes added at the end; sum8 is the additive sum and xor8 is XOR (BCC).',
			'serial.script.lessons.block.title' => 'Block frames you don\'t want sent',
			'serial.script.lessons.block.brief' => 'Return nil and the frame is not sent',
			'serial.script.lessons.block.text' => 'When before_send returns nil the frame is not sent and the data log records the block. Pass every other frame through with return frame.',
			'serial.script.lessons.modbus.title' => 'Modbus CRC16',
			'serial.script.lessons.modbus.brief' => 'crc16 returns the low byte, then the high byte',
			'serial.script.lessons.modbus.text' => 'crc16(frame) uses the Modbus algorithm and returns two values, low byte then high byte, which is the order Modbus RTU appends them. frame(...) builds a new frame from numbers, strings or other frames.',
			'serial.script.empty' => 'No scripts yet. Click New to write one.',
			'serial.script.toggle' => 'Enable / disable',
			'serial.script.autoOn' => 'Running automatically',
			'serial.script.autoOff' => 'Disabled, manual runs only',
			'serial.script.editorHint' => 'Lua · saved as you type · Tab inserts two spaces',
			'serial.script.run' => 'Run',
			'serial.script.fold' => 'Collapse',
			'serial.script.rename' => 'Rename',
			'serial.script.renameTitle' => 'Rename script',
			'serial.script.name' => 'Name',
			'serial.script.logTitle' => 'Run log',
			'serial.script.logCount' => ({required Object count}) => '${count} entries',
			'serial.script.clear' => 'Clear',
			'serial.script.logEmpty' => 'No output yet. Enabled scripts write here when data is received or sent.',
			'serial.script.changed' => ({required Object from, required Object to}) => '${from} → ${to}',
			'serial.script.blocked' => ({required Object from}) => '${from} → nil, blocked, not sent',
			'serial.script.dryRun' => ({required Object from, required Object to}) => 'Dry run ${from} → ${to} (not sent)',
			'serial.script.dryBlocked' => ({required Object from}) => 'Dry run ${from} → nil, this frame would be blocked (not sent)',
			'serial.script.manualRx' => ({required Object hex}) => 'Manual run · last frame ${hex}',
			'serial.script.noRx' => 'Manual run · nothing received yet',
			'serial.script.badTx' => 'Send box is empty or not valid HEX; cannot dry-run before_send',
			'serial.script.noHookLog' => 'Neither on_receive nor before_send is defined',
			'serial.script.tooLong' => 'Instruction limit exceeded, possibly an infinite loop; aborted',
			'serial.quick.note' => 'Send now. These do not enter history',
			'serial.quick.send' => 'Send',
			'serial.quick.empty' => 'No quick commands yet. Add one you send often, or add a folder to group them.',
			'serial.quick.newTitle' => 'New quick command',
			'serial.quick.editTitle' => 'Edit quick command',
			'serial.quick.name' => 'Name',
			'serial.quick.format' => 'Format',
			'serial.quick.data' => 'Payload',
			'serial.quick.key' => 'Shortcut',
			'serial.quick.noKey' => 'None',
			'serial.quick.folder' => 'Folder',
			'serial.quick.root' => 'Top level',
			'serial.quick.newFolder' => 'New folder',
			'serial.quick.add' => 'Add',
			'serial.quick.rename' => 'Rename',
			'serial.quick.folderCount' => ({required Object count}) => '${count}',
			'serial.quick.folderEmpty' => 'This folder is empty. Click Add to put a command here.',
			'serial.quick.folderNewTitle' => 'New folder',
			'serial.quick.folderEditTitle' => 'Rename folder',
			'serial.quick.folderName' => 'Name',
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
			'serial.reply.kind' => 'Syntax',
			'serial.reply.template' => 'Template',
			'serial.reply.regex' => 'Regex',
			'serial.reply.format' => 'Format',
			'serial.reply.ignoreCase' => 'Ignore case',
			'serial.reply.ignoreCaseShort' => 'Aa',
			'serial.reply.pattern' => 'Pattern',
			'serial.reply.patternHint' => 'HEX, e.g. A5 5A 03',
			'serial.reply.hintTemplateHex' => '?? matches any one byte, * matches any length; use \$1, \$2 in replies for the bytes they matched',
			'serial.reply.hintTemplateAscii' => '? matches any one byte, * any length; \\? \\* \\r \\n \\xHH are literals; use \$1, \$2 in replies',
			'serial.reply.hintRegexHex' => 'Matched against spaced uppercase HEX (e.g. A5 5A 03); write ^ and \$ yourself; use \$1, \$2 for groups',
			'serial.reply.hintRegexAscii' => 'Matched against the raw bytes; write ^ and \$ yourself; use \$1, \$2 for groups',
			'serial.reply.list' => 'Replies',
			'serial.reply.addReply' => 'Add reply',
			'serial.reply.enable' => 'Enable this rule',
			'serial.reply.delayHint' => 'Delay ms',
			'serial.reply.dataHint' => 'Reply HEX, \$1 allowed',
			'serial.reply.prefix' => 'Prefix',
			'serial.reply.frame' => 'Full frame',
			'serial.reply.contains' => 'Contains',
			'serial.reply.suffix' => 'Suffix',
			'serial.reply.toggleOn' => 'Enable / disable',
			'serial.reply.tutor' => 'Tutorial',
			'serial.reply.tutorNote' => 'Four template lessons, three regex lessons. Open one to fill the form.',
			'serial.reply.tutorFill' => 'Fill editor',
			'serial.reply.tutorWrote' => 'Written on the left. Save to add it to the rule list.',
			'serial.reply.tutorRx' => 'Received',
			'serial.reply.tutorTx' => 'Will send',
			'serial.reply.tutorFrom' => ({required Object from}) => 'from ${from}',
			'serial.reply.tutorHit' => 'yes',
			'serial.reply.tutorMiss' => 'no',
			'serial.reply.tutorWay' => 'Where',
			'serial.reply.tagFixed' => 'fixed',
			'serial.reply.tagIgnore' => 'skip',
			'serial.reply.tagMatch' => 'match',
			'serial.reply.tagBefore' => 'before',
			'serial.reply.tagLiteral' => 'literal',
			'serial.reply.lessons.order.title' => 'Nothing is sent until a packet arrives',
			'serial.reply.lessons.order.brief' => 'Replies go out in list order',
			'serial.reply.lessons.order.name' => 'Handshake reply',
			'serial.reply.lessons.order.text' => 'While the port is open, every received packet is compared with each enabled rule. A hit sends the reply list in order. Each delay starts after the previous reply, not from the moment the packet arrived. Two matching rules both reply. Nothing runs while the port is closed.',
			'serial.reply.lessons.order.rxNote' => 'Prefix only looks at the leading A5 5A. The last two bytes are not compared.',
			'serial.reply.lessons.place.title' => 'Prefix, full frame, contains, suffix',
			'serial.reply.lessons.place.brief' => 'Only templates have these four',
			'serial.reply.lessons.place.name' => 'Reply when it appears',
			'serial.reply.lessons.place.text' => 'The same pattern A5 5A hits or misses depending on where you look. Full frame must be exactly those bytes. Prefix checks the start, suffix the end, contains anywhere in the middle. Regex has no such menu: write ^ and \$ yourself.',
			'serial.reply.lessons.place.rxNote' => 'This packet starts with 00. Prefix misses; contains hits.',
			'serial.reply.lessons.wild.title' => '?? takes one byte, * takes a span',
			'serial.reply.lessons.wild.brief' => 'Wildcards become \$1, \$2 from left to right',
			'serial.reply.lessons.wild.name' => 'Echo captured bytes',
			'serial.reply.lessons.wild.text' => 'In a HEX template, ?? is any one byte and must be written as two question marks; a single ? will not save. * is any length, including empty. They become \$1 and \$2 from left to right, and writing \$1 in a reply substitutes the captured bytes. Templates are checked on save: \$3 is rejected when there is no third wildcard.',
			'serial.reply.lessons.wild.rxNote' => 'Full frame. ?? takes 11, * takes the remaining 22 33.',
			'serial.reply.lessons.ascii.title' => 'In ASCII, one ? is one byte',
			'serial.reply.lessons.ascii.brief' => 'The reply box is still HEX',
			'serial.reply.lessons.ascii.name' => 'Echo the byte after OK',
			'serial.reply.lessons.ascii.text' => 'With ASCII, one ? is any single byte and * is still any length. To match a question mark itself, write a backslash before it; the same for star, carriage return and line feed. A specific byte is backslash, x, and two hex digits, for example \\x0D. Ignore case exists only for ASCII. Replies are always HEX: the character 7 comes back as byte 37.',
			'serial.reply.lessons.ascii.rxNote' => 'Ignore case is on, so ok,7 matches OK,?. The question mark captures the character 7.',
			'serial.reply.lessons.reword.title' => 'Regex sees a line of HEX text',
			'serial.reply.lessons.reword.brief' => '* here does not mean any length',
			'serial.reply.lessons.reword.name' => 'Byte after the header',
			'serial.reply.lessons.reword.text' => 'Choosing regex removes the match menu. A HEX regex is not compared byte by byte; it is compared with the spaced hex text, such as A5 5A 03. * means “repeat the previous item”, and ?? is not “any one byte”. To capture one byte, wrap two hex digits: ([0-9A-F]{2}). Write ^ and \$ yourself.',
			'serial.reply.lessons.reword.rxNote' => 'The engine matches the text “A5 5A 03”. Without \$, extra bytes afterward still hit.',
			'serial.reply.lessons.groups.title' => 'Only parentheses become \$1',
			'serial.reply.lessons.groups.brief' => 'A missing \$n skips that reply',
			'serial.reply.lessons.groups.name' => 'Split two bytes',
			'serial.reply.lessons.groups.text' => 'A template’s ?? and * are numbered automatically. In a regex only parentheses become \$1 and \$2, in the order the opening parentheses appear. This lesson anchors the whole frame with \$. If a reply uses \$3 but there are only two groups, that reply is not sent and the log says the capture is missing. A group that catches only one hex digit is skipped the same way. A template would have blocked this at save time.',
			'serial.reply.lessons.groups.rxNote' => 'Two groups, \$1 then \$2. The final \$ means the frame ends there.',
			'serial.reply.lessons.reascii.title' => 'ASCII regex matches characters',
			'serial.reply.lessons.reascii.brief' => 'Compared as text, not as HEX words',
			'serial.reply.lessons.reascii.name' => 'After the comma',
			'serial.reply.lessons.reascii.text' => 'An ASCII regex walks the received characters, not the spaced hex text. Characters caught by parentheses are filled into the reply as bytes. Ignore case is available only for ASCII. Anchors are still ^ and \$, written by you.',
			'serial.reply.lessons.reascii.rxNote' => 'The characters are OK,42. (.+) puts both characters into the same \$1.',
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
			'serial.dialog.deleteFolder' => ({required Object name}) => 'Delete folder "${name}"? This cannot be undone.',
			'serial.dialog.deleteFolderWith' => ({required Object name, required Object count}) => 'Delete folder "${name}" and the ${count} commands in it? This cannot be undone.',
			'serial.dialog.deleteRule' => ({required Object name}) => 'Delete rule "${name}"? This cannot be undone.',
			'serial.dialog.deleteBatch' => ({required Object name}) => 'Delete batch "${name}"? This cannot be undone.',
			'serial.dialog.deleteHistory' => ({required Object count}) => 'Delete all ${count} history entries? This cannot be undone.',
			'serial.dialog.deleteScript' => ({required Object name}) => 'Delete script "${name}"? This cannot be undone.',
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
			'serial.dialog.fileTitle' => 'About data files',
			'serial.dialog.fileRaw' => 'Any file type works (.bin, .dat, .txt, …). The file\'s raw bytes are sent as-is, with no encoding conversion.',
			'serial.dialog.fileText' => 'Hex characters in a text file are not parsed: a .txt containing "01 02" sends the ASCII codes of those 5 characters. Use a binary file to send HEX data.',
			'serial.dialog.fileAppend' => 'If "Append checksum" or "Append CR LF" is checked, it is added after the file data. Escape parsing and AT auto-CR do not apply to files.',
			'serial.dialog.fileWhole' => 'The whole file is read into memory and written in one go, without splitting. Split large files yourself to avoid UI stalls while sending.',
			'serial.dialog.filePreview' => ({required Object count}) => 'While a file is loaded the send box is read-only and previews only the first ${count} bytes. Click "Remove" or the send box\'s "Clear" to leave file mode.',
			'serial.dialog.fileLoop' => 'With "Repeat every" checked, the whole file is resent on each period.',
			'serial.validate.needName' => 'Enter a name',
			'serial.validate.needData' => 'Enter the payload',
			'serial.validate.needFolderName' => 'Enter a folder name',
			'serial.validate.dupFolder' => 'A folder with this name already exists',
			'serial.validate.badHex' => 'HEX must be pairs of hex characters',
			'serial.validate.needRuleName' => 'Enter a rule name',
			'serial.validate.badPattern' => 'Pattern must be HEX; characters other than ?? and * must come in pairs',
			'serial.validate.badAsciiPattern' => 'Enter a pattern',
			'serial.validate.badRegex' => 'Regular expression cannot be parsed',
			'serial.validate.needReply' => 'Add at least one reply',
			'serial.validate.badReply' => ({required Object n}) => 'Reply ${n} must be HEX; \$1, \$2 may be inserted',
			'serial.validate.badCapture' => ({required Object n, required Object ref, required Object count}) => 'Reply ${n} refers to capture ${ref}, but the pattern has only ${count} wildcards',
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
			'serial.notice.folderSaved' => 'Folder saved',
			'serial.notice.ruleSaved' => 'Rule saved',
			'serial.notice.batchSaved' => 'Batch saved',
			'serial.notice.scriptSaved' => 'Script renamed',
			'serial.notice.lessonCreated' => ({required Object name, required Object title}) => 'Created ${name} from "${title}"',
			'serial.notice.lessonTried' => 'Sample run written to the run log',
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
