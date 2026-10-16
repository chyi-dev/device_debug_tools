# 生成可导入 device_debug_tools 的 JK89 配置包。运行后写出项目根目录 JSON。
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "coffee-machine-jk89-config.json"


def hx(data: list[int]) -> str:
    return " ".join(f"{b & 0xFF:02X}" for b in data)


def req(flag: int, params: list[int]) -> list[int]:
    body = [0xAA, 0x55, 1 + len(params) + 1, flag, *params]
    body.append(sum(body) & 0xFF)
    return body


def rsp(flag: int, payload: list[int]) -> list[int]:
    body = [0xA5, 0x5A, 1 + len(payload) + 1, flag, *payload]
    body.append(sum(body) & 0xFF)
    return body


def crc16(data: list[int]) -> tuple[int, int]:
    crc = 0xFFFF
    for b in data:
        crc ^= b
        for _ in range(8):
            crc = (crc >> 1) ^ 0xA001 if crc & 1 else crc >> 1
    return crc & 0xFF, (crc >> 8) & 0xFF


def modbus_read(addr: int, data: list[int]) -> list[int]:
    pdu = [addr, 0x03, len(data), *data]
    lo, hi = crc16(pdu)
    return rsp(0x20, pdu + [lo, hi])


def cmd(cid: str, name: str, frame: list[int]) -> dict:
    return {
        "type": "command",
        "id": cid,
        "name": name,
        "data": hx(frame),
        "format": "hex",
        "key": "",
    }


def folder(fid: str, name: str, commands: list[dict]) -> dict:
    return {
        "type": "folder",
        "id": fid,
        "name": name,
        "expanded": True,
        "commands": commands,
    }


def rule(rid: str, name: str, pattern: str, reply: list[int]) -> dict:
    return {
        "id": rid,
        "name": name,
        "match": "prefix",
        "kind": "template",
        "format": "hex",
        "ignoreCase": False,
        "pattern": pattern,
        "enabled": True,
        "replies": [{"data": hx(reply), "delay": 10}],
    }


STA = lambda flag: rsp(flag, [0x00])

tea = [
    0x01,
    0x03, 0x01, 0x01,
    0x08, 0x0B,
    0x00, 0x55,
    0x00, 0x32,
    0x00, 0x64,
    0x0A, 0x1E, 0x0A,
    0x00, 0x01,
]

info = (
    [0x00, 0x03, 0x00, 0x01, 0x00, 0x03, 0x00, 0x00]
    + [0x01, 0x00, 0x00, 0x00]
    + [0x03, 0x01, 0x03, 0x00]
    + [0x00] * 48
)
assert len(info) == 64

# 0x2A：1#–6# 有杯，功能状态为空闲(1)
drop_qj = 0
for i in range(6):
    drop_qj |= 1 << (i * 3)

