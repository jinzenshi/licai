#!/bin/bash

# 测试用例：验证修复后正常功能和拒绝功能都能正常工作

SCRIPT="/root/firsttry/todo.sh"
DATA_FILE="$HOME/.todo_data"
TEST_DIR=$(mktemp -d)

backup_data() {
    if [[ -f "$DATA_FILE" ]]; then
        cp "$DATA_FILE" "$TEST_DIR/backup_todo_data"
    fi
}

restore_data() {
    if [[ -f "$TEST_DIR/backup_todo_data" ]]; then
        cp "$TEST_DIR/backup_todo_data" "$DATA_FILE"
    else
        : > "$DATA_FILE"
    fi
    rm -rf "$TEST_DIR"
}

trap cleanup EXIT
cleanup() { restore_data; }

backup_data
: > "$DATA_FILE"

echo "=== 测试1: 正常添加待办（应成功） ==="
"$SCRIPT" add "正常的待办事项"
"$SCRIPT" list

echo ""
echo "=== 测试2: 添加包含分隔符的待办（应失败） ==="
DELIMITER_CHAR=$(printf '\x1f')
TODO_TEXT="前段${DELIMITER_CHAR}后段"
bash -c "$SCRIPT add '$TODO_TEXT'" || echo "(预期失败)"

echo ""
echo "=== 测试3: 再次列出待办（应只有正常的待办） ==="
"$SCRIPT" list

echo ""
echo "=== 测试4: 完成正常待办（应成功） ==="
"$SCRIPT" done 1
"$SCRIPT" list

echo ""
echo "=== 测试完成 ==="
