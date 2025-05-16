#!/bin/bash

# 환경변수 로딩
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "[❌] .env 파일이 없습니다. .env.sample을 복사해 주세요."
  exit 1
fi

# PostgreSQL 접속 테스트
if ! psql -c '\q' &> /dev/null; then
  echo "[❌] PostgreSQL 접속 실패. .env 파일 확인 필요."
  exit 2
fi

echo "📊 PostgreSQL 상태 모니터링 시작"
echo "-----------------------------------"

echo "🧠 [커넥션 상태 요약]"
psql -P pager=off -c "
SELECT state, COUNT(*) AS count
FROM pg_stat_activity
GROUP BY state;
"

echo -e "\n🐢 [지연된 쿼리 (3초 이상)]"
psql -P pager=off -c "
SELECT pid, now() - query_start AS duration, query
FROM pg_stat_activity
WHERE state != 'idle' AND now() - query_start > interval '3 seconds'
ORDER BY duration DESC;
"

echo -e "\n📈 [캐시 히트율 (단위: %)]"
psql -P pager=off -t -A -F $'\t' -c "
SELECT datname,
       round(blks_hit * 100.0 / NULLIF(blks_hit + blks_read,0), 2) AS cache_hit_ratio
FROM pg_stat_database
ORDER BY cache_hit_ratio ASC;
"

echo -e "\n🧹 [Checkpoint 및 WAL 상태 요약 - 1/2]"
psql -P pager=off -t -A -F $'\t' -c "
SELECT 'checkpoints_timed'         AS metric, checkpoints_timed::TEXT
FROM pg_stat_bgwriter UNION ALL
SELECT 'checkpoints_req',           checkpoints_req::TEXT
FROM pg_stat_bgwriter UNION ALL
SELECT 'checkpoint_write_time',     checkpoint_write_time::TEXT
FROM pg_stat_bgwriter UNION ALL
SELECT 'checkpoint_sync_time',      checkpoint_sync_time::TEXT
FROM pg_stat_bgwriter UNION ALL
SELECT 'buffers_checkpoint',        buffers_checkpoint::TEXT
FROM pg_stat_bgwriter UNION ALL
SELECT 'buffers_clean',             buffers_clean::TEXT
FROM pg_stat_bgwriter;
" | column -t -s $'\t'

echo -e "\n🧹 [Checkpoint 및 WAL 상태 요약 - 2/2]"
psql -P pager=off -t -A -F $'\t' -c "
SELECT 'maxwritten_clean'           AS metric, maxwritten_clean::TEXT
FROM pg_stat_bgwriter UNION ALL
SELECT 'buffers_backend',           buffers_backend::TEXT
FROM pg_stat_bgwriter UNION ALL
SELECT 'buffers_backend_fsync',     buffers_backend_fsync::TEXT
FROM pg_stat_bgwriter UNION ALL
SELECT 'buffers_alloc',             buffers_alloc::TEXT
FROM pg_stat_bgwriter;
" | column -t -s $'\t'

echo -e "\n✅ [완료] PostgreSQL 상태 점검이 끝났습니다."
