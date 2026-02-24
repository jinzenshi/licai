#!/bin/bash
# 测试: delete 不存在 ID 时也应回写有效数据并清理脏行

set -e

> ~/.todo_data

d=$'\x1f'
echo "bad line" >> ~/.todo_data
echo "1${d}正常任务${d}pending" >> ~/.todo_data
echo "2${d}脏状态任务${d}oops" >> ~/.todo_data

set +e
./todo.sh delete 999 >/tmp/test_delete_notfound_cleanup.out 2>&1
rc=$?
set -e

if [[ $rc -eq 0 ]]; then
  echo "❌ delete 不存在 ID 应返回失败"
  exit 1
fi

# 有效行应保留
grep -q "1${d}正常任务${d}pending" ~/.todo_data

# 脏行应被清理
if grep -q "bad line\|2${d}脏状态任务${d}oops" ~/.todo_data; then
  echo "❌ 未清理脏行"
  exit 1
fi

echo "✅ delete 不存在 ID 时会清理脏行并保留有效数据"
rm -f /tmp/test_delete_notfound_cleanup.out
