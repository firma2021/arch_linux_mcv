# 注意，=左右不能有空格

# 单引号包裹的字符串，不会进行变量替换，会进行别名替换

# bash在查找命令时,会按照以下顺序处理:
# 别名(alias)
# 关键字(if、then等)
# 函数
# 内建命令(cd、echo等)
# 路径中的脚本程序
# 通过type命令可以查看命令当前是属于哪一类。

# -----------------------------cli tools-------------------------------
# eza
alias ls='eza --icons --group-directories-first'
alias ll='ls --oneline --long --group --links --octal-permissions --header --time-style long-iso --sort=modified --color-scale=all'
alias lg='ll --git --git-repos --git-ignore'
alias la='ll --all'
alias lt='ll --tree'
alias ls_dir='ll -d'


alias cat='bat -n' # -n显示行号，原本的cat命令也如此
alias man='batman'
alias du='dust'
# alias df='df -T -h' # 显示文件系统的类型
alias df='duf --sort filesystem'

# gping
alias ping='gping'

# 显示匹配文本的行号、列号
# 将搜索模式作为字符串而不是正则表达式进行匹配
# 递归地跟踪符号链接
# 搜索所有文件，排除以 .git/ 开头的路径
alias rg_all='rg --column --line-number --fixed-strings --ignore-case --follow --hidden --glob "!.git/*" --color "always"'

alias reload='source ~/.zshrc'
alias restart='exec zsh -l'              # 重启zsh
alias fpath_print='echo ${(j:\n:)fpath}' # 将fpath数组中的元素用\n连接
alias path_print='echo ${(j:\n:)path}'
alias zshrc='${EDITOR:-vim} "${ZDOTDIR:-$HOME}"/.zshrc'
alias zshbench='for i in {1..10}; do /usr/bin/time zsh -lic exit; done'
alias zshdot='cd ${ZSH_DOT_DIR:-~}'

alias grep='grep --color -rn'

alias free='free --total --human --wide --seconds 10'

alias sudo='sudo -H' # 设置HOME环境变量为目标用户（通常是root用户）的家目录

alias mkdir='mkdir -pv' # 递归创建(parent)，打印创建的文件夹
alias rmdir='rmdir -p'

# 启用以下命令的交互模式，发生冲突时，让用户确认后再执行操作
alias cp='cp -rpi' # 递归复制,保留旧的时间戳和访问权限
alias mv='mv -i'
alias rm='rm -rfi' # 删除多个文件或目录时，让用户确认

alias tarls='tar -tvf' # list verbose file, 查看tar文件的详细信息

alias pstop='watch "ps aux | sort -nrk 3,3 | head -n 5"'

alias arch='uname -m' # 显示硬件架构

alias shred='shred -uz' # remove and zero, 删除文件，无法复原

# url encode/decode
alias urldecode='python3 -c "import sys, urllib.parse as ul; \
    print(ul.unquote_plus(sys.argv[1]))"'
alias urlencode='python3 -c "import sys, urllib.parse as ul; \
    print (ul.quote_plus(sys.argv[1]))"'

alias more='echo "请使用功能更强大的less命令: 可以向上浏览、通过/key来查找关键词key; 与more类似，按下回车显示下一行，按下空格显示下一页"'

alias procs='procs --use-config=large --tree'

function backup
{
  local now f
  now=$(date +"%Y%m%d-%H%M%S")
  for f in "$@"; do
    if [[ ! -e $f ]]; then
      echo "file not found: $f" 1>&2
      continue
    fi
    cp -R "$f" "$f"."$now".bak
    echo "copy $f to $f.$now.bak"
  done
}

