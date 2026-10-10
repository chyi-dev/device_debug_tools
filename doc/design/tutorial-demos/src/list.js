// 版 A · 课表：脚本页顶部切换「我的脚本 / 教程」，教程按课排列，点一课展开，用该课代码新建脚本
var tutUi = { view: 'tut', open: 'l3' };
var baseScriptHtml = scriptHtml;
function segHtml() {
  return '<span class="seg"><button data-act="tutView" data-id="mine"' + (tutUi.view === 'mine' ? ' class="on"' : '') + '>我的脚本 ' + S.scripts.length + '</button>' +
    '<button data-act="tutView" data-id="tut"' + (tutUi.view === 'tut' ? ' class="on"' : '') + '>教程</button></span>';
}
function lessonRow(l, i) {
  var open = tutUi.open === l.id;
  var head = '<div class="it tut' + (open ? ' active' : '') + '" data-act="tutOpen" data-id="' + l.id + '">' +
    '<span class="tutno lead">' + (i + 1) + '</span><span class="nm">' + esc(l.title) + '</span>' +
    '<span class="dt"><span class="schook">' + l.hook + '</span>' + esc(l.brief) + '</span></div>';
  if (!open) return head;
  return head + '<div class="tutopen"><p class="tuttext">' + esc(l.text) + '</p>' + tutCode(l.code) +
    '<div class="tutsample">样例帧 ' + l.sample + '</div>' +
    '<div class="tutacts"><button class="btn sm pri" data-act="tutNew" data-id="' + l.id + '">用这课新建脚本</button><button class="btn sm" data-act="tutTry" data-id="' + l.id + '">样例试跑</button></div></div>';
}
scriptHtml = function () {
  if (tutUi.view === 'mine') {
    return baseScriptHtml().replace('<span class="note" id="scNote">', segHtml() + '<span class="note" id="scNote">');
  }
  return '<div class="bar">' + segHtml() + '<span class="grow"></span><span class="note" id="scNote">' + scriptNote() + '</span></div>' +
    '<div class="list" id="scList" hidden></div>' +
    '<div class="list">' + LESSONS.map(lessonRow).join('') + '</div>' +
    '<div class="explain">' + TUT_NOTES + '</div>';
};
var baseTabClick = $('tabbody').onclick;
$('tabbody').onclick = function (e) {
  var b = e.target.closest('[data-act]'); if (!b) return;
  var act = b.dataset.act, id = b.dataset.id;
  if (act === 'tutView') { tutUi.view = id; return renderTab(); }
  if (act === 'tutOpen') { tutUi.open = tutUi.open === id ? null : id; return renderTab(); }
  if (act === 'tutNew') { var s = lessonNew(lessonById(id)); tutUi.view = 'mine'; renderTab(); hint('已用第 ' + id.slice(1) + ' 课新建 ' + s.name); return; }
  if (act === 'tutTry') { if (!scUi.dock) { scUi.dock = true; renderTab(); } lessonTry(lessonById(id)); return; }
  baseTabClick(e);
};
$('scDock').onclick = function (e) { $('tabbody').onclick(e); };
setTab('script');
