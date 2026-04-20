# Antigravity Auto-Accept (AA)

## What is this?
CDP(Chrome DevTools Protocol) 기반으로 Antigravity IDE의 Run/Accept/Allow/Retry 버튼을 자동 클릭하는 도구.
외부 의존성 0. Windows PowerShell 5.1+만 있으면 동작한다.

## Architecture

```
start.bat
  ├── setup.bat          argv.json에 remote-debugging-port=9000 주입
  └── aa.ps1             CDP WebSocket으로 3초마다 버튼 스캔 + 클릭
        │
        ├── GET /json/list          타겟 목록 (workbench.html 필터)
        ├── WebSocket connect       각 타겟의 webSocketDebuggerUrl
        └── Runtime.evaluate        버튼 클릭 JavaScript 주입
```

## Files

| File | Role | Lines |
|------|------|-------|
| `start.bat` | 원클릭 런처 (setup → aa) | ~20 |
| `setup.bat` | `~/.antigravity/argv.json`에 CDP 9000 포트 설정 | ~40 |
| `aa.ps1` | 핵심 엔진 — CDP WebSocket으로 버튼 자동 클릭 | ~200 |

## How AA works (for AI agents)

1. `http://127.0.0.1:9000/json/list`로 CDP 타겟 목록 조회
2. `url`에 `workbench.html`이 포함된 타겟만 필터 (webview/설정 페이지 제외)
3. 각 타겟의 `webSocketDebuggerUrl`로 WebSocket 연결
4. `Runtime.evaluate`로 클릭 JavaScript를 주입:
   - Shadow DOM까지 재귀 탐색 (`collectAll`)
   - menubar/titlebar/tab 영역 제외 (`isMenubar`)
   - opacity-70 조상 제외 (비활성 UI)
   - chat message 내부 제외 (`isInsideChatMessage`)
   - REJECT 텍스트 필터 → ACCEPT 텍스트 매칭 → 우선순위 정렬 → 최우선 1개 클릭

## Button priority

| Priority | Text | Condition |
|----------|------|-----------|
| 0 | `accept all` | BUTTON only |
| 1 | `run` | BUTTON only (SPAN/A에서 절대 클릭 안 함) |
| 2 | `accept`, `accept *` | BUTTON |
| 4 | `retry`, `apply`, `confirm`, `allow` | BUTTON |
| 54 | any ACCEPT text | A tag with role=button |
| 100+ | any ACCEPT text | SPAN with cursor-pointer |

## REJECT list (never click)

`always run`, `skip`, `reject`, `cancel`, `close`, `refine`, `running command`

## Safety filters

- `label-name`, `action-label`, `codicon` 클래스 → 스킵
- `tag === 'DIV'` → 스킵
- `offsetParent === null` (invisible) → 스킵
- `innerText.length > 20` → 스킵
- menubar/titlebar/tab 계열 → 스킵

## Configuration

```powershell
# Default values in aa.ps1
$Port = 9000          # CDP port
$IntervalMs = 3000    # Polling interval
$CooldownMs = 1500    # Per-target click cooldown
```

## Prerequisite

Antigravity must be launched with `--remote-debugging-port=9000`.
`setup.bat` handles this automatically by patching `argv.json`.

## Origin

Ported from [NeuronFS](https://github.com/rhino-acoustic/NeuronFS) `runtime/os_automation.go`.
Original: Go + goroutine. This version: PowerShell + WebSocket. Same click logic.
