# 单引号包裹的字符串，不会进行变量替换，会进行别名替换

# bash在查找命令时,会按照以下顺序处理:
# 别名(alias)
# 关键字(if、then等)
# 函数
# 内建命令(cd、echo等)
# 环境变量路径中的命令

alias ls='eza --icons --group-directories-first'
alias ll='ls --oneline --long --group --links --octal-permissions --header --time-style long-iso --sort=modified --color-scale=all'
alias lg='ll --git --git-repos --git-ignore'
alias la='ll --all'
alias lt='ll --tree'
alias ls_dir='ll -d'

alias cat='bat -n' # -n显示行号，原本的cat命令也如此
alias man='batman'
alias du='dust'
alias df='duf --sort filesystem' # alias df='df -T -h' # 显示文件系统的类型
alias ping='gping'

alias -g rg_all='rg --column --line-number --fixed-strings --ignore-case --follow --hidden --glob "!.git/*" --color "always"' # 显示匹配文本的行号、列号; 将搜索模式作为字符串而不是正则表达式进行匹配; 递归地跟踪符号链接; 搜索所有文件，排除以 .git/ 开头的路径
alias fd='fd --exclude={.git,.idea,.vscode,.sass-cache,node_modules,build,dist,vendor} --type f'
alias procs='procs --use-config=large --tree'

alias cp='cp -rpi' # 递归复制,保留旧的时间戳和访问权限; 启用交互模式，发生冲突时，让用户确认后再执行操作
alias mv='mv -i'
alias rm='rm -rfi'      # 删除多个文件或目录时，让用户确认
alias mkdir='mkdir -pv' # 递归创建(parent)，打印创建的文件夹
alias rmdir='rmdir -p'
alias grep='grep --color -n' # -r在当前目录中递归搜索 -n显示行号
alias free='free --total --human --wide'
alias sudo='sudo -H'    # 将HOME环境变量设置为目标用户的家目录
alias shred='shred -uz' # remove and zero, 删除文件，无法复原

alias fpath_print='echo ${(j:\n:)fpath}' # 将fpath数组中的元素用\n连接
alias path_print='echo ${(j:\n:)path}'

# 大括号 {} 允许多个命令作为一个整体被处理，特别是在管道操作中。
alias pstop='watch "{ ps aux | { head -n 1; tail -n +2 | sort -nrk 3,3 | head -n 5; } }"' # -n 按数值进行排序; -r 按降序排序; 3,3 只根据第三列进行排序
alias psgrep='f() { if [ $# -eq 0 ]; then echo "Usage: psgrep <process_name>"; return 1; fi; ps -ef | grep -v grep | { head -1; grep "$1"; }; }; f'
alias loadavg='echo "Load: number of processes in runnable or uninterruptable (disk sleep) state." && awk '\''{printf "load_average_1_minute:\t\t%s\nload_average_5_minutes:\t\t%s\nload_average_15_minutes:\t%s\nrunnable_processes/total_processes:\t%s\nlast_process_id:\t\t%s\n", $1, $2, $3, $4, $5}'\'' /proc/loadavg 2>/dev/null || echo "Cannot read /proc/loadavg"'

alias tar_list='f() { if [ $# -eq 0 ]; then echo "Usage: tar_list <archive>"; return 1; fi; tar -tvf "$1"; }; f'
alias tar_make='f() { if [ $# -lt 2 ]; then echo "Usage: tar_make <archive_name> <file1> [file2 ...]"; return 1; fi; local dest="${1}.tar.gz"; shift; tar -czvf "$dest" "$@"; }; f'
alias tar_unmake='f() { if [ $# -eq 0 ]; then echo "Usage: tar_unmake <archive>"; return 1; fi; tar -xzvf "$1"; }; f'
alias extract='function __extract() { if [ -f "$1" ]; then case $1 in *.tar.gz|*.tgz) tar xzvf "$1" ;; *.tar.bz2|*.tbz2) tar xjvf "$1" ;; *.tar.xz|*.txz) tar xJvf "$1" ;; *.tar) tar xvf "$1" ;; *.gz) gunzip "$1" ;; *.bz2) bunzip2 "$1" ;; *.xz) unxz "$1" ;; *.zip) unzip "$1" ;; *.rar) unrar x "$1" ;; *.7z) 7z x "$1" ;; *) echo "Unsupported format" ;; esac; else echo "Error: $1 is not a valid file!"; fi }; __extract'

