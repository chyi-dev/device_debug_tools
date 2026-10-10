// 版 A · 窄栏内完成：六页签横向滚动，列表 + 编辑器 + 运行日志都在 352px 面板里
(function () {
  var tab = scAddTab('脚本');
  var tabs = $('tabs');
  function edge() { tabs.classList.toggle('more', tabs.scrollLeft + tabs.clientWidth < tabs.scrollWidth - 2); }
  tabs.addEventListener('scroll', edge);
  tabs.addEventListener('wheel', function (e) { if (e.deltaY) { e.preventDefault(); tabs.scrollLeft += e.deltaY; } }, { passive: false });

  function rowHtml(s, cur) {
    return '<div class="it sc' + (s.id === cur.id ? ' active' : '') + (s.enabled ? '' : ' off') + '" data-act="scSel" data-id="' + s.id + '">' +
      '<button class="sw lead' + (s.enabled ? ' on' : '') + '" data-act="scToggle" data-id="' + s.id + '" title="启用 / 停用"></button>' +
      '<span class="nm">' + esc(s.name) + '</span>' +
      '<span class="dt">' + scHookChip(s) + '<span class="out">' + esc(s.last || (s.enabled ? '等待触发' : '已停用')) + '</span></span>' +
      '<span class="ops"><button class="link" data-act="scRun" data-id="' + s.id + '">运行</button></span></div>';
  }
  function listHtml() { var cur = SC.selected(); return SC.list.map(function (s) { return rowHtml(s, cur); }).join(''); }
  function note() { return '已启用 ' + SC.list.filter(function (s) { return s.enabled; }).length + ' / ' + SC.list.length + ' · 输入即保存'; }
  function editorHead(s) {
    return '<b>' + esc(s.name) + '</b>' + scHookChip(s) + '<span class="grow"></span><button class="btn sm pri" data-act="scRun" data-id="' + s.id + '">运行</button>';
  }

  function render() {
    var s = SC.selected();
    $('tabbody').innerHTML = '<div class="scA">' +
      '<div class="bar"><span class="note" id="scNote">' + note() + '</span><span class="grow"></span><button class="btn sm" data-act="scNew">新建</button></div>' +
      '<div class="list" id="scList">' + listHtml() + '</div>' +
      '<div class="schead" id="scEdHead">' + editorHead(s) + '</div>' +
      '<div class="scA-ed" id="scEd">' + scEditorHtml(s, 'scCode') + '</div>' +
      '<div class="schead"><b>运行日志</b><span id="scCount">' + SC.log.length + ' 条</span><span class="grow"></span><button class="link" data-act="scClear">清空</button></div>' +
      '<div class="sclog" id="scLog">' + scLogHtml() + '</div></div>';
    var l = $('scLog'); l.scrollTop = l.scrollHeight;
    tabs.scrollLeft = tabs.scrollWidth; edge();
  }
  scHookTab(render);

  SC.on(function (kind) {
    if (ui.tab !== 'script') return;
    if (kind === 'sel') return render();
    $('scList').innerHTML = listHtml(); $('scNote').textContent = note();
    if (kind === 'log') { var l = $('scLog'); var stick = l.scrollTop + l.clientHeight >= l.scrollHeight - 4; l.innerHTML = scLogHtml(); $('scCount').textContent = SC.log.length + ' 条'; if (stick) l.scrollTop = l.scrollHeight; }
    if (kind === 'list') $('scEdHead').innerHTML = editorHead(SC.selected());
  });

  $('tabbody').addEventListener('click', function (e) {
    var b = e.target.closest('[data-act]'); if (!b) return;
    var a = b.dataset.act, id = b.dataset.id;
    if (a === 'scToggle') { e.stopPropagation(); return SC.toggle(id); }
    if (a === 'scRun') { e.stopPropagation(); return SC.run(id); }
    if (a === 'scSel') return SC.select(id);
    if (a === 'scNew') { SC.create(); $('scCode').focus(); }
    if (a === 'scClear') SC.clearLog();
  });

  edge();
  setTab('script');
})();
