// 版 B · 课本：停靠区右侧「运行日志 / 教程」切换，一页一课，和代码编辑器并排
var bookUi = { pane: 'tut', i: 2, tried: null };
var baseScriptHtml = scriptHtml;
scriptHtml = function () {
  return baseScriptHtml().replace(/(<div class="explain">)/, '$1不会写？打开一个脚本，在下方运行日志旁的「教程」里一课一课看，代码可以直接插入编辑器。<br>');
};
function bookPage() {
  var l = LESSONS[bookUi.i];
  return '<div class="tutpage" id="tutPane">' +
    '<div class="tuttitle"><b>' + esc(l.title) + '</b><span class="schook">' + l.hook + '</span></div>' +
    '<p class="tuttext">' + esc(l.text) + '</p>' + tutCode(l.code) +
    '<div class="tutsample">样例帧 ' + l.sample + '</div>' +
    '<div class="tutacts"><button class="btn sm pri" data-act="bookInsert">插入到编辑器</button><button class="btn sm" data-act="bookTry">样例试跑</button></div>' +
    (bookUi.tried === l.id ? '<div class="tutout">' + l.out.map(esc).join('\n') + '</div>' : '') +
    '<p class="tutnotes">' + TUT_NOTES + '</p></div>';
}
var baseRenderDock = renderDock;
renderDock = function () {
  baseRenderDock();
  var box = document.querySelector('#scDock .sclogbox'); if (!box) return;
  var tut = bookUi.pane === 'tut';
  box.querySelector('.schead').innerHTML =
    '<span class="ptabs"><button data-act="bookPane" data-id="log"' + (tut ? '' : ' class="on"') + '>运行日志 <span id="scCount">' + S.scriptLog.length + ' 条</span></button>' +
    '<button data-act="bookPane" data-id="tut"' + (tut ? ' class="on"' : '') + '>教程</button></span><span class="grow"></span>' +
    (tut ? '<button class="link" data-act="bookGo" data-id="-1"' + (bookUi.i ? '' : ' disabled') + '>‹ 上一课</button><span class="tutpos">' + (bookUi.i + 1) + ' / ' + LESSONS.length + '</span><button class="link" data-act="bookGo" data-id="1"' + (bookUi.i < LESSONS.length - 1 ? '' : ' disabled') + '>下一课 ›</button>'
      : '<button class="link" data-act="scClear">清空</button>');
  $('scLog').hidden = tut;
  if (tut) box.insertAdjacentHTML('beforeend', bookPage());
};
var baseTabClick = $('tabbody').onclick;
$('tabbody').onclick = function (e) {
  var b = e.target.closest('[data-act]'); if (!b) return;
  var act = b.dataset.act, l = LESSONS[bookUi.i];
  if (act === 'bookPane') { bookUi.pane = b.dataset.id; return renderDock(); }
  if (act === 'bookGo') { bookUi.i = Math.max(0, Math.min(LESSONS.length - 1, bookUi.i + Number(b.dataset.id))); return renderDock(); }
  if (act === 'bookInsert') return lessonInsert(l);
  if (act === 'bookTry') { lessonTry(l); bookUi.tried = l.id; return renderDock(); }
  baseTabClick(e);
};
$('scDock').onclick = function (e) { $('tabbody').onclick(e); };
setTab('script');
