#!/bin/bash
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
{
  printf '1%s任务A%spending\n' "$DELIM" "$DELIM"
  printf 'badline-without-delimiter\n'
  printf '2%s任务B%spending\n' "$DELIM" "$DELIM"
} > "$DATA_FILE"

"$SCRIPT" done 1 >/tmp/test_done_malformed.log

if grep -q 'badline-without-delimiter' "$DATA_FILE"; then
  echo "FAIL: malformed line should be removed during rewrite"
  exit 1
fi

if ! grep -q "^1${DELIM}任务A${DELIM}done$" "$DATA_FILE"; then
  echo "FAIL: task 1 should be marked done"
  exit 1
fi

echo "PASS"
