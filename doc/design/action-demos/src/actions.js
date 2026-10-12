// 三版共用：复制一条配置，再按 Act.mode 决定次要操作放哪。
// more = 行尾「更多」；select = 点中后在下方展开；context = 右键。
var Act = { mode: 'more', sel: '' };

function copyName(name, taken, script) {
  var used = {};
  taken.forEach(function (n) { used[n] = 1; });
  var lua = script && /\.lua$/i.test(name);
  var stem = lua ? name.slice(0, -4) : name;
  function label(n) {
    if (!script) return n == null ? name + ' 副本' : name + ' 副本 ' + n;
    var suffix = n == null ? '_副本' : '_副本_' + n;
    return (lua ? stem + suffix + '.lua' : stem + suffix);
  }
  var text = label(null);
  for (var n = 2; used[text]; n++) text = label(n);
  return text;
}
function insertAfter(list, id, copy) {
  var next = [];
  list.forEach(function (item) {
    next.push(item);
    if (item.id === id) next.push(copy);
  });
  return next;
}
function dupQuick(id) {
  var src = byId(allQuick(), id);
  if (!src) return;
  var copy = { id: uid('q'), name: copyName(src.name, allQuick().map(function (c) { return c.name; })), data: src.data, format: src.format, key: '' };
  var folder = quickFolderOf(id);
  if (folder) folder.commands = insertAfter(folder.commands, id, copy);
  else S.quick = insertAfter(S.quick, id, copy);
  renderTab(); toast('已复制');
}
function dupBatch() {
  var src = byId(S.batch, ui.batchSel);
  if (!src) return;
  var copy = {
    id: uid('b'),
    name: copyName(src.name, S.batch.map(function (b) { return b.name; })),
    repeat: src.repeat, stopOnFail: src.stopOnFail,
    steps: src.steps.map(function (s) { return { data: s.data, delay: s.delay, note: s.note || '' }; })
  };
  S.batch = insertAfter(S.batch, src.id, copy);
  ui.batchSel = copy.id;
  renderTab(); toast('已复制');
}
function dupRule(id) {
  var src = byId(S.rules, id);
  if (!src) return;
  var copy = JSON.parse(JSON.stringify(src));
  copy.id = uid('r');
  copy.name = copyName(src.name, S.rules.map(function (r) { return r.name; }));
  copy.enabled = false;
  copy.hits = 0;
  S.rules = insertAfter(S.rules, id, copy);
  renderTab(); toast('已复制');
}
function dupScript(id) {
  var src = byId(S.scripts, id);
  if (!src) return;
  var copy = { id: uid('s'), name: copyName(src.name, S.scripts.map(function (s) { return s.name; }), true), action: src.action || '', enabled: false, runs: 0, last: '', code: src.code };
  S.scripts = insertAfter(S.scripts, id, copy);
  scUi.sel = copy.id; scUi.dock = true;
  renderTab(); toast('已复制');
}
function renameScript(id) {
  var s = byId(S.scripts, id);
  if (!s) return;
  dialog('重命名脚本',
    '<div class="row"><label>名称</label><input class="inp" id="dName" value="' + esc(s.name) + '"></div><div class="err" id="dlgErr"></div>',
    [{ text: '取消' }, { text: '保存', pri: true, run: function () {
      var name = $('dName').value.trim();
      if (!name) return fail('请填写名称');
      s.name = name; renderTab(); toast('脚本已重命名');
    } }]);
}
function deleteScript(id) {
  var s = byId(S.scripts, id);
  if (!s) return;
  confirmDel('脚本「' + s.name + '」', function () {
    S.scripts = S.scripts.filter(function (x) { return x.id !== id; });
    if (scUi.sel === id) scUi.sel = S.scripts[0] && S.scripts[0].id;
    renderTab();
  });
}

