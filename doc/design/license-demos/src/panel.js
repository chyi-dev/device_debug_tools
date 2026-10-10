// 版 C · 右栏即授权：到期后右栏只剩「授权」「校验计算」两页，授权在栏内完成，不先弹窗
(function () {
  document.getElementById('tabs').insertAdjacentHTML('afterbegin', '<button data-tab="license" class="lictab">授权</button>');

  function paneHtml() {
    return '<div class="licpane">' +
      '<div class="lichead"><b>试用已结束</b><span>' + LIC.TRIAL_END + ' 到期</span></div>' +
      '<p class="licp">串口收发、数据日志和校验计算照常可用。下面五项已暂停，配置都保留，激活后按原样恢复。</p>' +
      '<section class="licsec"><div class="lictitle"><i>1</i>把本机机器码发给供应商</div>' + LIC.machineHtml(true) + '</section>' +
      '<section class="licsec"><div class="lictitle"><i>2</i>粘贴收到的授权码</div>' + LIC.CODE_INPUT +
      '<div class="err lic-err" id="licErr"></div><button class="btn pri licgo" data-act="licActivate">激活</button>' +
      '<div class="licnote">' + LIC.HOW + '</div></section>' +
      '<div class="lictitle lictop">已暂停</div>' +
      '<div class="list">' + LIC.pausedRows().map(function (r) {
        return '<div class="it licrow"><span class="nm">' + r[0] + '</span><span class="dt">' + esc(r[1]) + '</span></div>';
      }).join('') + '</div></div>';
  }
  function go() {
    var err = LIC.activate($('licCode').value);
    if (err) { $('licErr').textContent = err; $('licCode').focus(); }
  }

  var orig = renderTab;
  renderTab = function () {
    if (ui.tab !== 'license') return orig();
    $('tabbody').innerHTML = paneHtml();
    LIC.bindCode($('licCode'), go);
    renderDock();
  };

  LIC.init({
    tabsLocked: true,
    apply: function (lk) {
      $('tabs').classList.toggle('lk', lk);
      if (lk) setTab('license');
      else if (ui.tab === 'license') setTab('quick');
    },
    open: function () {
      if (!LIC.locked()) return false;
      setTools(true); setTab('license'); $('licCode').focus();
      return true;
    },
    click: function (t, stop) {
      if (t.dataset.act !== 'licActivate') return false;
      stop(); go(); return true;
    }
  });
})();
