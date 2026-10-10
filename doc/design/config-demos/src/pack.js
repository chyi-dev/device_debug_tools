// ---------- 配置包：快捷指令 / 自动应答 / 批量发送 / 脚本 ----------
// 文件形状与 Flutter 侧一致：{ kind, version, quick?, rules?, batch?, scripts? }，各列表沿用各自 toJson()。
var Pack = (function () {
  var KIND = 'device-debug-config';
  var CATS = [
    { key: 'quick', name: '快捷指令', unit: '条', tab: 'quick', file: 'quick-commands.json' },
    { key: 'rules', name: '自动应答', unit: '条', tab: 'reply', file: 'auto-reply-rules.json' },
    { key: 'batch', name: '批量发送', unit: '个任务', tab: 'batch', file: 'batch-jobs.json' },
    { key: 'scripts', name: '脚本', unit: '个', tab: 'script', file: 'lua-scripts.json' }
  ];
  function cat(key) { return CATS.filter(function (c) { return c.key === key; })[0]; }

  function count(key, list) {
    if (key !== 'quick') return list.length;
    var n = 0; list.forEach(function (x) { n += isFolder(x) ? (x.commands || []).length : 1; }); return n;
  }
  function current(key) { return count(key, S[key]); }
  function clean(key, list) {
    return list.map(function (x) {
      var o = JSON.parse(JSON.stringify(x));
      if (key === 'rules') delete o.hits;
      if (key === 'scripts') { delete o.runs; delete o.last; }
      return o;
    });
  }
  function build(keys) {
    var out = { kind: KIND, version: 1 };
    keys.forEach(function (k) { out[k] = clean(k, S[k]); });
    return out;
  }
  function download(keys, name) {
    Serial.download(name || 'device-debug-config.json', JSON.stringify(build(keys), null, 2));
  }

  // 旧的单列表文件按首项形状识别类别
  function guess(arr) {
    var x = arr[0];
    if (!x || typeof x !== 'object') return null;
    if (Array.isArray(x.steps)) return 'batch';
    if (typeof x.code === 'string') return 'scripts';
    if ('pattern' in x || Array.isArray(x.replies)) return 'rules';
    if (x.type || Array.isArray(x.commands) || 'data' in x) return 'quick';
    return null;
  }
  // 返回 { lists, legacy }；格式不对抛出带中文说明的 Error
  function parse(text) {
    var raw;
    try { raw = JSON.parse(text); } catch (e) { throw new Error('不是有效的 JSON 文件'); }
    var lists = {};
    if (Array.isArray(raw)) {
      var k = guess(raw);
      if (!k) throw new Error(raw.length ? '认不出这份列表属于哪一类' : '空列表认不出属于哪一类');
      lists[k] = raw;
      return { lists: lists, legacy: true };
    }
    if (!raw || raw.kind !== KIND) throw new Error('不是本工具导出的配置文件');
    CATS.forEach(function (c) {
      if (c.key in raw) {
        if (!Array.isArray(raw[c.key])) throw new Error(c.name + ' 不是列表');
        lists[c.key] = raw[c.key];
      }
    });
    if (!Object.keys(lists).length) throw new Error('文件里没有任何可导入的类别');
    return { lists: lists, legacy: false };
  }

  function quickOf(arr) {
    var used = {};
    var cmd = function (x) { var k = x.key || ''; if (k && used[k]) k = ''; if (k) used[k] = 1; return { id: uid('q'), name: String(x.name || x.data || '未命名'), data: String(x.data || ''), format: x.format === 'ASCII' || x.format === 'ascii' ? 'ASCII' : 'HEX', key: k }; };
    return arr.map(function (x) {
      if (x.type === 'folder' || Array.isArray(x.commands)) return { type: 'folder', id: uid('f'), name: String(x.name || '未命名'), expanded: x.expanded !== false, commands: (x.commands || []).map(cmd) };
      return cmd(x);
    });
  }
  var normalize = {
    quick: quickOf,
    rules: function (arr) { return arr.map(function (x) { return { id: uid('r'), name: String(x.name || '未命名'), match: x.match || 'prefix', kind: x.kind === 'regex' ? 'regex' : 'template', format: x.format === 'ASCII' ? 'ASCII' : 'HEX', ignoreCase: !!x.ignoreCase, pattern: String(x.pattern || ''), enabled: !!x.enabled, hits: 0, replies: (x.replies || []).map(function (r) { return { data: String(r.data || ''), delay: Number(r.delay) || 0 }; }) }; }); },
    batch: function (arr) { return arr.map(function (x) { return { id: uid('b'), name: String(x.name || '未命名'), repeat: Number(x.repeat) > 0 ? Number(x.repeat) : 1, stopOnFail: x.stopOnFail !== false, steps: (x.steps || []).map(function (s) { return typeof s === 'string' ? { data: s, delay: 0, note: '' } : { data: String(s.data || ''), delay: Number(s.delay) || 0, note: String(s.note || '') }; }) }; }); },
    scripts: function (arr) { return arr.filter(function (x) { return x && String(x.name || '').trim(); }).map(function (x) { return { id: uid('s'), name: String(x.name).trim(), action: x.action || '', enabled: !!x.enabled, runs: 0, last: '', code: String(x.code || '') }; }); }
  };

  function enabledScripts(lists) { return (lists.scripts || []).filter(function (x) { return x && x.enabled; }).length; }
  function batchRunning() { return !!ui.batchRun; }

  function apply(lists, keys) {
    if (keys.indexOf('batch') >= 0 && batchRunning()) Serial.stopBatch();
    keys.forEach(function (k) { S[k] = normalize[k](lists[k]); });
    if (keys.indexOf('batch') >= 0) ui.batchSel = S.batch[0] && S.batch[0].id;
    if (keys.indexOf('scripts') >= 0) { scUi.sel = S.scripts[0] && S.scripts[0].id; scUi.dock = false; }
    renderTab(); renderStatus();
    toast('已导入 ' + keys.map(function (k) { return cat(k).name + ' ' + current(k) + ' ' + cat(k).unit; }).join('，'));
  }

  // 导入前的提醒：会立刻生效的副作用
  function caveats(lists, keys) {
    var out = [];
    if (keys.indexOf('scripts') >= 0 && enabledScripts(lists)) out.push('其中 ' + enabledScripts(lists) + ' 个脚本是启用状态，导入后立即参与自动运行。');
    if (keys.indexOf('batch') >= 0 && batchRunning()) out.push('批量发送正在运行，导入会先停止它。');
    return out;
  }

  function pick(cb) {
    pickFile('.json', function (txt, file) {
      if (txt == null) return;
      try { cb(parse(txt), file.name); } catch (e) { toast(e.message, true); }
    });
  }

  // ---------- 清单对话框（清单版、页签版共用） ----------
  function checks() { return Array.prototype.map.call(document.querySelectorAll('#dlgBody .pk-row input:checked'), function (x) { return x.value; }); }

  function exportDialog() {
    dialog('导出配置',
      '<p class="pk-lead">勾选要写进文件的类别。导入时，文件里没有的类别保持不动。</p>' +
      '<div class="pk-table">' + CATS.map(function (c) {
        return '<label class="pk-row"><input type="checkbox" value="' + c.key + '" checked><span class="pk-nm">' + c.name + '</span>' +
          '<span class="pk-num">' + current(c.key) + ' ' + c.unit + '</span></label>';
      }).join('') + '</div><div class="err" id="dlgErr"></div>',
      [{ text: '取消' }, { text: '导出', pri: true, run: function () {
        var keys = checks();
        if (!keys.length) return fail('至少勾选一类');
        download(keys);
        toast('已导出 ' + keys.map(function (k) { return cat(k).name; }).join('、'));
      } }]);
  }

  function importDialog(res, fileName) {
    var lists = res.lists;
    var rowHtml = function (c) {
      var has = c.key in lists, n = has ? count(c.key, lists[c.key]) : 0, m = current(c.key);
      return '<label class="pk-row' + (has ? '' : ' off') + '"><input type="checkbox" value="' + c.key + '"' + (has ? ' checked' : ' disabled') + '><span class="pk-nm">' + c.name + '</span>' +
        '<span class="pk-num">' + (has ? '文件 <b>' + n + '</b> ' + c.unit + '，替换当前 ' + m + ' ' + c.unit : '文件里没有，保持当前 ' + m + ' ' + c.unit) + '</span></label>';
    };
    dialog('导入配置',
      '<p class="pk-file"><span>' + esc(fileName) + '</span>' + (res.legacy ? '<span class="pk-tag">旧格式 · 单类列表</span>' : '') + '</p>' +
      '<p class="pk-lead">勾选的类别整表替换，无法撤销；不勾选的保持现状。</p>' +
      '<div class="pk-table">' + CATS.map(rowHtml).join('') + '</div>' +
      '<p class="pk-warn" id="pkWarn"></p><div class="err" id="dlgErr"></div>',
      [{ text: '取消' }, { text: '导入并替换', pri: true, run: function () {
        var keys = checks();
        if (!keys.length) return fail('至少勾选一类');
        apply(lists, keys);
      } }]);
    var sync = function () { $('pkWarn').textContent = caveats(lists, checks()).join(''); };
    $('dlgBody').onchange = sync; sync();
  }

  return {
    CATS: CATS, cat: cat, count: count, current: current, build: build, download: download,
    parse: parse, apply: apply, caveats: caveats, pick: pick,
    exportDialog: exportDialog, importDialog: importDialog
  };
})();

// 文件菜单：keepOld 为假时去掉原来的四个分项，再把本版菜单项追加到末尾
function packMenu(html, keepOld) {
  var drop = document.querySelector('[data-cmd="exportQuick"]').parentNode;
  if (!keepOld) ['exportQuick', 'importQuick', 'exportRules', 'importRules'].forEach(function (c) { drop.querySelector('[data-cmd="' + c + '"]').remove(); });
  drop.insertAdjacentHTML('beforeend', html);
}
var baseCommand = command;
command = function (cmd) {
  if (cmd === 'packExport') return Pack.exportDialog();
  if (cmd === 'packImport') return Pack.pick(Pack.importDialog);
  return baseCommand(cmd);
};
