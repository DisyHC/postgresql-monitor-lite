# 🐘 PostgreSQL 상태 모니터링 CLI (pg-monitor)

PostgreSQL의 커넥션, 캐시 적중률, WAL 상태 등을 한 번에 확인할 수 있는 Bash 기반 경량 CLI 도구입니다.  
운영 중인 데이터베이스의 상태를 실시간으로 진단할 수 있도록 설계되었습니다.

---

## 🧱 디렉토리 구조

```bash
pg_monitor/
├── pg_monitor.sh     # 핵심 스크립트
├── .env.sample    # 테스트용 샘플 설정파일
└── READEME.md                  # 설명서
```

---

## ✨ 주요 기능

- 커넥션 상태 요약 출력 (`pg_stat_activity`)
- 3초 이상 실행 중인 지연 쿼리 탐지
- 캐시 히트율(`pg_stat_database`) 출력
- Checkpoint & WAL 상태(`pg_stat_bgwriter`) 상세 출력
- `.env` 기반 외부 접속정보 분리
- 컬러/정렬 기반으로 깔끔한 출력 포맷 제공

---

## ⚙️ 사용 방법

```bash
# 1. 클론 또는 다운로드
git clone https://github.com/DisyHC/pg-monitor.git
cd pg-monitor

# 2. 환경설정 파일 생성
cp .env.sample .env
vim .env   # 접속 정보 입력

# 3. 실행
chmod +x monitor_postgres.sh
./monitor_postgres.sh
```

---

## 🔐 .env 파일 구성

`.env.sample` 파일을 참고하여 `.env` 파일을 만들어주세요.

```env
PGHOST=127.0.0.1
PGPORT=5432
PGUSER=pgmon_user
PGDATABASE=your_db
PGPASSWORD=your_password
```

---

## 🧠 지표 설명 및 활용 가이드

### 📌 커넥션 상태 (pg_stat_activity)

| 항목 | 설명 | 활용 상황 |
|------|------|------------|
| `active` | 현재 쿼리 실행 중인 세션 수 | 트래픽 폭주 시 확인 |
| `idle` | 유휴 상태 커넥션 (사용 안함) | 커넥션 낭비 여부 점검 |
| `idle in transaction` | 트랜잭션은 열려 있지만 대기 중 | 트랜잭션 누락/코드 결함 감지 |
| `total` | 전체 접속 수 | `max_connections` 임계점 근접 시 점검 필요 |

---

### 🐢 지연 쿼리 탐지

3초 이상 실행되고 있는 쿼리를 조회하여 Lock, Full Scan 등의 이슈를 조기에 파악할 수 있습니다.

---

### 📈 캐시 히트율 (pg_stat_database)

| 항목 | 설명 | 해석 |
|------|------|------|
| `cache_hit_ratio` | 블록 캐시 적중률 (%) | 90% 이상 유지 권장 |
| `blks_hit` / `blks_read` | 메모리 vs 디스크 비율 기반 | 낮으면 디스크 의존도 ↑ |

---

### 🧹 Checkpoint 및 WAL 상태 (pg_stat_bgwriter)

| 항목 | 설명 | 진단 포인트 |
|------|------|--------------|
| `checkpoints_timed` / `req` | 자동 / 강제 체크포인트 횟수 | 잦으면 I/O 병목 가능 |
| `checkpoint_write_time` | 쓰기 작업 소요 시간 | 길면 디스크 성능 문제 |
| `buffers_clean`, `backend` | 백그라운드 청소 vs backend write | 자동 청소 부족 여부 확인 |
| `buffers_alloc` | 새 할당된 shared_buffers 수 | 부족할 경우 캐시 조정 필요 |
| `maxwritten_clean` | 청소 중단 횟수 | I/O 부하 감지 포인트 |

---

## 🔄 활용 예시

- 신규 서비스 배포 후 DB 상태 점검
- 느려진 서비스에서 long query 추적
- 캐시 설정 변경 전후 히트율 비교
- 정기 점검 스크립트에 삽입 (ex: crontab)

---

## 🛠️ 향후 기능 계획 (Roadmap)

- [ ] `--loop` 옵션 추가 (watch 모드)
- [ ] 임계값 초과 시 컬러 경고
- [ ] HTML 리포트 출력 기능
- [ ] Slack/Telegram 연동 알림

---


