#!/bin/bash
# 测试 done/delete 对非法 ID 输入的处理

set -e

> ~/.todo_data
./todo.sh add "样例任务" >/dev/null

out_done=$(./todo.sh done abc 2>&1 || true)
out_del=$(./todo.sh delete abc 2>&1 || true)

if [[ "$out_done" != *"ID必须为数字"* ]]; then
  echo "❌ done 非法ID提示不正确: $out_done"
  exit 1
fi

if [[ "$out_del" != *"ID必须为数字"* ]]; then
  echo "❌ delete 非法ID提示不正确: $out_del"
  exit 1
fi

echo "✅ 非法ID校验通过"
