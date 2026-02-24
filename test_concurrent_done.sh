#!/bin/bash
# 测试并发执行 done 操作时的竞态条件问题

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

echo "=== 初始状态 ==="
cat "$DATA_FILE"
echo ""

# 并发执行 done 操作 - 模拟竞态条件
echo "=== 并发执行 done ==="
"$SCRIPT" done 1 >/tmp/concurrent_done1.log 2>&1 &
"$SCRIPT" done 2 >/tmp/concurrent_done2.log 2>&1 &
"$SCRIPT" done 3 >/tmp/concurrent_done3.log 2>&1 &

wait

echo "=== 完成后的数据文件 ==="
cat "$DATA_FILE"
echo ""

# 检查数据完整性
# 验证每个待办是否恰好出现一次
count_1=$(grep -c "^1${DELIM}" "$DATA_FILE" || true)
count_2=$(grep -c "^2${DELIM}" "$DATA_FILE" || true)
count_3=$(grep -c "^3${DELIM}" "$DATA_FILE" || true)

echo "ID 1 出现次数: $count_1"
echo "ID 2 出现次数: $count_2"
echo "ID 3 出现次数: $count_3"

# 如果有任何一个ID出现0次或多次，说明存在竞态条件导致的数据丢失
if [[ "$count_1" -ne 1 || "$count_2" -ne 1 || "$count_3" -ne 1 ]]; then
    echo "FAIL: 并发 done 操作导致数据丢失或重复!"
    echo "预期每个ID恰好出现1次"
    exit 1
fi

echo "PASS"
