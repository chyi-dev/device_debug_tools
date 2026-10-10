// 版 C · 选题新建：「新建」先选从哪一课开始；右栏说明换成可插入的片段清单
var pickUi = { sel: 'blank' };
var baseScriptHtml = scriptHtml;
function snippetRows() {
  return LESSONS.map(function (l, i) {
    return '<div class="it snip"><span class="tutno lead">' + (i + 1) + '</span><span class="nm">' + esc(l.title) + '</span>' +
      '<span class="dt"><span class="schook">' + l.hook + '</span>' + esc(l.brief) + '</span>' +
      '<span class="ops"><button class="link" data-act="pickInsert" data-id="' + l.id + '">插入</button></span></div>';
  }).join('');
}
scriptHtml = function () {
  return baseScriptHtml().replace(/<div class="explain">[\s\S]*$/, '') +
    '<div class="subhead"><b>常用片段</b><span>插入到当前脚本末尾</span></div>' +
    '<div class="list">' + snippetRows() + '</div>' +
    '<div class="explain">on_receive 在收到数据后运行；before_send 拦截每一帧发送，返回 nil 则不发。<br>' + TUT_NOTES + '</div>';
};
function cardHtml(id, no, title, hook, brief, code) {
  return '<button class="tcard' + (pickUi.sel === id ? ' on' : '') + '" data-card="' + id + '">' +
    '<span class="tchead"><span class="tutno">' + no + '</span><b>' + esc(title) + '</b>' + (hook ? '<span class="schook">' + hook + '</span>' : '') + '</span>' +
    '<span class="tcbrief">' + esc(brief) + '</span>' + tutCode(code) + '</button>';
}
function pickBody() {
  return '<p class="tutnotes">选一课作为起点，新脚本会带上这课的代码和注释，之后照着改。</p><div class="tcards">' +
    cardHtml('blank', '0', '空白脚本', 'on_receive', '只打印收到的每一帧', '-- 新脚本：收到数据时运行\nfunction on_receive(frame)\n  log(frame:hex())\nend') +
    LESSONS.map(function (l, i) { return cardHtml(l.id, i + 1, l.title, l.hook, l.brief, l.code); }).join('') + '</div>';
}
function openPicker() {
  pickUi.sel = 'blank';
  dialog('新建脚本', pickBody(), [{ text: '取消' }, { text: '新建', pri: true, run: function () {
    var s = pickUi.sel === 'blank' ? Serial.newScript() : lessonNew(lessonById(pickUi.sel));
    scUi.sel = s.id; scUi.dock = true; renderTab(); hint('已新建 ' + s.name);
  } }]);
  document.querySelector('#modal .dialog').classList.add('wide');
}
$('dlgBody').addEventListener('click', function (e) {
  var c = e.target.closest('[data-card]'); if (!c) return;
  pickUi.sel = c.dataset.card;
  document.querySelectorAll('.tcard').forEach(function (x) { x.classList.toggle('on', x === c); });
});
var baseClose = closeDialog;
closeDialog = function () { document.querySelector('#modal .dialog').classList.remove('wide'); baseClose(); };
var baseTabClick = $('tabbody').onclick;
$('tabbody').onclick = function (e) {
  var b = e.target.closest('[data-act]'); if (!b) return;
  if (b.dataset.act === 'scNew') return openPicker();
  if (b.dataset.act === 'pickInsert') { if (!scUi.dock) { scUi.dock = true; renderTab(); } return lessonInsert(lessonById(b.dataset.id)); }
  baseTabClick(e);
};
$('scDock').onclick = function (e) { $('tabbody').onclick(e); };
setTab('script');
