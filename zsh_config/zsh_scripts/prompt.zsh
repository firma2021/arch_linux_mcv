function check_last_cmd_exit_code()
{
  local last_cmd_exit_code=$?

  last_cmd_exit_info="%F{green}%{√%}%f"

  if [[ $last_cmd_exit_code -ne 0 ]]; then

    last_cmd_exit_info="%F{red}[$last_cmd_exit_code]%f"

    if [ "$last_cmd_exit_code" -gt 128 ] && [ "$last_cmd_exit_code" -lt 160 ]; then
      local signal_number=$((last_cmd_exit_code - 128))
      local signal_name=$(kill -l $signal_number)
      last_cmd_exit_info+=":%F{red}$signal_name($signal_number)%f"
    fi

  fi
}

function calculate_cmd_exec_elapsed_time()
{
  cmd_exec_elapsed_time=""

  if [ "$cmd_exec_begin_time" ]; then

    cmd_exec_end_time=$(print -P %D{%s%3.}) # print -P是zsh内置的命令，%D是时间格式化命令. 相当于date +%s%3N。%3N 表示从纳秒值中取前三位，即毫秒值。

    local d_ms=$((cmd_exec_end_time - cmd_exec_begin_time))
    local d_s=$((d_ms / 1000))
    local ms=$((d_ms % 1000))
    local s=$((d_s % 60))
    local m=$(((d_s / 60) % 60))
    local h=$((d_s / 3600))

    if ((h > 0)); then
      cmd_exec_elapsed_time=${h}h${m}m${s}s
    elif ((m > 0)); then
      cmd_exec_elapsed_time=${m}m${s}.${ms}s
    elif ((s > 0)); then
      cmd_exec_elapsed_time=${s}.${ms}s
    else
      cmd_exec_elapsed_time=${ms}ms
    fi

    cmd_exec_elapsed_time="%F{yellow}${cmd_exec_elapsed_time}%f"
    unset cmd_exec_begin_time
  fi
}

# 执行命令前调用
function preexec()
{
  cmd_exec_begin_time=$(print -P %D{%s%3.})
}

# 命令执行完毕后，生成提示符前调用
function precmd()
{
  check_last_cmd_exit_code

  calculate_cmd_exec_elapsed_time
}

setopt prompt_subst # 在显示提示符之前先对其进行参数扩展、命令替换和算术扩展

# %B：开始粗体文本模式
# %b：结束粗体文本模式
# %F{cyan}：开始使用青色（cyan）前景色
# %f：结束前景色设置
# %(!.#.>)：如果当前用户是超级用户（root）则显示#, 否则显示 >
# %(5~|%-1~/.../%3~|%4~): 最多只显示四层目录。它是条件判断语句，分隔符是 |
# 5~: 当前工作目录的路径至少有5层
# %-1~/.../%3~: 显示第一个目录，然后是 ...，然后是最后三层目录
# %4~: 显示最后四层目录

PROMPT='%B%F{cyan}%(5~|%-1~/.../%3~|%4~)%f%F{magenta}%(!.#.>)%f%b '

# %(x.true-text.false-text) 是条件判断
# %(1j.%F{blue}&(%j)%f.): 至少有1个后台job时，打印 & 和job的数量
# %U: 开启下划线文本
# %u: 关闭下划线文本
# %*: 以 24 小时制显示当前时间,包括秒数
RPROMPT='%B%(1j.%F{blue}&(%j)%f.) ${last_cmd_exit_info} ${cmd_exec_elapsed_time} %F{blue}%U%*%u%f%b'
