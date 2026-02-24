#!/bin/bash
# 测试并发执行 delete 操作时的竞态条件问题
# delete_todo 缺少文件锁，并发执行可能导致数据丢失

set -e

SCRIPT="/root/firsttry/todo.sh"
DATA_FILE="$HOME/.todo_data"
BACKUP=$(mktemp)

cleanup() {
    if [[ -f "$BACKUP" ]]; then
        cp "$BACKUP" "$DATA_FILE" 2>/dev/null || true
        rm -f "$BACKUP"
    fi
    rm -f "$DATA_FILE.lock"
}
trap cleanup EXIT

cp "$DATA_FILE" "$BACKUP" 2>/dev/null || : > "$BACKUP"

# 创建多个待办事项
> "$DATA_FILE"
DELIM=$(printf '\x1f')
printf '1%s任务A%spending\n' "$DELIM" "$DELIM" >> "$DATA_FILE"
printf '2%s任务B%spending\n' "$DELIM" "$DELIM" >> "$DATA_FILE"
printf '3%s任务C%spending\n' "$DELIM" "$DELIM" >> "$DATA_FILE"
printf '4%s任务D%spending\n' "$DELIM" "$DELIM" >> "$DATA_FILE"
printf '5%s任务E%spending\n' "$DELIM" "$DELIM" >> "$DATA_FILE"

echo "=== 初始状态 ==="
cat "$DATA_FILE"
echo ""

# 并发执行 delete 操作 - 模拟竞态条件
echo "=== 并发执行 delete ==="
"$SCRIPT" delete 1 >/tmp/concurrent_delete1.log 2>&1 &
"$SCRIPT" delete 2 >/tmp/concurrent_delete2.log 2>&1 &
"$SCRIPT" delete 3 >/tmp/concurrent_delete3.log 2>&1 &
"$SCRIPT" delete 4 >/tmp/concurrent_delete4.log 2>&1 &
"$SCRIPT" delete 5 >/tmp/concurrent_delete5.log 2>&1 &

wait

echo "=== 删除后的数据文件 ==="
cat "$DATA_FILE"
echo ""

# 检查数据完整性
# 删除5个待办后，数据文件应该为空或不包含任何有效待办
remaining_lines=$(grep -v '^$' "$DATA_FILE" | grep -c "${DELIM}" || true)

echo "剩余有效行数: $remaining_lines"

# 如果有数据残留，说明存在竞态条件
# 正确情况下，数据文件应该为空或只有空行
if [[ "$remaining_lines" -gt 0 ]]; then
    echo "FAIL: 并发 delete 操作导致数据不一致!"
    echo "预期: 数据文件为空 (所有5个待办都被正确删除)"
    echo "实际: 仍有 $remaining_lines 行数据"
    exit 1
fi

echo "PASS"
