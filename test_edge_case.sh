#!/bin/bash
# 测试 list_todos 对数据文件中空行/不完整数据的处理

set -e

echo "=== 测试：list_todos 对异常数据的处理 ==="

# 清空数据文件
> ~/.todo_data

# 场景1：添加正常数据
echo "1. 添加正常待办..."
./todo.sh add "正常任务" >/dev/null

# 场景2：手动添加空行到数据文件（模拟损坏）
echo "" >> ~/.todo_data

# 场景3：添加另一个正常数据
./todo.sh add "第二个任务" >/dev/null

# 场景4：手动添加不完整的数据（缺少status）
echo "2\x1f缺失状态" >> ~/.todo_data

echo "2. 当前数据文件内容："
cat -A ~/.todo_data
echo ""

echo "3. 执行 list 命令："
output=$(./todo.sh list 2>&1)
echo "$output"

# 验证：检查是否有异常的空行输出
if echo "$output" | grep -E '\[\s*\]\s*#\s*$' >/dev/null; then
    echo ""
    echo "❌ 测试失败：发现异常的空ID输出"
    exit 1
fi

# 验证：检查是否包含原始分隔符
if echo "$output" | grep -E '#.*\x1f' >/dev/null; then
    echo ""
    echo "❌ 测试失败：输出包含原始分隔符"
    exit 1
fi

echo ""
echo "✅ 测试通过：list_todos 正确处理了异常数据"
