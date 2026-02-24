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

if "$SCRIPT" add $'第一行\n第二行' >/tmp/test_add_newline.log 2>&1; then
  echo "FAIL: newline todo should be rejected"
  exit 1
fi

if ! grep -q "不能包含换行符" /tmp/test_add_newline.log; then
  echo "FAIL: should show newline error"
  exit 1
fi

echo "PASS"
