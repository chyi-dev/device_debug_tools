///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsZh = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$zh app = Translations$app$zh.internal(_root);
	late final Translations$nav$zh nav = Translations$nav$zh.internal(_root);
	late final Translations$home$zh home = Translations$home$zh.internal(_root);
	late final Translations$common$zh common = Translations$common$zh.internal(_root);
	late final Translations$serial$zh serial = Translations$serial$zh.internal(_root);
}

// Path: app
class Translations$app$zh {
	Translations$app$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '设备调试工具'
	String get title => '设备调试工具';
}

// Path: nav
class Translations$nav$zh {
	Translations$nav$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '首页'
	String get home => '首页';

	/// zh: '串口'
	String get serial => '串口';
}

// Path: home
class Translations$home$zh {
	Translations$home$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '欢迎使用设备调试工具'
	String get welcome => '欢迎使用设备调试工具';

	/// zh: '在 lib/features 下添加功能模块'
	String get placeholder => '在 lib/features 下添加功能模块';
}

// Path: common
class Translations$common$zh {
	Translations$common$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '确认'
	String get confirm => '确认';

	/// zh: '取消'
	String get cancel => '取消';

	/// zh: '重试'
	String get retry => '重试';

	/// zh: '暂无数据'
	String get empty => '暂无数据';

	/// zh: '加载失败'
	String get error => '加载失败';

	/// zh: '加载中…'
	String get loading => '加载中…';

	/// zh: '保存'
	String get save => '保存';

	/// zh: '删除'
	String get delete => '删除';

	/// zh: '关闭'
	String get close => '关闭';

	/// zh: '新增'
	String get add => '新增';

	/// zh: '编辑'
	String get edit => '编辑';
}

// Path: serial
class Translations$serial$zh {
	Translations$serial$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$serial$menu$zh menu = Translations$serial$menu$zh.internal(_root);
	late final Translations$serial$kbd$zh kbd = Translations$serial$kbd$zh.internal(_root);

	/// zh: '精简模式'
	String get compact => '精简模式';

	/// zh: '工具面板'
	String get toolsPanel => '工具面板';

	/// zh: '收起或展开左侧设置栏'
	String get compactTip => '收起或展开左侧设置栏';

	/// zh: '显示或隐藏工具面板'
	String get toolsTip => '显示或隐藏工具面板';

	late final Translations$serial$port$zh port = Translations$serial$port$zh.internal(_root);
	late final Translations$serial$parityOpt$zh parityOpt = Translations$serial$parityOpt$zh.internal(_root);
	late final Translations$serial$flowOpt$zh flowOpt = Translations$serial$flowOpt$zh.internal(_root);
	late final Translations$serial$mark$zh mark = Translations$serial$mark$zh.internal(_root);
	late final Translations$serial$rx$zh rx = Translations$serial$rx$zh.internal(_root);
	late final Translations$serial$tx$zh tx = Translations$serial$tx$zh.internal(_root);
	late final Translations$serial$checksum$zh checksum = Translations$serial$checksum$zh.internal(_root);
	late final Translations$serial$log$zh log = Translations$serial$log$zh.internal(_root);
	late final Translations$serial$sendBox$zh sendBox = Translations$serial$sendBox$zh.internal(_root);
	late final Translations$serial$tab$zh tab = Translations$serial$tab$zh.internal(_root);
	late final Translations$serial$quick$zh quick = Translations$serial$quick$zh.internal(_root);
	late final Translations$serial$batch$zh batch = Translations$serial$batch$zh.internal(_root);
	late final Translations$serial$reply$zh reply = Translations$serial$reply$zh.internal(_root);
	late final Translations$serial$history$zh history = Translations$serial$history$zh.internal(_root);
	late final Translations$serial$calc$zh calc = Translations$serial$calc$zh.internal(_root);
	late final Translations$serial$status$zh status = Translations$serial$status$zh.internal(_root);
	late final Translations$serial$dialog$zh dialog = Translations$serial$dialog$zh.internal(_root);
	late final Translations$serial$validate$zh validate = Translations$serial$validate$zh.internal(_root);
	late final Translations$serial$notice$zh notice = Translations$serial$notice$zh.internal(_root);
}

// Path: serial.menu
class Translations$serial$menu$zh {
	Translations$serial$menu$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '文件'
	String get file => '文件';

	/// zh: '设置'
	String get settings => '设置';

	/// zh: '工具'
	String get tools => '工具';

	/// zh: '帮助'
	String get help => '帮助';

	/// zh: '保存接收数据…'
	String get saveRecv => '保存接收数据…';

	/// zh: '导出快捷指令'
	String get exportQuick => '导出快捷指令';

	/// zh: '导入快捷指令…'
	String get importQuick => '导入快捷指令…';

	/// zh: '导出应答规则'
	String get exportRules => '导出应答规则';

	/// zh: '导入应答规则…'
	String get importRules => '导入应答规则…';

	/// zh: '白底经典'
	String get themeLight => '白底经典';

	/// zh: '黑底经典'
	String get themeDark => '黑底经典';

	/// zh: '精简模式（收起左栏）'
	String get compact => '精简模式（收起左栏）';

	/// zh: '显示工具面板'
	String get toolsPanel => '显示工具面板';

	/// zh: '快捷键说明'
	String get keys => '快捷键说明';

	/// zh: '关于'
	String get about => '关于';
}

// Path: serial.kbd
class Translations$serial$kbd$zh {
	Translations$serial$kbd$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'Ctrl+S'
	String get ctrlS => 'Ctrl+S';

	/// zh: 'F12'
	String get f12 => 'F12';
}

// Path: serial.port
class Translations$serial$port$zh {
	Translations$serial$port$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '串口设置'
	String get title => '串口设置';

	/// zh: '串口地址'
	String get name => '串口地址';

	/// zh: '波特率'
	String get baud => '波特率';

	/// zh: '校验位'
	String get parity => '校验位';

	/// zh: '数据位'
	String get dataBits => '数据位';

	/// zh: '停止位'
	String get stopBits => '停止位';

	/// zh: '流控'
	String get flow => '流控';

	/// zh: '刷新'
	String get refresh => '刷新';

	/// zh: '重新扫描串口'
	String get refreshTip => '重新扫描串口';

	/// zh: '打开'
	String get open => '打开';

	/// zh: '关闭'
	String get close => '关闭';

	/// zh: '无可用串口'
	String get empty => '无可用串口';

	/// zh: '引脚状态'
	String get pinsTip => '引脚状态';
}

// Path: serial.parityOpt
class Translations$serial$parityOpt$zh {
	Translations$serial$parityOpt$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'NONE'
	String get none => 'NONE';

	/// zh: 'ODD'
	String get odd => 'ODD';

	/// zh: 'EVEN'
	String get even => 'EVEN';

	/// zh: 'MARK'
	String get mark => 'MARK';

	/// zh: 'SPACE'
	String get space => 'SPACE';
}

