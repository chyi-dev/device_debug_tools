/* 版 B · 分步写入：选课之后，按「看这一包 / 写入匹配 / 写入应答」填左边。
   打开时停在第 3 课的「写入匹配」，左边对应栏位已经写上并勾出边。 */
RT.id = 'wild';
RT.step = 'match';
RT.paint = function () {
  var cur = RT.byId(RT.id);
  var html = '<div class="railhead"><b>教程</b><span>先选一课，再按三步写进左边。每一步只动它负责的栏。</span></div><div class="pick">';
  RT.groups.forEach(function (g) {
    html += '<div class="g">' + g.label + '</div>';
    RT.lessons.forEach(function (l) {
      if (l.group !== g.id) return;
      html += '<button type="button" data-rt="lesson" data-id="' + l.id + '"' + (l.id === RT.id ? ' class="on"' : '') + '>' +
        RT.no(l) + ' ' + esc(l.short) + '</button>';
    });
  });
  html += '</div><div class="steps"><div class="stepkicker">' + RT.no(cur) + ' · ' + esc(cur.title) + '</div>';
  cur.steps.forEach(function (s, i) {
    var on = RT.step === s.id;
    html += '<button type="button" class="step' + (on ? ' on' : '') + '" data-rt="step" data-id="' + s.id + '">' +
      '<span class="no">' + (i + 1) + '</span><span>' + esc(s.title) + '</span></button>';
    if (!on) return;
    var visual = s.id === 'see' ? (RT.table(cur) + RT.strip(cur)) : (s.id === 'match' ? '<div class="recipe">' + esc(RT.recipe(cur)) + '</div>' : RT.tx(cur));
    var btn = s.id === 'see' ? '' : '<div class="acts"><button type="button" class="btn sm pri" data-rt="fill" data-id="' + s.id + '">' +
      (s.id === 'match' ? '写入匹配' : '写入应答') + '</button></div>';
    html += '<div class="stepbody"><p class="tuttext">' + esc(s.text) + '</p>' + visual + btn + RT.wroteLine(s.id) + '</div>';
  });
  html += '<div class="stepall acts"><button type="button" class="btn sm" data-rt="fill" data-id="all">整课填入</button></div>' + RT.wroteLine('all') + '</div>';
  $('rail').innerHTML = html;
};
RT.onClick = function (act, id) {
  if (act === 'lesson') { RT.id = id; RT.step = 'see'; RT.wrote = ''; RT.hot(''); RT.paint(); return; }
  if (act === 'step') { RT.step = id; RT.wrote = ''; RT.hot(''); RT.paint(); return; }
  if (act === 'fill') {
    var l = RT.byId(RT.id);
    if (id === 'all') { RT.fill(l); RT.wrote = 'all'; RT.hot(''); }
    else { RT.fill(l, id); RT.wrote = id; RT.step = id; }
    RT.paint();
    if (id !== 'all') RT.hot(id);
  }
};
setTab('reply');
editRule(null);
RT.fill(RT.byId('wild'), 'match');
RT.hot('match');