function menuItems(kind, id) {
  var editAct = { quick: 'quickEdit', rule: 'ruleEdit', folder: 'folderEdit', batch: 'batchEdit', script: 'scRename' }[kind];
  var dupAct = { quick: 'quickDup', rule: 'ruleDup', batch: 'batchDup', script: 'scDup' }[kind];
  var delAct = { quick: 'quickDel', rule: 'ruleDel', folder: 'folderDel', batch: 'batchDel', script: 'scDel' }[kind];
  var editText = (kind === 'folder' || kind === 'script') ? '重命名' : '编辑';
  var edit = { act: editAct, id: id, text: editText };
  var dup = dupAct ? { act: dupAct, id: id, text: '复制' } : null;
  var del = { act: delAct, id: id, text: '删除', danger: true };
  if (Act.mode === 'context') {
    if (kind === 'batch') return [dup, del];
    if (kind === 'folder') return [edit, del];
    return [edit, dup, del];
  }
  if (Act.mode === 'more') {
    if (kind === 'quick' || kind === 'rule' || kind === 'batch') return [dup, del];
    if (kind === 'folder') return [edit, del];
    return [edit, dup, del];
  }
  if (kind === 'folder') return [edit, del];
  return [edit, dup, del];
}
function menuHtml(items) {
  return items.map(function (it) {
    return '<button data-act="' + it.act + '"' + (it.id ? ' data-id="' + it.id + '"' : '') + (it.danger ? ' class="danger"' : '') + '>' + it.text + '</button>';
  }).join('');
}
function moreBtn(kind, id) {
  return '<button class="link" data-act="menuOpen" data-kind="' + kind + '" data-id="' + (id || '') + '">更多</button>';
}
function barHtml(items, inner) {
  return '<div class="actbar' + (inner ? ' in' : '') + '">' + items.map(function (it) {
    return '<button class="link' + (it.danger ? ' danger' : '') + '" data-act="' + it.act + '"' + (it.id ? ' data-id="' + it.id + '"' : '') + '>' + it.text + '</button>';
  }).join('') + '</div>';
}
function picked(kind, id) { return Act.mode === 'select' && Act.sel === kind + ':' + id; }

Act.hide = function () {
  var m = $('actCtx');
  if (m) m.hidden = true;
};
Act.open = function (x, y, items, alignRight) {
  var m = $('actCtx');
  m.innerHTML = menuHtml(items);
  m.hidden = false;
  m.style.left = '0px';
  m.style.top = '0px';
  var w = m.offsetWidth, h = m.offsetHeight;
  var left = alignRight ? x - w : x;
  var top = y;
  if (left + w > innerWidth - 8) left = innerWidth - 8 - w;
  if (left < 8) left = 8;
  if (top + h > innerHeight - 8) top = Math.max(8, y - h - 8);
  m.style.left = left + 'px';
  m.style.top = top + 'px';
};
Act.run = function (act, id) {
  if (act === 'quickDup') return dupQuick(id);
  if (act === 'quickEdit') return editQuick(byId(allQuick(), id));
  if (act === 'quickDel') return confirmDel('快捷指令「' + byId(allQuick(), id).name + '」', function () { removeQuick(id); renderTab(); });
  if (act === 'folderEdit') return editFolder(byId(S.quick, id));
  if (act === 'folderDel') {
    var fd = byId(S.quick, id);
    return confirmDel('文件夹「' + fd.name + '」' + (fd.commands.length ? '会一并删除其中 ' + fd.commands.length + ' 条指令，' : ''), function () { removeQuick(id); renderTab(); });
  }
  if (act === 'batchDup') return dupBatch();
  if (act === 'batchEdit') return editBatch(byId(S.batch, ui.batchSel));
  if (act === 'batchDel') return confirmDel('批量任务「' + byId(S.batch, ui.batchSel).name + '」', function () {
    S.batch = S.batch.filter(function (x) { return x.id !== ui.batchSel; });
    ui.batchSel = S.batch[0] && S.batch[0].id;
    renderTab();
  });
  if (act === 'ruleDup') return dupRule(id);
  if (act === 'ruleEdit') return editRule(byId(S.rules, id));
  if (act === 'ruleDel') return confirmDel('应答规则「' + byId(S.rules, id).name + '」', function () {
    S.rules = S.rules.filter(function (x) { return x.id !== id; });
    renderTab(); renderStatus();
  });
  if (act === 'scDup') return dupScript(id);
  if (act === 'scRename') return renameScript(id);
  if (act === 'scDel') return deleteScript(id);
  return false;
};

