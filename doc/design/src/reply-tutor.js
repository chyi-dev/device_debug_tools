/* 应答教程三版共用的课与「填进左边」。
   假设：教程只长在「新增 / 编辑应答规则」右侧；左边仍是现在的表单。
   课按现有引擎来写：模板的 ?? / *、四种位置、ASCII 转义；
   正则 HEX 比的是空格分隔的十六进制文字，只有括号才捕获。
   「填入」只改左边，不保存；保存仍走原来的校验。
   视觉母题：一帧拆成字节格，被抓进 $n 的格子用搜索高亮色。 */
var RT = {
  id: 'wild',
  open: 'wild',
  step: 'see',
  wrote: '',
  paint: function () {},
  onClick: function () {}
};

RT.lessons = [
  {
    id: 'order', group: 'template', short: '收到才发',
    title: '收到之后才发',
    brief: '命中后按应答列表一条条发',
    text: '串口打开后，每一包收到的数据都会跟已启用的规则比。命中的按应答列表顺序发送，每条延时从上一包发出之后算，不是从收到的时刻重算。列表里两条都命中，就会都回，不是中了一条就停。串口关着时，规则不执行。',
    rule: { name: '握手应答', kind: 'template', format: 'HEX', match: 'prefix', pattern: 'A5 5A', replies: [{ delay: 20, data: 'A5 81' }, { delay: 50, data: 'A5 5A 00' }] },
    rxNote: '前缀只认开头的 A5 5A，后面两字节不参与。',
    rx: [{ t: 'A5', tag: '前缀' }, { t: '5A', tag: '前缀' }, { t: '01', tag: '忽略', dim: true }, { t: '02', tag: '忽略', dim: true }],
    tx: [{ delay: 20, data: 'A5 81', from: 'A5 81' }, { delay: 50, data: 'A5 5A 00', from: 'A5 5A 00' }],
    steps: [
      { id: 'see', title: '看收到的这一包', text: '这一包以 A5 5A 开头。前缀规则只看开头，后面的 01 02 不参与比较。' },
      { id: 'match', title: '写入匹配', text: '语法选模板，格式 HEX，匹配方式选前缀，匹配数据写 A5 5A。' },
      { id: 'reply', title: '写入应答', text: '先等 20ms 发 A5 81，再等 50ms 发 A5 5A 00。第二段是从第一包发出后算的。' }
    ]
  },
  {
    id: 'place', group: 'template', short: '四种位置',
    title: '前缀、整帧、包含、结尾',
    brief: '这四项只有模板有',
    text: '同一条匹配数据 A5 5A，换匹配方式，中不中完全不同。整帧必须整包一模一样；前缀只看开头；结尾只看末尾；包含只要中间出现过。正则没有这个下拉，位置要自己写 ^ 和 $。',
    rule: { name: '帧里出现就回', kind: 'template', format: 'HEX', match: 'contains', pattern: 'A5 5A', replies: [{ delay: 0, data: 'A5 90' }] },
    table: {
      head: ['方式', 'A5 5A 03 00', '00 A5 5A'],
      rows: [['前缀', '中', '不中'], ['包含', '中', '中'], ['整帧', '不中', '不中'], ['结尾', '不中', '中']]
    },
    rxNote: '这一包开头是 00。前缀不中，包含能中。',
    rx: [{ t: '00', tag: '在前', dim: true }, { t: 'A5', tag: '匹配' }, { t: '5A', tag: '匹配' }],
    tx: [{ delay: 0, data: 'A5 90', from: 'A5 90' }],
    steps: [
      { id: 'see', title: '看同一条数据的四种结果', text: '匹配数据都是 A5 5A。整帧两包都不中，因为都不是正好这两个字节。' },
      { id: 'match', title: '写入匹配', text: '下面填进去的是「包含」。00 A5 5A 这种开头不对的包，前缀不中，包含能中。' },
      { id: 'reply', title: '写入应答', text: '命中后立刻发 A5 90。延时 0 表示上一条（这里是收到）之后马上发。' }
    ]
  },
  {
    id: 'wild', group: 'template', short: '?? 和 *',
    title: '?? 抓一字节，* 抓一段',
    brief: '通配符从左到右就是 $1、$2',
    text: 'HEX 模板里 ?? 是任意一字节，必须写成两个问号，只写一个问号存不进去。* 是任意长度，可以是空。它们按从左到右变成 $1、$2，应答里写 $1 就会换成抓到的字节。模板在保存时就检查：没有第三个通配符却写了 $3，不许存。',
    rule: { name: '回传抓到的字节', kind: 'template', format: 'HEX', match: 'frame', pattern: 'A5 ?? *', replies: [{ delay: 10, data: 'B0 $1' }, { delay: 10, data: '$2' }] },
    rxNote: '整帧。?? 吃掉 11，* 吃掉剩下的 22 33。',
    rx: [{ t: 'A5', tag: '固定' }, { t: '11', tag: '$1', cap: true }, { t: '22', tag: '$2', cap: true }, { t: '33', tag: '$2', cap: true }],
    tx: [{ delay: 10, data: 'B0 11', from: 'B0 $1' }, { delay: 10, data: '22 33', from: '$2' }],
    steps: [
      { id: 'see', title: '看收到的这一包', text: '整帧 A5 11 22 33。?? 只占一个字节，* 把剩下的都拿走，可以是空。' },
      { id: 'match', title: '写入匹配', text: '语法模板，格式 HEX，匹配方式整帧，匹配数据 A5 ?? *。?? 是 $1，* 是 $2。' },
      { id: 'reply', title: '写入应答', text: '10ms 后 B0 $1 发出 B0 11。再过 10ms，$2 发出 22 33。' }
    ]
  },
  {
    id: 'ascii', group: 'template', short: 'ASCII 问号',
    title: 'ASCII 里一个 ? 是一字节',
    brief: '应答框仍然写 HEX',
    text: '格式改成 ASCII 之后，一个 ? 就是任意一字节，* 仍是任意长度。想匹配问号本身，写成反斜杠加问号；星号、回车、换行同样加反斜杠。指定某个字节用反斜杠 x 加两位，例如 \\x0D。忽略大小写只在 ASCII 下有。应答框永远写 HEX：字符 7 抓进来是字节 37。',
    rule: { name: '回传 OK 后一字节', kind: 'template', format: 'ASCII', match: 'prefix', pattern: 'OK,?', ignoreCase: true, replies: [{ delay: 30, data: '$1' }] },
    rxNote: '忽略大小写，所以 ok,7 也能对上 OK,?。问号抓到字符 7。',
    rx: [{ t: 'o', tag: '固定' }, { t: 'k', tag: '固定' }, { t: ',', tag: '固定' }, { t: '7', tag: '$1', cap: true }],
    tx: [{ delay: 30, data: '37', from: '$1' }],
    steps: [
      { id: 'see', title: '看收到的这一包', text: '收到的是字符 ok,7。ASCII 模板按字符比，一个 ? 只吃一个字节。' },
      { id: 'match', title: '写入匹配', text: '格式选 ASCII，匹配方式前缀，匹配数据 OK,?，并勾上忽略大小写。' },
      { id: 'reply', title: '写入应答', text: '应答仍是 HEX。$1 换成字符 7 的字节，发出 37。' }
    ]
  },
  {
    id: 'reword', group: 'regex', short: '正则不是模板',
    title: '正则看的是一行 HEX 文字',
    brief: '这里的 * 不是任意长度',
    text: '语法改成正则后，没有「匹配方式」这一栏。HEX 正则不按字节格子比，而是去比空格分隔的十六进制文字，例如 A5 5A 03。表达式里的 * 是「前一个东西重复」，?? 也不再表示任意一字节。要抓一个字节，写括号包住两位：([0-9A-F]{2})。开头用 ^，结尾用 $，自己写。',
    rule: { name: '取帧头后一字节', kind: 'regex', format: 'HEX', match: 'prefix', pattern: '^A5 5A ([0-9A-F]{2})', replies: [{ delay: 40, data: 'A5 $1' }] },
    rxNote: '引擎拿去匹配的文字是「A5 5A 03」。这条没写 $，后面再跟字节也会中。',
    rx: [{ t: 'A5', tag: '字面' }, { t: '5A', tag: '字面' }, { t: '03', tag: '$1', cap: true }],
    tx: [{ delay: 40, data: 'A5 03', from: 'A5 $1' }],
    steps: [
      { id: 'see', title: '看它实际在比什么', text: '字节会先变成文字 A5 5A 03。正则比的是这行字，不是左边这种格子本身。' },
      { id: 'match', title: '写入匹配', text: '语法选正则，匹配方式会消失。匹配数据写 ^A5 5A ([0-9A-F]{2})。不要把模板的 * 原样搬过来。' },
      { id: 'reply', title: '写入应答', text: '括号里的 03 是 $1。应答 A5 $1 发出 A5 03。' }
    ]
  },
  {
    id: 'groups', group: 'regex', short: '括号才捕获',
    title: '只有括号才是 $1',
    brief: '写了不存在的 $n，那一条会跳过',
    text: '模板的 ?? 和 * 会自动占编号。正则只有圆括号里的内容才变成 $1、$2，按左括号出现的顺序。这条用 $ 锚住整帧，两对括号各抓一个字节。应答里如果写了 $3，而只有两组括号，这一条不发送，系统日志记「引用的捕获不存在，已跳过」。括号若只抓到一个十六进制字符，同样跳过。模板则会在点保存时就拦住。',
    rule: { name: '拆开两个字节', kind: 'regex', format: 'HEX', match: 'frame', pattern: '^A5 5A ([0-9A-F]{2}) ([0-9A-F]{2})$', replies: [{ delay: 20, data: 'B1 $1' }, { delay: 20, data: 'B2 $2' }] },
    rxNote: '两对括号，按从左到右是 $1、$2。末尾的 $ 表示整帧到此结束。',
    rx: [{ t: 'A5', tag: '字面' }, { t: '5A', tag: '字面' }, { t: '11', tag: '$1', cap: true }, { t: '22', tag: '$2', cap: true }],
    tx: [{ delay: 20, data: 'B1 11', from: 'B1 $1' }, { delay: 20, data: 'B2 22', from: 'B2 $2' }],
    steps: [
      { id: 'see', title: '看两组括号各抓什么', text: '文字是 A5 5A 11 22。第一对括号是 11，第二对是 22。没有括号的 A5、5A 不会变成 $n。' },
      { id: 'match', title: '写入匹配', text: '正则 HEX，匹配数据 ^A5 5A ([0-9A-F]{2}) ([0-9A-F]{2})$。最后的 $ 把整帧锚死。' },
      { id: 'reply', title: '写入应答', text: 'B1 $1 发出 B1 11，B2 $2 发出 B2 22。若写成 $3，这一条会被跳过，规则仍算命中。' }
    ]
  },
  {
    id: 'reascii', group: 'regex', short: 'ASCII 逐字',
    title: 'ASCII 正则逐字匹配',
    brief: '对着字符比，不是对着 HEX 文字',
    text: 'ASCII 正则对着收到的原始字符匹配，一个字符一个字符比，不是「A5 5A」那种十六进制文字。括号抓到的字符按字节填进应答。忽略大小写同样只在 ASCII 时可选。锚点还是自己写 ^ 和 $。',
    rule: { name: '取逗号后面', kind: 'regex', format: 'ASCII', match: 'prefix', pattern: '^OK,(.+)$', replies: [{ delay: 20, data: '$1' }] },
    rxNote: '收到字符 OK,42。(.+) 把 42 两个字符抓进同一个 $1。',
    rx: [{ t: 'O', tag: '字面' }, { t: 'K', tag: '字面' }, { t: ',', tag: '字面' }, { t: '4', tag: '$1', cap: true }, { t: '2', tag: '$1', cap: true }],
    tx: [{ delay: 20, data: '34 32', from: '$1' }],
    steps: [
      { id: 'see', title: '看收到的字符', text: 'OK,42 是五个字符。括号把逗号后面的 4 和 2 收成一个 $1，发出时是两个字节。' },
      { id: 'match', title: '写入匹配', text: '语法正则，格式 ASCII，匹配数据 ^OK,(.+)$。没有匹配方式这一栏。' },
      { id: 'reply', title: '写入应答', text: '$1 换成 4 和 2 的字节，发出 34 32。' }
    ]
  }
];

