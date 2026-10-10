// 版 A · 页签上锁：到期后五个进阶页签变灰并标「锁定」，点按弹出授权对话框；只剩校验计算可切换
LIC.init({
  tabsLocked: true,
  apply: function (lk) {
    document.querySelectorAll('#tabs button').forEach(function (b) {
      var name = b.dataset.name || (b.dataset.name = b.textContent);
      var hit = lk && LIC.LOCKED_TABS.indexOf(b.dataset.tab) >= 0;
      b.classList.toggle('lk', hit);
      b.innerHTML = hit ? '<span>' + name + '</span><small>锁定</small>' : name;
      b.title = hit ? '试用已结束，点按输入授权码' : '';
    });
    if (lk && LIC.LOCKED_TABS.indexOf(ui.tab) >= 0) setTab('calc');
  }
});
