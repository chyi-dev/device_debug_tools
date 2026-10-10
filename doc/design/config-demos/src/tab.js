// 页签版：四个页签的标题条各自「导出 / 导入」只动这一类；文件菜单仍是整包清单
packMenu('<button data-cmd="packExport">导出配置…</button><button data-cmd="packImport">导入配置…</button>');

var tabCat = { quick: 'quick', reply: 'rules', batch: 'batch', script: 'scripts' };
var tabLinks = '<span class="tb-io"><button class="link" data-act="pkTabExport">导出</button><button class="link" data-act="pkTabImport">导入</button></span>';
function withLinks(fn) {
  return function () {
    var h = fn(), at = h.indexOf('</div>');
    if (h.indexOf('<div class="bar">') !== 0 || at < 0) return h;
    return h.slice(0, at) + tabLinks + h.slice(at);
  };
}
quickHtml = withLinks(quickHtml);
replyHtml = withLinks(replyHtml);
batchHtml = withLinks(batchHtml);
var tabScriptBase = scriptHtml;
scriptHtml = function () { return tutUi.view === 'mine' ? withLinks(tabScriptBase)() : tabScriptBase(); };

function tabImport(res, fileName) {
  var k = tabCat[ui.tab], c = Pack.cat(k);
  if (!(k in res.lists)) return toast('文件里没有' + c.name + '，未导入', true);
  var warn = Pack.caveats(res.lists, [k]).join('');
  dialog('导入' + c.name,
    '<p class="pk-file"><span>' + esc(fileName) + '</span></p>' +
    '<p class="tb-sum"><b>' + Pack.count(k, res.lists[k]) + '</b> ' + c.unit + c.name + '，替换当前 ' + Pack.current(k) + ' ' + c.unit + '。</p>' +
    '<p class="pk-lead">只替换这一类，其他页签不受影响。替换后无法撤销。</p>' +
    (warn ? '<p class="pk-warn">' + warn + '</p>' : ''),
    [{ text: '取消' }, { text: '替换', pri: true, run: function () { Pack.apply(res.lists, [k]); } }]);
}

var tabClickBase = $('tabbody').onclick;
$('tabbody').onclick = function (e) {
  var b = e.target.closest('[data-act]');
  if (b && b.dataset.act === 'pkTabExport') {
    var c = Pack.cat(tabCat[ui.tab]);
    Pack.download([c.key], c.file);
    return toast(c.name + '已导出');
  }
  if (b && b.dataset.act === 'pkTabImport') return Pack.pick(tabImport);
  return tabClickBase.call(this, e);
};
renderTab();
