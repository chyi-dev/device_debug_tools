/* 版 C · 字节对照：课名是索引，选中的课始终在下方用一帧格子讲完。 */
RT.id = 'wild';
RT.paint = function () {
  var cur = RT.byId(RT.id);
  var html = '<div class="railhead"><b>教程</b><span>点课名看这一帧怎么中、会发出什么，再填进左边。</span></div><div class="rscroll">';
  RT.groups.forEach(function (g) {
    html += '<div class="glab">' + g.label + '</div>';
    RT.lessons.forEach(function (l) {
      if (l.group !== g.id) return;
      html += '<button type="button" class="lrow' + (l.id === RT.id ? ' on' : '') + '" data-rt="lesson" data-id="' + l.id + '">' +
        '<span class="ti"><span class="no">' + RT.no(l) + '</span><span>' + esc(l.title) + '</span></span></button>';
    });
  });
  html += '</div><div class="detail"><h4>' + RT.no(cur) + ' · ' + esc(cur.title) + '</h4>' +
    '<p class="snote">' + esc(cur.brief) + '</p>' +
    RT.table(cur) +
    '<div class="recipe">' + esc(RT.recipe(cur)) + '</div>' +
    RT.strip(cur) + RT.tx(cur) +
    '<div class="acts"><button type="button" class="btn sm pri" data-rt="fill" data-id="' + cur.id + '">填入编辑器</button></div>' +
    RT.wroteLine(cur.id) + '</div>';
  $('rail').innerHTML = html;
};
RT.onClick = function (act, id) {
  if (act === 'lesson') { RT.id = id; RT.wrote = ''; RT.paint(); return; }
  if (act === 'fill') { RT.fill(RT.byId(RT.id)); RT.wrote = RT.id; RT.hot(''); RT.paint(); }
};
setTab('reply');
editRule(null);
