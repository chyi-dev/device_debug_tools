// 版 B · 日志状态条：到期后数据日志标题下多一行锁定说明；工具页签照常切换，被锁页内容只读，点任何操作弹出授权对话框
(function () {
  var paused = '快捷指令、批量发送、自动应答、历史发送、脚本已暂停，配置保留';
  document.querySelector('.loghead').insertAdjacentHTML('afterend',
    '<div class="lkbar" id="lkBar"><b>试用已结束</b><span>' + paused + '</span><button class="btn sm pri" data-act="licOpen">输入授权码</button></div>');
  var orig = renderTab;
  renderTab = function () {
    orig();
    var hit = LIC.locked() && LIC.LOCKED_TABS.indexOf(ui.tab) >= 0, body = $('tabbody');
    body.classList.toggle('lk', hit);
    if (hit) body.insertAdjacentHTML('afterbegin', '<div class="lknote">本页只读 · 试用结束后暂停</div>');
  };
  LIC.init({
    apply: function (lk) {
      document.querySelector('.logbox').classList.toggle('locked', lk);
      if (lk) scUi.dock = false;
    }
  });
})();