function quickOps(q) {
  var key = q.key ? '<span class="key">' + q.key + '</span>' : '';
  if (Act.mode === 'more') return key + '<button class="link" data-act="quickEdit" data-id="' + q.id + '">编辑</button>' + moreBtn('quick', q.id);
  if (Act.mode === 'select') return key;
  return key;
}
function quickRowAct(q, inner) {
  var pick = Act.mode === 'select' ? ' data-act="pick" data-kind="quick" data-id="' + q.id + '"' : '';
  var kind = Act.mode === 'context' ? ' data-kind="quick" data-id="' + q.id + '"' : '';
  var row = '<div class="it' + (inner ? ' in' : '') + (picked('quick', q.id) ? ' picked' : '') + '"' + pick + kind + '>' +
    '<button class="btn sm pri lead" data-act="quickSend" data-id="' + q.id + '">发送</button>' +
    '<span class="nm">' + esc(q.name) + '</span><span class="dt">' + (q.format === 'ASCII' ? 'ASCII · ' : '') + esc(q.data) + '</span>' +
    '<span class="ops">' + quickOps(q) + '</span></div>';
  if (picked('quick', q.id)) row += barHtml(menuItems('quick', q.id), inner);
  return row;
}
function folderRowAct(x) {
  var pick = Act.mode === 'select' ? ' data-act="pick" data-kind="folder" data-id="' + x.id + '"' : '';
  var kind = Act.mode === 'context' ? ' data-kind="folder" data-id="' + x.id + '"' : '';
  var extra = Act.mode === 'more' ? moreBtn('folder', x.id) : '';
  var row = '<div class="fd' + (picked('folder', x.id) ? ' picked' : '') + '"' + pick + kind + '>' +
    '<span class="arw" data-act="folderToggle" data-id="' + x.id + '">' + (x.expanded ? '▼' : '▶') + '</span>' +
    '<span class="nm">' + esc(x.name) + '</span><span class="cnt">' + x.commands.length + ' 条</span>' +
    '<button class="link" data-act="quickNewIn" data-id="' + x.id + '">新增</button>' + extra + '</div>';
  if (picked('folder', x.id)) row += barHtml(menuItems('folder', x.id));
  return row + (x.expanded
    ? (x.commands.length ? x.commands.map(function (q) { return quickRowAct(q, true); }).join('') : '<div class="explain in">文件夹为空。点「新增」在这里添加指令。</div>')
    : '');
}