// Path: serial.flowOpt
class Translations$serial$flowOpt$zh {
	Translations$serial$flowOpt$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'NONE'
	String get none => 'NONE';

	/// zh: 'RTS/CTS'
	String get rtsCts => 'RTS/CTS';

	/// zh: 'DTR/DSR'
	String get dtrDsr => 'DTR/DSR';

	/// zh: 'XON/XOFF'
	String get xonXoff => 'XON/XOFF';
}

// Path: serial.mark
class Translations$serial$mark$zh {
	Translations$serial$mark$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'OPENED'
	String get opened => 'OPENED';

	/// zh: 'CLOSED'
	String get closed => 'CLOSED';

	/// zh: 'RECV'
	String get recv => 'RECV';

	/// zh: 'SEND'
	String get send => 'SEND';

	/// zh: 'HEX'
	String get hex => 'HEX';

	/// zh: 'ASCII'
	String get ascii => 'ASCII';
}

// Path: serial.rx
class Translations$serial$rx$zh {
	Translations$serial$rx$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '接收设置'
	String get title => '接收设置';

	/// zh: '按日志模式显示'
	String get logMode => '按日志模式显示';

	/// zh: '接收区自动换行'
	String get wrap => '接收区自动换行';

	/// zh: '接收数据不显示'
	String get hide => '接收数据不显示';

	/// zh: '接收保存到文件'
	String get save => '接收保存到文件';

	/// zh: '自动滚屏'
	String get scroll => '自动滚屏';

	/// zh: '分包超时'
	String get timeout => '分包超时';

	/// zh: '保存数据'
	String get saveData => '保存数据';

	/// zh: '清除接收'
	String get clear => '清除接收';
}

// Path: serial.tx
class Translations$serial$tx$zh {
	Translations$serial$tx$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '发送设置'
	String get title => '发送设置';

	/// zh: '自动解析转义符'
	String get escape => '自动解析转义符';

	/// zh: 'AT 指令自动回车'
	String get at => 'AT 指令自动回车';

	/// zh: '末尾追加回车换行'
	String get crlf => '末尾追加回车换行';

	/// zh: '自动发送附加位'
	String get checksum => '自动发送附加位';

	/// zh: '发送完自动清空'
	String get clear => '发送完自动清空';

	/// zh: '打开文件数据源…'
	String get file => '打开文件数据源…';

	/// zh: '循环周期'
	String get loop => '循环周期';

	/// zh: '数据文件说明'
	String get fileHelp => '数据文件说明';
}

// Path: serial.checksum
class Translations$serial$checksum$zh {
	Translations$serial$checksum$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'SUM8'
	String get sum => 'SUM8';

	/// zh: 'XOR/BCC'
	String get xor => 'XOR/BCC';

	/// zh: 'LRC'
	String get lrc => 'LRC';

	/// zh: 'CRC8'
	String get crc8 => 'CRC8';

	/// zh: 'CRC16'
	String get crc16 => 'CRC16';

	/// zh: 'CRC32'
	String get crc32 => 'CRC32';
}

// Path: serial.log
class Translations$serial$log$zh {
	Translations$serial$log$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '数据日志'
	String get title => '数据日志';

	/// zh: '搜索接收内容'
	String get search => '搜索接收内容';

	/// zh: '等待数据…'
	String get waiting => '等待数据…';

	/// zh: '串口未打开。左侧选择串口后点「打开」。'
	String get closed => '串口未打开。左侧选择串口后点「打开」。';

	/// zh: '$count 处匹配'
	String matches({required Object count}) => '${count} 处匹配';

	/// zh: '$count 条记录'
	String records({required Object count}) => '${count} 条记录';

	/// zh: '接收不显示'
	String get rxHidden => '接收不显示';

	/// zh: '$port 已打开 · $baud $frame'
	String opened({required Object port, required Object baud, required Object frame}) => '${port} 已打开 · ${baud} ${frame}';

	/// zh: '$port 已关闭'
	String closedPort({required Object port}) => '${port} 已关闭';

	/// zh: '自动响应「$name」命中，按顺序回复 $count 条'
	String autoReply({required Object name, required Object count}) => '自动响应「${name}」命中，按顺序回复 ${count} 条';

	/// zh: '自动响应「$name」第 $step 条应答引用的捕获不存在，已跳过'
	String replySkipped({required Object name, required Object step}) => '自动响应「${name}」第 ${step} 条应答引用的捕获不存在，已跳过';

	/// zh: '批量任务「$name」开始，共 $steps 步$extra'
	String batchStart({required Object name, required Object steps, required Object extra}) => '批量任务「${name}」开始，共 ${steps} 步${extra}';

	/// zh: ' × $rounds 轮'
	String batchRounds({required Object rounds}) => ' × ${rounds} 轮';

	/// zh: '批量任务「$name」完成'
	String batchDone({required Object name}) => '批量任务「${name}」完成';

	/// zh: '第 $step 步失败，任务停止'
	String batchFail({required Object step}) => '第 ${step} 步失败，任务停止';

	/// zh: '批量任务已手动停止'
	String get batchStopped => '批量任务已手动停止';
}

// Path: serial.sendBox
class Translations$serial$sendBox$zh {
	Translations$serial$sendBox$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '发送'
	String get send => '发送';

	/// zh: '停止循环'
	String get stopLoop => '停止循环';

	/// zh: '清除'
	String get clear => '清除';

	/// zh: '实发 $count 字节：$hex'
	String preview({required Object count, required Object hex}) => '实发 ${count} 字节：${hex}';

	/// zh: 'Ctrl+Enter 发送 · Esc 停止循环/批量'
	String get foot => 'Ctrl+Enter 发送 · Esc 停止循环/批量';

	/// zh: 'HEX 格式不正确：需要成对的十六进制字符'
	String get badHex => 'HEX 格式不正确：需要成对的十六进制字符';

	/// zh: '发送内容为空'
	String get empty => '发送内容为空';
}

// Path: serial.tab
class Translations$serial$tab$zh {
	Translations$serial$tab$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '快捷指令'
	String get quick => '快捷指令';

	/// zh: '批量发送'
	String get batch => '批量发送';

	/// zh: '自动应答'
	String get reply => '自动应答';

	/// zh: '历史发送'
	String get history => '历史发送';

	/// zh: '校验计算'
	String get calc => '校验计算';
}

// Path: serial.quick
class Translations$serial$quick$zh {
	Translations$serial$quick$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '点「发送」立即发出，不进入历史'
	String get note => '点「发送」立即发出，不进入历史';

	/// zh: '发送'
	String get send => '发送';

	/// zh: '还没有快捷指令。点「新增」保存常用的一条指令，或点「新增文件夹」先分组。'
	String get empty => '还没有快捷指令。点「新增」保存常用的一条指令，或点「新增文件夹」先分组。';

	/// zh: '新增快捷指令'
	String get newTitle => '新增快捷指令';

	/// zh: '编辑快捷指令'
	String get editTitle => '编辑快捷指令';

