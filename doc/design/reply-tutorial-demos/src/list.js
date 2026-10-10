/* 版 A · 课表：点一课就在列表里展开，对照左边的空表单。 */
RT.open = 'wild';
RT.paint = function () {
  var html = '<div class="railhead"><b>教程</b><span>模板四课，正则三课。点开一课，可填进左边。</span></div><div class="rscroll">';
  RT.groups.forEach(function (g) {
    html += '<div class="glab">' + g.label + '</div>';
    RT.lessons.forEach(function (l) {
      if (l.group !== g.id) return;
      var on = RT.open === l.id;
      html += '<button type="button" class="lrow' + (on ? ' on' : '') + '" data-rt="open" data-id="' + l.id + '">' +
        '<span class="ti"><span class="no">' + RT.no(l) + '</span><span>' + esc(l.title) + '</span></span>' +
        '<span class="br">' + esc(l.brief) + '</span></button>';
      if (!on) return;
      html += '<div class="lbody">' + RT.block(l) +
        '<div class="acts"><button type="button" class="btn sm pri" data-rt="fill" data-id="' + l.id + '">填入编辑器</button></div>' +
        RT.wroteLine(l.id) + '</div>';
    });
  });
  $('rail').innerHTML = html + '</div>';
};
RT.onClick = function (act, id) {
  if (act === 'open') { RT.open = RT.open === id ? '' : id; RT.paint(); return; }
  if (act === 'fill') { RT.fill(RT.byId(id)); RT.wrote = id; RT.hot(''); RT.paint(); }
};
setTab('reply');
editRule(null);