function extract
{
	local remove_archive
	local success
	local extract_dir

	if (( $# == 0 )); then
		cat <<-'EOF' >&2
			Usage: extract [-option] [file ...]

			Options:
			    -r, --remove    Remove archive after unpacking.
		EOF
	fi

	remove_archive=1
	if [[ "$1" == "-r" ]] || [[ "$1" == "--remove" ]]; then
		remove_archive=0
		shift
	fi

	while (( $# > 0 )); do
		if [[ ! -f "$1" ]]; then
			echo "extract: '$1' is not a valid file" >&2
			shift
			continue
		fi

		success=0
		extract_dir="${1:t:r}"
		case "${1:l}" in
			(*.tar.gz|*.tgz) (( $+commands[pigz] )) && { pigz -dc "$1" | tar xv } || tar zxvf "$1" ;;
			(*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$1" ;;
			(*.tar.xz|*.txz)
				tar --xz --help &> /dev/null \
				&& tar --xz -xvf "$1" \
				|| xzcat "$1" | tar xvf - ;;
			(*.tar.zma|*.tlz)
				tar --lzma --help &> /dev/null \
				&& tar --lzma -xvf "$1" \
				|| lzcat "$1" | tar xvf - ;;
			(*.tar.zst|*.tzst)
				tar --zstd --help &> /dev/null \
				&& tar --zstd -xvf "$1" \
				|| zstdcat "$1" | tar xvf - ;;
			(*.tar) tar xvf "$1" ;;
			(*.tar.lz) (( $+commands[lzip] )) && tar xvf "$1" ;;
			(*.tar.lz4) lz4 -c -d "$1" | tar xvf - ;;
			(*.tar.lrz) (( $+commands[lrzuntar] )) && lrzuntar "$1" ;;
			(*.gz) (( $+commands[pigz] )) && pigz -dk "$1" || gunzip -k "$1" ;;
			(*.bz2) bunzip2 "$1" ;;
			(*.xz) unxz "$1" ;;
			(*.lrz) (( $+commands[lrunzip] )) && lrunzip "$1" ;;
			(*.lz4) lz4 -d "$1" ;;
			(*.lzma) unlzma "$1" ;;
			(*.z) uncompress "$1" ;;
			(*.zip|*.war|*.jar|*.sublime-package|*.ipsw|*.xpi|*.apk|*.aar|*.whl) unzip "$1" -d $extract_dir ;;
			(*.rar) unrar x -ad "$1" ;;
			(*.rpm) mkdir "$extract_dir" && cd "$extract_dir" && rpm2cpio "../$1" | cpio --quiet -id && cd .. ;;
			(*.7z) 7za x "$1" ;;
			(*.deb)
				mkdir -p "$extract_dir/control"
				mkdir -p "$extract_dir/data"
				cd "$extract_dir"; ar vx "../${1}" > /dev/null
				cd control; tar xzvf ../control.tar.gz
				cd ../data; extract ../data.tar.*
				cd ..; rm *.tar.* debian-binary
				cd ..
			;;
			(*.zst) unzstd "$1" ;;
			(*)
				echo "extract: '$1' cannot be extracted" >&2
				success=1
			;;
		esac

		(( success = $success > 0 ? $success : $? ))
		(( $success == 0 )) && (( $remove_archive == 0 )) && rm "$1"
		shift
	done
}

function countfiles()
{
  if [ -z "$1" ]; then
    cur_path="."
  else
    cur_path="$1"
  fi

  files_num=$(ls -A "$cur_path" | wc -l) # -A不包括.和..
  echo "$files_num files in $cur_path"
}

# tar
function tar_list
{
  tar -tvf # t即list，列出归档文件中的所有文件

}
function tar_make
{
  echo "tar -czvf ${1}.tar.gz $1: create, gzip, verbose, file"
  local dest="$1".tar.gz
  shift
  local src="$@"
  tar -czvf "$dest" "$src"
}
function tar_unmake
{
  echo "tar -zxvf $1: extract, gzip, verbose, file"
  tar -xzvf "$1"
}

function extract()
{
  if [ -f "$1" ]; then
    case $1 in
      *.7z) 7z x "$1" ;;
      *.lzma) unlzma "$1" ;;
      *.rar) unrar x "$1" ;;
      *.tar) tar xvf "$1" ;;
      *.tar.bz2) tar xvjf "$1" ;;
      *.bz2) bunzip2 "$1" ;;
      *.tar.gz) tar xvzf "$1" ;;
      *.gz) gunzip "$1" ;;
      *.tar.xz) tar Jxvf "$1" ;;
      *.xz) xz -d "$1" ;;
      *.tbz2) tar xvjf "$1" ;;
      *.tgz) tar xvzf "$1" ;;
      *.zip) unzip "$1" ;;
      *.Z) uncompress ;;
      *) echo "don't know how to extract $1..." ;;
    esac
  else
    echo "Error: $1 is not a valid file!"
  fi
}

