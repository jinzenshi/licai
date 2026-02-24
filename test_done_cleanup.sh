#!/bin/bash
# 测试 done 命令对脏数据的处理
# 问题：当 done 命令未找到ID或操作失败时，应清理脏数据（与 delete 行为一致）

set -e

SCRIPT="/root/firsttry/todo.sh"
DATA_FILE="$HOME/.todo_data"
BACKUP=$(mktemp)

cleanup() {
  if [[ -f "$BACKUP" ]]; then
    cp "$BACKUP" "$DATA_FILE" 2>/dev/null || true
    rm -f "$BACKUP"
  fi
}
trap cleanup EXIT

cp "$DATA_FILE" "$BACKUP" 2>/dev/null || : > "$BACKUP"

DELIM=$(printf '\x1f')

# 准备测试数据：包含脏数据行
{
  printf '1%s任务A%spending\n' "$DELIM" "$DELIM"
  printf 'badline-without-delimiter\n'
  printf '2%s任务B%spending\n' "$DELIM" "$DELIM"
} > "$DATA_FILE"

echo "=== 测试1: done 一个不存在的ID ==="

# 尝试 done 一个不存在的ID (应该失败)
if "$SCRIPT" done 999 2>/dev/null; then
  echo "FAIL: 应该报错"
  exit 1
fi

# 验证：脏数据应该被清理
if grep -q 'badline-without-delimiter' "$DATA_FILE"; then
  echo "FAIL: 脏数据行应该在 done 失败后被清理"
  exit 1
fi

echo "测试1通过：done 失败后脏数据被清理"

# 重新准备测试数据
{
  printf '1%s任务A%spending\n' "$DELIM" "$DELIM"
  printf 'badline-without-delimiter\n'
  printf '2%s任务B%spending\n' "$DELIM" "$DELIM"
} > "$DATA_FILE"

echo "=== 测试2: done 一个已完成的ID ==="

# 先标记任务1为完成
"$SCRIPT" done 1 >/dev/null

# 再尝试完成同一个任务（应该提示已存在）
if ! "$SCRIPT" done 1 2>&1 | grep -q "已完成"; then
  echo "FAIL: 应该提示已存在"
  exit 1
fi

# 验证：脏数据应该被清理
if grep -q 'badline-without-delimiter' "$DATA_FILE"; then
  echo "FAIL: 脏数据行应该在 done 提示已完成后被清理"
  exit 1
fi

echo "测试2通过：done 提示已完成后脏数据被清理"

echo ""
echo "✅ 所有测试通过"
