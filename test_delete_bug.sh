#!/bin/bash
# 测试 delete_todo 的严重 bug：删除不存在的 ID 会清空整个数据文件

echo "=== 测试：删除不存在的 ID ==="

# 先添加几个待办
echo "1. 添加测试待办..."
./todo.sh add "任务A"
./todo.sh add "任务B"
./todo.sh add "任务C"

echo ""
echo "2. 当前待办列表："
./todo.sh list

echo ""
echo "3. 尝试删除不存在的 ID (999)..."
./todo.sh delete 999

echo ""
echo "4. 删除后的待办列表："
./todo.sh list

echo ""
echo "=== 测试完成 ==="
