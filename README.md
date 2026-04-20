# Antigravity Auto-Accept

Antigravity IDE에서 AI 에이전트의 Run/Accept/Allow/Retry 버튼을 자동으로 클릭합니다.

**외부 의존성 0** — Windows PowerShell 5.1+만 있으면 됩니다.

## Quick Start

```bat
git clone https://github.com/rhino-acoustic/antigravity-aa.git
cd antigravity-aa
start.bat
```

## 파일 구조

| 파일 | 역할 |
|------|------|
| `start.bat` | 원클릭 실행 (setup + aa) |
| `setup.bat` | argv.json에 CDP 포트 9000 자동 설정 |
| `aa.ps1` | CDP 기반 버튼 자동 클릭 (PowerShell) |

## 작동 원리

1. `setup.bat`이 `~/.antigravity/argv.json`에 `remote-debugging-port: 9000`을 추가
2. Antigravity 재시작 후 CDP가 활성화됨
3. `aa.ps1`이 3초마다 CDP로 workbench 페이지를 스캔
4. Run/Accept/Allow/Retry 버튼 발견 시 자동 클릭

## 클릭 대상

**자동 클릭**: `run`, `accept`, `accept all`, `send all`, `retry`, `apply`, `confirm`, `allow once`, `allow`

**클릭 안 함**: `always run`, `skip`, `reject`, `cancel`, `close`, `refine`, `running command`

## 옵션

```powershell
# 포트 변경
powershell -File aa.ps1 -Port 9222

# 폴링 간격 변경 (ms)
powershell -File aa.ps1 -IntervalMs 5000

# 클릭 쿨다운 변경 (ms)
powershell -File aa.ps1 -CooldownMs 2000
```

## 요구사항

- Windows 10/11
- PowerShell 5.1+ (기본 설치됨)
- Antigravity IDE

## License

MIT
