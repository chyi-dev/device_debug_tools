// 版 C · 借中间列：右栏只留列表和开关；编辑器 + 运行日志停靠在数据日志下方，收发与脚本输出同屏
(function () {
  var tab = scAddTab('脚本');
  tab.classList.add('scC-tab');
  var center = document.querySelector('.center');
  var dock = document.createElement('div');
  dock.className = 'scdock'; dock.id = 'scDock';
  center.insertBefore(dock, center.querySelector('.sendbox'));
  var docked = true;

  function rowHtml(s, cur) {
    return '<div class="it sc' + (docked && s.id === cur.id ? ' active' : '') + (s.enabled ? '' : ' off') + '" data-act="scSel" data-id="' + s.id + '">' +
      '<button class="sw lead' + (s.enabled ? ' on' : '') + '" data-act="scToggle" data-id="' + s.id + '" title="启用 / 停用"></button>' +
      '<span class="nm">' + esc(s.name) + '</span>' +
      '<span class="dt">' + scHookChip(s) + '<span class="out">' + (s.runs ? '已输出 ' + s.runs + ' 次' : (s.enabled ? '等待触发' : '已停用')) + '</span></span></div>';
  }
  function listHtml() { var cur = SC.selected(); return SC.list.map(function (s) { return rowHtml(s, cur); }).join(''); }
  function note() { return '已启用 ' + SC.list.filter(function (s) { return s.enabled; }).length + ' / ' + SC.list.length; }

  function renderPanel() {
    $('tabbody').innerHTML = '<div class="bar"><span class="note" id="scNote">' + note() + '</span><span class="grow"></span><button class="btn sm" data-act="scNew">新建</button></div>' +
      '<div class="list" id="scList">' + listHtml() + '</div>' +
      '<div class="explain">点一行在中间下方打开编辑器和运行日志，数据日志与发送框保持可见。开关只控制自动运行，「运行」随时可手动试一次。</div>';
    setDock(docked);
  }
  function dockHead(s) {
    return '<b>' + esc(s.name) + '</b>' + scHookChip(s) + '<span>' + (s.enabled ? '自动运行中' : '已停用，仅手动运行') + '</span>' +
      '<span class="grow"></span><span>输入即保存</span><button class="btn sm pri" data-act="scRun" data-id="' + s.id + '">运行</button><button class="link" data-act="scFold">收起</button>';
  }
  function renderDock() {
    var s = SC.selected();
    dock.innerHTML = '<div class="schead" id="scDockHead">' + dockHead(s) + '</div>' +
      '<div class="scC-body">' + scEditorHtml(s, 'scCode') +
      '<div class="scC-log"><div class="schead"><b>运行日志</b><span id="scCount">' + SC.log.length + ' 条</span><span class="grow"></span><button class="link" data-act="scClear">清空</button></div>' +
      '<div class="sclog" id="scLog">' + scLogHtml() + '</div></div></div>';
    var l = $('scLog'); l.scrollTop = l.scrollHeight;
  }
  function setDock(on) {
    docked = on;
    var show = on && ui.tab === 'script';
    center.classList.toggle('withdock', show);
    if (show) renderDock(); else dock.innerHTML = '';
    if ($('scList')) $('scList').innerHTML = listHtml();
    if (ui.scroll) $('log').scrollTop = $('log').scrollHeight;
  }
  scHookTab(renderPanel, function () { center.classList.remove('withdock'); dock.innerHTML = ''; });

  SC.on(function (kind) {
    if (ui.tab !== 'script') return;
    if (kind === 'sel') return setDock(true);
    $('scList').innerHTML = listHtml(); $('scNote').textContent = note();
    if (!$('scLog')) return;
    if (kind === 'log') { var l = $('scLog'), stick = l.scrollTop + l.clientHeight >= l.scrollHeight - 4; l.innerHTML = scLogHtml(); $('scCount').textContent = SC.log.length + ' 条'; if (stick) l.scrollTop = l.scrollHeight; }
    if (kind === 'list') $('scDockHead').innerHTML = dockHead(SC.selected());
  });

  function onAct(e) {
    var b = e.target.closest('[data-act]'); if (!b) return;
    var a = b.dataset.act, id = b.dataset.id;
    if (a === 'scToggle') { e.stopPropagation(); return SC.toggle(id); }
    if (a === 'scRun') return SC.run(id);
    if (a === 'scSel') { if (docked && SC.selected().id === id) return; docked = true; return SC.select(id); }
    if (a === 'scNew') { docked = true; SC.create(); $('scCode').focus(); }
    if (a === 'scClear') SC.clearLog();
    if (a === 'scFold') setDock(false);
  }
  $('tabbody').addEventListener('click', onAct);
  dock.addEventListener('click', onAct);

  setTab('script');
})();
