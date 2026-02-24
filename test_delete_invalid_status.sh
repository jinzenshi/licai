#!/bin/bash
# 测试: delete_todo 重写时应清理非法 status 行

set -e

> ~/.todo_data

d=$'\x1f'
echo "1${d}正常任务1${d}pending" >> ~/.todo_data
echo "2${d}脏状态任务${d}oops" >> ~/.todo_data
echo "3${d}正常任务2${d}pending" >> ~/.todo_data

./todo.sh delete 1 > /tmp/test_delete_invalid_status.out

# 被删除的任务1不应存在
if grep -q "1${d}正常任务1${d}pending" ~/.todo_data; then
  echo "❌ 目标任务未删除"
  exit 1
fi

# 非法 status 行应被清理
if grep -q "2${d}脏状态任务${d}oops" ~/.todo_data; then
  echo "❌ 非法 status 行未被清理"
  exit 1
fi

# 其他正常行应保留
grep -q "3${d}正常任务2${d}pending" ~/.todo_data

echo "✅ delete_todo 会清理非法 status 行"
rm -f /tmp/test_delete_invalid_status.out
