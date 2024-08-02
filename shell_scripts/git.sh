#!/usr/bin/env bash

cat << EOF
+----------------------------------------+--------------------------------+
| git checkout                           | 切换分支或恢复工作树文件       |
+----------------------------------------+--------------------------------+
| git push origin $(git symbolic-ref --short -q HEAD)    | 将当前分支推送到远程仓库       |
+----------------------------------------+--------------------------------+
| git pull origin $(git symbolic-ref --short -q HEAD) --ff-only | 仅允许快进合并方式拉取当前分支 |
+----------------------------------------+--------------------------------+
| git --no-pager diff                    | 显示更改，不使用分页器         |
+----------------------------------------+--------------------------------+
| git --no-pager status                  | 显示工作树状态，不使用分页器   |
+----------------------------------------+--------------------------------+
| git --no-pager status -s               | 简短格式显示状态，不用分页器   |
+----------------------------------------+--------------------------------+
| git --no-pager show                    | 显示各种对象，不使用分页器     |
+----------------------------------------+--------------------------------+
| git push origin --tags                 | 将所有标签推送到远程仓库       |
+----------------------------------------+--------------------------------+
EOF


#!/bin/bash

cat << EOF
+------------------------------------------------------------------------------+--------------------------------+
| git tag -n --sort=taggerdate | tail -n                                        | 列出最近的n个标签及其信息      |
+------------------------------------------------------------------------------+--------------------------------+
| git tag -a "$1" -m "$2"                                                       | 创建带有信息的新标签           |
+------------------------------------------------------------------------------+--------------------------------+
| git add --all && git commit -m "$*"                                           | 添加所有更改并提交             |
+------------------------------------------------------------------------------+--------------------------------+
| git --no-pager log --date=format:'%Y-%m-%d %H:%M' --pretty=tformat:"$1"       | 自定义格式显示提交日志         |
| --graph -n "${2-10}"                                                          |                                |
+------------------------------------------------------------------------------+--------------------------------+
| gitlog "%C(${hashColor})%h %C(${contentColor})%s%Creset" "$1"                 | 显示彩色的简洁提交日志         |
+------------------------------------------------------------------------------+--------------------------------+
| gitlog "%C(${hashColor})%h %C(${dateColor})%cd %C(${authorColor})%cn:         | 显示彩色的详细提交日志         |
| %C(${contentColor})%s%Creset" "$1"                                            |                                |
+------------------------------------------------------------------------------+--------------------------------+
EOF