RT.groups = [{ id: 'template', label: '模板' }, { id: 'regex', label: '正则' }];

RT.byId = function (id) {
  for (var i = 0; i < RT.lessons.length; i++) if (RT.lessons[i].id === id) return RT.lessons[i];
};
RT.no = function (l) { return RT.lessons.indexOf(l) + 1; };
RT.recipe = function (l) {
  var r = l.rule;
  var fmt = r.format === 'ASCII' ? 'ASCII' : 'HEX';
  if (r.kind === 'regex') return '正则 ' + fmt + ' · ' + r.pattern;
  return matchName[r.match] + ' ' + fmt + (r.ignoreCase ? ' Aa' : '') + ' · ' + r.pattern;
};

RT.strip = function (l) {
  return '<div class="strip"><div class="slab">收到</div><div class="bytes">' + l.rx.map(function (b) {
    return '<span class="' + (b.cap ? 'cap' : '') + (b.dim ? ' dim' : '') + '">' + esc(b.t) + '<small>' + esc(b.tag) + '</small></span>';
  }).join('') + '</div>' + (l.rxNote ? '<p class="snote">' + esc(l.rxNote) + '</p>' : '') + '</div>';
};
RT.tx = function (l) {
  return '<div class="strip"><div class="slab">将发出</div>' + l.tx.map(function (x) {
    return '<div class="tx"><span class="ms">+' + x.delay + ' ms</span><code>' + esc(x.data) + '</code><span class="from">由 ' + esc(x.from) + '</span></div>';
  }).join('') + '</div>';
};
RT.table = function (l) {
  if (!l.table) return '';
  return '<table class="cmp"><thead><tr>' + l.table.head.map(function (h, i) {
    return '<th' + (i ? ' class="hex"' : '') + '>' + esc(h) + '</th>';
  }).join('') + '</tr></thead><tbody>' + l.table.rows.map(function (row) {
    return '<tr>' + row.map(function (c, i) {
      var cls = c === '中' ? 'yes' : (c === '不中' ? 'no' : '');
      return '<td' + (cls ? ' class="' + cls + '"' : '') + '>' + esc(c) + '</td>';
    }).join('') + '</tr>';
  }).join('') + '</tbody></table>';
};
RT.block = function (l) {
  return '<p class="rttext">' + esc(l.text) + '</p>' + RT.table(l) +
    '<div class="recipe">' + esc(RT.recipe(l)) + '</div>' + RT.strip(l) + RT.tx(l);
};

