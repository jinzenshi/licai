#!/bin/bash
# 测试: done_todo 不应处理/保留非法 status 记录

set -e

> ~/.todo_data

d=$'\x1f'
echo "1${d}正常任务${d}pending" >> ~/.todo_data
echo "2${d}脏状态任务${d}oops" >> ~/.todo_data

./todo.sh done 1 > /tmp/test_done_invalid_status.out

# 任务1应被完成
grep -q "1${d}正常任务${d}done" ~/.todo_data

# 非法状态行应在重写时被清理
if grep -q "2${d}脏状态任务${d}oops" ~/.todo_data; then
  echo "❌ 非法 status 行未被清理"
  exit 1
fi

echo "✅ done_todo 会清理非法 status 行"
rm -f /tmp/test_done_invalid_status.out
