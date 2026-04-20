# Antigravity Auto-Accept (AA)

이 프로젝트는 Antigravity IDE의 AI 에이전트 버튼(Run, Accept, Allow, Retry 등)을 CDP로 자동 클릭하는 도구다.

## 네가 할 일

사용자가 이 프로젝트를 열었다면, AA를 설치하거나 수정하려는 것이다.

### 즉시 실행
```bat
start.bat
```
이것 하나로 argv.json CDP 9000 설정 + 자동 클릭 루프가 시작된다.

### 코드 수정 시 알아야 할 것

1. **aa.ps1**이 핵심이다. CDP WebSocket으로 `Runtime.evaluate`를 호출해 JavaScript를 주입한다.
2. 클릭 JavaScript는 NeuronFS `os_automation.go`에서 포팅했다. 동일한 안전장치가 적용되어 있다.
3. 버튼 우선순위: `accept all`(0) > `run`(1) > `accept`(2) > 나머지(4)
4. `run`은 BUTTON 태그에서만 클릭한다. SPAN/A에서는 절대 클릭 안 한다.
5. REJECT 목록: `always run`, `skip`, `reject`, `cancel`, `close`, `refine`, `running command`

### 구조
```
start.bat        → setup.bat 호출 후 aa.ps1 실행
setup.bat        → ~/.antigravity/argv.json에 CDP 9000 포트 설정
aa.ps1           → 3초마다 CDP로 버튼 스캔 + 자동 클릭
```

### 안전 필터 (건드리지 마라)
- menubar/titlebar/tab 영역 스킵
- opacity-70 조상 (비활성 UI) 스킵
- chat message 내부 스킵
- label-name/action-label/codicon 클래스 스킵
- invisible 요소 (offsetParent === null) 스킵
- 텍스트 20자 초과 스킵

### 설정값
| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| `$Port` | 9000 | CDP 포트 |
| `$IntervalMs` | 3000 | 폴링 간격 (ms) |
| `$CooldownMs` | 1500 | 클릭 후 재클릭 대기 (ms) |

### 의존성
없다. Windows PowerShell 5.1+ 기본 내장.
