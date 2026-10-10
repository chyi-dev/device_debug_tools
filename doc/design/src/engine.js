// 模拟串口引擎：三版设计稿共用，界面只订阅事件、调用方法。
var Serial = (function () {
  var PORTS = [
    { id: 'COM3', label: 'COM3 · USB-SERIAL CH340' },
    { id: 'COM5', label: 'COM5 · Bluetooth Link' },
    { id: 'USB0', label: 'USB0 · FTDI FT232R' }
  ];
  var listeners = {};
  var seq = 0;
  var deviceTimer = null;
  var loopTimer = null;
  var batchRun = null;
  var temp = 246, hum = 521;

  var state = {
    open: false,
    port: 'COM3',
    baud: 115200, dataBits: 8, parity: 'N', stopBits: 1, flow: '无', encoding: 'UTF-8',
    rx: 0, tx: 0,
    lines: [],
    history: ['A5 01 00 00 01 07', 'A5 02 00 00 02 08'],
    sendFormat: 'HEX', checksum: 'none', crlf: false,
    escape: true, atCrlf: false, packetTimeout: 20,
    dtr: false, rts: false,
    pins: { dcd: false, dsr: false, cts: false, ri: false },
    streaming: false,
    rules: [
      { id: 'r1', name: '温湿度回包确认', match: 'prefix', pattern: 'A5 5A 03', enabled: true, hits: 0,
        replies: [{ data: 'A5 A0 00 A0', delay: 80 }, { data: 'A5 A1 01 A2', delay: 120 }] },
      { id: 'r2', name: '设备上线确认', match: 'frame', pattern: 'A5 81 00 00 81', enabled: true, hits: 0,
        replies: [{ data: 'A5 02 00 00 02 08', delay: 50 }] },
      { id: 'r3', name: '校验失败重发', match: 'contains', pattern: 'EE', enabled: false, hits: 0,
        replies: [{ data: 'A5 01 00 00 01 07', delay: 200 }] }
    ],
    quick: [
      { id: 'q1', name: '读取温湿度', data: 'A5 01 00 00 01 07', key: 'F1' },
      { id: 'q2', name: '读取设备信息', data: 'A5 02 00 00 02 08', key: 'F2' },
      { id: 'q3', name: '启动采集', data: 'A5 10 01 00 11', key: 'F3' },
      { id: 'q4', name: '停止采集', data: 'A5 10 00 00 10', key: 'F4' }
    ],
    batch: [
      { id: 'b1', name: '传感器启动流程', interval: 500, stopOnFail: true,
        steps: ['A5 02 00 00 02 08', 'A5 10 01 00 11', 'A5 01 00 00 01 07'] },
      { id: 'b2', name: '设备复位自检', interval: 800, stopOnFail: true,
        steps: ['A5 10 00 00 10', 'A5 02 00 00 02 08', 'A5 01 00 00 01 07', 'A5 10 01 00 11'] }
    ],
    // Lua 脚本：on_receive 收到数据后运行；before_send 拦截每一帧发送，返回处理后的帧再发出，返回 nil 则不发
    scripts: [
      { id: 's1', name: 'parse_sensor.lua', action: 'parse', enabled: true, runs: 0, last: '',
        code: '-- 收到 A5 5A 03 帧后解析温湿度\nfunction on_receive(frame)\n  if frame:starts_with(0xA5, 0x5A, 0x03) then\n    local t = frame:u16(4) / 10\n    local h = frame:u16(6) / 10\n    log(string.format("temp=%.1f℃ hum=%.1f%%", t, h))\n  end\nend' },
      { id: 's2', name: 'add_checksum.lua', action: 'checksum', enabled: false, runs: 0, last: '',
        code: '-- 发送前拦截：帧尾追加 SUM8 后再发出\n-- 返回 nil 表示拦截，这一帧不发送\nfunction before_send(frame)\n  return frame:append(sum8(frame))\nend' }
    ],
    scriptLog: []
  };

  function on(type, fn) { (listeners[type] = listeners[type] || []).push(fn); }
  function emit(type, payload) { (listeners[type] || []).forEach(function (fn) { fn(payload); }); }

  // ---------- 字节工具 ----------
  function parseHex(text) {
    var clean = text.replace(/0x/gi, '').replace(/[^0-9a-fA-F]/g, '');
    if (!clean.length || clean.length % 2) return null;
    var out = [];
    for (var i = 0; i < clean.length; i += 2) out.push(parseInt(clean.substr(i, 2), 16));
    return out;
  }
  function textBytes(text, escape) {
    if (escape === false) return Array.from(new TextEncoder().encode(text));
    // 先把转义序列换成占位的原始字节，避免被 UTF-8 编码二次处理
    var out = [], i = 0;
    while (i < text.length) {
      var rest = text.slice(i), m;
      if ((m = /^\\x\[([0-9a-fA-F\s]*)\]/.exec(rest))) { out = out.concat(parseHex(m[1]) || []); i += m[0].length; continue; }
      if ((m = /^\\x([0-9a-fA-F]{2})/.exec(rest))) { out.push(parseInt(m[1], 16)); i += m[0].length; continue; }
      if ((m = /^\\([rnt0\\])/.exec(rest))) { out.push({ r: 13, n: 10, t: 9, '0': 0, '\\': 92 }[m[1]]); i += 2; continue; }
      var ch = text.codePointAt(i), s = String.fromCodePoint(ch);
      out = out.concat(Array.from(new TextEncoder().encode(s)));
      i += s.length;
    }
    return out;
  }
  function hex(bytes) { return bytes.map(function (b) { return (b < 16 ? '0' : '') + b.toString(16).toUpperCase(); }).join(' '); }
  function ascii(bytes) { return bytes.map(function (b) { return b >= 32 && b < 127 ? String.fromCharCode(b) : '.'; }).join(''); }
  function sum8(bytes) { return bytes.reduce(function (a, b) { return (a + b) & 0xFF; }, 0); }
  function xor8(bytes) { return bytes.reduce(function (a, b) { return a ^ b; }, 0); }
  function crc16(bytes) {
    var crc = 0xFFFF;
    bytes.forEach(function (b) {
      crc ^= b;
      for (var i = 0; i < 8; i++) crc = crc & 1 ? (crc >> 1) ^ 0xA001 : crc >> 1;
    });
    return [crc & 0xFF, crc >> 8];
  }
  function lrc(bytes) { return (-sum8(bytes)) & 0xFF; }
  function crc8(bytes) {
    var crc = 0;
    bytes.forEach(function (b) {
      crc ^= b;
      for (var i = 0; i < 8; i++) crc = crc & 0x80 ? ((crc << 1) ^ 0x07) & 0xFF : (crc << 1) & 0xFF;
    });
    return crc;
  }
  function crc32(bytes) {
    var crc = 0xFFFFFFFF;
    bytes.forEach(function (b) {
      crc ^= b;
      for (var i = 0; i < 8; i++) crc = crc & 1 ? (crc >>> 1) ^ 0xEDB88320 : crc >>> 1;
    });
    crc = (crc ^ 0xFFFFFFFF) >>> 0;
    return [crc >>> 24, (crc >>> 16) & 0xFF, (crc >>> 8) & 0xFF, crc & 0xFF];
  }
  // 返回要追加的校验字节；CRC16 为 MODBUS 低字节在前，CRC32 为大端
  function checksumBytes(bytes, kind) {
    if (kind === 'sum') return [sum8(bytes)];
    if (kind === 'xor') return [xor8(bytes)];
    if (kind === 'lrc') return [lrc(bytes)];
    if (kind === 'crc8') return [crc8(bytes)];
    if (kind === 'crc16') return crc16(bytes);
    if (kind === 'crc32') return crc32(bytes);
    return [];
  }
  function withChecksum(bytes, kind) { return bytes.concat(checksumBytes(bytes, kind)); }

  // ---------- 帧解析：返回字段列表，供详情树和字节高亮 ----------
  function dissect(bytes) {
    if (!bytes || bytes[0] !== 0xA5) return { summary: ascii(bytes || []), fields: [] };
    var f = [{ name: '帧头', from: 0, to: 1, value: '0xA5' }];
    if (bytes[1] === 0x5A && bytes[2] === 0x03 && bytes.length >= 8) {
      var t = ((bytes[3] << 8) | bytes[4]) / 10, h = ((bytes[5] << 8) | bytes[6]) / 10;
      var ok = sum8(bytes.slice(0, 7)) === bytes[7];
      f.push({ name: '应答标识', from: 1, to: 2, value: '0x5A' },
        { name: '命令', from: 2, to: 3, value: '0x03 温湿度上报' },
        { name: '温度', from: 3, to: 5, value: t.toFixed(1) + ' ℃' },
        { name: '湿度', from: 5, to: 7, value: h.toFixed(1) + ' %RH' },
        { name: '校验 SUM8', from: 7, to: 8, value: ok ? '正确' : '错误', ok: ok });
      return { summary: '温度 ' + t.toFixed(1) + ' ℃ · 湿度 ' + h.toFixed(1) + ' %RH', fields: f, temp: t, hum: h, ok: ok };
    }
    if (bytes[1] === 0x5A && bytes[2] === 0x82) {
      var info = ascii(bytes.slice(3, bytes.length - 1));
      f.push({ name: '应答标识', from: 1, to: 2, value: '0x5A' },
        { name: '命令', from: 2, to: 3, value: '0x82 设备信息' },
        { name: '型号 / 固件', from: 3, to: bytes.length - 1, value: info },
        { name: '校验 SUM8', from: bytes.length - 1, to: bytes.length, value: '正确', ok: true });
      return { summary: '设备信息 ' + info, fields: f, ok: true };
    }
    var names = { 0x01: '读取温湿度', 0x02: '读取设备信息', 0x10: '采集开关', 0x81: '上线确认', 0xA0: '主机确认', 0xA1: '主机确认（第二包）' };
    var name = names[bytes[1]] || '未知命令';
    f.push({ name: '命令', from: 1, to: 2, value: '0x' + hex([bytes[1]]) + ' ' + name });
    if (bytes.length > 3) f.push({ name: '参数', from: 2, to: bytes.length - 1, value: hex(bytes.slice(2, bytes.length - 1)) });
    if (bytes.length > 2) f.push({ name: '校验', from: bytes.length - 1, to: bytes.length, value: '0x' + hex([bytes[bytes.length - 1]]) });
    var extra = bytes[1] === 0x10 ? (bytes[2] ? ' · 开启' : ' · 关闭') : '';
    return { summary: name + extra, fields: f };
  }

  // ---------- 缓冲区 ----------
  function push(dir, bytes, text) {
    var d = bytes ? dissect(bytes) : { summary: text, fields: [] };
    var line = { no: ++seq, time: new Date(), dir: dir, bytes: bytes, text: text || d.summary, info: d };
    state.lines.push(line);
    if (state.lines.length > 500) state.lines.shift();
    if (dir === 'rx') state.rx += bytes.length;
    if (dir === 'tx') state.tx += bytes.length;
    emit('line', line);
    emit('state', state);
    if (dir === 'rx') { receiveHooks(line); matchRules(bytes); }
    return line;
  }
  function sys(text) { return push('sys', null, text); }

  // ---------- 连接 ----------
  function configure(patch) { Object.assign(state, patch); emit('state', state); }
  function portLabel() { var p = PORTS.filter(function (x) { return x.id === state.port; })[0]; return p ? p.label : state.port; }
  function frameFormat() { return state.dataBits + state.parity + state.stopBits; }
  // 模拟下位机把 DTR 回环到 DSR、RTS 回环到 CTS，连上即有 DCD
  function updatePins() {
    state.pins.dcd = state.open;
    state.pins.dsr = state.open && state.dtr;
    state.pins.cts = state.open && state.rts;
    emit('pins', state.pins);
  }
  function setSignal(name, on) { state[name] = !!on; updatePins(); emit('state', state); }
  function ring() {
    if (!state.open) return;
    state.pins.ri = true; emit('pins', state.pins);
    setTimeout(function () { state.pins.ri = false; emit('pins', state.pins); }, 600);
  }
  function open() {
    if (state.open) return;
    state.open = true;
    sys(state.port + ' 已打开 · ' + state.baud + ' ' + frameFormat());
    updatePins();
    emit('state', state);
    setTimeout(function () { if (state.open) device([0xA5, 0x81, 0x00, 0x00, 0x81]); }, 400);
  }
  function close() {
    if (!state.open) return;
    state.open = false;
    stopStream(); stopLoop(); stopBatch(true);
    flushRx();
    sys(state.port + ' 已关闭');
    updatePins();
    emit('state', state);
  }
  function toggle() { state.open ? close() : open(); }

  // ---------- 模拟下位机 ----------
  // 每帧分两段到达，间隔 8ms；接收端按分包超时合并，超时设得过小会看到被拆开的帧
  var rxPending = [], rxTimer = null;
  function flushRx() {
    clearTimeout(rxTimer); rxTimer = null;
    if (!rxPending.length) return;
    var b = rxPending; rxPending = [];
    push('rx', b);
  }
  function rxChunk(bytes) {
    rxPending = rxPending.concat(bytes);
    clearTimeout(rxTimer);
    rxTimer = setTimeout(flushRx, Math.max(0, Number(state.packetTimeout) || 0));
  }
  function device(bytes) {
    if (!state.open) return;
    var cut = Math.ceil(bytes.length / 2);
    rxChunk(bytes.slice(0, cut));
    setTimeout(function () { if (state.open) rxChunk(bytes.slice(cut)); }, 8);
  }
  function sensorFrame() {
    temp += Math.round((Math.random() - 0.5) * 4);
    hum += Math.round((Math.random() - 0.5) * 6);
    var b = [0xA5, 0x5A, 0x03, temp >> 8, temp & 0xFF, hum >> 8, hum & 0xFF];
    return b.concat([sum8(b)]);
  }
  function infoFrame() {
    var b = [0xA5, 0x5A, 0x82].concat(Array.from(new TextEncoder().encode('TH-01 fw1.2.0')));
    return b.concat([sum8(b)]);
  }
  function startStream() {
    if (deviceTimer) return;
    state.streaming = true;
    deviceTimer = setInterval(function () { device(sensorFrame()); }, 3000);
    emit('state', state);
  }
  function stopStream() {
    clearInterval(deviceTimer); deviceTimer = null; state.streaming = false; emit('state', state);
  }
  function deviceRespond(bytes) {
    if (bytes[0] !== 0xA5) return;
    var cmd = bytes[1];
    setTimeout(function () {
      if (cmd === 0x01) device(sensorFrame());
      else if (cmd === 0x02) device(infoFrame());
      else if (cmd === 0x10) { bytes[2] ? startStream() : stopStream(); device([0xA5, 0x90, bytes[2], 0x00, 0x90 + bytes[2]]); }
    }, 60 + Math.random() * 60);
  }

  // ---------- 发送 ----------
  function encode(text, format, checksum, crlf, extra) {
    extra = extra || {};
    var escape = extra.escape != null ? extra.escape : state.escape;
    var atCrlf = extra.atCrlf != null ? extra.atCrlf : state.atCrlf;
    var bytes = format === 'HEX' ? parseHex(text) : textBytes(text, escape);
    if (!bytes) return { error: 'HEX 格式不正确：需要成对的十六进制字符' };
    if (!bytes.length) return { error: '发送内容为空' };
    bytes = withChecksum(bytes, checksum || 'none');
    var endsCrlf = bytes[bytes.length - 2] === 0x0D && bytes[bytes.length - 1] === 0x0A;
    var isAt = format !== 'HEX' && /^\s*AT/i.test(text);
    if ((crlf || (atCrlf && isAt)) && !endsCrlf) bytes = bytes.concat([0x0D, 0x0A]);
    return { bytes: bytes };
  }
  function send(text, opts) {
    opts = opts || {};
    if (!state.open) { emit('blocked', '串口未打开，发送已拦截'); return false; }
    var r = encode(text, opts.format || state.sendFormat, opts.checksum != null ? opts.checksum : state.checksum, opts.crlf != null ? opts.crlf : state.crlf, opts);
    if (r.error) { emit('blocked', r.error); return false; }
    var out = sendHooks(r.bytes);
    if (!out) return false;
    r.bytes = out;
    push('tx', r.bytes);
    var h = text.trim();
    if (h && !opts.silentHistory) {
      state.history = [h].concat(state.history.filter(function (x) { return x !== h; })).slice(0, 12);
      emit('history', state.history);
    }
    deviceRespond(r.bytes);
    return true;
  }
  function sendRepeat(text, times, interval, loop) {
    stopLoop();
    var n = 0;
    if (!send(text)) return;
    n++;
    if (!loop && n >= times) return;
    loopTimer = setInterval(function () {
      if (!send(text, { silentHistory: true })) return stopLoop();
      n++;
      if (!loop && n >= times) stopLoop();
    }, Math.max(20, interval));
    emit('loop', true);
  }
  function stopLoop() { if (loopTimer) { clearInterval(loopTimer); loopTimer = null; emit('loop', false); } }

  // ---------- 自动响应 ----------
  // 规则：kind 为 template（默认）或 regex，format 为 HEX（默认）或 ASCII，ignoreCase 只对 ASCII 生效。
  // 模板记号：固定字节 { b }、任意一字节 { any }（HEX ?? / ASCII ?）、任意长度 { many }（*）
  function parseTemplate(pattern, format) {
    var out = [], i = 0;
    if (format !== 'ASCII') {
      var s = pattern.replace(/0x/gi, '').replace(/[^0-9a-fA-F?*]/g, '');
      while (i < s.length) {
        if (s[i] === '*') { out.push({ many: true }); i++; }
        else if (s[i] === '?') { if (s[i + 1] !== '?') return null; out.push({ any: true }); i += 2; }
        else { if (!/^[0-9a-fA-F]{2}$/.test(s.substr(i, 2))) return null; out.push({ b: parseInt(s.substr(i, 2), 16) }); i += 2; }
      }
      return out.length ? out : null;
    }
    var esc = { r: 13, n: 10, t: 9, '0': 0, '\\': 92, '?': 63, '*': 42 }, m;
    while (i < pattern.length) {
      var c = pattern[i], rest = pattern.slice(i);
      if (c === '*') { out.push({ many: true }); i++; continue; }
      if (c === '?') { out.push({ any: true }); i++; continue; }
      if (c === '\\' && esc[pattern[i + 1]] != null) { out.push({ b: esc[pattern[i + 1]] }); i += 2; continue; }
      if ((m = /^\\x([0-9a-fA-F]{2})/.exec(rest))) { out.push({ b: parseInt(m[1], 16) }); i += 4; continue; }
      var ch = String.fromCodePoint(pattern.codePointAt(i));
      Array.from(new TextEncoder().encode(ch)).forEach(function (b) { out.push({ b: b }); });
      i += ch.length;
    }
    return out.length ? out : null;
  }
  function lower(b) { return b >= 0x41 && b <= 0x5A ? b + 0x20 : b; }
  function matchFrom(toks, k, bytes, pos, endAnchored, fold, caps) {
    if (k === toks.length) return !endAnchored || pos === bytes.length;
    var t = toks[k];
    if (t.many) {
      for (var end = bytes.length; end >= pos; end--) {
        caps.push(bytes.slice(pos, end));
        if (matchFrom(toks, k + 1, bytes, end, endAnchored, fold, caps)) return true;
        caps.pop();
      }
      return false;
    }
    if (pos >= bytes.length) return false;
    if (t.any) {
      caps.push([bytes[pos]]);
      if (matchFrom(toks, k + 1, bytes, pos + 1, endAnchored, fold, caps)) return true;
      caps.pop();
      return false;
    }
    var same = fold ? lower(bytes[pos]) === lower(t.b) : bytes[pos] === t.b;
    return same && matchFrom(toks, k + 1, bytes, pos + 1, endAnchored, fold, caps);
  }
  // 命中返回捕获数组（$1 起），未命中返回 null；正则 HEX 捕获到半个字节时该项为 null
  function ruleCaptures(rule, bytes) {
    var isHex = rule.format !== 'ASCII';
    if (rule.kind === 'regex') {
      var re;
      try { re = new RegExp(rule.pattern, isHex || rule.ignoreCase ? 'i' : ''); } catch (e) { return null; }
      var m = re.exec(isHex ? hex(bytes) : String.fromCharCode.apply(null, bytes));
      if (!m) return null;
      return m.slice(1).map(function (g) {
        if (!g) return [];
        return isHex ? parseHex(g) : Array.from(g, function (c) { return c.charCodeAt(0) & 0xFF; });
      });
    }
    var toks = parseTemplate(rule.pattern, rule.format);
    if (!toks) return null;
    var fold = !isHex && rule.ignoreCase;
    var startAnchored = rule.match === 'prefix' || rule.match === 'frame';
    var endAnchored = rule.match === 'frame' || rule.match === 'suffix';
    for (var s = 0; s <= (startAnchored ? 0 : bytes.length); s++) {
      var caps = [];
      if (matchFrom(toks, 0, bytes, s, endAnchored, fold, caps)) return caps;
    }
    return null;
  }
  function captureCount(pattern, format) {
    var toks = parseTemplate(pattern, format);
    return toks ? toks.filter(function (t) { return t.b == null; }).length : null;
  }
  // 应答里的 $n 换成捕获字节；引用不存在或结果不是 HEX 时返回 null
  function expandReply(data, caps) {
    var ok = true;
    var out = data.replace(/\$(\d+)/g, function (_, n) {
      var c = caps[Number(n) - 1];
      if (!c) { ok = false; return ''; }
      return ' ' + hex(c) + ' ';
    });
    return ok && parseHex(out) ? out.trim() : null;
  }
  function matchRules(bytes) {
    state.rules.forEach(function (rule) {
      if (!rule.enabled) return;
      var caps = ruleCaptures(rule, bytes);
      if (!caps) return;
      rule.hits++;
      emit('rule', rule);
      runReplies(rule, caps);
    });
  }
  function runReplies(rule, caps) {
    var wait = 0;
    sys('自动响应「' + rule.name + '」命中，按顺序回复 ' + rule.replies.length + ' 条');
    rule.replies.forEach(function (r, i) {
      wait += Number(r.delay) || 0;
      setTimeout(function () {
        if (!state.open) return;
        var data = expandReply(r.data, caps);
        if (data == null) return sys('自动响应「' + rule.name + '」第 ' + (i + 1) + ' 条应答引用的捕获不存在，已跳过');
        send(data, { format: 'HEX', checksum: 'none', crlf: false, silentHistory: true });
      }, wait);
    });
  }
  function fireRule(id) {
    var rule = byId(state.rules, id);
    if (!state.open) return emit('blocked', '串口未打开，规则不会执行');
    rule.hits++; emit('rule', rule); runReplies(rule, []);
  }

  // ---------- 批量 ----------
  // 步骤可以是 HEX 字符串（使用任务统一间隔），也可以是 { data, delay, format }，delay 为发送本条前的等待
  function stepOf(job, s) { return typeof s === 'string' ? { data: s, delay: job.interval, format: 'HEX' } : s; }
  function runBatch(id) {
    if (!state.open) return emit('blocked', '串口未打开，批量任务未启动');
    stopBatch(true);
    var job = byId(state.batch, id), i = 0, round = 1, rounds = Math.max(1, Number(job.repeat) || 1);
    var steps = job.steps.map(function (s) { return stepOf(job, s); });
    batchRun = { id: id, step: 0, total: steps.length, round: 1, rounds: rounds, timer: null };
    sys('批量任务「' + job.name + '」开始，共 ' + steps.length + ' 步' + (rounds > 1 ? ' × ' + rounds + ' 轮' : ''));
    function finish(msg) { sys(msg); batchRun = null; emit('batch', null); }
    function next() {
      if (!batchRun) return;
      if (i >= steps.length) {
        if (round >= rounds) return finish('批量任务「' + job.name + '」完成');
        round++; i = 0; batchRun.round = round;
      }
      var st = steps[i];
      batchRun.timer = setTimeout(function () {
        if (!batchRun) return;
        batchRun.step = i + 1;
        emit('batch', batchRun);
        var ok = send(st.data, { format: st.format || 'HEX', checksum: 'none', crlf: false, silentHistory: true });
        if (!ok && job.stopOnFail) return finish('第 ' + (i + 1) + ' 步失败，任务停止');
        i++;
        next();
      }, i === 0 && round === 1 ? 0 : Number(st.delay) || 0);
    }
    next();
  }
  function stopBatch(silent) {
    if (!batchRun) return;
    clearTimeout(batchRun.timer);
    if (!silent) sys('批量任务已手动停止');
    batchRun = null; emit('batch', null);
  }

  // ---------- Lua 脚本（设计稿只模拟预置脚本的效果，不执行 Lua） ----------
  function scriptHook(s) { return /function\s+before_send\s*\(/.test(s.code) ? 'before_send' : 'on_receive'; }
  function scriptOut(s, text, err) {
    s.runs++; s.last = text;
    state.scriptLog.push({ time: new Date(), name: s.name, text: text, err: !!err });
    if (state.scriptLog.length > 200) state.scriptLog.shift();
    emit('script', 'log');
  }
  function lastSensor() { return state.lines.slice().reverse().filter(function (l) { return l.dir === 'rx' && l.info.temp != null; })[0]; }
  function parseOut(s, line) {
    if (!line) return scriptOut(s, '还没有收到 A5 5A 03 温湿度帧', true);
    scriptOut(s, 'temp=' + line.info.temp.toFixed(1) + '℃ hum=' + line.info.hum.toFixed(1) + '%');
  }
  function receiveHooks(line) {
    state.scripts.forEach(function (s) {
      if (!s.enabled || scriptHook(s) !== 'on_receive') return;
      if (s.action === 'parse') { if (line.info.temp != null) parseOut(s, line); }
      else scriptOut(s, '收到 ' + line.bytes.length + ' 字节：' + hex(line.bytes));
    });
  }
  // 按列表顺序串联：上一个脚本处理后的帧交给下一个；任一脚本返回 nil 则整帧不发
  function sendHooks(bytes) {
    var out = bytes;
    for (var i = 0; i < state.scripts.length && out; i++) {
      var s = state.scripts[i];
      if (!s.enabled || scriptHook(s) !== 'before_send') continue;
      var next = s.action === 'checksum' ? out.concat([sum8(out)]) : out;
      scriptOut(s, hex(out) + ' → ' + hex(next));
      out = next;
    }
    return out;
  }
  // 手动运行：on_receive 用最近一帧收包；before_send 拿发送框内容试算，不真正发出
  function runScript(id, txText) {
    var s = byId(state.scripts, id);
    if (scriptHook(s) === 'on_receive') {
      if (s.action === 'parse') return parseOut(s, lastSensor());
      var rx = state.lines.slice().reverse().filter(function (l) { return l.dir === 'rx'; })[0];
      return scriptOut(s, rx ? '手动运行 · 最近一帧 ' + hex(rx.bytes) : '手动运行 · 还没有收到数据');
    }
    var sample = parseHex(txText || '');
    if (!sample) return scriptOut(s, '发送框不是 HEX，无法试算', true);
    scriptOut(s, hex(sample) + ' → ' + hex(s.action === 'checksum' ? sample.concat([sum8(sample)]) : sample) + '（试算，未发送）');
  }
  function toggleScript(id) { var s = byId(state.scripts, id); s.enabled = !s.enabled; emit('script', 'list'); return s; }
  function newScript() {
    var s = { id: 's' + Date.now().toString(36), name: 'script' + (state.scripts.length + 1) + '.lua', action: 'custom', enabled: false, runs: 0, last: '',
      code: '-- 新脚本：收到数据时运行\nfunction on_receive(frame)\n  log(frame:hex())\nend' };
    state.scripts.push(s); emit('script', 'list');
    return s;
  }
  function clearScriptLog() { state.scriptLog.length = 0; emit('script', 'log'); }

  // ---------- 杂项 ----------
  function byId(list, id) { return list.filter(function (x) { return x.id === id; })[0]; }
  function clear() { state.lines = []; emit('clear'); emit('state', state); }
  function pad(n, w) { return String(n).padStart(w || 2, '0'); }
  function stamp(d) { return pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds()) + '.' + pad(d.getMilliseconds(), 3); }
  function logText() {
    return state.lines.map(function (l) {
      return '[' + stamp(l.time) + '] ' + l.dir.toUpperCase() + '  ' + (l.bytes ? hex(l.bytes) + '  ; ' + l.info.summary : l.text);
    }).join('\r\n');
  }
  function download(name, text) {
    var a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([text], { type: 'text/plain;charset=utf-8' }));
    a.download = name; a.click();
    setTimeout(function () { URL.revokeObjectURL(a.href); }, 1000);
  }
  function removeHistory(i) { state.history.splice(i, 1); emit('history', state.history); }
  function resetCounters() { state.rx = 0; state.tx = 0; emit('state', state); }
  function saveLog() { download('serial-' + state.port + '-' + Date.now() + '.log', logText()); }
  function exportRules() { download('auto-reply-rules.json', JSON.stringify(state.rules, null, 2)); }
  function seed() {
    // 预置一段历史会话，让首屏不是空白
    state.open = true;
    updatePins();
    sys(state.port + ' 已打开 · ' + state.baud + ' ' + frameFormat());
    device([0xA5, 0x81, 0x00, 0x00, 0x81]);
  }

  return {
    PORTS: PORTS, state: state, on: on,
    open: open, close: close, toggle: toggle, configure: configure, portLabel: portLabel, frameFormat: frameFormat,
    send: send, sendRepeat: sendRepeat, stopLoop: stopLoop, encode: encode,
    fireRule: fireRule, captureCount: captureCount, runBatch: runBatch, stopBatch: stopBatch,
    runScript: runScript, toggleScript: toggleScript, newScript: newScript, clearScriptLog: clearScriptLog, scriptHook: scriptHook,
    clear: clear, saveLog: saveLog, exportRules: exportRules, logText: logText, seed: seed,
    hex: hex, ascii: ascii, parseHex: parseHex, textBytes: textBytes, dissect: dissect, stamp: stamp,
    sum8: sum8, xor8: xor8, lrc: lrc, crc8: crc8, crc16: crc16, crc32: crc32,
    checksumBytes: checksumBytes, withChecksum: withChecksum,
    setSignal: setSignal, ring: ring, download: download, removeHistory: removeHistory, resetCounters: resetCounters
  };
})();