RT.fill = function (l, part) {
  var rule = l.rule;
  var all = !part || part === 'all';
  if (all || part === 'match') {
    $('dName').value = rule.name;
    $('dKind').value = rule.kind;
    $('dFormat').value = rule.format;
    $('dMatch').value = rule.match || 'prefix';
    $('dPattern').value = rule.pattern;
    $('dCase').checked = !!rule.ignoreCase;
    $('dKind').dispatchEvent(new Event('change'));
  }
  if (all || part === 'reply') {
    $('dLines').innerHTML = rule.replies.map(replyLine).join('');
    renumber();
    $('dOn').checked = true;
  }
};
RT.hot = function (part) {
  document.querySelectorAll('.ruleform .hot').forEach(function (n) { n.classList.remove('hot'); });
  if (part === 'match') {
    ['dName', 'dKind', 'dFormat', 'dMatch', 'dPattern'].forEach(function (id) {
      var el = $(id);
      if (!el) return;
      var row = el.closest('.row');
      if (row && row.style.display !== 'none') row.classList.add('hot');
    });
    var caseRow = $('dCaseRow');
    if (caseRow && caseRow.style.display !== 'none') caseRow.classList.add('hot');
  }
  if (part === 'reply') {
    var sub = document.querySelector('.ruleform .sub');
    var lines = document.querySelector('.ruleform .lines');
    if (sub) sub.classList.add('hot');
    if (lines) lines.classList.add('hot');
  }
};
RT.wroteLine = function (key) {
  if (RT.wrote !== key) return '';
  return '<p class="wrote">已写入左边，点「保存」才会出现在规则列表里。</p>';
};

