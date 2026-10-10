// 授权原型共用层：试用中 / 已到期 / 已授权三态，机器码 + 授权码离线激活。
// 设计稿只比对一条示例授权码，不做真实签名校验。
var LIC = (function () {
  var MACHINE = 'A4F2-19C8-7B03-E6D1';
  var VALID = 'DDT1-4F2A-19C8-7B03-E6D1';
  var TRIAL_LEFT = 9, TRIAL_END = '2026-10-08';
  var LOCKED_TABS = ['quick', 'batch', 'reply', 'history', 'script'];
  var LOCKED_ACTS = /^(quick|folder|batch|rule|hist|sc|tut)/;
  var KEY = 'ddt.license.' + LIC_VARIANT;
  var V = {};
  var st = localStorage.getItem(KEY) || 'expired';

  function locked() { return st === 'expired'; }

  // 到期后自动应答与脚本停止自动运行；开关原值留在 _on，激活后按原样恢复
  function guard(list) {
    list.forEach(function (x) {
      if (Object.prototype.hasOwnProperty.call(x, '_on')) return;
      var v = x.enabled;
      delete x.enabled;
      Object.defineProperty(x, '_on', { value: v, writable: true, enumerable: false });
      Object.defineProperty(x, 'enabled', {
        get: function () { return this._on && !locked(); },
        set: function (nv) { this._on = nv; },
        enumerable: true, configurable: true
      });
    });
  }
  function wasOn(x) { return Object.prototype.hasOwnProperty.call(x, '_on') ? x._on : x.enabled; }

  function set(next) {
    st = next;
    localStorage.setItem(KEY, st);
    if (locked()) { guard(S.rules); guard(S.scripts); Serial.stopBatch(true); }
    if (V.apply) V.apply(locked());
    renderTab(); renderStatus(); renderChip();
  }

  function renderChip() {
    var el = $('stLic');
    el.className = 'lic ' + st;
    el.innerHTML = st === 'trial' ? '<button data-act="licOpen">试用剩余 ' + TRIAL_LEFT + ' 天</button>'
      : st === 'expired' ? '<button data-act="licOpen">试用已结束 · 输入授权码</button>'
      : '<button data-act="licOpen">已授权</button>';
  }

  function normalize(v) {
    return v.toUpperCase().replace(/[^0-9A-Z]/g, '').slice(0, 20).replace(/(.{4})(?=.)/g, '$1-');
  }
  function check(v) {
    var code = normalize(v || '');
    if (!code) return '请填写授权码';
    if (!/^[0-9A-Z]{4}(-[0-9A-Z]{4}){4}$/.test(code)) return '格式不对：授权码为 5 组、每组 4 位，用 - 分隔';
    if (code !== VALID) return '这个授权码不属于本机（机器码 ' + MACHINE + '），请核对后重试';
    return '';
  }
  function activate(v) {
    var err = check(v);
    if (err) return err;
    set('licensed');
    toast('授权成功，全部功能已解锁');
    hint('已授权 · 本机 ' + MACHINE);
    return '';
  }
  function bindCode(el, onEnter) {
    el.oninput = function () { var n = normalize(el.value); if (n !== el.value) el.value = n; };
    el.onkeydown = function (e) { if (e.key === 'Enter') { e.preventDefault(); onEnter(); } };
  }
  function copyMachine() {
    var done = function () { toast('机器码已复制'); };
    try { navigator.clipboard.writeText(MACHINE).then(done, done); } catch (e) { done(); }
  }

  function lead() {
    return st === 'trial'
      ? '试用还剩 ' + TRIAL_LEFT + ' 天。到期后快捷指令、批量发送、自动应答、历史发送和脚本会暂停，现在激活可提前解锁。'
      : '试用已于 ' + TRIAL_END + ' 结束。快捷指令、批量发送、自动应答、历史发送和脚本已暂停，配置都还在，激活后按原样恢复。';
  }
  function machineHtml(big) {
    return '<div class="lic-mc' + (big ? ' big' : '') + '"><code>' + MACHINE + '</code><button class="btn sm" data-act="licCopy">复制</button></div>';
  }
  var CODE_INPUT = '<input class="inp lic-code" id="licCode" placeholder="XXXX-XXXX-XXXX-XXXX-XXXX" spellcheck="false" autocomplete="off">';
  var HOW = '把机器码发给供应商换取授权码。授权码只对这台电脑有效，离线校验，不需要联网。';

  function openDialog() {
    if (st === 'licensed') {
      return dialog('授权信息',
        '<div class="row"><label>状态</label><span class="lic-ok">已授权，全部功能可用</span></div>' +
        '<div class="row"><label>本机机器码</label><code class="lic-mono">' + MACHINE + '</code></div>' +
        '<div class="row"><label>授权码</label><code class="lic-mono">' + VALID.slice(0, 4) + '-••••-••••-••••-' + VALID.slice(-4) + '</code></div>',
        [{ text: '关闭', pri: true }]);
    }
    dialog('软件授权',
      '<p class="lic-lead">' + lead() + '</p>' +
      '<div class="row"><label>本机机器码</label>' + machineHtml(false) + '</div>' +
      '<div class="row"><label for="licCode">授权码</label>' + CODE_INPUT + '</div>' +
      '<div class="explain" style="padding:0">' + HOW + '</div>' +
      '<div class="err" id="dlgErr"></div>',
      [{ text: '取消' }, { text: '激活', pri: true, run: function () { var err = activate($('licCode').value); if (err) return fail(err); } }]);
    bindCode($('licCode'), function () { $('dlgFoot').querySelector('.pri').click(); });
  }
  function open() { if (V.open && V.open()) return; openDialog(); }

  // 已暂停的功能与各自保留的配置，供版 C 的右栏使用
  function pausedRows() {
    var keys = allQuick().filter(function (q) { return q.key; }).length;
    var rulesOn = S.rules.filter(wasOn).length, scOn = S.scripts.filter(wasOn).length;
    return [
      ['快捷指令', allQuick().length + ' 条 · ' + (keys ? 'F 键绑定 ' + keys + ' 个不响应' : '无 F 键绑定')],
      ['批量发送', S.batch.length + ' 个任务'],
      ['自动应答', S.rules.length + ' 条规则 · 原启用 ' + rulesOn + ' 条，不再自动回复'],
      ['历史发送', S.history.length + ' 条记录 · 不能重发或填入'],
      ['脚本', S.scripts.length + ' 个 Lua 脚本 · 原启用 ' + scOn + ' 个，钩子不运行']
    ];
  }

  function closeMenus() { document.querySelectorAll('.menu.open').forEach(function (x) { x.classList.remove('open'); }); }

  // 捕获阶段拦截：先于工具面板与菜单自己的点击处理
  document.addEventListener('click', function (e) {
    var t = e.target.closest('[data-act],[data-tab],[data-cmd]');
    if (!t) return;
    var act = t.dataset.act, tab = t.dataset.tab, cmd = t.dataset.cmd;
    var stop = function () { e.stopPropagation(); e.preventDefault(); closeMenus(); };
    if (act === 'licOpen' || cmd === 'license') { stop(); return open(); }
    if (act === 'licCopy') { stop(); return copyMachine(); }
    if (cmd && cmd.indexOf('licPreview:') === 0) { stop(); set(cmd.slice(11)); return hint('预览：' + { trial: '试用中', expired: '已到期', licensed: '已授权' }[st]); }
    if (V.click && V.click(t, stop)) return;
    if (!locked()) return;
    var tabName = tab || (cmd && cmd.indexOf('tab:') === 0 ? cmd.slice(4) : '');
    var hit = (act && LOCKED_ACTS.test(act)) || (V.tabsLocked && tabName && LOCKED_TABS.indexOf(tabName) >= 0);
    if (hit) { stop(); open(); }
  }, true);

  document.addEventListener('keydown', function (e) {
    if (!locked() || $('modal').classList.contains('show') || !/^F[1-8]$/.test(e.key)) return;
    e.preventDefault(); e.stopPropagation();
    toast('试用已结束，F1–F8 快捷指令已暂停', true);
  }, true);

  function init(variant) {
    V = variant || {};
    var help = document.querySelectorAll('.menu')[3].querySelector('.drop');
    help.insertAdjacentHTML('beforeend',
      '<button data-cmd="license">软件授权…</button><hr>' +
      '<button data-cmd="licPreview:trial">预览：试用中</button>' +
      '<button data-cmd="licPreview:expired">预览：已到期</button>' +
      '<button data-cmd="licPreview:licensed">预览：已授权</button>');
    $('stHint').insertAdjacentHTML('afterend', '<span class="lic" id="stLic"></span>');
    set(st);
  }

  return {
    init: init, set: set, open: open, openDialog: openDialog, locked: locked, state: function () { return st; },
    activate: activate, bindCode: bindCode, machineHtml: machineHtml, pausedRows: pausedRows,
    CODE_INPUT: CODE_INPUT, HOW: HOW, TRIAL_END: TRIAL_END, LOCKED_TABS: LOCKED_TABS
  };
})();