	/// zh: '名称'
	String get name => '名称';

	/// zh: '格式'
	String get format => '格式';

	/// zh: '指令数据'
	String get data => '指令数据';

	/// zh: '快捷键'
	String get key => '快捷键';

	/// zh: '无'
	String get noKey => '无';

	/// zh: '文件夹'
	String get folder => '文件夹';

	/// zh: '根目录'
	String get root => '根目录';

	/// zh: '新增文件夹'
	String get newFolder => '新增文件夹';

	/// zh: '新增'
	String get add => '新增';

	/// zh: '重命名'
	String get rename => '重命名';

	/// zh: '$count 条'
	String folderCount({required Object count}) => '${count} 条';

	/// zh: '文件夹为空。点「新增」在这里添加指令。'
	String get folderEmpty => '文件夹为空。点「新增」在这里添加指令。';

	/// zh: '新增文件夹'
	String get folderNewTitle => '新增文件夹';

	/// zh: '重命名文件夹'
	String get folderEditTitle => '重命名文件夹';

	/// zh: '名称'
	String get folderName => '名称';
}

// Path: serial.batch
class Translations$serial$batch$zh {
	Translations$serial$batch$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '新建'
	String get kNew => '新建';

	/// zh: '编辑'
	String get edit => '编辑';

	/// zh: '删除'
	String get delete => '删除';

	/// zh: '重复'
	String get repeat => '重复';

	/// zh: '轮'
	String get rounds => '轮';

	/// zh: '失败即停'
	String get stopOnFail => '失败即停';

	/// zh: '开始发送'
	String get start => '开始发送';

	/// zh: '停止'
	String get stop => '停止';

	/// zh: '$count 条指令'
	String commands({required Object count}) => '${count} 条指令';

	/// zh: '第 $round/$rounds 轮 · 第 $step/$total 条'
	String progress({required Object round, required Object rounds, required Object step, required Object total}) => '第 ${round}/${rounds} 轮 · 第 ${step}/${total} 条';

	/// zh: '#'
	String get colIndex => '#';

	/// zh: '延时'
	String get colDelay => '延时';

	/// zh: '指令数据'
	String get colData => '指令数据';

	/// zh: '备注'
	String get colNote => '备注';

	/// zh: '延时指发送本条之前等待的毫秒数，第一条立即发送。'
	String get explain => '延时指发送本条之前等待的毫秒数，第一条立即发送。';

	/// zh: '还没有批量任务。'
	String get empty => '还没有批量任务。';

	/// zh: '新建批量任务'
	String get newTitle => '新建批量任务';

	/// zh: '编辑批量任务'
	String get editTitle => '编辑批量任务';

	/// zh: '任务名称'
	String get name => '任务名称';

	/// zh: '指令序列（延时 ms / 数据 / 备注）'
	String get sequence => '指令序列（延时 ms / 数据 / 备注）';

	/// zh: '添加指令'
	String get addStep => '添加指令';

	/// zh: '延时 ms'
	String get delayHint => '延时 ms';

	/// zh: '指令数据 HEX'
	String get dataHint => '指令数据 HEX';

	/// zh: '备注'
	String get noteHint => '备注';
}

// Path: serial.reply
class Translations$serial$reply$zh {
	Translations$serial$reply$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '已启用 $enabled / $total，按列表顺序逐条匹配'
	String note({required Object enabled, required Object total}) => '已启用 ${enabled} / ${total}，按列表顺序逐条匹配';

	/// zh: '新增规则'
	String get add => '新增规则';

	/// zh: '执行'
	String get fire => '执行';

	/// zh: '$count 次'
	String hits({required Object count}) => '${count} 次';

	/// zh: '收到的数据与规则匹配后，按应答列表顺序依次发送；每条应答的延时从上一条发出后开始计算。'
	String get explain => '收到的数据与规则匹配后，按应答列表顺序依次发送；每条应答的延时从上一条发出后开始计算。';

	/// zh: '新增应答规则'
	String get newTitle => '新增应答规则';

	/// zh: '编辑应答规则'
	String get editTitle => '编辑应答规则';

	/// zh: '规则名称'
	String get name => '规则名称';

	/// zh: '匹配方式'
	String get match => '匹配方式';

	/// zh: '语法'
	String get kind => '语法';

	/// zh: '模板'
	String get template => '模板';

	/// zh: '正则'
	String get regex => '正则';

	/// zh: '格式'
	String get format => '格式';

	/// zh: '忽略大小写'
	String get ignoreCase => '忽略大小写';

	/// zh: 'Aa'
	String get ignoreCaseShort => 'Aa';

	/// zh: '匹配数据'
	String get pattern => '匹配数据';

	/// zh: 'HEX，如 A5 5A 03'
	String get patternHint => 'HEX，如 A5 5A 03';

	/// zh: '?? 匹配任意一字节，* 匹配任意长度；应答里用 \$1、\$2 依次引用它们匹配到的字节'
	String get hintTemplateHex => '?? 匹配任意一字节，* 匹配任意长度；应答里用 \$1、\$2 依次引用它们匹配到的字节';

	/// zh: '? 匹配任意一字节，* 匹配任意长度，\\? \\* \\r \\n \\xHH 为字面量；应答里用 \$1、\$2 引用'
	String get hintTemplateAscii => '? 匹配任意一字节，* 匹配任意长度，\\? \\* \\r \\n \\xHH 为字面量；应答里用 \$1、\$2 引用';

	/// zh: '对空格分隔的大写 HEX（如 A5 5A 03）匹配，锚点自己写 ^ 和 \$；应答里用 \$1、\$2 引用括号分组'
	String get hintRegexHex => '对空格分隔的大写 HEX（如 A5 5A 03）匹配，锚点自己写 ^ 和 \$；应答里用 \$1、\$2 引用括号分组';

	/// zh: '对原始字节逐字匹配，锚点自己写 ^ 和 \$；应答里用 \$1、\$2 引用括号分组'
	String get hintRegexAscii => '对原始字节逐字匹配，锚点自己写 ^ 和 \$；应答里用 \$1、\$2 引用括号分组';

	/// zh: '应答列表'
	String get list => '应答列表';

	/// zh: '添加应答'
	String get addReply => '添加应答';

	/// zh: '启用此规则'
	String get enable => '启用此规则';

	/// zh: '延时 ms'
	String get delayHint => '延时 ms';

	/// zh: '应答数据 HEX，可写 \$1'
	String get dataHint => '应答数据 HEX，可写 \$1';

	/// zh: '前缀'
	String get prefix => '前缀';

	/// zh: '整帧'
	String get frame => '整帧';

	/// zh: '包含'
	String get contains => '包含';

	/// zh: '结尾'
	String get suffix => '结尾';

	/// zh: '启用 / 停用'
	String get toggleOn => '启用 / 停用';
}

// Path: serial.history
class Translations$serial$history$zh {
	Translations$serial$history$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '只记录用「发送」按钮发出的数据'
	String get note => '只记录用「发送」按钮发出的数据';