alias urldecode='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'
alias urlencode='python3 -c "import sys, urllib.parse as ul; print (ul.quote_plus(sys.argv[1]))"'

alias backup='function _backup() {
  local now f
  now=$(date +"%Y%m%d-%H%M%S")
  for f in "$@"; do
    if [[ ! -e $f ]]; then
      echo "file not found: $f" 1>&2
      continue
    fi
    cp -R "$f" "$f.$now.bak"
    echo "copy $f to $f.$now.bak"
  done
}; _backup'

alias sys_maint='function _sys_maint() {
  echo "欢迎进入系统维护!"
  echo
  echo "你想清理两周前的系统日志吗？(y/n)"
  read clear_logs
  if [[ $clear_logs == "y" ]]; then
    echo "正在清理系统日志..."
    sudo journalctl --vacuum-time=2weeks
  fi
  echo "你想清理包缓存吗？(y/n)"
  read clear_cache
  if [[ $clear_cache == "y" ]]; then
    echo "正在清理全部包缓存..."
    sudo pacman -Scc
  fi
  echo "你想删除孤儿包吗？(y/n)"
  read delete_orphans
  if [[ $delete_orphans == "y" ]]; then
    echo "正在删除孤儿包..."
    sudo pacman -Rns \$(pacman -Qdtq)
  fi
  echo "你想更新镜像吗？(y/n)"
  read update_mirrors
  if [[ $update_mirrors == "y" ]]; then
    echo "正在更新镜像..."
    reflector --verbose --country 'China' --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
  fi
  echo "请手动清理以下目录的数据:"
  echo "~/.config/"
  echo "~/.cache/"
  echo "~/.local/share/"
  echo
  echo "请手动查找并删除无效链接"
}; _sys_maint'

alias venv_make='function _venv_make(){ if [[ -z $1 ]]; then echo "venv_make: Usage venv_make <venv-name>" 1>&2; return 1; fi; local venv_dir; if [[ -z $PYTHON_VENV_DIR ]]; then venv_dir="$PYTHON_VENV_DIR/$1"; else venv_dir="$HOME/.local/share/virtualenvs/$1"; fi; echo "make venv in $venv_dir"; python3 -m venv "$venv_dir"; _venv_activate "$1"; }; _venv_make'
alias venv_activate='function _venv_activate(){ if [[ -z $1 ]]; then echo "venv_activate: Usage venv_activate venv-name" 1>&2; return 1; fi; local venv_dir; if [[ -z $PYTHON_VENV_DIR ]]; then venv_dir="$PYTHON_VENV_DIR/$1"; else venv_dir="$HOME/.local/share/virtualenvs/$1"; fi; if [[ ! -d $venv_dir ]]; then echo "venv_activate: $1 must be a directory " 1>&2; return 1; fi; echo "activate venv in $venv_dir"; source "$venv_dir/bin/activate"; }; _venv_activate'
alias pip_update="pip3 list --outdated | cut -d ' ' -f1 | xargs -n1 pip3 install -U"
alias pip_list="pip list"
alias python_clean='find "${@:-.}" -type f -name "*.py[co]" -delete; find "${@:-.}" -type d -name "__pycache__" -delete; find "${@:-.}" -depth -type d -name ".mypy_cache" -exec rm -r "{}" +; find "${@:-.}" -depth -type d -name ".pytest_cache" -exec rm -r "{}" +'

alias nvim_clean='rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim'