RT.mount = function () {
  var body = $('dlgBody');
  var form = document.createElement('div');
  form.className = 'ruleform';
  while (body.firstChild) form.appendChild(body.firstChild);
  body.classList.add('split');
  body.appendChild(form);
  var rail = document.createElement('aside');
  rail.id = 'rail';
  rail.className = 'rail';
  body.appendChild(rail);
  document.querySelector('.dialog').classList.add('wide');
  rail.onclick = function (e) {
    var t = e.target.closest('[data-rt]');
    if (!t) return;
    RT.onClick(t.dataset.rt, t.dataset.id);
  };
  RT.paint();
};
RT.unmount = function () {
  var body = $('dlgBody');
  var form = body.querySelector('.ruleform');
  if (form) {
    while (form.firstChild) body.insertBefore(form.firstChild, form);
    form.remove();
  }
  var rail = $('rail');
  if (rail) rail.remove();
  body.classList.remove('split');
  var d = document.querySelector('.dialog');
  if (d) d.classList.remove('wide');
};
RT.toggle = function () {
  var on = !$('rail');
  if (on) RT.mount(); else RT.unmount();
  $('rtToggle').classList.toggle('pri', on);
};

var baseEditRule = editRule;
editRule = function (rule) {
  baseEditRule(rule);
  var btn = document.createElement('button');
  btn.type = 'button';
  btn.id = 'rtToggle';
  btn.className = 'btn sm';
  btn.textContent = '教程';
  btn.onclick = RT.toggle;
  $('dlgTitle').appendChild(btn);
};
var baseCloseDialog = closeDialog;
closeDialog = function () {
  RT.unmount();
  var btn = $('rtToggle');
  if (btn) btn.remove();
  baseCloseDialog();
};