	/// zh: '清空'
	String get clear => '清空';

	/// zh: '重新发送'
	String get resendTip => '重新发送';

	/// zh: '启动前'
	String get beforeStart => '启动前';

	/// zh: '点时间重发 · 点「填入」放回发送框'
	String get fillHint => '点时间重发 · 点「填入」放回发送框';

	/// zh: '填入'
	String get fill => '填入';

	/// zh: '还没有发送记录。'
	String get empty => '还没有发送记录。';
}

// Path: serial.calc
class Translations$serial$calc$zh {
	Translations$serial$calc$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '取发送框内容'
	String get fromTx => '取发送框内容';

	/// zh: '字节数'
	String get bytes => '字节数';

	/// zh: 'SUM8 累加和'
	String get sum => 'SUM8 累加和';

	/// zh: 'XOR / BCC'
	String get xor => 'XOR / BCC';

	/// zh: 'LRC'
	String get lrc => 'LRC';

	/// zh: 'CRC8'
	String get crc8 => 'CRC8';

	/// zh: 'CRC16 MODBUS'
	String get crc16 => 'CRC16 MODBUS';

	/// zh: 'CRC32'
	String get crc32 => 'CRC32';

	/// zh: '追加'
	String get append => '追加';

	/// zh: '请输入成对的十六进制字符'
	String get badHex => '请输入成对的十六进制字符';

	/// zh: '请输入内容'
	String get empty => '请输入内容';

	/// zh: 'CRC16 为 MODBUS（低字节在前），CRC32 为标准 IEEE（大端）。「追加」会把校验值接到发送框末尾。'
	String get explain => 'CRC16 为 MODBUS（低字节在前），CRC32 为标准 IEEE（大端）。「追加」会把校验值接到发送框末尾。';
}

// Path: serial.status
class Translations$serial$status$zh {
	Translations$serial$status$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '复位计数'
	String get reset => '复位计数';

	/// zh: '自动应答 $enabled/$total'
	String reply({required Object enabled, required Object total}) => '自动应答 ${enabled}/${total}';

	/// zh: '正在保存 $name · $count 条'
	String saving({required Object name, required Object count}) => '正在保存 ${name} · ${count} 条';

	/// zh: '$name · $count 字节'
	String fileMeta({required Object name, required Object count}) => '${name} · ${count} 字节';
}

// Path: serial.dialog
class Translations$serial$dialog$zh {
	Translations$serial$dialog$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '确认删除'
	String get deleteTitle => '确认删除';

	/// zh: '删除快捷指令「$name」后无法恢复。'
	String deleteQuick({required Object name}) => '删除快捷指令「${name}」后无法恢复。';

	/// zh: '删除文件夹「$name」后无法恢复。'
	String deleteFolder({required Object name}) => '删除文件夹「${name}」后无法恢复。';

	/// zh: '删除文件夹「$name」会一并删除其中 $count 条指令，删除后无法恢复。'
	String deleteFolderWith({required Object name, required Object count}) => '删除文件夹「${name}」会一并删除其中 ${count} 条指令，删除后无法恢复。';

	/// zh: '删除应答规则「$name」后无法恢复。'
	String deleteRule({required Object name}) => '删除应答规则「${name}」后无法恢复。';

	/// zh: '删除批量任务「$name」后无法恢复。'
	String deleteBatch({required Object name}) => '删除批量任务「${name}」后无法恢复。';

	/// zh: '删除全部 $count 条发送历史后无法恢复。'
	String deleteHistory({required Object count}) => '删除全部 ${count} 条发送历史后无法恢复。';

	/// zh: '快捷键说明'
	String get keysTitle => '快捷键说明';

	/// zh: '知道了'
	String get know => '知道了';

	/// zh: '关于'
	String get aboutTitle => '关于';

	/// zh: '设备调试工具 · 串口调试台。选择串口并打开后即可收发数据。'
	String get aboutBody => '设备调试工具 · 串口调试台。选择串口并打开后即可收发数据。';

	/// zh: '快捷指令、批量发送和自动应答在串口关闭时不会执行。接收数据按分包超时合并。附加位支持 SUM8、XOR/BCC、LRC、CRC8、CRC16（MODBUS，低字节在前）和 CRC32（IEEE，大端）。'
	String get aboutDetail => '快捷指令、批量发送和自动应答在串口关闭时不会执行。接收数据按分包超时合并。附加位支持 SUM8、XOR/BCC、LRC、CRC8、CRC16（MODBUS，低字节在前）和 CRC32（IEEE，大端）。';

	/// zh: '发送（发送框内）'
	String get keySend => '发送（发送框内）';

	/// zh: '发送绑定了快捷键的快捷指令'
	String get keyQuick => '发送绑定了快捷键的快捷指令';

	/// zh: '停止循环发送和批量发送'
	String get keyStop => '停止循环发送和批量发送';

	/// zh: '保存接收数据'
	String get keySave => '保存接收数据';

	/// zh: '清除接收'
	String get keyClear => '清除接收';

	/// zh: '搜索接收内容'
	String get keySearch => '搜索接收内容';

	/// zh: '打开本说明'
	String get keyHelp => '打开本说明';

	/// zh: 'Ctrl+Enter'
	String get ctrlEnter => 'Ctrl+Enter';

	/// zh: 'F1–F8'
	String get fKeys => 'F1–F8';

	/// zh: 'Esc'
	String get esc => 'Esc';

	/// zh: 'Ctrl+L'
	String get ctrlL => 'Ctrl+L';

	/// zh: 'Ctrl+F'
	String get ctrlF => 'Ctrl+F';

	/// zh: '移除'
	String get remove => '移除';

	/// zh: '数据文件说明'
	String get fileTitle => '数据文件说明';

	/// zh: '支持任意类型文件（.bin、.dat、.txt 等），按文件的原始字节发送，不做编码转换。'
	String get fileRaw => '支持任意类型文件（.bin、.dat、.txt 等），按文件的原始字节发送，不做编码转换。';

	/// zh: '文本文件里的十六进制字符不会被解析：内容为「01 02」的 .txt 实际发送的是这 5 个字符的 ASCII 码。需要发送 HEX 数据请使用二进制文件。'
	String get fileText => '文本文件里的十六进制字符不会被解析：内容为「01 02」的 .txt 实际发送的是这 5 个字符的 ASCII 码。需要发送 HEX 数据请使用二进制文件。';

	/// zh: '勾选「自动发送附加位」或「末尾追加回车换行」时，会追加到文件数据末尾；转义符解析和 AT 指令自动回车对文件不生效。'
	String get fileAppend => '勾选「自动发送附加位」或「末尾追加回车换行」时，会追加到文件数据末尾；转义符解析和 AT 指令自动回车对文件不生效。';

