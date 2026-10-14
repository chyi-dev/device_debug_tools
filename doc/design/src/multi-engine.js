// 多协议调试台模拟引擎：Serial / BLE / MQTT / WebSocket
var Multi = (function () {
  var listeners = {};
  var idSeq = 0;
  var counters = {};
  var conns = [];
  var activeId = null;

  function nextId(kind) { idSeq++; return kind + '-' + idSeq; }

  function create(kind) {
    var id = nextId(kind);
    var conn = {
      id: id,
      kind: kind,
      open: false,
      rx: 0,
      tx: 0,
      lines: [],
      config: defaultConfig(kind)
    };
    conns.push(conn);
    activeId = id;
    if (kind === 'serial') conn.config.port = 'COM3';
    if (kind === 'mqtt') conn.config.host = 'broker.local';
    if (kind === 'ws') conn.config.url = 'ws://192.168.1.20/ws';
    emit('change', null);
    return conn;
  }

  function defaultConfig(kind) {
    if (kind === 'serial') return { port: '', baud: 115200, parity: 'N', dataBits: 8, stopBits: 1, flow: '无' };
    if (kind === 'ble') return { device: '', service: 'FFF0', notify: 'FFF1', write: 'FFF2' };
    if (kind === 'mqtt') return { host: '127.0.0.1', port: 1883, client: 'ddt-desk-1', sub: '#', pub: '', qos: 1, tls: false };
    if (kind === 'ws') return { url: 'ws://127.0.0.1:8080', protocols: '', heartbeat: 30 };
    return {};
  }

  function labelOf(kind) {
    return { serial: 'SERIAL', ble: 'BLE', mqtt: 'MQTT', ws: 'WS' }[kind];
  }

  function colorOf(kind) {
    return { serial: '#3ccf7a', ble: '#5b9fff', mqtt: '#f0a04b', ws: '#b388ff' }[kind];
  }

  function titleOf(conn) {
    if (conn.kind === 'serial') return conn.config.port || 'Serial';
    if (conn.kind === 'ble') return conn.config.device || 'BLE';
    if (conn.kind === 'mqtt') return conn.config.host || 'MQTT';
    return conn.config.url || 'WebSocket';
  }

  function subtitleOf(conn) {
    if (conn.kind === 'serial') return conn.config.baud + ' 8N1';
    if (conn.kind === 'ble') return (conn.config.service || '—') + ' / ' + (conn.config.notify || '—');
    if (conn.kind === 'mqtt') return (conn.config.sub || '#') + ' · QoS ' + conn.config.qos;
    return 'heartbeat ' + (conn.config.heartbeat || 0) + 's';
  }

  function select(id) {
    if (!conns.find(function (c) { return c.id === id; })) return;
    activeId = id;
    emit('change', null);
  }

  function active() { return conns.find(function (c) { return c.id === activeId; }); }

  function update(id, config) {
    var c = conns.find(function (x) { return x.id === id; });
    if (!c) return;
    c.config = config;
    emit('change', null);
  }

  function open(id) {
    var c = conns.find(function (x) { return x.id === id; });
    if (!c) return;
    if (c.kind === 'ble') {
      log(c, 'sys', 'BLE 桌面端暂未接入适配器，配置已保存');
      emit('change', null);
      return;
    }
    c.open = true;
    log(c, 'sys', labelOf(c.kind) + ' CONNECTED ' + titleOf(c));
    if (c.kind === 'mqtt') {
      setTimeout(function () { log(c, 'rx', 'home/temp {"c":23.4}'); emit('change', null); }, 600);
    } else if (c.kind === 'ws') {
      setTimeout(function () { log(c, 'rx', '{"event":"hello","id":7}'); emit('change', null); }, 400);
    } else if (c.kind === 'serial') {
      setTimeout(function () { log(c, 'rx', 'A5 5A 03 00 F6 02 09 0E'); emit('change', null); }, 300);
    }
    emit('change', null);
  }

  function close(id) {
    var c = conns.find(function (x) { return x.id === id; });
    if (!c) return;
    c.open = false;
    log(c, 'sys', labelOf(c.kind) + ' CLOSED');
    emit('change', null);
  }

  function remove(id) {
    conns = conns.filter(function (x) { return x.id !== id; });
    if (activeId === id) activeId = conns.length ? conns[0].id : null;
    emit('change', null);
  }

  function send(id, text, asHex) {
    var c = conns.find(function (x) { return x.id === id; });
    if (!c || !c.open) return '连接未打开';
    var bytes = asHex ? text.replace(/[^0-9a-fA-F]/g, '').length / 2 : new TextEncoder().encode(text).length;
    c.tx += Math.floor(bytes);
    log(c, 'tx', asHex ? ('SEND HEX> ' + text) : ('SEND ASCII> ' + text));
    if (c.kind === 'serial' && text.toUpperCase().includes('A5 01')) {
      setTimeout(function () { log(c, 'rx', 'A5 5A 03 00 F6 02 09 0E'); emit('change', null); }, 80);
    }
    if (c.kind === 'mqtt') {
      setTimeout(function () { log(c, 'rx', 'device/ack {"ok":1}'); emit('change', null); }, 200);
    }
    emit('change', null);
    return null;
  }

  function log(conn, dir, text) {
    var now = new Date();
    var pad = function (n) { return String(n).padStart(2, '0'); };
    var ms = String(now.getMilliseconds()).padStart(3, '0');
    var t = pad(now.getHours()) + ':' + pad(now.getMinutes()) + ':' + pad(now.getSeconds()) + '.' + ms;
    if (dir === 'rx') conn.rx += new TextEncoder().encode(text).length;
    conn.lines.push({ t: t, dir: dir, text: text });
    if (conn.lines.length > 2000) conn.lines.splice(0, conn.lines.length - 1500);
  }

  function clear(id) {
    var c = conns.find(function (x) { return x.id === id; });
    if (c) { c.lines = []; emit('change', null); }
  }

  function on(type, fn) { (listeners[type] = listeners[type] || []).push(fn); }
  function emit(type, payload) { (listeners[type] || []).forEach(function (fn) { fn(payload); }); }

  // 初始示例数据：同时打开一个串口、一个 MQTT、一个 WS
  create('serial');
  create('mqtt');
  create('ws');
  open(conns[0].id);
  open(conns[1].id);
  open(conns[2].id);

  return {
    conns: function () { return conns; },
    activeId: function () { return activeId; },
    active: active,
    create: create,
    select: select,
    update: update,
    open: open,
    close: close,
    remove: remove,
    send: send,
    clear: clear,
    labelOf: labelOf,
    colorOf: colorOf,
    titleOf: titleOf,
    subtitleOf: subtitleOf,
    defaultConfig: defaultConfig,
    on: on,
    emit: emit
  };
})();
