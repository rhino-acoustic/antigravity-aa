# aa.ps1 - Antigravity Auto-Accept (CDP)
# Zero dependencies. PowerShell 5.1+ only.
# Connects to Antigravity via Chrome DevTools Protocol (port 9000)
# and auto-clicks Run/Accept/Allow/Retry buttons every 3 seconds.

param(
    [int]$Port = 9000,
    [int]$IntervalMs = 3000,
    [int]$CooldownMs = 1500
)

$ErrorActionPreference = 'SilentlyContinue'

# ── Button click JavaScript (ported from NeuronFS os_automation.go) ──
$clickScript = @'
(() => {
    function collectAll(root) {
        const found = [];
        const walk = node => {
            if (!node) return;
            if (node.shadowRoot) walk(node.shadowRoot);
            const children = node.children || [];
            for (let i = 0; i < children.length; i++) {
                if (children[i].nodeType === 1) { found.push(children[i]); walk(children[i]); }
            }
        };
        walk(root);
        return found;
    }
    function isMenubar(el) {
        let p = el;
        while (p) {
            const cls = (p.className||'').toString().toLowerCase();
            if (cls.includes('menubar')||cls.includes('titlebar')||cls.includes('tabs-container')||cls.includes('tab ')||cls.includes('monaco-icon')) return true;
            const role = (p.getAttribute('role')||'').toLowerCase();
            if (role === 'menubar' || role === 'menuitem' || role === 'tab' || role === 'tablist') return true;
            p = p.parentElement;
        }
        return false;
    }
    function hasOpacity70Ancestor(el) {
        let p = el.parentElement;
        while (p) { if ((p.className||'').toString().includes('opacity-70')) return true; p = p.parentElement; }
        return false;
    }
    function isInsideChatMessage(el) {
        let p = el.parentElement;
        while (p) { const cls = (p.className||'').toString().toLowerCase(); if (cls.includes('markdown')||cls.includes('message-content')||cls.includes('chat-message')||cls.includes('rendered-markdown')) return true; p = p.parentElement; }
        return false;
    }
    function forceClick(el) {
        const opts = { view: window, bubbles: true, cancelable: true };
        try { el.dispatchEvent(new PointerEvent('pointerdown', { ...opts, pointerId: 1 })); } catch {}
        try { el.dispatchEvent(new MouseEvent('mousedown', opts)); } catch {}
        try { el.dispatchEvent(new MouseEvent('mouseup', opts)); } catch {}
        try { el.click(); } catch {}
        try { el.dispatchEvent(new MouseEvent('click', opts)); } catch {}
        try { el.dispatchEvent(new PointerEvent('pointerup', { ...opts, pointerId: 1 })); } catch {}
    }
    const REJECT = ["always run","skip","reject","cancel","close","refine","running command"];
    const ACCEPT = ["run","accept","accept all","send all","retry","apply","confirm","allow once","allow"];
    const BUTTON_ONLY = ["run"];
    const allEls = collectAll(document.body);
    const candidates = [];
    for (const el of allEls) {
        const tag = el.tagName;
        if (!tag || tag === 'DIV') continue;
        if (isMenubar(el)) continue;
        const cls = (el.className||'').toString().toLowerCase();
        const isButton = tag === 'BUTTON';
        const hasRole = el.getAttribute('role') === 'button';
        const hasButtonClass = cls.includes('ide-button') || cls.includes('monaco-button');
        const hasCursorPointer = cls.includes('cursor-pointer');
        if (!(isButton || hasRole || hasButtonClass || hasCursorPointer)) continue;
        const text = (el.innerText || el.textContent || '').trim().toLowerCase();
        if (!text || text.length > 20) continue;
        if (el.offsetParent === null) continue;
        if (!isButton && hasOpacity70Ancestor(el)) continue;
        if (REJECT.some(r => text === r || text.includes(r))) continue;
        if (cls.includes('label-name') || cls.includes('action-label') || cls.includes('codicon')) continue;
        if (isButton) {
            const matched = ACCEPT.find(a => text === a || text.startsWith(a));
            if (matched) {
                const pri = matched === 'accept all' ? 0 : matched === 'run' ? 1 : matched.includes('accept') ? 2 : 4;
                candidates.push({ el, text: matched, tag, priority: pri });
            }
        } else if (tag === 'SPAN') {
            if (!hasCursorPointer || isInsideChatMessage(el)) continue;
            const matched = ACCEPT.find(a => text === a);
            if (matched && BUTTON_ONLY.includes(matched)) continue;
            if (matched) {
                const pri = 100 + (matched.includes('accept') ? 2 : 4);
                candidates.push({ el, text: matched, tag, priority: pri });
            }
        } else if (tag === 'A' && (hasRole || hasButtonClass)) {
            const matched = ACCEPT.find(a => text === a);
            if (matched && BUTTON_ONLY.includes(matched)) continue;
            if (matched) {
                candidates.push({ el, text: matched, tag, priority: 54 });
            }
        }
    }
    candidates.sort((a, b) => a.priority - b.priority);
    if (candidates.length > 0) { const best = candidates[0]; forceClick(best.el); return { found: true, text: best.text, tag: best.tag, total: candidates.length }; }
    return { found: false };
})()
'@