	/// zh: '文件整体读入内存后一次写出，不做分包。较大的文件请先自行拆分，避免发送期间界面卡顿。'
	String get fileWhole => '文件整体读入内存后一次写出，不做分包。较大的文件请先自行拆分，避免发送期间界面卡顿。';

	/// zh: '载入后发送框只读，仅预览前 $count 字节；点「移除」或发送框的「清除」可退出文件模式。'
	String filePreview({required Object count}) => '载入后发送框只读，仅预览前 ${count} 字节；点「移除」或发送框的「清除」可退出文件模式。';

	/// zh: '勾选「循环周期」时，按周期重复发送整个文件。'
	String get fileLoop => '勾选「循环周期」时，按周期重复发送整个文件。';
}

// Path: serial.validate
class Translations$serial$validate$zh {
	Translations$serial$validate$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '请填写名称'
	String get needName => '请填写名称';

	/// zh: '请填写指令数据'
	String get needData => '请填写指令数据';

	/// zh: '请填写文件夹名称'
	String get needFolderName => '请填写文件夹名称';

	/// zh: '已有同名文件夹'
	String get dupFolder => '已有同名文件夹';

	/// zh: 'HEX 数据需为成对的十六进制字符'
	String get badHex => 'HEX 数据需为成对的十六进制字符';

	/// zh: '请填写规则名称'
	String get needRuleName => '请填写规则名称';

	/// zh: '匹配数据需为 HEX，?? 和 * 之外的字符需成对'
	String get badPattern => '匹配数据需为 HEX，?? 和 * 之外的字符需成对';

	/// zh: '请填写匹配数据'
	String get badAsciiPattern => '请填写匹配数据';

	/// zh: '正则表达式无法解析'
	String get badRegex => '正则表达式无法解析';

	/// zh: '至少需要一条应答'
	String get needReply => '至少需要一条应答';

	/// zh: '第 $n 条应答数据需为 HEX，可插入 \$1、\$2'
	String badReply({required Object n}) => '第 ${n} 条应答数据需为 HEX，可插入 \$1、\$2';

	/// zh: '第 $n 条应答引用了第 $ref 个捕获，但匹配数据只有 $count 个通配符'
	String badCapture({required Object n, required Object ref, required Object count}) => '第 ${n} 条应答引用了第 ${ref} 个捕获，但匹配数据只有 ${count} 个通配符';

	/// zh: '第 $n 条延时需为非负数'
	String badDelay({required Object n}) => '第 ${n} 条延时需为非负数';

	/// zh: '请填写任务名称'
	String get needTask => '请填写任务名称';

	/// zh: '至少需要一条指令'
	String get needStep => '至少需要一条指令';

	/// zh: '第 $n 条数据需为 HEX'
	String badStep({required Object n}) => '第 ${n} 条数据需为 HEX';

	/// zh: '第 $n 条延时需为非负数'
	String badStepDelay({required Object n}) => '第 ${n} 条延时需为非负数';
}

// Path: serial.notice
class Translations$serial$notice$zh {
	Translations$serial$notice$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '就绪'
	String get ready => '就绪';

	/// zh: '串口已打开'
	String get portOpened => '串口已打开';

	/// zh: '串口已关闭'
	String get portClosed => '串口已关闭';

	/// zh: '串口未打开，发送已拦截'
	String get portClosedSend => '串口未打开，发送已拦截';

	/// zh: '串口未打开，规则不会执行'
	String get portClosedRule => '串口未打开，规则不会执行';

	/// zh: '串口未打开，批量任务未启动'
	String get portClosedBatch => '串口未打开，批量任务未启动';

	/// zh: '请先选择串口'
	String get noPort => '请先选择串口';

	/// zh: '请先关闭当前串口再切换'
	String get portBusy => '请先关闭当前串口再切换';

	/// zh: '打开串口失败：$detail'
	String openFailed({required Object detail}) => '打开串口失败：${detail}';

	/// zh: '参数未能生效：$detail'
	String configFailed({required Object detail}) => '参数未能生效：${detail}';

	/// zh: '串口已打开；部分线路参数可能未按界面勾选写入（Windows 驱动限制）'
	String get configPartial => '串口已打开；部分线路参数可能未按界面勾选写入（Windows 驱动限制）';

	/// zh: '波特率需为正整数'
	String get baudInvalid => '波特率需为正整数';

	/// zh: '分包超时需为非负整数'
	String get timeoutInvalid => '分包超时需为非负整数';

	/// zh: '循环周期至少 10 ms'
	String get periodInvalid => '循环周期至少 10 ms';

	/// zh: '重复次数需为正整数'
	String get repeatInvalid => '重复次数需为正整数';

	/// zh: '扫描完成，发现 $count 个串口'
	String scanDone({required Object count}) => '扫描完成，发现 ${count} 个串口';

	/// zh: '参数已即时生效：$conn'
	String paramsApplied({required Object conn}) => '参数已即时生效：${conn}';

	/// zh: '分包超时 $ms ms'
	String timeoutHint({required Object ms}) => '分包超时 ${ms} ms';

	/// zh: '分包超时小于 8 ms，连续到达的数据可能被拆成多条显示'
	String get timeoutSplitHint => '分包超时小于 8 ms，连续到达的数据可能被拆成多条显示';

	/// zh: '开始保存接收数据，取消勾选时写出文件'
	String get saveStarted => '开始保存接收数据，取消勾选时写出文件';

	/// zh: '已写出 $name（$count 条）'
	String saveWritten({required Object name, required Object count}) => '已写出 ${name}（${count} 条）';

	/// zh: '接收数据已保存为文本'
	String get logSaved => '接收数据已保存为文本';

	/// zh: '接收区已清除'
	String get recvCleared => '接收区已清除';

	/// zh: '循环发送中，周期 $period ms'
	String loopStarted({required Object period}) => '循环发送中，周期 ${period} ms';

	/// zh: '循环发送已停止'
	String get loopStopped => '循环发送已停止';

	/// zh: '批量发送中 · 第 $step/$total 条'
	String batchRunning({required Object step, required Object total}) => '批量发送中 · 第 ${step}/${total} 条';

	/// zh: '批量发送结束'
	String get batchEnded => '批量发送结束';

	/// zh: '$name 已启用'
	String ruleOn({required Object name}) => '${name} 已启用';

	/// zh: '$name 已停用'
	String ruleOff({required Object name}) => '${name} 已停用';

	/// zh: '已删除'
	String get deleted => '已删除';

	/// zh: '快捷指令已保存'
	String get quickSaved => '快捷指令已保存';

	/// zh: '文件夹已保存'
	String get folderSaved => '文件夹已保存';

	/// zh: '应答规则已保存'
	String get ruleSaved => '应答规则已保存';

	/// zh: '批量任务已保存'
	String get batchSaved => '批量任务已保存';

	/// zh: '已填入发送框：$text'
	String checksumFilled({required Object text}) => '已填入发送框：${text}';

	/// zh: '快捷指令已导出'
	String get exportedQuick => '快捷指令已导出';

