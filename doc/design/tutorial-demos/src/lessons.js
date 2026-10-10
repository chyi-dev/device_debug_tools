// 六课共用数据：三版只换教程放在哪里、怎么用，课本身不变。
// out 是样例帧在真实 Lua 引擎里的输出；设计稿不执行 Lua，直接回放。
var LESSONS = [
  {
    id: 'l1', name: 'lesson1_hooks.lua', title: '脚本什么时候运行', hook: 'on_receive',
    brief: '两个钩子：收到数据后、发送数据前',
    text: '写一个叫 on_receive 的函数，每收到一包数据就会调用它，frame 是这一包的字节。写 before_send 则在每一帧发出前调用（发送、快捷指令、批量、自动应答都算），返回的帧才会真正发出。开关只控制自动运行；「运行」是用最近一帧或发送框内容试算，不会发数据。',
    code: '-- 收到一包数据后运行，frame 是这一包的字节\nfunction on_receive(frame)\n  log("收到", frame:len(), "字节")\nend\n',
    sample: 'A5 81 00 00 81', out: ['收到 5 字节']
  },
  {
    id: 'l2', name: 'lesson2_print.lua', title: '把一帧打印出来', hook: 'on_receive',
    brief: 'log 输出到运行日志，帧会显示成 HEX',
    text: 'log 把内容写到右侧运行日志，多个参数用空格连起来；print 和 log 是同一个函数。直接传入帧会显示成 HEX，frame:sub(i, j) 取第 i 到第 j 字节，frame:str() 按 ASCII 转成文字。',
    code: 'function on_receive(frame)\n  log(frame)                     -- 整帧 HEX\n  log("帧头", frame:sub(1, 2))   -- 第 1~2 字节\n  log("末字节", frame:u8(frame:len()))\nend\n',
    sample: 'A5 5A 03 00 F6 02 09 03', out: ['A5 5A 03 00 F6 02 09 03', '帧头 A5 5A', '末字节 3']
  },
  {
    id: 'l3', name: 'lesson3_parse.lua', title: '认帧头、取数值', hook: 'on_receive',
    brief: 'starts_with 判断帧头，u16 读两字节整数',
    text: 'frame:starts_with(0xA5, 0x5A, 0x03) 判断帧头；不是要的帧就 return 跳过。下标从 1 开始：u8(i) 读第 i 字节，u16(i) 把第 i、i+1 字节按大端拼成整数，小端用 u16le(i)。',
    code: '-- 温湿度帧：A5 5A 03 温度(2) 湿度(2) 校验\nfunction on_receive(frame)\n  if not frame:starts_with(0xA5, 0x5A, 0x03) then return end\n  local t = frame:u16(4) / 10\n  local h = frame:u16(6) / 10\n  log(string.format("温度 %.1f℃ 湿度 %.1f%%", t, h))\nend\n',
    sample: 'A5 5A 03 00 F6 02 09 03', out: ['温度 24.6℃ 湿度 52.1%']
  },
  {
    id: 'l4', name: 'lesson4_checksum.lua', title: '发送前补校验', hook: 'before_send',
    brief: 'before_send 返回改过的帧，append 追加字节',
    text: 'before_send 收到即将发出的帧，返回什么就发什么。frame:append(...) 返回在末尾追加字节后的新帧；sum8 是累加和，xor8 是异或（BCC）。',
    code: '-- 发出前在帧尾补 SUM8\nfunction before_send(frame)\n  return frame:append(sum8(frame))\n  -- 改用异或校验：return frame:append(xor8(frame))\nend\n',
    sample: 'A5 01 00 00 01', out: ['A5 01 00 00 01 → A5 01 00 00 01 A7']
  },
  {
    id: 'l5', name: 'lesson5_block.lua', title: '拦截不想发的帧', hook: 'before_send',
    brief: '返回 nil，这一帧就不发',
    text: 'before_send 返回 nil 时这一帧不会发出，系统日志会记一条拦截。其他帧要原样放行，记得 return frame。',
    code: '-- 不让「停止采集」发出去，其余照常\nfunction before_send(frame)\n  if frame:starts_with(0xA5, 0x10, 0x00) then\n    log("已拦截停止采集")\n    return nil\n  end\n  return frame\nend\n',
    sample: 'A5 10 00 00 10', out: ['已拦截停止采集', 'A5 10 00 00 10 → nil，已拦截']
  },
  {
    id: 'l6', name: 'lesson6_modbus.lua', title: 'Modbus 补 CRC16', hook: 'before_send',
    brief: 'crc16 返回低字节、高字节',
    text: 'crc16(frame) 按 Modbus 算法返回两个值：低字节、高字节，正好按 Modbus RTU 的顺序追加。frame(...) 可以从数字、字符串或别的帧拼出一个新帧。',
    code: '-- Modbus RTU：帧尾追加 CRC16，低字节在前\nfunction before_send(frame)\n  local lo, hi = crc16(frame)\n  return frame:append(lo, hi)\nend\n',
    sample: '01 03 00 00 00 01', out: ['01 03 00 00 00 01 → 01 03 00 00 00 01 84 0A']
  }
];
var TUT_NOTES = '下标从 1 开始 · 0x 写法可以直接用 · 死循环会被自动中止，os.execute 等危险函数已移除';

function lessonById(id) { return byId(LESSONS, id); }
function tutPush(name, text, err) {
  S.scriptLog.push({ time: new Date(), name: name, text: text, err: !!err });
  if ($('scLog')) { $('scLog').innerHTML = scriptLogHtml(); $('scLog').scrollTop = $('scLog').scrollHeight; }
  if ($('scCount')) $('scCount').textContent = S.scriptLog.length + ' 条';
}
// 样例试跑：把这一课的样例帧喂给代码，不碰串口
function lessonTry(l) {
  tutPush(l.name, '样例试跑 · ' + l.hook + ' ← ' + l.sample);
  l.out.forEach(function (t) { tutPush(l.name, t); });
}
function lessonNew(l) {
  var s = Serial.newScript();
  s.name = l.name; s.code = l.code;
  scUi.sel = s.id; scUi.dock = true;
  return s;
}
function lessonInsert(l) {
  var s = scriptSel(); if (!s) return;
  s.code = s.code.replace(/\s*$/, '') + '\n\n' + l.code;
  renderTab();
  var c = $('scCode'); if (c) { c.focus(); c.scrollTop = c.scrollHeight; }
  toast('已插入到 ' + s.name + ' 末尾');
}
function tutCode(code) { return '<pre class="tutcode">' + esc(code.replace(/\n$/, '')) + '</pre>'; }
