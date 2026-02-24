#!/bin/bash
# 测试: list_todos 应等待写锁释放（读操作需加共享锁）

set -e

> ~/.todo_data
./todo.sh add "任务1" > /dev/null

# 持有写锁 2 秒
(
  flock -x 200
  sleep 2
) 200>~/.todo_data.lock &
locker_pid=$!

# 确保锁已拿到
sleep 0.2

start=$(date +%s)
./todo.sh list > /tmp/list_lock_wait_output.txt
end=$(date +%s)

wait $locker_pid

elapsed=$((end-start))

# 未加锁时通常 <1s；加共享锁后应等待写锁释放（约2s）
if [[ "$elapsed" -lt 2 ]]; then
  echo "❌ list 未等待锁释放，耗时: ${elapsed}s"
  exit 1
fi

echo "✅ list 等待写锁释放，耗时: ${elapsed}s"
rm -f /tmp/list_lock_wait_output.txt
