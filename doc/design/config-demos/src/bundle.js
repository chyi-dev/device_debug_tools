// 总包版：分项导入导出不动，下方加「全部」两项；导出不问，导入用一张前后对照确认
packMenu('<hr><button data-cmd="bundleExport">导出全部配置</button><button data-cmd="bundleImport">导入全部配置…</button>', true);

function bundleConfirm(res, fileName) {
  var lists = res.lists, keys = Object.keys(lists);
  var rows = Pack.CATS.map(function (c) {
    var has = c.key in lists, m = Pack.current(c.key);
    return '<tr' + (has ? '' : ' class="same"') + '><th>' + c.name + '</th><td>' + m + ' ' + c.unit + '</td>' +
      '<td class="to">' + (has ? Pack.count(c.key, lists[c.key]) + ' ' + c.unit : '不变') + '</td></tr>';
  }).join('');
  var warn = Pack.caveats(lists, keys).join('');
  dialog('替换 ' + keys.length + ' 类配置？',
    '<p class="pk-file"><span>' + esc(fileName) + '</span>' + (res.legacy ? '<span class="pk-tag">旧格式 · 单类列表</span>' : '') + '</p>' +
    '<table class="bd-cmp"><thead><tr><th></th><th>当前</th><th>导入后</th></tr></thead><tbody>' + rows + '</tbody></table>' +
    '<p class="pk-lead">文件里有的类别整表替换，无法撤销。只想换其中一类，请用文件菜单上方的分项导入。</p>' +
    (warn ? '<p class="pk-warn">' + warn + '</p>' : ''),
    [{ text: '取消' }, { text: '替换', pri: true, run: function () { Pack.apply(lists, keys); } }]);
}

var bundleBase = command;
command = function (cmd) {
  if (cmd === 'bundleExport') {
    var keys = Pack.CATS.map(function (c) { return c.key; });
    Pack.download(keys);
    return toast('已导出全部配置：' + Pack.CATS.map(function (c) { return c.name + ' ' + Pack.current(c.key); }).join('，'));
  }
  if (cmd === 'bundleImport') return Pack.pick(bundleConfirm);
  return bundleBase(cmd);
};
