#!/bin/bash
# 测试并发添加时是否存在 ID 重复问题 (竞态条件)

set -e

# 清空数据文件
> ~/.todo_data

echo "=== 测试并发添加待办 ==="

# 使用后台进程模拟并发添加
./todo.sh add "任务1" >/dev/null &
./todo.sh add "任务2" >/dev/null &
./todo.sh add "任务3" >/dev/null &
./todo.sh add "任务4" >/dev/null &
./todo.sh add "任务5" >/dev/null &

# 等待所有后台任务完成
wait

echo "=== 添加后的列表 ==="
./todo.sh list

# 检查是否有重复 ID
echo ""
echo "=== 检查重复 ID ==="
ids=$(cut -d $'\x1f' -f1 ~/.todo_data | sort -n)
duplicate_ids=$(echo "$ids" | uniq -d)

if [[ -n "$duplicate_ids" ]]; then
    echo "❌ 发现重复 ID: $duplicate_ids"
    echo "原始 IDs:"
    echo "$ids"
    exit 1
else
    echo "✅ 没有重复 ID"
    echo "IDs: $ids"
fi
