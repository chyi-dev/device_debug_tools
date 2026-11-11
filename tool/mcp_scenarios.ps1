# 对本机 device_debug_tools MCP 做一轮联调。保存为 UTF-8 BOM。

param(
  [string]$TabId = 'tab-1794193952356003-0',
  [int]$Port = 39217,
  [int]$TimeoutSec = 300
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { Add-Type -AssemblyName System.Net.Http -ErrorAction Stop } catch {}

$script:pass = 0
$script:fail = 0
$script:seq = 0
$script:TabName = ''
$script:Kind = ''
$script:Open = $false
$script:IsMqtt = $false
$script:Root = "http://127.0.0.1:$Port"
$script:Endpoint = "$script:Root/mcp"

function New-LocalClient([int]$seconds) {
  $handler = New-Object System.Net.Http.HttpClientHandler
  $handler.UseProxy = $false
  $client = New-Object System.Net.Http.HttpClient -ArgumentList $handler
  $client.Timeout = [TimeSpan]::FromSeconds($seconds)
  return $client
}

$script:Fast = New-LocalClient 20
$script:Slow = New-LocalClient ($TimeoutSec + 5)

function Unwrap-Error($err) {
  $ex = $err.Exception
  if ($null -eq $ex) { return [string]$err }
  while ($null -ne $ex.InnerException) { $ex = $ex.InnerException }
  return [string]$ex.Message
}

function Escape-Json([string]$s) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('"')
  foreach ($ch in $s.ToCharArray()) {
    $code = [int]$ch
    if ($ch -eq '"') { [void]$sb.Append('\"') }
    elseif ($ch -eq '\') { [void]$sb.Append('\\') }
    elseif ($code -eq 8) { [void]$sb.Append('\b') }
    elseif ($code -eq 12) { [void]$sb.Append('\f') }
    elseif ($code -eq 10) { [void]$sb.Append('\n') }
    elseif ($code -eq 13) { [void]$sb.Append('\r') }
    elseif ($code -eq 9) { [void]$sb.Append('\t') }
    elseif ($code -lt 32) { [void]$sb.Append(('\u{0:x4}' -f $code)) }
    else { [void]$sb.Append($ch) }
  }
  [void]$sb.Append('"')
  $sb.ToString()
}

function To-Json($Value) {
  if ($null -eq $Value) { return 'null' }
  if ($Value -is [string]) { return (Escape-Json $Value) }
  if ($Value -is [bool]) {
    if ($Value) { return 'true' } else { return 'false' }
  }
  if ($Value -is [byte] -or $Value -is [int16] -or $Value -is [int32] -or $Value -is [int64] -or $Value -is [decimal] -or $Value -is [single] -or $Value -is [double]) {
    return [System.Convert]::ToString($Value, [System.Globalization.CultureInfo]::InvariantCulture)
  }
  if ($Value -is [System.Collections.IList]) {
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($item in $Value) { [void]$parts.Add((To-Json $item)) }
    return '[' + ($parts -join ',') + ']'
  }
  if ($Value -is [System.Collections.IDictionary]) {
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($key in @($Value.Keys)) {
      [void]$parts.Add(((Escape-Json ([string]$key)) + ':' + (To-Json $Value[$key])))
    }
    return '{' + ($parts -join ',') + '}'
  }
  throw "无法编码类型 $($Value.GetType().FullName)"
}

function As-List($value) {
  if ($null -eq $value) { return ,@() }
  return ,@($value)
}

function Get-ContentText($result) {
  if ($null -eq $result) { return '' }
  $items = @($result.content)
  if ($items.Count -lt 1) { return '' }
  $text = $items[0].text
  if ($null -eq $text) { return '' }
  return [string]$text
}

function Test-IsError($result) {
  if ($null -eq $result) { return $false }
  $p = $result.PSObject.Properties['isError']
  return ($null -ne $p -and $p.Value -eq $true)
}

function Complete-Resp($raw) {
  $status = 0
  $body = ''
  $connect = $true
  if ($null -ne $raw) {
    $status = [int]$raw.status
    $body = [string]$raw.body
    $connect = [bool]$raw.connect
  }
  $json = $null
  if (-not $connect -and $body.Trim().Length -gt 0) {
    try { $json = $body | ConvertFrom-Json } catch { $json = $null }
  }
  $text = ''
  $isError = $false
  if ($null -ne $json -and $null -ne $json.PSObject.Properties['result']) {
    $text = Get-ContentText $json.result
    $isError = Test-IsError $json.result
  }
  [pscustomobject]@{
    status = $status
    body = $body
    connect = $connect
    json = $json
    text = $text
    isError = $isError
  }
}

function Send-Fast([string]$Method, [string]$Url, $Json) {
  $m = switch ($Method) {
    'GET' { [System.Net.Http.HttpMethod]::Get }
    'OPTIONS' { [System.Net.Http.HttpMethod]::Options }
    default { [System.Net.Http.HttpMethod]::Post }
  }
  $req = New-Object System.Net.Http.HttpRequestMessage -ArgumentList $m, $Url
  try {
    if ($null -ne $Json -and $Method -eq 'POST') {
      $req.Content = New-Object System.Net.Http.StringContent -ArgumentList ([string]$Json), ([Text.Encoding]::UTF8), 'application/json'
    }
    $resp = $script:Fast.SendAsync($req).GetAwaiter().GetResult()
    $body = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $code = [int]$resp.StatusCode
    $resp.Dispose()
    return @{ status = $code; body = $body; connect = $false }
  } catch {
    return @{ status = 0; body = (Unwrap-Error $_); connect = $true }
  } finally {
    $req.Dispose()
  }
}

function Invoke-Rpc([string]$Method, $Params) {
  $script:seq++
  $payload = @{
    jsonrpc = '2.0'
    id = $script:seq
    method = $Method
    params = $Params
  }
  Complete-Resp (Send-Fast 'POST' $script:Endpoint (To-Json $payload))
}

function Invoke-Tool([string]$Name, $Arguments) {
  Invoke-Rpc 'tools/call' @{ name = $Name; arguments = $Arguments }
}

function Start-Tool([string]$Name, $Arguments) {
  $script:seq++
  $payload = @{
    jsonrpc = '2.0'
    id = $script:seq
    method = 'tools/call'
    params = @{ name = $Name; arguments = $Arguments }
  }
  $cts = New-Object System.Threading.CancellationTokenSource
  $req = New-Object System.Net.Http.HttpRequestMessage -ArgumentList ([System.Net.Http.HttpMethod]::Post), $script:Endpoint
  $req.Content = New-Object System.Net.Http.StringContent -ArgumentList (To-Json $payload), ([Text.Encoding]::UTF8), 'application/json'
  $task = $script:Slow.SendAsync($req, $cts.Token)
  return @{ task = $task; req = $req; cts = $cts }
}

function Finish-Tool($pending) {
  $finished = $false
  try {
    $finished = $pending.task.Wait([TimeSpan]::FromSeconds($TimeoutSec))
  } catch {
    $pending.req.Dispose()
    $pending.cts.Dispose()
    return (Complete-Resp @{ status = 0; body = (Unwrap-Error $_); connect = $true })
  }
  if (-not $finished) {
    try { $pending.cts.Cancel() } catch {}
    try { [void]$pending.task.Wait(2000) } catch {}
    $pending.req.Dispose()
    $pending.cts.Dispose()
    return (Complete-Resp @{ status = 0; body = '等待界面操作超时'; connect = $true })
  }
  try {
    $resp = $pending.task.Result
    $body = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $code = [int]$resp.StatusCode
    $resp.Dispose()
    return (Complete-Resp @{ status = $code; body = $body; connect = $false })
  } catch {
    return (Complete-Resp @{ status = 0; body = (Unwrap-Error $_); connect = $true })
  } finally {
    $pending.req.Dispose()
    $pending.cts.Dispose()
  }
}

function Pass([string]$Case) {
  $script:pass++
  Write-Host "  PASS  $Case" -ForegroundColor Green
}

function Fail([string]$Case, [string]$Detail) {
  $script:fail++
  Write-Host "  FAIL  $Case" -ForegroundColor Red
  if ($Detail) { Write-Host "        $Detail" -ForegroundColor Red }
}

function Section([string]$Title) {
  Write-Host ""
  Write-Host "==== $Title ====" -ForegroundColor Yellow
}

function Step([string]$Text) {
  Write-Host ""
  Write-Host $Text -ForegroundColor Cyan
  [void](Read-Host '做好后按 Enter')
}

function Ask-Yes([string]$Case, [string]$Prompt) {
  $ans = Read-Host "$Prompt （Y/N）"
  if ($ans -eq 'Y' -or $ans -eq 'y') { Pass $Case; return $true }
  Fail $Case "回答：$ans"
  return $false
}

function Expect-Status([string]$Case, $Resp, [int]$Status) {
  if ($null -eq $Resp -or $Resp.connect) {
    $why = ''
    if ($null -ne $Resp) { $why = [string]$Resp.body }
    Fail $Case "连不上 $why"
    return $false
  }
  if ([int]$Resp.status -ne $Status) {
    Fail $Case "HTTP $($Resp.status) $($Resp.body)"
    return $false
  }
  Pass $Case
  return $true
}

function Expect-RpcError([string]$Case, $Resp, [int]$Code) {
  if ($null -eq $Resp -or $Resp.connect) {
    Fail $Case '连不上'
    return $false
  }
  if ([int]$Resp.status -ne 200 -or $null -eq $Resp.json -or $null -eq $Resp.json.error) {
    Fail $Case "HTTP $($Resp.status) $($Resp.body)"
    return $false
  }
  if ([int]$Resp.json.error.code -ne $Code) {
    Fail $Case "code=$($Resp.json.error.code) $($Resp.body)"
    return $false
  }
  Pass $Case
  return $true
}

function Expect-Tool([string]$Case, $Resp, [bool]$WantError, [string]$Contains) {
  if ($null -eq $Resp -or $Resp.connect) {
    $why = '无响应'
    if ($null -ne $Resp -and $Resp.body) { $why = [string]$Resp.body }
    Fail $Case $why
    return $false
  }
  if ([int]$Resp.status -ne 200) {
    Fail $Case "HTTP $($Resp.status) $($Resp.body)"
    return $false
  }
  if ($Resp.isError -ne $WantError) {
    Fail $Case "isError=$($Resp.isError) text=$($Resp.text)"
    return $false
  }
  if ($Contains -and $Resp.text.IndexOf($Contains) -lt 0) {
    Fail $Case "正文不含「$Contains」：$($Resp.text)"
    return $false
  }
  Pass $Case
  return $true
}

function Read-Rows($text) {
  try { return @(As-List ($text | ConvertFrom-Json)) } catch { return @() }
}

function Sync-Target {
  $list = Invoke-Tool 'list_connections' @{}
  if ($list.connect -or $list.isError) { return $false }
  foreach ($row in (Read-Rows $list.text)) {
    if ($row.id -eq $TabId) {
      $script:TabName = [string]$row.name
      $script:Kind = [string]$row.kind
      $script:Open = [bool]$row.open
      $script:IsMqtt = ($script:Kind -eq 'mqtt')
      return $true
    }
  }
  return $false
}

function New-ScriptArgs([string]$Name) {
  @{
    tabId = $TabId
    name = $Name
    code = 'function on_receive(frame) end'
  }
}

function New-ReplyArgs([string]$Name, [string]$Pattern, $Replies) {
  @{
    tabId = $TabId
    name = $Name
    pattern = $Pattern
    match = 'contains'
    format = 'hex'
    replies = $Replies
  }
}

function Show-Summary {
  Write-Host ""
  Write-Host "通过 $($script:pass)  失败 $($script:fail)" -ForegroundColor Yellow
  if ($script:Kind) {
    Write-Host "这次打的是 $script:Kind / $($script:TabName)。另外四种协议换 -TabId 再跑一遍。"
  }
}

function Invoke-Suite {
  $stamp = Get-Date -Format 'HHmmss'
  $luaAsk = "ask_$stamp.lua"
  $luaOn = "on_$stamp.lua"
  $luaOff = "off_$stamp.lua"
  $luaRevoke = "revoke_$stamp.lua"
  $replyAsk = "ack_$stamp"
  $replyOn = "ack_on_$stamp"
  $replyOff = "ack_off_$stamp"
  $replyBad = "ack_bad_$stamp"
  $oneReply = @(@{ data = 'A5 5A 01'; delayMs = 0 })

  Step (@(
    '步骤 1',
    '菜单「MCP」（在「工具」后、「帮助」前）：',
    '- 勾选「启用 MCP」「发送数据」「读取数据」「自动应答」「实现脚本」「快捷指令」',
    '- 「脚本启用策略」「自动应答启用策略」「快捷指令启用策略」都选「询问」',
    "- 页签 $TabId 还在，连接已打开",
    "- 设置里的地址应是 $($script:Endpoint)。不是就改用 -Port 重跑。"
  ) -join "`n")

  Section '协议'
  $init = Invoke-Rpc 'initialize' @{
    protocolVersion = '2024-11-05'
    capabilities = @{}
    clientInfo = @{ name = 'mcp-scenarios'; version = '1' }
  }
  if ($init.connect -or [int]$init.status -ne 200) {
    Fail 'initialize' "连不上或 HTTP $($init.status)。确认已启用 MCP，端口是 $Port。"
    Show-Summary
    return $script:fail
  }
  $info = $init.json.result.serverInfo
  if ($init.json.result.protocolVersion -eq '2024-11-05' -and $info.name -eq 'device_debug_tools') {
    Pass 'initialize'
  } else {
    Fail 'initialize' $init.body
  }
  Ask-Yes '设置显示已连接' '打开 MCP 设置，是否显示「Cursor 已连上」？'

  $note = Complete-Resp (Send-Fast 'POST' $script:Endpoint '{"jsonrpc":"2.0","method":"notifications/initialized"}')
  if ((Expect-Status 'notifications/initialized → 202' $note 202) -and $note.body.Trim().Length -eq 0) {
    Pass '通知没有包体'
  } elseif (-not $note.connect -and [int]$note.status -eq 202) {
    Fail '通知没有包体' $note.body
  }

  $ping = Invoke-Rpc 'ping' @{}
  if (-not $ping.connect -and [int]$ping.status -eq 200 -and $null -ne $ping.json.result -and $null -eq $ping.json.error) {
    Pass 'ping'
  } else {
    Fail 'ping' $ping.body
  }

  $listed = Invoke-Rpc 'tools/list' @{}
  $toolNames = @()
  if (-not $listed.connect -and $null -ne $listed.json.result) {
    $toolNames = @(As-List $listed.json.result.tools | ForEach-Object { [string]$_.name })
  }
  $needTools = @('list_connections', 'read_logs', 'send_data', 'import_script', 'import_reply', 'import_quick')
  $missing = @($needTools | Where-Object { $toolNames -notcontains $_ })
  if ($missing.Count -eq 0) { Pass 'tools/list 六个工具' } else { Fail 'tools/list 六个工具' ($missing -join ', ') }

  Expect-RpcError '未知方法 -32601' (Invoke-Rpc 'no_such' @{}) -32601
  Expect-RpcError '非法请求 -32600' (Complete-Resp (Send-Fast 'POST' $script:Endpoint '{}')) -32600
  Expect-RpcError '空方法 -32600' (Complete-Resp (Send-Fast 'POST' $script:Endpoint '{"jsonrpc":"2.0","id":1,"method":""}')) -32600
  Expect-Status '坏 JSON → 500' (Complete-Resp (Send-Fast 'POST' $script:Endpoint 'not-json')) 500
  Expect-Status 'GET → 405' (Complete-Resp (Send-Fast 'GET' $script:Endpoint $null)) 405
  Expect-Status 'OPTIONS → 204' (Complete-Resp (Send-Fast 'OPTIONS' $script:Endpoint $null)) 204
  Expect-Status '错误路径 → 404' (Complete-Resp (Send-Fast 'POST' "$script:Root/nope" '{}')) 404

  $batch = Complete-Resp (Send-Fast 'POST' $script:Endpoint '[{"jsonrpc":"2.0","id":1,"method":"ping","params":{}},{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}]')
  $batchItems = As-List $batch.json
  if (-not $batch.connect -and $batchItems.Count -eq 2 -and $null -ne $batchItems[0].result -and $null -ne $batchItems[1].result.tools) {
    Pass '批量请求'
  } else {
    Fail '批量请求' $batch.body
  }
  Expect-Tool '未知工具' (Invoke-Tool 'no_such_tool' @{}) $true '未知工具'

  Section '定位页签'
  $list = Invoke-Tool 'list_connections' @{}
  if (-not (Expect-Tool 'list_connections' $list $false $TabId) -or -not (Sync-Target)) {
    Fail '解析目标页签' "list_connections 里没有 $TabId"
    Show-Summary
    return $script:fail
  }
  Write-Host "  页签 $script:Kind / $($script:TabName) / open=$($script:Open)"
  if (-not $script:Open) {
    Step '步骤 2：该页签 open=false。请打开连接，不要关闭页签。'
    if (-not (Sync-Target)) {
      Fail '刷新页签' 'list_connections 失败'
      Show-Summary
      return $script:fail
    }
  }

  Expect-Tool '只传 tabId 读取' (Invoke-Tool 'read_logs' @{ tabId = $TabId }) $false '['
  Expect-Tool '只传 tabName 读取' (Invoke-Tool 'read_logs' @{ tabName = $script:TabName }) $false '['
  Expect-Tool '两个都不传' (Invoke-Tool 'read_logs' @{}) $true 'tab_required'
  Expect-Tool '名称不匹配' (Invoke-Tool 'read_logs' @{ tabId = $TabId; tabName = '___mismatch___' }) $true 'tab_name_mismatch'
  Expect-Tool '页签 ID 不存在' (Invoke-Tool 'read_logs' @{ tabId = 'tab-does-not-exist' }) $true 'tab_not_found'
  Expect-Tool '页签名称不存在' (Invoke-Tool 'read_logs' @{ tabName = '___missing___' }) $true 'tab_not_found'

  $rows = Read-Rows $list.text
  $counts = @{}
  foreach ($row in $rows) {
    $n = [string]$row.name
    if (-not $counts.ContainsKey($n)) { $counts[$n] = 0 }
    $counts[$n]++
  }
  $dupName = $null
  foreach ($key in @($counts.Keys)) {
    if ($counts[$key] -gt 1) { $dupName = $key; break }
  }
  if ($dupName) {
    Expect-Tool '同名页签须用 tabId' (Invoke-Tool 'read_logs' @{ tabName = $dupName }) $true 'tab_name_ambiguous'
  } else {
    Write-Host '  当前没有同名页签，跳过 tab_name_ambiguous。要测这条，开两个同名页签再跑。'
  }

  Section '发送'
  if ($script:Open) {
    $hex = Invoke-Tool 'send_data' @{
      tabId = $TabId
      tabName = $script:TabName
      data = 'A5 5A 01'
      format = 'hex'
    }
    if (Expect-Tool 'send_data hex（ID 与名称一致）' $hex $false '已发送') {
      Ask-Yes '发送落在目标页签' "数据日志里这帧 A5 5A 01 是否只出现在「$($script:TabName)」？"
    }
    Expect-Tool 'send_data ascii（只传 tabId）' (Invoke-Tool 'send_data' @{
      tabId = $TabId
      data = 'hi'
      format = 'ascii'
    }) $false '已发送'
  } else {
    Fail 'send_data hex' '连接仍未打开'
  }

  Section '询问导入'
  $askJob = Start-Tool 'import_script' (New-ScriptArgs $luaAsk)
  Write-Host ""
  Write-Host "请求已挂起。先关掉 MCP 设置，点顶栏「消息」，点开「脚本 · $luaAsk」，点「启用」。不要点「取消」，也不要只关窗口。" -ForegroundColor Cyan
  $scriptImported = Expect-Tool 'import_script 询问后启用' (Finish-Tool $askJob) $false '已导入并启用'
  if ($scriptImported) {
    Expect-Tool '同名脚本' (Invoke-Tool 'import_script' (New-ScriptArgs $luaAsk)) $true '同名脚本已存在'
  }

  if ($script:IsMqtt) {
    Write-Host '  当前是 MQTT，跳过询问导入应答。稍后断言 unsupported。' -ForegroundColor DarkYellow
  } else {
    $replyJob = Start-Tool 'import_reply' (New-ReplyArgs $replyAsk 'A5 5A' $oneReply)
    Write-Host ""
    Write-Host "请求已挂起。点「消息」，点开「自动应答 · $replyAsk」，点「取消」（导入但不启用）。不要点「启用」。" -ForegroundColor Cyan
    $replyImported = Expect-Tool 'import_reply 询问后不启用' (Finish-Tool $replyJob) $false '已导入未启用'
    if ($replyImported) {
      Expect-Tool '同名自动应答' (Invoke-Tool 'import_reply' (New-ReplyArgs $replyAsk 'A5 5A' $oneReply)) $true '同名自动应答已存在'
    }
  }

  Section '启用策略'
  Step '步骤 3：把「脚本启用策略」改为「默认启用」。其余先别动。'
  Expect-Tool '脚本默认启用' (Invoke-Tool 'import_script' (New-ScriptArgs $luaOn)) $false '已导入并启用'

  Step '步骤 4：把「脚本启用策略」改为「默认禁用」。'
  Expect-Tool '脚本默认禁用' (Invoke-Tool 'import_script' (New-ScriptArgs $luaOff)) $false '已导入未启用'

  Step '步骤 5：把「自动应答启用策略」改为「默认启用」。'
  if ($script:IsMqtt) {
    Expect-Tool 'MQTT 不支持自动应答' (Invoke-Tool 'import_reply' (New-ReplyArgs $replyOn 'A5 5A' $oneReply)) $true 'unsupported'
  } else {
    Expect-Tool '应答默认启用' (Invoke-Tool 'import_reply' (New-ReplyArgs $replyOn 'A5 5A' $oneReply)) $false '已导入并启用'
  }

  Step '步骤 6：把「自动应答启用策略」改为「默认禁用」。'
  if ($script:IsMqtt) {
    Expect-Tool 'MQTT 应答在禁用策略下仍拒绝' (Invoke-Tool 'import_reply' (New-ReplyArgs $replyOff 'A5 5A' $oneReply)) $true 'unsupported'
  } else {
    Expect-Tool '应答默认禁用' (Invoke-Tool 'import_reply' (New-ReplyArgs $replyOff 'A5 5A' $oneReply)) $false '已导入未启用'
    Expect-Tool '应答参数无效' (Invoke-Tool 'import_reply' (New-ReplyArgs $replyBad '' @())) $true 'invalid_reply'
  }

  Section '循环发送'
  $loop = Invoke-Tool 'send_data' @{
    tabId = $TabId
    data = 'A5 5A 01'
    format = 'hex'
    loop = $true
  }
  if (Expect-Tool '拒绝循环发送' $loop $true '不支持循环发送') {
    Ask-Yes '循环发送写进该页签日志' "「$($script:TabName)」的日志里是否有系统消息「循环发送被拒绝」？"
  }

  Section '关掉授权'
  Step '步骤 7：取消勾选「读取数据」。'
  Expect-Tool '未授权读取' (Invoke-Tool 'read_logs' @{ tabId = $TabId }) $true '未授权读取数据'

  Step '步骤 8：取消勾选「发送数据」。'
  Expect-Tool '未授权发送' (Invoke-Tool 'send_data' @{
    tabId = $TabId
    data = '00'
    format = 'hex'
  }) $true '未授权发送数据'

  Step '步骤 9：取消勾选「自动应答」。'
  Expect-Tool '未授权自动应答' (Invoke-Tool 'import_reply' (New-ReplyArgs "denied_$stamp" 'A5' $oneReply)) $true '未授权自动应答'

  Step '步骤 10：确认「实现脚本」已勾选，「脚本启用策略」选「询问」。先不要取消勾选。'
  $revokeJob = Start-Tool 'import_script' (New-ScriptArgs $luaRevoke)
  Write-Host '请求已挂起（脚本已进列表、未启用）。不要点「消息」。看到顶栏数字后，取消勾选「实现脚本」。' -ForegroundColor Cyan
  # 询问仅表示是否启用：关闭授权前条目已导入，故返回「已导入未启用」
  Expect-Tool '询问中关闭脚本授权' (Finish-Tool $revokeJob) $false '已导入未启用'
  Expect-Tool '未授权实现脚本' (Invoke-Tool 'import_script' (New-ScriptArgs "denied_$stamp.lua")) $true '未授权实现脚本'

  Section '断开连接，并关闭 MCP'
  Step '步骤 11：重新勾选「发送数据」。断开该页签的连接，不要关闭页签。'
  Expect-Tool '连接未打开' (Invoke-Tool 'send_data' @{
    tabId = $TabId
    data = '00'
    format = 'hex'
  }) $true 'send_failed'

  Step '步骤 12：取消勾选「启用 MCP」。'
  $down = Invoke-Rpc 'ping' @{}
  if ($down.connect -or [int]$down.status -eq 0) {
    Pass '关闭 MCP 后连不上'
  } else {
    Fail '关闭 MCP 后连不上' "HTTP $($down.status) $($down.body)"
  }

  Show-Summary
  Write-Host 'MCP 现在是关的。还要用的话，重新勾选「启用 MCP」。'
  return $script:fail
}

try {
  $code = Invoke-Suite
} catch {
  Fail '脚本中断' $_.Exception.Message
  Write-Host $_.ScriptStackTrace
  $code = 1
} finally {
  if ($script:Fast) { $script:Fast.Dispose() }
  if ($script:Slow) { $script:Slow.Dispose() }
}
if ($code -gt 0) { exit 1 }
exit 0