	/// zh: '应答规则已导出'
	String get exportedRules => '应答规则已导出';

	/// zh: '已导入 $count 条'
	String imported({required Object count}) => '已导入 ${count} 条';

	/// zh: '文件格式不正确，需要导出的 JSON'
	String get importInvalid => '文件格式不正确，需要导出的 JSON';

	/// zh: '已载入 $name'
	String fileLoaded({required Object name}) => '已载入 ${name}';
}

/// The flat map containing all translations for locale <zh>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => '设备调试工具',
			'nav.home' => '首页',
			'nav.serial' => '串口',
			'home.welcome' => '欢迎使用设备调试工具',
			'home.placeholder' => '在 lib/features 下添加功能模块',
			'common.confirm' => '确认',
			'common.cancel' => '取消',
			'common.retry' => '重试',
			'common.empty' => '暂无数据',
			'common.error' => '加载失败',
			'common.loading' => '加载中…',
			'common.save' => '保存',
			'common.delete' => '删除',
			'common.close' => '关闭',
			'common.add' => '新增',
			'common.edit' => '编辑',
			'serial.menu.file' => '文件',
			'serial.menu.settings' => '设置',
			'serial.menu.tools' => '工具',
			'serial.menu.help' => '帮助',
			'serial.menu.saveRecv' => '保存接收数据…',
			'serial.menu.exportQuick' => '导出快捷指令',
			'serial.menu.importQuick' => '导入快捷指令…',
			'serial.menu.exportRules' => '导出应答规则',
			'serial.menu.importRules' => '导入应答规则…',
			'serial.menu.themeLight' => '白底经典',
			'serial.menu.themeDark' => '黑底经典',
			'serial.menu.compact' => '精简模式（收起左栏）',
			'serial.menu.toolsPanel' => '显示工具面板',
			'serial.menu.keys' => '快捷键说明',
			'serial.menu.about' => '关于',
			'serial.kbd.ctrlS' => 'Ctrl+S',
			'serial.kbd.f12' => 'F12',
			'serial.compact' => '精简模式',
			'serial.toolsPanel' => '工具面板',
			'serial.compactTip' => '收起或展开左侧设置栏',
			'serial.toolsTip' => '显示或隐藏工具面板',
			'serial.port.title' => '串口设置',
			'serial.port.name' => '串口地址',
			'serial.port.baud' => '波特率',
			'serial.port.parity' => '校验位',
			'serial.port.dataBits' => '数据位',
			'serial.port.stopBits' => '停止位',
			'serial.port.flow' => '流控',
			'serial.port.refresh' => '刷新',
			'serial.port.refreshTip' => '重新扫描串口',
			'serial.port.open' => '打开',
			'serial.port.close' => '关闭',
			'serial.port.empty' => '无可用串口',
			'serial.port.pinsTip' => '引脚状态',
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
			'serial.rx.title' => '接收设置',
			'serial.rx.logMode' => '按日志模式显示',
			'serial.rx.wrap' => '接收区自动换行',
			'serial.rx.hide' => '接收数据不显示',
			'serial.rx.save' => '接收保存到文件',
			'serial.rx.scroll' => '自动滚屏',
			'serial.rx.timeout' => '分包超时',
			'serial.rx.saveData' => '保存数据',
			'serial.rx.clear' => '清除接收',
			'serial.tx.title' => '发送设置',
			'serial.tx.escape' => '自动解析转义符',
			'serial.tx.at' => 'AT 指令自动回车',
			'serial.tx.crlf' => '末尾追加回车换行',
			'serial.tx.checksum' => '自动发送附加位',
			'serial.tx.clear' => '发送完自动清空',
			'serial.tx.file' => '打开文件数据源…',
			'serial.tx.loop' => '循环周期',
			'serial.tx.fileHelp' => '数据文件说明',
			'serial.checksum.sum' => 'SUM8',
			'serial.checksum.xor' => 'XOR/BCC',
			'serial.checksum.lrc' => 'LRC',
			'serial.checksum.crc8' => 'CRC8',
			'serial.checksum.crc16' => 'CRC16',
			'serial.checksum.crc32' => 'CRC32',
			'serial.log.title' => '数据日志',
			'serial.log.search' => '搜索接收内容',
			'serial.log.waiting' => '等待数据…',
			'serial.log.closed' => '串口未打开。左侧选择串口后点「打开」。',
			'serial.log.matches' => ({required Object count}) => '${count} 处匹配',
			'serial.log.records' => ({required Object count}) => '${count} 条记录',
			'serial.log.rxHidden' => '接收不显示',
			'serial.log.opened' => ({required Object port, required Object baud, required Object frame}) => '${port} 已打开 · ${baud} ${frame}',
			'serial.log.closedPort' => ({required Object port}) => '${port} 已关闭',
			'serial.log.autoReply' => ({required Object name, required Object count}) => '自动响应「${name}」命中，按顺序回复 ${count} 条',
			'serial.log.replySkipped' => ({required Object name, required Object step}) => '自动响应「${name}」第 ${step} 条应答引用的捕获不存在，已跳过',
			'serial.log.batchStart' => ({required Object name, required Object steps, required Object extra}) => '批量任务「${name}」开始，共 ${steps} 步${extra}',
			'serial.log.batchRounds' => ({required Object rounds}) => ' × ${rounds} 轮',
			'serial.log.batchDone' => ({required Object name}) => '批量任务「${name}」完成',
			'serial.log.batchFail' => ({required Object step}) => '第 ${step} 步失败，任务停止',
			'serial.log.batchStopped' => '批量任务已手动停止',
			'serial.sendBox.send' => '发送',
			'serial.sendBox.stopLoop' => '停止循环',
			'serial.sendBox.clear' => '清除',
			'serial.sendBox.preview' => ({required Object count, required Object hex}) => '实发 ${count} 字节：${hex}',
			'serial.sendBox.foot' => 'Ctrl+Enter 发送 · Esc 停止循环/批量',
			'serial.sendBox.badHex' => 'HEX 格式不正确：需要成对的十六进制字符',
			'serial.sendBox.empty' => '发送内容为空',
			'serial.tab.quick' => '快捷指令',
			'serial.tab.batch' => '批量发送',
			'serial.tab.reply' => '自动应答',
			'serial.tab.history' => '历史发送',
			'serial.tab.calc' => '校验计算',
			'serial.quick.note' => '点「发送」立即发出，不进入历史',
			'serial.quick.send' => '发送',
			'serial.quick.empty' => '还没有快捷指令。点「新增」保存常用的一条指令，或点「新增文件夹」先分组。',
			'serial.quick.newTitle' => '新增快捷指令',
			'serial.quick.editTitle' => '编辑快捷指令',
			'serial.quick.name' => '名称',
			'serial.quick.format' => '格式',
			'serial.quick.data' => '指令数据',
			'serial.quick.key' => '快捷键',
			'serial.quick.noKey' => '无',
			'serial.quick.folder' => '文件夹',
			'serial.quick.root' => '根目录',
			'serial.quick.newFolder' => '新增文件夹',
			'serial.quick.add' => '新增',
			'serial.quick.rename' => '重命名',
			'serial.quick.folderCount' => ({required Object count}) => '${count} 条',
			'serial.quick.folderEmpty' => '文件夹为空。点「新增」在这里添加指令。',
			'serial.quick.folderNewTitle' => '新增文件夹',
			'serial.quick.folderEditTitle' => '重命名文件夹',
			'serial.quick.folderName' => '名称',
			'serial.batch.kNew' => '新建',
			'serial.batch.edit' => '编辑',
			'serial.batch.delete' => '删除',
			'serial.batch.repeat' => '重复',
			'serial.batch.rounds' => '轮',
			'serial.batch.stopOnFail' => '失败即停',
			'serial.batch.start' => '开始发送',
			'serial.batch.stop' => '停止',
			'serial.batch.commands' => ({required Object count}) => '${count} 条指令',
			'serial.batch.progress' => ({required Object round, required Object rounds, required Object step, required Object total}) => '第 ${round}/${rounds} 轮 · 第 ${step}/${total} 条',
			'serial.batch.colIndex' => '#',
			'serial.batch.colDelay' => '延时',
			'serial.batch.colData' => '指令数据',
			'serial.batch.colNote' => '备注',
			'serial.batch.explain' => '延时指发送本条之前等待的毫秒数，第一条立即发送。',
			'serial.batch.empty' => '还没有批量任务。',
			'serial.batch.newTitle' => '新建批量任务',
			'serial.batch.editTitle' => '编辑批量任务',
			'serial.batch.name' => '任务名称',
			'serial.batch.sequence' => '指令序列（延时 ms / 数据 / 备注）',
			'serial.batch.addStep' => '添加指令',
			'serial.batch.delayHint' => '延时 ms',
			'serial.batch.dataHint' => '指令数据 HEX',
			'serial.batch.noteHint' => '备注',
			'serial.reply.note' => ({required Object enabled, required Object total}) => '已启用 ${enabled} / ${total}，按列表顺序逐条匹配',
			'serial.reply.add' => '新增规则',
			'serial.reply.fire' => '执行',
			'serial.reply.hits' => ({required Object count}) => '${count} 次',
			'serial.reply.explain' => '收到的数据与规则匹配后，按应答列表顺序依次发送；每条应答的延时从上一条发出后开始计算。',
			'serial.reply.newTitle' => '新增应答规则',
			'serial.reply.editTitle' => '编辑应答规则',
			'serial.reply.name' => '规则名称',
			'serial.reply.match' => '匹配方式',
			'serial.reply.kind' => '语法',
			'serial.reply.template' => '模板',
			'serial.reply.regex' => '正则',
			'serial.reply.format' => '格式',
			'serial.reply.ignoreCase' => '忽略大小写',
			'serial.reply.ignoreCaseShort' => 'Aa',
			'serial.reply.pattern' => '匹配数据',
			'serial.reply.patternHint' => 'HEX，如 A5 5A 03',
			'serial.reply.hintTemplateHex' => '?? 匹配任意一字节，* 匹配任意长度；应答里用 \$1、\$2 依次引用它们匹配到的字节',
			'serial.reply.hintTemplateAscii' => '? 匹配任意一字节，* 匹配任意长度，\\? \\* \\r \\n \\xHH 为字面量；应答里用 \$1、\$2 引用',
			'serial.reply.hintRegexHex' => '对空格分隔的大写 HEX（如 A5 5A 03）匹配，锚点自己写 ^ 和 \$；应答里用 \$1、\$2 引用括号分组',
			'serial.reply.hintRegexAscii' => '对原始字节逐字匹配，锚点自己写 ^ 和 \$；应答里用 \$1、\$2 引用括号分组',
			'serial.reply.list' => '应答列表',
			'serial.reply.addReply' => '添加应答',
			'serial.reply.enable' => '启用此规则',
			'serial.reply.delayHint' => '延时 ms',
			'serial.reply.dataHint' => '应答数据 HEX，可写 \$1',
			'serial.reply.prefix' => '前缀',
			'serial.reply.frame' => '整帧',
			'serial.reply.contains' => '包含',
			'serial.reply.suffix' => '结尾',
			'serial.reply.toggleOn' => '启用 / 停用',
			'serial.history.note' => '只记录用「发送」按钮发出的数据',
			'serial.history.clear' => '清空',
			'serial.history.resendTip' => '重新发送',
			'serial.history.beforeStart' => '启动前',
			'serial.history.fillHint' => '点时间重发 · 点「填入」放回发送框',
			'serial.history.fill' => '填入',
			'serial.history.empty' => '还没有发送记录。',
			'serial.calc.fromTx' => '取发送框内容',
			'serial.calc.bytes' => '字节数',
			'serial.calc.sum' => 'SUM8 累加和',
			'serial.calc.xor' => 'XOR / BCC',
			'serial.calc.lrc' => 'LRC',
			'serial.calc.crc8' => 'CRC8',
			'serial.calc.crc16' => 'CRC16 MODBUS',
			'serial.calc.crc32' => 'CRC32',
			'serial.calc.append' => '追加',
			'serial.calc.badHex' => '请输入成对的十六进制字符',
			'serial.calc.empty' => '请输入内容',
			'serial.calc.explain' => 'CRC16 为 MODBUS（低字节在前），CRC32 为标准 IEEE（大端）。「追加」会把校验值接到发送框末尾。',
			'serial.status.reset' => '复位计数',
			'serial.status.reply' => ({required Object enabled, required Object total}) => '自动应答 ${enabled}/${total}',
			'serial.status.saving' => ({required Object name, required Object count}) => '正在保存 ${name} · ${count} 条',
			'serial.status.fileMeta' => ({required Object name, required Object count}) => '${name} · ${count} 字节',
			'serial.dialog.deleteTitle' => '确认删除',
			'serial.dialog.deleteQuick' => ({required Object name}) => '删除快捷指令「${name}」后无法恢复。',
			'serial.dialog.deleteFolder' => ({required Object name}) => '删除文件夹「${name}」后无法恢复。',
			'serial.dialog.deleteFolderWith' => ({required Object name, required Object count}) => '删除文件夹「${name}」会一并删除其中 ${count} 条指令，删除后无法恢复。',
			'serial.dialog.deleteRule' => ({required Object name}) => '删除应答规则「${name}」后无法恢复。',
			'serial.dialog.deleteBatch' => ({required Object name}) => '删除批量任务「${name}」后无法恢复。',
			'serial.dialog.deleteHistory' => ({required Object count}) => '删除全部 ${count} 条发送历史后无法恢复。',
			'serial.dialog.keysTitle' => '快捷键说明',
			'serial.dialog.know' => '知道了',
			'serial.dialog.aboutTitle' => '关于',
			'serial.dialog.aboutBody' => '设备调试工具 · 串口调试台。选择串口并打开后即可收发数据。',
			'serial.dialog.aboutDetail' => '快捷指令、批量发送和自动应答在串口关闭时不会执行。接收数据按分包超时合并。附加位支持 SUM8、XOR/BCC、LRC、CRC8、CRC16（MODBUS，低字节在前）和 CRC32（IEEE，大端）。',
			'serial.dialog.keySend' => '发送（发送框内）',
			'serial.dialog.keyQuick' => '发送绑定了快捷键的快捷指令',
			'serial.dialog.keyStop' => '停止循环发送和批量发送',
			'serial.dialog.keySave' => '保存接收数据',
			'serial.dialog.keyClear' => '清除接收',
			'serial.dialog.keySearch' => '搜索接收内容',
			'serial.dialog.keyHelp' => '打开本说明',
			'serial.dialog.ctrlEnter' => 'Ctrl+Enter',
			'serial.dialog.fKeys' => 'F1–F8',
			'serial.dialog.esc' => 'Esc',
			'serial.dialog.ctrlL' => 'Ctrl+L',
			'serial.dialog.ctrlF' => 'Ctrl+F',
			'serial.dialog.remove' => '移除',
			'serial.dialog.fileTitle' => '数据文件说明',
			'serial.dialog.fileRaw' => '支持任意类型文件（.bin、.dat、.txt 等），按文件的原始字节发送，不做编码转换。',
			'serial.dialog.fileText' => '文本文件里的十六进制字符不会被解析：内容为「01 02」的 .txt 实际发送的是这 5 个字符的 ASCII 码。需要发送 HEX 数据请使用二进制文件。',
			'serial.dialog.fileAppend' => '勾选「自动发送附加位」或「末尾追加回车换行」时，会追加到文件数据末尾；转义符解析和 AT 指令自动回车对文件不生效。',
			'serial.dialog.fileWhole' => '文件整体读入内存后一次写出，不做分包。较大的文件请先自行拆分，避免发送期间界面卡顿。',
			'serial.dialog.filePreview' => ({required Object count}) => '载入后发送框只读，仅预览前 ${count} 字节；点「移除」或发送框的「清除」可退出文件模式。',
			'serial.dialog.fileLoop' => '勾选「循环周期」时，按周期重复发送整个文件。',
			'serial.validate.needName' => '请填写名称',
			'serial.validate.needData' => '请填写指令数据',
			'serial.validate.needFolderName' => '请填写文件夹名称',
			'serial.validate.dupFolder' => '已有同名文件夹',
			'serial.validate.badHex' => 'HEX 数据需为成对的十六进制字符',
			'serial.validate.needRuleName' => '请填写规则名称',
			'serial.validate.badPattern' => '匹配数据需为 HEX，?? 和 * 之外的字符需成对',
			'serial.validate.badAsciiPattern' => '请填写匹配数据',
			'serial.validate.badRegex' => '正则表达式无法解析',
			'serial.validate.needReply' => '至少需要一条应答',
			'serial.validate.badReply' => ({required Object n}) => '第 ${n} 条应答数据需为 HEX，可插入 \$1、\$2',
			'serial.validate.badCapture' => ({required Object n, required Object ref, required Object count}) => '第 ${n} 条应答引用了第 ${ref} 个捕获，但匹配数据只有 ${count} 个通配符',
			'serial.validate.badDelay' => ({required Object n}) => '第 ${n} 条延时需为非负数',
			'serial.validate.needTask' => '请填写任务名称',
			'serial.validate.needStep' => '至少需要一条指令',
			'serial.validate.badStep' => ({required Object n}) => '第 ${n} 条数据需为 HEX',
			'serial.validate.badStepDelay' => ({required Object n}) => '第 ${n} 条延时需为非负数',
			'serial.notice.ready' => '就绪',
			'serial.notice.portOpened' => '串口已打开',
			'serial.notice.portClosed' => '串口已关闭',
			'serial.notice.portClosedSend' => '串口未打开，发送已拦截',
			'serial.notice.portClosedRule' => '串口未打开，规则不会执行',
			'serial.notice.portClosedBatch' => '串口未打开，批量任务未启动',
			'serial.notice.noPort' => '请先选择串口',
			'serial.notice.portBusy' => '请先关闭当前串口再切换',
			'serial.notice.openFailed' => ({required Object detail}) => '打开串口失败：${detail}',
			'serial.notice.configFailed' => ({required Object detail}) => '参数未能生效：${detail}',
			'serial.notice.configPartial' => '串口已打开；部分线路参数可能未按界面勾选写入（Windows 驱动限制）',
			'serial.notice.baudInvalid' => '波特率需为正整数',
			'serial.notice.timeoutInvalid' => '分包超时需为非负整数',
			'serial.notice.periodInvalid' => '循环周期至少 10 ms',
			'serial.notice.repeatInvalid' => '重复次数需为正整数',
			'serial.notice.scanDone' => ({required Object count}) => '扫描完成，发现 ${count} 个串口',
			'serial.notice.paramsApplied' => ({required Object conn}) => '参数已即时生效：${conn}',
			'serial.notice.timeoutHint' => ({required Object ms}) => '分包超时 ${ms} ms',
			'serial.notice.timeoutSplitHint' => '分包超时小于 8 ms，连续到达的数据可能被拆成多条显示',
			'serial.notice.saveStarted' => '开始保存接收数据，取消勾选时写出文件',
			'serial.notice.saveWritten' => ({required Object name, required Object count}) => '已写出 ${name}（${count} 条）',
			'serial.notice.logSaved' => '接收数据已保存为文本',
			'serial.notice.recvCleared' => '接收区已清除',
			'serial.notice.loopStarted' => ({required Object period}) => '循环发送中，周期 ${period} ms',
			'serial.notice.loopStopped' => '循环发送已停止',
			'serial.notice.batchRunning' => ({required Object step, required Object total}) => '批量发送中 · 第 ${step}/${total} 条',
			'serial.notice.batchEnded' => '批量发送结束',
			'serial.notice.ruleOn' => ({required Object name}) => '${name} 已启用',
			'serial.notice.ruleOff' => ({required Object name}) => '${name} 已停用',
			'serial.notice.deleted' => '已删除',
			'serial.notice.quickSaved' => '快捷指令已保存',
			'serial.notice.folderSaved' => '文件夹已保存',
			'serial.notice.ruleSaved' => '应答规则已保存',
			'serial.notice.batchSaved' => '批量任务已保存',
			'serial.notice.checksumFilled' => ({required Object text}) => '已填入发送框：${text}',
			'serial.notice.exportedQuick' => '快捷指令已导出',
			'serial.notice.exportedRules' => '应答规则已导出',
			'serial.notice.imported' => ({required Object count}) => '已导入 ${count} 条',
			'serial.notice.importInvalid' => '文件格式不正确，需要导出的 JSON',
			'serial.notice.fileLoaded' => ({required Object name}) => '已载入 ${name}',
			_ => null,
		};
	}
}