quick = [
    folder("f-status", "状态查询", [
        cmd("q-1e", "查询设备状态", req(0x1E, [])),
        cmd("q-1f", "查询制作状态", req(0x1F, [])),
        cmd("q-2c", "控制板基本信息", req(0x2C, [0x01])),
        cmd("q-2a", "多落杯器状态", req(0x2A, [])),
    ]),
    folder("f-make", "制作控制", [
        cmd("q-01-hot", "制作热饮1", req(0x01, [0x01, 0x02])),
        cmd("q-01-cold", "制作冷饮1", req(0x01, [0x11, 0x02])),
        cmd("q-17", "现磨制作完成", req(0x17, [0x01])),
        cmd("q-1d-tea", "设置制作流程-萃茶热饮", req(0x1D, tea)),
    ]),
    folder("f-param", "设备参数", [
        cmd("q-04", "设置热水温度 90/85", req(0x04, [90, 85])),
        cmd("q-05", "设置冷水温度 10/5", req(0x05, [10, 5])),
        cmd("q-07-auto", "出杯方式-自动落杯", req(0x07, [0x00])),
        cmd("q-07-manual", "出杯方式-手动放杯", req(0x07, [0x01])),
        cmd("q-24", "送杯 等待20秒", req(0x24, [0x00, 20])),
        cmd("q-1c", "补水", req(0x1C, [])),
        cmd("q-26", "复位主控", req(0x26, [0x04])),
    ]),
    folder("f-clean", "清洗维护", [
        cmd("q-0a", "清洗全部速溶管道", req(0x0A, [0x01])),
        cmd("q-27", "整机管路清洗", req(0x27, [90, 60, 1, 1, 10, 3, 1, 30, 2, 2])),
        cmd("q-29-start", "排空水路-开始", req(0x29, [0x01, 0x01, 0x00])),
        cmd("q-29-query", "排空水路-查询", req(0x29, [0x02, 0x00, 0x00])),
        cmd("q-29-auth", "排空水路-授权继续", req(0x29, [0x03, 0x01, 0x00])),
    ]),
    folder("f-test", "测试调试", [
        cmd("q-1a-powder", "1通道出粉5秒", req(0x1A, [0x01, 0x01, 0x01, 0x32])),
        cmd("q-1a-hot", "1通道出热水5秒", req(0x1A, [0x01, 0x02, 0x01, 0x32])),
    ]),
    folder("f-modbus", "模组透传", [
        cmd("q-20-main", "查询主控模组", req(0x20, [0x01, 0x03, 0x00, 0x1F, 0x00, 0x02])),
        cmd("q-20-door", "查询前门模组", req(0x20, [0x02, 0x03, 0x00, 0x00, 0x00, 0x02])),
        cmd("q-20-ice", "查询制冰模组", req(0x20, [0x03, 0x03, 0x00, 0x00, 0x00, 0x02])),
        cmd("q-20-ground", "查询现磨模组", req(0x20, [0x04, 0x03, 0x80, 0x01, 0x00, 0x02])),
        cmd("q-20-tea", "查询萃茶模组", req(0x20, [0x05, 0x03, 0x80, 0x01, 0x00, 0x02])),
        cmd("q-20-soda", "查询苏打模组", req(0x20, [0x06, 0x03, 0x00, 0xA4, 0x00, 0x02])),
        cmd("q-20-top", "查询小料模组", req(0x20, [0x80, 0x03, 0x00, 0x00, 0x00, 0x02])),
    ]),
    folder("f-lock", "电子锁", [
        cmd("q-1b-open", "开1号电子锁", req(0x1B, [0x01, 0x00])),
        cmd("q-1b-close", "关1号电子锁", req(0x1B, [0x01, 0x01])),
        cmd("q-1b-query", "查询1号电子锁", req(0x1B, [0x01, 0x02])),
    ]),
]