quickHtml = function () {
  return '<div class="bar"><span class="note">点「发送」立即发出，不进入历史</span><span class="grow"></span><button class="btn sm" data-act="folderNew">新增文件夹</button><button class="btn sm" data-act="quickNew">新增</button></div>' +
    '<div class="list">' + S.quick.map(function (x) { return isFolder(x) ? folderRowAct(x) : quickRowAct(x, false); }).join('') + '</div>' +
    (S.quick.length ? '' : '<div class="explain">还没有快捷指令。点「新增」保存常用的一条指令，或点「新增文件夹」先分组。</div>');
};
batchHtml = function () {
  var job = byId(S.batch, ui.batchSel) || S.batch[0];
  if (!job) return '<div class="bar"><span class="grow"></span><button class="btn sm" data-act="batchNew">新建任务</button></div><div class="explain">还没有批量任务。</div>';
  ui.batchSel = job.id;
  var run = ui.batchRun && ui.batchRun.id === job.id ? ui.batchRun : null;
  var kind = Act.mode === 'context' ? ' data-kind="batch"' : '';
  var tail = Act.mode === 'more' ? moreBtn('batch', job.id) : '';
  var edit = Act.mode === 'select' ? '' : '<button class="btn sm" data-act="batchEdit">编辑</button>';
  var strip = Act.mode === 'select' ? barHtml(menuItems('batch', job.id)) : '';
  return '<div class="bar"' + kind + '><select id="batchSel" style="flex:1">' + S.batch.map(function (b) {
    return '<option value="' + b.id + '"' + (b.id === job.id ? ' selected' : '') + '>' + esc(b.name) + '</option>';
  }).join('') + '</select><button class="btn sm" data-act="batchNew">新建</button>' + edit + tail + '</div>' +
    '<div class="batchmeta"><label>重复 <input class="inp" id="batchRepeat" value="' + job.repeat + '"> 轮</label><label><input type="checkbox" id="batchStop"' + (job.stopOnFail ? ' checked' : '') + '>失败即停</label>' +
    '<span style="margin-left:auto">' + (run ? '第 ' + run.round + '/' + run.rounds + ' 轮 · 第 ' + run.step + '/' + run.total + ' 条' : job.steps.length + ' 条指令') + '</span>' +
    (run ? '<button class="btn sm danger" data-act="batchStop">停止</button>' : '<button class="btn sm pri" data-act="batchRun">开始发送</button>') + '</div>' +
    (run ? '<div class="prog"><i style="width:' + (((run.round - 1) * run.total + run.step) / (run.rounds * run.total) * 100) + '%"></i></div>' : '') +
    strip +
    '<table class="steps"' + kind + '><thead><tr><th>#</th><th>延时</th><th>指令数据</th><th>备注</th></tr></thead><tbody>' +
    job.steps.map(function (s, i) { return '<tr class="' + (run && run.step === i + 1 ? 'now' : '') + '"><td>' + (i + 1) + '</td><td>' + s.delay + ' ms</td><td>' + esc(s.data) + '</td><td class="note">' + esc(s.note || '') + '</td></tr>'; }).join('') +
    '</tbody></table><div class="explain">延时指发送本条之前等待的毫秒数，第一条立即发送。</div>';
};
replyHtml = function () {
  var on = S.rules.filter(function (r) { return r.enabled; }).length;
  return '<div class="bar"><span class="note">已启用 ' + on + ' / ' + S.rules.length + '，按列表顺序逐条匹配</span><span class="grow"></span><button class="btn sm" data-act="ruleNew">新增规则</button></div>' +
    '<div class="list">' + S.rules.map(function (r) {
      var pick = Act.mode === 'select' ? ' data-act="pick" data-kind="rule" data-id="' + r.id + '"' : '';
      var kind = Act.mode === 'context' ? ' data-kind="rule" data-id="' + r.id + '"' : '';
      var ops = '<span class="hits">' + r.hits + ' 次</span><button class="link" data-act="ruleFire" data-id="' + r.id + '">执行</button>';
      if (Act.mode === 'more') ops += '<button class="link" data-act="ruleEdit" data-id="' + r.id + '">编辑</button>' + moreBtn('rule', r.id);
      var row = '<div class="it' + (picked('rule', r.id) ? ' picked' : '') + '"' + pick + kind + '>' +
        '<button class="sw lead' + (r.enabled ? ' on' : '') + '" data-act="ruleToggle" data-id="' + r.id + '" title="启用 / 停用"></button>' +
        '<span class="nm">' + esc(r.name) + '</span><span class="dt">' + esc(ruleLabel(r)) + ' → ' +
        r.replies.map(function (x) { return '+' + x.delay + 'ms ' + x.data; }).map(esc).join('，') + '</span>' +
        '<span class="ops">' + ops + '</span></div>';
      if (picked('rule', r.id)) row += barHtml(menuItems('rule', r.id));
      return row;
    }).join('') + '</div>' +
    '<div class="explain">收到的数据与规则匹配后，按应答列表顺序依次发送；每条应答的延时从上一条发出后开始计算。</div>';
};
scriptRows = function () {
  var cur = scriptSel();
  return S.scripts.map(function (s) {
    var on = scUi.dock && s === cur;
    var kind = Act.mode === 'context' ? ' data-kind="script" data-id="' + s.id + '"' : '';
    var row = '<div class="it sc' + (on ? ' active' : '') + (s.enabled ? '' : ' off') + '" data-act="scSel" data-id="' + s.id + '"' + kind + '>' +
      '<button class="sw lead' + (s.enabled ? ' on' : '') + '" data-act="scToggle" data-id="' + s.id + '" title="启用 / 停用"></button>' +
      '<span class="nm">' + esc(s.name) + '</span>' +
      '<span class="dt"><span class="schook">' + Serial.scriptHook(s) + '</span>' + (s.runs ? '已输出 ' + s.runs + ' 次' : (s.enabled ? '等待触发' : '已停用')) + '</span></div>';
    if (Act.mode === 'select' && on) row += barHtml(menuItems('script', s.id));
    return row;
  }).join('');
};
dockHead = function (s) {
  var more = Act.mode === 'more' ? moreBtn('script', s.id) : '';
  return '<b>' + esc(s.name) + '</b><span class="schook">' + Serial.scriptHook(s) + '</span><span>' + (s.enabled ? '自动运行中' : '已停用，仅手动运行') + '</span>' +
    '<span class="grow"></span><span>Lua · 输入即保存 · Tab 缩进两格</span><button class="btn sm pri" data-act="scRun" data-id="' + s.id + '">运行</button>' +
    more + '<button class="link" data-act="scFold">收起</button>';
};