function Get-Timestamp { return (Get-Date).ToString("HH:mm:ss") }

function Write-AA {
    param([string]$Msg, [string]$Color = "Green")
    Write-Host "[$(Get-Timestamp)] [AA] $Msg" -ForegroundColor $Color
}

# ── CDP target discovery ──
function Get-CDPTargets {
    param([int]$P)
    try {
        $resp = Invoke-RestMethod -Uri "http://127.0.0.1:${P}/json/list" -TimeoutSec 3
        return $resp
    } catch {
        return $null
    }
}

# ── WebSocket CDP call ──
function Invoke-CDPEval {
    param([string]$WsUrl, [string]$Expression)

    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $ct = [System.Threading.CancellationToken]::None

    try {
        $uri = [Uri]$WsUrl
        $ws.ConnectAsync($uri, $ct).GetAwaiter().GetResult()

        # Send Runtime.evaluate
        $id = Get-Random -Minimum 1 -Maximum 999999
        $msg = @{
            id = $id
            method = "Runtime.evaluate"
            params = @{
                expression = $Expression
                returnByValue = $true
            }
        } | ConvertTo-Json -Depth 5 -Compress

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)
        $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).GetAwaiter().GetResult()

        # Receive response
        $buf = New-Object byte[] 65536
        $result = ""
        do {
            $seg = New-Object System.ArraySegment[byte] -ArgumentList @(,$buf)
            $recv = $ws.ReceiveAsync($seg, $ct).GetAwaiter().GetResult()
            $result += [System.Text.Encoding]::UTF8.GetString($buf, 0, $recv.Count)
        } while (-not $recv.EndOfMessage)

        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "", $ct).GetAwaiter().GetResult()

        return ($result | ConvertFrom-Json)
    } catch {
        return $null
    } finally {
        if ($ws) { $ws.Dispose() }
    }
}

# ── Main loop ──
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "   Antigravity Auto-Accept (CDP:$Port)" -ForegroundColor Cyan
Write-Host "   Interval: ${IntervalMs}ms | Cooldown: ${CooldownMs}ms" -ForegroundColor Cyan
Write-Host "   Press Ctrl+C to stop" -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""

$lastClickTime = @{}
$connectedTargets = @{}

while ($true) {
    $targets = Get-CDPTargets -P $Port

    if (-not $targets) {
        Write-AA "CDP port $Port unreachable. Waiting..." "Yellow"
        Start-Sleep -Seconds 5
        continue
    }

    # Filter workbench targets only
    $workbenchTargets = @($targets | Where-Object {
        $_.type -ne "worker" -and
        $_.url -like "*workbench*" -and
        $_.webSocketDebuggerUrl
    })

    # Track new connections
    foreach ($t in $workbenchTargets) {
        if (-not $connectedTargets.ContainsKey($t.id)) {
            $name = $t.title
            if ($name -match "^(.+?) - ") { $name = $Matches[1] }
            $connectedTargets[$t.id] = $name
            Write-AA "Connected: [$name]" "Green"
        }
    }

    # Clean disconnected
    $activeIds = @($workbenchTargets | ForEach-Object { $_.id })
    $toRemove = @($connectedTargets.Keys | Where-Object { $_ -notin $activeIds })
    foreach ($id in $toRemove) {
        Write-AA "Disconnected: [$($connectedTargets[$id])]" "DarkGray"
        $connectedTargets.Remove($id)
        $lastClickTime.Remove($id)
    }

    # Poll each target
    foreach ($t in $workbenchTargets) {
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $lastClick = if ($lastClickTime.ContainsKey($t.id)) { $lastClickTime[$t.id] } else { 0 }

        if (($now - $lastClick) -lt $CooldownMs) { continue }

        $resp = Invoke-CDPEval -WsUrl $t.webSocketDebuggerUrl -Expression $clickScript

        if ($resp -and $resp.result -and $resp.result.result -and $resp.result.result.value) {
            $val = $resp.result.result.value
            if ($val.found -eq $true) {
                $name = if ($connectedTargets.ContainsKey($t.id)) { $connectedTargets[$t.id] } else { "?" }
                Write-AA "Click: `"$($val.text)`" ($($val.tag)) [$name]" "Magenta"
                $lastClickTime[$t.id] = $now
            }
        }
    }

    Start-Sleep -Milliseconds $IntervalMs
}
