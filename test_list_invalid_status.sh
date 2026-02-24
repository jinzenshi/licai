#!/bin/bash
# 测试: list 应跳过非法 status 记录

set -e

> ~/.todo_data

d=$'\x1f'
echo "1${d}正常待办${d}pending" >> ~/.todo_data
echo "2${d}已完成待办${d}done" >> ~/.todo_data
echo "3${d}脏状态待办${d}oops" >> ~/.todo_data

out=$(./todo.sh list)

echo "$out" | grep -q "#1 正常待办"
echo "$out" | grep -q "#2 已完成待办"

if echo "$out" | grep -q "#3 脏状态待办"; then
  echo "❌ 非法 status 记录被错误展示"
  exit 1
fi

echo "✅ 非法 status 记录已被过滤"
