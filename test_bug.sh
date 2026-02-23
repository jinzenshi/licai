#!/bin/bash
# 测试 todo.sh 的 bug

echo "=== 测试 1: 空文件时获取 ID ==="
# 清空数据文件
> ~/.todo_data

# 模拟 get_next_id 函数
DATA_FILE="$HOME/.todo_data"
result=$(get_next_id)
echo "结果: '$result'"

# 测试添加功能
echo ""
echo "=== 测试 2: 空文件时添加待办 ==="
./todo.sh add "测试任务"

echo ""
echo "=== 测试 3: 验证 ID ==="
./todo.sh list