/* 版 A · 课表：点一课就在列表里展开，对照左边的空表单。 */
RT.open = 'wild';
RT.paint = function () {
  var html = '<div class="railhead"><b>教程</b><span>模板四课，正则三课。点开一课，可填进左边。</span></div><div class="rscroll">';
  RT.groups.forEach(function (g) {
    html += '<div class="glab">' + g.label + '</div>';
    RT.lessons.forEach(function (l) {
      if (l.group !== g.id) return;
      var on = RT.open === l.id;
      html += '<button type="button" class="lrow' + (on ? ' on' : '') + '" data-rt="open" data-id="' + l.id + '">' +
        '<span class="ti"><span class="no">' + RT.no(l) + '</span><span>' + esc(l.title) + '</span></span>' +
        '<span class="br">' + esc(l.brief) + '</span></button>';
      if (!on) return;
      html += '<div class="lbody">' + RT.block(l) +
        '<div class="acts"><button type="button" class="btn sm pri" data-rt="fill" data-id="' + l.id + '">填入编辑器</button></div>' +
        RT.wroteLine(l.id) + '</div>';
    });
  });
  $('rail').innerHTML = html + '</div>';
};
RT.onClick = function (act, id) {
  if (act === 'open') { RT.open = RT.open === id ? '' : id; RT.paint(); return; }
  if (act === 'fill') { RT.fill(RT.byId(id)); RT.wrote = id; RT.hot(''); RT.paint(); }
};
