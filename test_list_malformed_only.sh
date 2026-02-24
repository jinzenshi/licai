#!/bin/bash
# 测试: 当数据文件仅有脏行时，list 应提示没有待办

set -e

> ~/.todo_data
echo "bad line" >> ~/.todo_data
echo "1\x1fmissing_status" >> ~/.todo_data
echo "abc\x1f任务\x1fpending" >> ~/.todo_data

out=$(./todo.sh list)

if ! echo "$out" | grep -q "📝 没有待办事项"; then
  echo "❌ 仅脏行时未提示无待办"
  echo "$out"
  exit 1
fi

echo "✅ 仅脏行时正确提示无待办"
