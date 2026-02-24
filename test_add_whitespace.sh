#!/bin/bash
set -e

SCRIPT="/root/firsttry/todo.sh"
DATA_FILE="$HOME/.todo_data"
BACKUP=$(mktemp)

cleanup() {
  cp "$BACKUP" "$DATA_FILE" 2>/dev/null || true
  rm -f "$BACKUP"
}
trap cleanup EXIT

cp "$DATA_FILE" "$BACKUP" 2>/dev/null || : > "$BACKUP"
: > "$DATA_FILE"

if "$SCRIPT" add "   " >/tmp/test_add_whitespace.log 2>&1; then
  echo "FAIL: whitespace-only todo should be rejected"
  exit 1
fi

if ! grep -q "请输入待办内容" /tmp/test_add_whitespace.log; then
  echo "FAIL: should show empty-content error"
  exit 1
fi

echo "PASS"