rules = [
    rule("r-1e", "应答-设备状态正常", "AA 55 ?? 1E", rsp(0x1E, [0x00] * 8)),
    rule(
        "r-1f",
        "应答-制作成功",
        "AA 55 ?? 1F",
        rsp(0x1F, [0x80, 0x00, 0x00, 0xA1]),
    ),
    rule("r-2c", "应答-控制板信息", "AA 55 ?? 2C", rsp(0x2C, [0x00, 0x01, *info])),
    rule(
        "r-2a",
        "应答-多落杯器正常",
        "AA 55 ?? 2A",
        rsp(0x2A, [0x00, 0x00, 0x3F, (drop_qj >> 24) & 0xFF, (drop_qj >> 16) & 0xFF, (drop_qj >> 8) & 0xFF, drop_qj & 0xFF]),
    ),
    rule("r-01", "应答-制作饮品成功", "AA 55 ?? 01", STA(0x01)),
    rule("r-17", "应答-现磨完成成功", "AA 55 ?? 17", STA(0x17)),
    rule("r-1d", "应答-设置制作流程成功", "AA 55 ?? 1D", STA(0x1D)),
    rule("r-04", "应答-热水温度成功", "AA 55 ?? 04", STA(0x04)),
    rule("r-05", "应答-冷水温度成功", "AA 55 ?? 05", STA(0x05)),
    rule("r-07", "应答-出杯方式成功", "AA 55 ?? 07", STA(0x07)),
    rule("r-24", "应答-送杯成功", "AA 55 ?? 24", STA(0x24)),
    rule("r-1c", "应答-补水成功", "AA 55 ?? 1C", STA(0x1C)),
    rule("r-26", "应答-复位成功", "AA 55 ?? 26", STA(0x26)),
    rule("r-0a", "应答-清洗速溶管道成功", "AA 55 ?? 0A", STA(0x0A)),
    rule("r-27", "应答-整机清洗成功", "AA 55 ?? 27", STA(0x27)),
    rule("r-29-start", "应答-排空开始", "AA 55 05 29 01", rsp(0x29, [0x00, 0x40, 0x01])),
    rule("r-29-query", "应答-排空完成", "AA 55 05 29 02", rsp(0x29, [0x00, 0x80, 0x07])),
    rule("r-29-auth", "应答-排空授权", "AA 55 05 29 03", rsp(0x29, [0x00, 0x80, 0x07])),
    rule("r-1a", "应答-单元测试成功", "AA 55 ?? 1A", STA(0x1A)),
    rule("r-20-main", "应答-主控模组", "AA 55 08 20 01 03 00 1F", modbus_read(0x01, [0, 0, 0, 0])),
    rule("r-20-door", "应答-前门模组", "AA 55 08 20 02 03 00 00", modbus_read(0x02, [0, 0, 0, 0])),
    rule("r-20-ice", "应答-制冰模组", "AA 55 08 20 03 03 00 00", modbus_read(0x03, [0, 0, 0, 0])),
    rule("r-20-ground", "应答-现磨模组", "AA 55 08 20 04 03 80 01", modbus_read(0x04, [0, 0, 0, 0])),
    rule("r-20-tea", "应答-萃茶模组", "AA 55 08 20 05 03 80 01", modbus_read(0x05, [0, 0, 0, 0])),
    rule("r-20-soda", "应答-苏打模组", "AA 55 08 20 06 03 00 A4", modbus_read(0x06, [0, 0, 0, 0])),
    rule("r-20-top", "应答-小料模组", "AA 55 08 20 80 03 00 00", modbus_read(0x80, [0, 0, 0, 0])),
    rule("r-1b", "应答-电子锁成功", "AA 55 ?? 1B", rsp(0x1B, [0x00, 0x80])),
]

checksum_lua = """-- AA 55 帧若末字节还不是 SUM8，则补上；已带正确校验的快捷指令保持原样
function before_send(frame)
  if frame:len() < 4 then return frame end
  if frame:u8(1) ~= 0xAA or frame:u8(2) ~= 0x55 then return frame end
  local body = frame:sub(1, frame:len() - 1)
  if sum8(body) == frame:u8(frame:len()) then
    return frame
  end
  return frame:append(sum8(frame))
end
"""

