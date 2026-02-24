#!/bin/bash

# 测试用例: 复现 done_todo 在处理已完成的唯一待办时的数据丢失问题

# 设置测试数据文件
export HOME="/tmp/test_home_$$"
mkdir -p "$HOME"
TEST_DATA="$HOME/.todo_data"

# 替换 todo.sh 中的 DATA_FILE
sed 's|^DATA_FILE=.*|DATA_FILE="'"$TEST_DATA"'"|' /root/firsttry/todo.sh > /tmp/todo_test.sh
chmod +x /tmp/todo_test.sh

# 清理函数
cleanup() {
    rm -f "$TEST_DATA" /tmp/todo_test.sh
    rm -rf "$HOME"
}

# 捕获错误
trap cleanup EXIT

echo "=== 测试开始 ==="

# 1. 添加一个待办
echo "步骤1: 添加一个待办 '测试任务'"
/tmp/todo_test.sh add "测试任务"

# 2. 查看添加后的内容
echo ""
echo "步骤2: 查看添加后的数据文件内容:"
cat "$TEST_DATA"
echo ""

# 3. 标记为完成
echo ""
echo "步骤3: 标记为完成 (done 1)"
/tmp/todo_test.sh done 1

# 4. 再次标记为完成 (这应该触发 bug)
echo ""
echo "步骤4: 再次标记为完成 (done 1) - 这应该会触发问题"
/tmp/todo_test.sh done 1

# 5. 检查数据文件
echo ""
echo "步骤5: 检查数据文件内容:"
if [[ -s "$TEST_DATA" ]]; then
    echo "文件内容:"
    cat "$TEST_DATA"
    echo ""
    echo "文件有内容 - 测试通过 (未发生数据丢失)"
else
    echo "文件为空 - BUG! 数据丢失了!"
    echo "测试失败: done 一个已完成的唯一待办导致数据文件被清空"
    exit 1
fi

# 6. 验证 list 命令
echo ""
echo "步骤6: 验证 list 命令"
list_output=$(/tmp/todo_test.sh list)
echo "$list_output"

echo ""
echo "=== 测试完成 ==="
