// 版 B · 栏内启停，编辑进浮层：面板只管开关、运行和最近输出；改代码在加宽浮层里，左代码右日志
(function () {
  scAddTab('脚本');

  function rowHtml(s) {
    return '<div class="it sc' + (s.enabled ? '' : ' off') + '">' +
      '<button class="sw lead' + (s.enabled ? ' on' : '') + '" data-act="scToggle" data-id="' + s.id + '" title="启用 / 停用"></button>' +
      '<span class="nm">' + esc(s.name) + '</span>' +
      '<span class="dt">' + scHookChip(s) + '<span class="out">' + (s.runs ? s.runs + ' 次' : (s.enabled ? '等待触发' : '已停用')) + '</span></span>' +
      '<span class="ops"><button class="link" data-act="scRun" data-id="' + s.id + '">运行</button><button class="link" data-act="scEdit" data-id="' + s.id + '">编辑</button></span></div>';
  }
  function note() { return '已启用 ' + SC.list.filter(function (s) { return s.enabled; }).length + ' / ' + SC.list.length; }

  function render() {
    $('tabbody').innerHTML = '<div class="scB">' +
      '<div class="bar"><span class="note" id="scNote">' + note() + '</span><span class="grow"></span><button class="btn sm" data-act="scNew">新建</button></div>' +
      '<div class="list" id="scList">' + SC.list.map(rowHtml).join('') + '</div>' +
      '<div class="schead"><b>最近输出</b><span class="grow"></span><button class="link" data-act="scClear">清空</button></div>' +
      '<div class="sclog" id="scLog">' + scLogHtml(8) + '</div>' +
      '<div class="explain">启用的脚本在收到数据（onReceive）或发送之前（beforeSend）自动运行。点「编辑」在大窗口里改代码、看完整日志。</div></div>';
    var l = $('scLog'); l.scrollTop = l.scrollHeight;
  }
  scHookTab(render);

  var editing = null;
  function openEditor(s) {
    editing = s;
    dialog('编辑脚本',
      '<div class="scB-top"><input class="inp" id="scName" value="' + esc(s.name) + '">' + scHookChip(s) +
      '<label><input type="checkbox" id="scOn"' + (s.enabled ? ' checked' : '') + '>启用</label><span class="grow"></span><span class="note">输入即保存 · Tab 缩进两格</span></div>' +
      '<div class="scB-split">' + scEditorHtml(s, 'scCode') +
      '<div class="scB-log"><div class="schead"><b>运行日志</b><span id="scCount">' + SC.log.length + ' 条</span><span class="grow"></span><button class="link" id="scDlgClear">清空</button></div>' +
      '<div class="sclog" id="scDlgLog">' + scLogHtml() + '</div></div></div>',
      [{ text: '运行一次', run: function () { SC.run(s.id); return false; } }, { text: '完成', pri: true }]);
    document.querySelector('#modal .dialog').classList.add('wide');
    var l = $('scDlgLog'); l.scrollTop = l.scrollHeight;
    $('scName').onchange = function () { var v = this.value.trim(); if (v) { s.name = v; render(); } else this.value = s.name; };
    $('scOn').onchange = function () { SC.toggle(s.id); };
    $('scDlgClear').onclick = SC.clearLog;
    $('scCode').focus();
  }
  var baseClose = closeDialog;
  closeDialog = function () {
    baseClose();
    editing = null;
    document.querySelector('#modal .dialog').classList.remove('wide');
  };

  SC.on(function (kind) {
    if (ui.tab === 'script' && $('scList')) {
      $('scList').innerHTML = SC.list.map(rowHtml).join(''); $('scNote').textContent = note();
      if (kind === 'log') { var l = $('scLog'); l.innerHTML = scLogHtml(8); l.scrollTop = l.scrollHeight; }
    }
    if (editing && kind === 'log' && $('scDlgLog')) {
      var d = $('scDlgLog'), stick = d.scrollTop + d.clientHeight >= d.scrollHeight - 4;
      d.innerHTML = scLogHtml(); $('scCount').textContent = SC.log.length + ' 条';
      if (stick) d.scrollTop = d.scrollHeight;
    }
  });

  $('tabbody').addEventListener('click', function (e) {
    var b = e.target.closest('[data-act]'); if (!b) return;
    var a = b.dataset.act, id = b.dataset.id;
    if (a === 'scToggle') SC.toggle(id);
    if (a === 'scRun') SC.run(id);
    if (a === 'scEdit') openEditor(SC.get(id));
    if (a === 'scNew') openEditor(SC.create());
    if (a === 'scClear') SC.clearLog();
  });

  setTab('script');
})();
