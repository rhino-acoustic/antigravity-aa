<p align="center">
  <h1 align="center">⚡ Antigravity Auto-Accept</h1>
  <p align="center">
    <strong>Zero-dependency auto-clicker for Antigravity IDE</strong><br>
    CDP-based • PowerShell native • No install required
  </p>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#how-it-works">How it Works</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#safety">Safety</a>
</p>

---

## What it does

Automatically clicks **Run**, **Accept**, **Accept All**, **Allow**, **Retry**, **Apply**, and **Confirm** buttons in Antigravity IDE — so your AI agent runs uninterrupted.

No extensions. No Node.js. No Go. Just **Windows PowerShell**.

## Quick Start

```bash
git clone https://github.com/rhino-acoustic/antigravity-aa.git
cd antigravity-aa
start.bat
```

That's it. Three commands.

> **First time?** Restart Antigravity after running `setup.bat` to enable CDP on port 9000.

## How it Works

```
start.bat
  │
  ├── setup.bat
  │     └── Patches ~/.antigravity/argv.json
  │         with "remote-debugging-port": 9000
  │
  └── aa.ps1  (main loop, runs forever)
        │
        ├── GET http://127.0.0.1:9000/json/list
        │     → Discovers all Antigravity windows
        │
        ├── Filter: only "workbench.html" targets
        │     → Skips webviews, settings, workers
        │
        ├── WebSocket → Runtime.evaluate
        │     → Injects button-scanning JavaScript
        │
        └── Clicks highest-priority accept button
              → With 1.5s cooldown per window
```

## Button Priority

| Priority | Button Text | Tag |
|:--------:|-------------|-----|
| 0 | `accept all` | BUTTON |
| 1 | `run` | BUTTON only |
| 2 | `accept` | BUTTON |
| 4 | `retry` `apply` `confirm` `allow` | BUTTON |
| 54 | any accept text | A (role=button) |
| 100+ | any accept text | SPAN (cursor-pointer) |

### Never clicks

`always run` · `skip` · `reject` · `cancel` · `close` · `refine` · `running command`

## Configuration

```powershell
# Custom port
powershell -File aa.ps1 -Port 9222

# Slower polling (5 seconds)
powershell -File aa.ps1 -IntervalMs 5000

# Longer cooldown between clicks
powershell -File aa.ps1 -CooldownMs 3000
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-Port` | `9000` | CDP remote debugging port |
| `-IntervalMs` | `3000` | Scan interval in milliseconds |
| `-CooldownMs` | `1500` | Per-window click cooldown |

## Safety

The click script applies **6 safety filters** to prevent accidental clicks:

1. **Menubar/Titlebar/Tab** — Never clicks navigation UI
2. **Opacity-70 ancestors** — Skips greyed-out/disabled elements
3. **Chat messages** — Won't click text inside AI responses
4. **Label/Action/Codicon** — Skips icon-only and label elements
5. **Invisible elements** — `offsetParent === null` check
6. **Long text** — Ignores buttons with text > 20 characters

Additionally, `run` is restricted to `<button>` tags only — it will never be clicked on `<span>` or `<a>` elements.

## Requirements

- **Windows 10/11**
- **PowerShell 5.1+** (pre-installed on Windows)
- **Antigravity IDE**

## Files

```
antigravity-aa/
├── start.bat      One-click launcher
├── setup.bat      CDP port 9000 auto-config
├── aa.ps1         Core engine (PowerShell CDP client)
├── GEMINI.md      AI agent context document
├── README.md      This file
└── LICENSE         MIT
```

## Origin

Ported from [NeuronFS](https://github.com/rhino-acoustic/NeuronFS) `runtime/os_automation.go` — same click logic, same safety filters, zero external dependencies.

## License

MIT