var actTaken = { menuOpen: 1, pick: 1, quickDup: 1, batchDup: 1, ruleDup: 1, scDup: 1, scRename: 1, scDel: 1 };
Act.handle = function (e) {
  var b = e.target.closest('[data-act]');
  if (!b) return false;
  var act = b.dataset.act;
  if (act === 'menuOpen') {
    e.stopPropagation();
    var was = !$('actCtx').hidden && $('actCtx').dataset.from === b.dataset.kind + ':' + b.dataset.id;
    Act.hide();
    if (!was) {
      var r = b.getBoundingClientRect();
      $('actCtx').dataset.from = b.dataset.kind + ':' + b.dataset.id;
      Act.open(r.right, r.bottom + 4, menuItems(b.dataset.kind, b.dataset.id), true);
    }
    return true;
  }
  if (act === 'pick') {
    Act.sel = b.dataset.kind + ':' + b.dataset.id;
    renderTab();
    return true;
  }
  if (actTaken[act]) {
    Act.hide();
    Act.run(act, b.dataset.id);
    return true;
  }
  if (b.closest('#actCtx')) {
    Act.hide();
    if (Act.run(act, b.dataset.id) !== false) return true;
  }
  return false;
};

Act.install = function () {
  if (!$('actCtx')) {
    var m = document.createElement('div');
    m.id = 'actCtx';
    m.hidden = true;
    document.body.appendChild(m);
    m.onclick = function (e) {
      var b = e.target.closest('[data-act]');
      if (!b) return;
      e.stopPropagation();
      Act.hide();
      Act.run(b.dataset.act, b.dataset.id);
    };
  }
  var prevDock = renderDock;
  renderDock = function () {
    prevDock();
    var head = $('scDockHead');
    var s = scriptSel();
    if (head && s && Act.mode === 'context') {
      head.dataset.kind = 'script';
      head.dataset.id = s.id;
    }
  };
  var prev = $('tabbody').onclick;
  $('tabbody').onclick = function (e) {
    if (Act.handle(e)) return;
    prev.call(this, e);
  };
  document.addEventListener('click', function (e) {
    if (e.target.closest('#actCtx') || e.target.closest('[data-act="menuOpen"]')) return;
    Act.hide();
  });
  document.addEventListener('contextmenu', function (e) {
    if (Act.mode !== 'context') return;
    var host = e.target.closest('[data-kind]');
    if (!host) return;
    e.preventDefault();
    var kind = host.dataset.kind, id = host.dataset.id || '';
    var r = { quick: 1, folder: 1, rule: 1, batch: 1, script: 1 };
    if (!r[kind]) return;
    Act.open(e.clientX, e.clientY, menuItems(kind, id), false);
  });
  renderTab();
};
