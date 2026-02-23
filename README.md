# Todo List CLI

一个简单的命令行待办事项管理工具。

## 功能

- 添加待办事项
- 列出所有待办事项
- 标记完成
- 删除待办事项
- 数据持久化到本地文件

## 使用方法

```bash
# 添加待办
./todo.sh add "完成任务"

# 列出待办
./todo.sh list

# 标记完成
./todo.sh done <id>

# 删除待办
./todo.sh delete <id>

# 帮助
./todo.sh help
```

## 文件

- `todo.sh` - 主程序
- `todos.txt` - 数据文件（自动创建）
