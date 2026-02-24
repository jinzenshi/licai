#!/bin/bash
# 测试 todo.sh 的基本行为

echo "=== 测试 1: 空文件时添加待办 ==="
# 清空数据文件
> ~/.todo_data
./todo.sh add "测试任务"

echo ""
echo "=== 测试 2: 验证首个 ID 应为 1 ==="
first_line=$(head -n 1 ~/.todo_data)
case "$first_line" in
  1$'\x1f'*) echo "✅ ID 正确: 1" ;;
  *) echo "❌ ID 错误: $first_line"; exit 1 ;;
esac

echo ""
echo "=== 测试 3: 列表输出验证 ==="
./todo.sh list
