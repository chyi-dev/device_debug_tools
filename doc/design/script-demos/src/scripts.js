// 脚本层：三版共用的数据、钩子与运行日志。只模拟两个预置脚本的效果，不执行任意 JS。
var SC = (function () {
  var list = [
    { id: 's1', name: 'parseSensor.js', action: 'parse', enabled: true, runs: 0,
      code: '// 收到 A5 5A 03 帧后解析温湿度\nonReceive(frame => {\n  if (frame.startsWith(0xA5, 0x5A, 0x03)) {\n    const t = frame.u16(3) / 10;\n    const h = frame.u16(5) / 10;\n    log(`temp=${t}℃ hum=${h}%`);\n  }\n});' },
    { id: 's2', name: 'addChecksum.js', action: 'checksum', enabled: false, runs: 0,
      code: '// 发送前在帧尾追加 SUM8\nbeforeSend(frame => frame.append(sum8(frame)));' }
  ];
  var log = [];
  var subs = [];
  var sel = 's1';
  var n = 0;

  function hookOf(s) { return /beforeSend\s*\(/.test(s.code) ? 'beforeSend' : 'onReceive'; }
  function get(id) { return list.filter(function (s) { return s.id === id; })[0]; }
  function changed(kind) { subs.forEach(function (fn) { fn(kind); }); }
  function write(s, text, err) {
    s.runs++;
    s.last = text;
    log.push({ no: ++n, time: new Date(), name: s.name, text: text, err: !!err });
    if (log.length > 200) log.shift();
    changed('log');
  }

  function lastSensor() {
    return Serial.state.lines.slice().reverse().filter(function (l) { return l.dir === 'rx' && l.info.temp != null; })[0];
  }
  function parse(s, line) {
    if (!line) return write(s, '还没有收到 A5 5A 03 温湿度帧', true);
    write(s, 'temp=' + line.info.temp.toFixed(1) + '℃ hum=' + line.info.hum.toFixed(1) + '%');
  }
  function lastRx() { return Serial.state.lines.slice().reverse().filter(function (l) { return l.dir === 'rx'; })[0]; }

  // 钩子：收到数据走 onReceive
  Serial.on('line', function (l) {
    if (l.dir !== 'rx') return;
    list.forEach(function (s) {
      if (!s.enabled || hookOf(s) !== 'onReceive') return;
      if (s.action === 'parse') { if (l.info.temp != null) parse(s, l); }
      else write(s, '收到 ' + l.bytes.length + ' 字节：' + Serial.hex(l.bytes));
    });
  });

  // 钩子：发送前走 beforeSend
  var rawSend = Serial.send;
  Serial.send = function (text, opts) {
    opts = Object.assign({}, opts);
    var fmt = opts.format || Serial.state.sendFormat;
    list.forEach(function (s) {
      if (!s.enabled || hookOf(s) !== 'beforeSend' || !Serial.state.open) return;
      if (s.action === 'checksum' && fmt === 'HEX' && Serial.parseHex(text)) {
        var b = Serial.parseHex(text);
        write(s, Serial.hex(b) + ' → 追加 SUM8 ' + Serial.hex([Serial.sum8(b)]));
        text = Serial.hex(b.concat([Serial.sum8(b)]));
      } else if (s.action !== 'checksum') write(s, '未修改：' + text.trim());
    });
    return rawSend(text, opts);
  };

  function run(id) {
    var s = get(id);
    if (s.action === 'parse') return parse(s, lastSensor());
    if (s.action === 'checksum') {
      var b = Serial.parseHex($('txInput').value);
      if (!b) return write(s, '发送框不是 HEX，无法试算', true);
      return write(s, Serial.hex(b) + ' → ' + Serial.hex(Serial.withChecksum(b, 'sum')) + '（试算，未发送）');
    }
    var l = lastRx();
    write(s, l ? '手动运行 · 最近一帧 ' + Serial.hex(l.bytes) : '手动运行 · 还没有收到数据');
  }
  function toggle(id) {
    var s = get(id); s.enabled = !s.enabled;
    hint(s.name + (s.enabled ? ' 已启用 · ' + hookOf(s) : ' 已停用'));
    changed('list');
  }
  function create() {
    var k = list.length + 1;
    var s = { id: 's' + Date.now().toString(36), name: 'script' + k + '.js', action: 'custom', enabled: false, runs: 0,
      code: '// 新脚本：收到数据时运行\nonReceive(frame => {\n  log(frame.hex());\n});' };
    list.push(s); sel = s.id;
    changed('list'); changed('sel');
    return s;
  }
  function setCode(id, code) { var s = get(id); s.code = code; changed('list'); }
  function clearLog() { log.length = 0; changed('log'); }
  function select(id) { sel = id; changed('sel'); }

  return {
    list: list, log: log, get: get, hookOf: hookOf, run: run, toggle: toggle, create: create, setCode: setCode,
    clearLog: clearLog, select: select, selected: function () { return get(sel) || list[0]; },
    on: function (fn) { subs.push(fn); }
  };
})();

// ---------- 共用片段 ----------
function scTime(d) { return Serial.stamp(d); }
function scLogHtml(max) {
  var rows = max ? SC.log.slice(-max) : SC.log;
  if (!rows.length) return '<div class="sclog-empty">还没有输出。启用脚本后，收到或发送数据时会写在这里。</div>';
  return rows.map(function (e) {
    return '<div class="sclog-row' + (e.err ? ' err' : '') + '"><span class="t">' + scTime(e.time) + '</span><span class="n">' + esc(e.name) + '</span><span class="o">' + esc(e.text) + '</span></div>';
  }).join('');
}
function scHookChip(s) { return '<span class="schook">' + SC.hookOf(s) + '</span>'; }
function scEditorHtml(s, id) {
  var lines = s.code.split('\n').length;
  var g = ''; for (var i = 1; i <= lines; i++) g += i + '\n';
  return '<div class="sced"><pre class="gut" aria-hidden="true">' + g + '</pre><textarea id="' + id + '" spellcheck="false" data-sid="' + s.id + '">' + esc(s.code) + '</textarea></div>';
}
// 编辑器：输入即保存，行号随内容和滚动同步
document.addEventListener('input', function (e) {
  var t = e.target;
  if (!t.dataset || !t.dataset.sid || t.tagName !== 'TEXTAREA') return;
  SC.setCode(t.dataset.sid, t.value);
  var gut = t.previousElementSibling, lines = t.value.split('\n').length, g = '';
  for (var i = 1; i <= lines; i++) g += i + '\n';
  gut.textContent = g;
});
document.addEventListener('scroll', function (e) {
  var t = e.target;
  if (t.dataset && t.dataset.sid && t.previousElementSibling) t.previousElementSibling.scrollTop = t.scrollTop;
}, true);
document.addEventListener('keydown', function (e) {
  var t = e.target;
  if (e.key !== 'Tab' || !t.dataset || !t.dataset.sid) return;
  e.preventDefault();
  var a = t.selectionStart;
  t.setRangeText('  ', a, t.selectionEnd, 'end');
  t.dispatchEvent(new Event('input', { bubbles: true }));
});

// 页签：「脚本」接到现有工具面板与「工具」菜单
function scAddTab(label) {
  var b = document.createElement('button');
  b.dataset.tab = 'script'; b.textContent = label;
  $('tabs').appendChild(b);
  var m = document.querySelector('[data-cmd="tab:calc"]');
  var mb = document.createElement('button');
  mb.dataset.cmd = 'tab:script'; mb.textContent = '脚本';
  m.after(mb);
  return b;
}
var scBaseRender = renderTab;
function scHookTab(renderScript, onLeave) {
  renderTab = function () {
    if (ui.tab === 'script') return renderScript();
    if (onLeave) onLeave();
    scBaseRender();
  };
}