status_lua = """-- 解析 0x1E 查询设备状态应答
local function bit(v, n)
  return (v >> n) & 1
end

function on_receive(frame)
  if frame:len() < 8 then return end
  if frame:u8(1) ~= 0xA5 or frame:u8(2) ~= 0x5A or frame:u8(4) ~= 0x1E then
    return
  end
  local v = (frame:u8(5) << 24) | (frame:u8(6) << 16) | (frame:u8(7) << 8) | frame:u8(8)
  local names = {"正常空闲", "正常忙", "异常", "故障"}
  log("0x1E 整机", names[(v & 3) + 1])
  local faults = {
    {2, "E14前门离线"}, {3, "E15制冰离线"}, {4, "E10现磨离线"},
    {6, "制冰故障"}, {7, "现磨故障"}, {8, "E02无杯"},
    {9, "A01无盖"}, {10, "E01缺水"}, {12, "E25首次加热"},
    {13, "A09杯托有杯"}, {14, "A165无豆"}, {15, "E04主控传感器"},
    {30, "E12轨道故障"}, {31, "A116电子锁故障"},
  }
  local hit = {}
  for i = 1, #faults do
    if bit(v, faults[i][1]) == 1 then
      hit[#hit + 1] = faults[i][2]
    end
  end
  if frame:len() >= 13 then
    local v2 = (frame:u8(9) << 24) | (frame:u8(10) << 16) | (frame:u8(11) << 8) | frame:u8(12)
    local more = {
      {0, "E28废盘"}, {1, "E29集粉盘"}, {4, "萃茶离线"},
      {5, "萃茶故障"}, {6, "小料离线"}, {7, "小料故障"}, {9, "苏打故障"},
    }
    for i = 1, #more do
      if bit(v2, more[i][1]) == 1 then
        hit[#hit + 1] = more[i][2]
      end
    end
  end
  if #hit == 0 then
    log("0x1E 故障", "无")
  else
    log("0x1E 故障", table.concat(hit, " "))
  end
end
"""

making_lua = """-- 解析 0x1F 制作状态应答
function on_receive(frame)
  if frame:len() < 8 then return end
  if frame:u8(1) ~= 0xA5 or frame:u8(2) ~= 0x5A or frame:u8(4) ~= 0x1F then
    return
  end
  local v = (frame:u8(5) << 24) | (frame:u8(6) << 16) | (frame:u8(7) << 8) | frame:u8(8)
  local drink = v & 0x0F
  local hot = ((v >> 4) & 1) == 0
  local dropped = ((v >> 7) & 1) == 1
  local waiting = ((v >> 6) & 1) == 1
  local step = (v >> 10) & 0x7F
  local total = (v >> 17) & 0x7F
  local fail = (v >> 24) & 0x3F
  local result = (v >> 30) & 3
  local results = {"未执行", "制作中", "成功", "失败"}
  local failText = fail == 0 and "无" or string.format("EM%02d", fail)
  log(string.format(
    "0x1F 饮品%d %s 落杯%s 取杯%s 步骤%d/%d 失败%s 结果%s",
    drink,
    hot and "热" or "冷",
    dropped and "是" or "否",
    waiting and "是" or "否",
    step,
    total,
    failText,
    results[result + 1]
  ))
end
"""

scripts = [
    {
        "id": "s-jk89-checksum",
        "name": "jk89_checksum.lua",
        "enabled": True,
        "code": checksum_lua,
    },
    {
        "id": "s-jk89-status",
        "name": "jk89_parse_status.lua",
        "enabled": True,
        "code": status_lua,
    },
    {
        "id": "s-jk89-making",
        "name": "jk89_parse_making.lua",
        "enabled": True,
        "code": making_lua,
    },
]

pack = {
    "kind": "device-debug-config",
    "version": 1,
    "quick": quick,
    "rules": rules,
    "scripts": scripts,
}

# 文档中的固定示例必须原样出现
known = {
    "查询设备状态": "AA 55 02 1E 1F",
    "查询制作状态": "AA 55 02 1F 20",
    "多落杯器状态": "AA 55 02 2A 2B",
    "补水": "AA 55 02 1C 1D",
    "1通道出粉5秒": "AA 55 06 1A 01 01 01 32 54",
    "1通道出热水5秒": "AA 55 06 1A 01 02 01 32 55",
    "开1号电子锁": "AA 55 04 1B 01 00 1F",
}
for group in quick:
    for item in group["commands"]:
        expect = known.get(item["name"])
        if expect and item["data"] != expect:
            raise SystemExit(f"{item['name']} got {item['data']} want {expect}")

OUT.write_text(json.dumps(pack, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"wrote {OUT}")
