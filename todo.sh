#!/bin/bash

# Todo List CLI - 简单待办事项管理工具

DATA_FILE="$HOME/.todo_data"
DELIMITER="::"

# 初始化数据文件
if [[ ! -f "$DATA_FILE" ]]; then
    touch "$DATA_FILE"
fi

# 获取下一个ID (修复: 查找最大ID而非仅看最后一行)
get_next_id() {
    if [[ ! -s "$DATA_FILE" ]]; then
        echo "1"
        return
    fi
    
    # 提取所有数字ID，找出最大值，避免非数字ID导致的ID冲突
    local max_id=$(awk -F'|' '{if ($1 ~ /^[0-9]+$/) if ($1 > max) max=$1} END {print (max=="") ? "1" : max+1}' "$DATA_FILE")
    echo "$max_id"
}

# 添加待办
add_todo() {
    local todo_text="$*"
    if [[ -z "$todo_text" ]]; then
        echo "Error: 请输入待办内容"
        exit 1
    fi
    local id=$(get_next_id)
    echo "$id$DELIMITER$todo_text$DELIMITERpending" >> "$DATA_FILE"
    echo "✅ 已添加: $todo_text (ID: $id)"
}

# 列出待办
list_todos() {
    if [[ ! -s "$DATA_FILE" ]]; then
        echo "📝 没有待办事项"
        return
    fi
    
    echo "📋 待办事项列表:"
    echo "-------------------"
    while IFS='|' read -r id text status; do
        if [[ "$status" == "done" ]]; then
            echo "[✓] #$id $text"
        else
            echo "[ ] #$id $text"
        fi
    done < "$DATA_FILE"
    echo "-------------------"
}

# 完成待办
done_todo() {
    local id="$1"
    if [[ -z "$id" ]]; then
        echo "Error: 请指定待办ID"
        exit 1
    fi
    
    local temp_file=$(mktemp)
    local found=0
    
    while IFS='|' read -r curr_id text status; do
        if [[ "$curr_id" == "$id" ]]; then
            echo "$curr_id|$text|done" >> "$temp_file"
            echo "✅ 已完成: $text"
            found=1
        else
            echo "$curr_id|$text|$status" >> "$temp_file"
        fi
    done < "$DATA_FILE"
    
    mv "$temp_file" "$DATA_FILE"
    
    if [[ $found -eq 0 ]]; then
        echo "Error: 未找到ID为 $id 的待办"
    fi
}

# 删除待办
delete_todo() {
    local id="$1"
    if [[ -z "$id" ]]; then
        echo "Error: 请指定待办ID"
        exit 1
    fi
    
    local temp_file=$(mktemp)
    local found=0
    
    while IFS='|' read -r curr_id text status; do
        if [[ "$curr_id" == "$id" ]]; then
            echo "🗑️ 已删除: $text"
            found=1
        else
            echo "$curr_id|$text|$status" >> "$temp_file"
        fi
    done < "$DATA_FILE"
    
    mv "$temp_file" "$DATA_FILE"
    
    if [[ $found -eq 0 ]]; then
        echo "Error: 未找到ID为 $id 的待办"
    fi
}

# 显示帮助
show_help() {
    echo "Todo List CLI - 简单待办事项管理工具"
    echo ""
    echo "使用方法:"
    echo "  $0 add <内容>     添加待办事项"
    echo "  $0 list          列出所有待办"
    echo "  $0 done <ID>     标记完成"
    echo "  $0 delete <ID>   删除待办"
    echo "  $0 help          显示帮助"
}

# 主命令处理
case "$1" in
    add)
        shift
        add_todo "$@"
        ;;
    list)
        list_todos
        ;;
    done)
        done_todo "$2"
        ;;
    delete)
        delete_todo "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "未知命令: $1"
        echo "使用 '$0 help' 查看帮助"
        exit 1
        ;;
esac