psgrep()
{
  if [ $# -eq 0 ]; then
    echo "Usage: psgrep <process_name>"
    return 1
  fi

  ps -ef |  grep -v grep | { head -1; grep $1; }
}

function hist()
{
  echo "Use !number to execute the command"
  history -i
}

function mkcd()
{
  # parents, 递归地创建目录，如果父目录不存在，自动创建
  mkdir -p "$1"
  cd $1 || exit
}

function note()
{
  if [ -z "$1" ]; then
    "$EDITOR" "$HOME/.notes/note_${countfiles}.txt"
  else
    "$EDITOR" "$HOME/.notes/$1"
  fi
}

function sshf()
{
  if [[ ! -e ~/.ssh/config ]]; then
    echo 'There is no SSH config file!'
    return
  fi

  hostnames=$(awk ' $1 == "Host" { print $2 } ' ~/.ssh/config)
  if [[ -z ${hostnames} ]]; then
    echo 'There are no host entries in the SSH config file'
    return
  fi

  selected=$(printf "%s\n" "${hostnames[@]}" | fzf --reverse --border=rounded --cycle --height=30% --header='pick a host')
  if [[ -z ${selected} ]]; then
    echo 'Nothing was selected :('
    return
  fi

  echo "SSH to ${selected}..."
  ssh "$selected"
}

function loadavg()
{
  if [[ ! -f "/proc/loadavg" ]]; then
    echo "/proc/loadavg does not exist"
  fi

  local loadavg
  loadavg=$(cat /proc/loadavg 2> /dev/null)

  if [[ -n $loadavg ]]; then
    local loadavg_fields=($(echo "$loadavg" | cut -d' ' -f1-))
    printf "load_average_1_minute:\t\t%s\n" "${loadavg_fields[1]}"
    printf "load_average_5_minutes:\t\t%s\n" "${loadavg_fields[2]}"
    printf "load_average_15_minutes:\t%s\n" "${loadavg_fields[3]}"
    printf "runnable_processes/total_processes: \t%s\n" "${loadavg_fields[4]}"
    printf "last_process_id\t%s\n" "${loadavg_fields[5]}"
  else
    echo "cannot read /proc/loadavg"
  fi
}

function proxy_set()
{
  local __user=$(
    read -p "username: "
    echo "${REPLY}"
  )
  local __pass=$(
    read -sp "password: "
    echo "${REPLY}"
  )

  # Deal with no newlines after `read -p`.
  echo

  local __serv=${1-$(
    read -p "server: "
    echo "${REPLY}"
  )}
  local __prot=${2-$(
    read -p "protocol: "
    echo "${REPLY}"
  )}

  # Create proxy url.
  local __prox="${__prot}://${__user}:${__pass}@${__serv}"

  export HTTP_PROXY="${__prox}"
  export HTTPS_PROXY="${__prox}"
  export SOCKS_PROXY="${__prox}"
  export FTP_PROXY="${__prox}"
  export ALL_PROXY="${__prox}"

  export http_proxy="${__prox}"
  export https_proxy="${__prox}"
  export socks_proxy="${__prox}"
  export ftp_proxy="${__prox}"
  export all_proxy="${__prox}"
}

function proxy_unset()
{
  unset HTTP_PROXY HTTPS_PROXY SOCKS_PROXY FTP_PROXY ALL_PROXY
  unset http_proxy https_proxy socks_proxy ftp_proxy all_proxy
}

function nvim_clean()
{
  rm -rf ~/.config/nvim
  rm -rf ~/.local/share/nvim
  rm -rf ~/.local/state/nvim
  rm -rf ~/.cache/nvim
}

function gap()
{
  if [[ -z $1 ]]; then
    echo "please commit message input!!" 1>&2
    exit 1
  fi
  git add . && git commit -m "$1" && git push
}

function preview()
{
    # 如果$1是test.cpp， 得到text/x-c++
    mime_type=$(file -b -L --mime-type "$1") # brief, follow symbolic links.

    # 这是参数扩展语法。
    # **删除匹配的后缀部分，/*匹配/后的任意字符序列。
    # 即从变量 $mime_type 的末尾开始，删除最长的匹配模式 /*
    # 效果为提取出text
    file_type=${mime_type%%/*}

    echo "$1 : $mime_type"

    if [ -d "$1" ]; then
    eza --icons --oneline --long -o --header -all --time-style long-iso --sort extension --hyperlink --color=always "$1"
    elif [ "$mime_type" = "text/html" ]; then
    w3m -dump "$1"
    elif [ "$mime_type" = "application/zip" ]; then
    unzip -l "$1"
    elif [ "$mime_type" = "application/x-pie-executable" ]; then
    objdump -D "$1" | bat -n --language=asm --color=always # --disassemble-all
    elif [ "$file_type" = "text" ]; then
    bat -n --color=always "$1" # 如果不指定--color=always，则不会高亮显示
    elif [ "$file_type" = "image" ]; then
    viu -w 16 -h 10 "$1"
    else
    bat -n --color=always "$1"
    fi
}

alias make='make -j$(nproc)' # 执行nproc命令，获得cpu数量，然后并行make
alias cm='cmake -B./build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && make -C ./build'
alias cmr='cmake -B./build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && make -C ./build && echo "===== output =====" && ./build/$(cat CMakeLists.txt | grep add_executable | sed "s/\s*add_executable\s*(\s*//g" | cut -d " " -f 1)'

alias fd='fd --exclude={.git,.idea,.vscode,.sass-cache,node_modules,build,dist,vendor} --type f'

function system_maintenance()
{
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
    sudo pacman -Rns $(pacman -Qdtq)
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
  echo "请手动查找并删除无效链接"
}
