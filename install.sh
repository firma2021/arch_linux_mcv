#!/usr/bin/env bash
set -o nounset
set -o pipefail

# ANSI 颜色代码，24位真彩色,38表示前景色，2表示真彩色，中间的3位是RGB, 最后的1表示粗体
orange="\033[38;2;255;102;0;1m" # 用于接收用户输入时的提示信息
red='\033[38;2;255;0;0;1m'      # 用于错误信息
purple='\033[38;2;63;13;164;1m' # 用于普通信息
reset="\033[0m"

function init_git
{
  if pacman -Q git; then
    echo -e "${purple}已安装git !"
  else
    echo -e "${purple}安装git..."
    sudo pacman -S --noconfirm git
  fi

  if ! git config user.name; then
    echo -e "${orange}请输入您的 Git 用户名称: "
    read -r USER_NAME # -r将\视为普通字符
    git config --global user.name "$USER_NAME"
  fi

  if ! git config --global user.email; then
    echo -e "${orange}请输入您的 Git 邮箱地址: "
    read -r USER_EMAIL
    git config --global user.email "$USER_EMAIL"
  fi

  echo -e "${purple}将git的默认分支名设置为main..."
  git config --global init.defaultBranch main

  echo -e "${purple}设置git命令别名"
  git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ci %cr) %C(bold blue)<%an>%Creset'"
  git config --global alias.br "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate"

  echo -e "${purple}您当前的git配置为: "
  git config --list
}

function init_pacman
{
  if ! pacman -Q reflector; then
    echo -e "${purple}安装reflector..."
    sudo pacman -S --noconfirm reflector
  fi

  echo -e "${purple}添加国内源:"
  sudo reflector --verbose --country 'China' --age 120 --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

  if pacman -Q yay; then
    echo -e "${purple}已安装yay!"
  else
    echo -e "${purple} 安装AUR包管理器yay..."
    sudo pacman -S --needed base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay || echo "${red}无法进入 yay目录"
    makepkg -si
  fi

  echo -e "${purple}请您在 /etc/pacman.conf 中的 [options] 下, 添加Color、ILoveCandy、VerbosePkgLists、ParallelDownloads; 注释掉NoProgressBar"

  echo -e "如果您的发行版为manjaro, 请为pamac启用aur和flatpak"
}

function install_zsh
{
  if ! pacman -Q zsh; then
    echo -e "${purple}安装zsh..."
    sudo pacman -S --noconfirm zsh
  fi

  echo -e "${purple}将 $USER 使用的shell切换为zsh..."
  chsh -s /usr/bin/zsh
  echo -e "将 root 使用的shell切换为zsh..."
  sudo chsh -s /usr/bin/zsh root

  if ! pacman -Q zsh-autosuggestions zsh-fast-syntax-highlighting zsh-completions; then
    sudo pacman -S --noconfirm zsh-autosuggestions zsh-completions
    yay -S --noconfirm zsh-fast-syntax-highlighting
  fi

  echo -e "${purple}" "已安装插件: "
  ls /usr/share/zsh/plugins

  if [ -f "$HOME/.zshrc" ]; then
    backup_file_name=".zshrc_$(date +'%Y-%m-%d-%H-%M-%S')"
    mv ~/.zshrc "$HOME/$backup_file_name"
    echo -e "${purple}已存在旧的.zshrc配置文件。备份为 $HOME/$backup_file_name"
  fi
  cp -pv ./zsh_config/.zshrc ~/.zshrc

  echo -e "${purple}" "复制zsh脚本..."
  sudo cp -rpiv ./zsh_config/zsh_scripts /usr/share/zsh/zsh_scripts
}

function install_cli_tools
{

  local cli_tools=('bat' 'bat-extras' 'eza' 'fd' 'procs' 'gping' 'fzf' 'ripgrep' 'dust' 'duf' 'cloc')

  yay -S "${cli_tools[@]}"

  echo -e "${purple}" "执行pacman -Qe命令, 查看您安装的包"
}

function install_dev_tools
{
  local python_packages=('python' 'python-pip')
  local cpp_packages=('gcc' 'clang' 'gdb' 'make' 'cmake' 'ninja' 'libc++' 'boost')
  local shell_packages=('shellcheck' 'shfmt')
  local dev_packages=('man-db' 'man-pages' 'man-pages-zh_cn')

  yay -S "${dev_packages[@]}"
  yay -S "${shell_packages[@]}"
  yay -S "${cpp_packages[@]}"
  yay -S "${python_packages[@]}"

  cp -rpiv clangd ~/.config

  echo -e "${purple}" "执行pacman -Qe命令, 查看您安装的包"
}

function install_system_tools
{
  if pacman -Q neofetch &> /dev/null; then
    sudo pacman -Rsn neofetch
  fi
  yay -S 'fastfetch'

  yay -S 'catppuccin-cursors-latte'

  if pacman -Q htop &> /dev/null; then
    sudo pacman -Rsn htop
  fi
  yay -S 'mission-center'
  yay -S 'stacer-bin'

  yay -S 'archlinux-tweak-tool-git'

  echo -e "如果您使用的是KDE桌面环境, 请用pacman命令安装kwalletmanager, 以在设置中关闭kwallet."
  echo -e "${purple}" "执行pacman -Qe命令, 查看您安装的包"
}

function install_fonts
{
  local fonts=('otf-monaspace' 'otf-monaspace-nerd' 'ttf-lxgw-wenkai')

  yay -S "${fonts[@]}"
}

function install_input_method
{

  local input_method=('fcitx5-im' 'fcitx5-chinese-addons' 'fcitx5-pinyin-moegirl' 'fcitx5-pinyin-zhwiki')

  yay -S "${input_method[@]}"

  echo '请在/etc/environment中添加XMODIFIERS=@im=fcitx'
}

function install_shell_scripts
{
  if [ -d "/usr/share/shell_scripts" ]; then
    backup_file_name="$(date +'%Y-%m-%d-%H-%M-%S')"
    sudo mv /usr/share/shell_scripts "/usr/share/shell_scripts_$backup_file_name"
    echo -e "${purple}备份旧目录为 /usr/share/zsh/zsh_scripts_$backup_file_name"
  fi
  sudo cp -rpv ./shell_scripts /usr/share/shell_scripts

  bashrc="$HOME/.bashrc"
  zshrc="$HOME/.zshrc"

  if ! grep -q 'export PATH="$PATH:/usr/share/shell_scripts"' "$bashrc"; then
    echo 'export PATH="$PATH:/usr/share/shell_scripts"' >> "$bashrc"
  fi

  if ! grep -q 'export PATH="$PATH:/usr/share/shell_scripts"' "$zshrc"; then
    echo 'export PATH="$PATH:/usr/share/shell_scripts"' >> "$zshrc"
  fi
}

function set_local_rtc
{
  timedatectl set-local-rtc 1
}

while true; do
  echo -e "${purple}请选择要执行的功能:"
  echo "1) 安装/初始化 git"
  echo "2) 安装/初始化 pacman 和 yay"
  echo "3) 安装zsh/zsh插件/实用zsh脚本"
  echo "4) 安装实用 shell 脚本"
  echo "5) 安装命令行工具"
  echo "6) 安装c++, python, shell开发工具"
  echo "7) 安装鼠标主题和系统工具"
  echo "8) 安装字体"
  echo "9) 安装输入法"
  echo "10) 将硬件时钟设置为本地时区"
  echo "11) 退出"

  echo -e "${reset}"

  read -r -p "请输入选项 (1-9): " choice
  case $choice in
    1) init_git ;;
    2) init_pacman ;;
    3) install_zsh ;;
    4) install_shell_scripts ;;
    5) install_cli_tools ;;
    6) install_dev_tools ;;
    7) install_system_tools ;;
    8) install_fonts ;;
    9) install_input_method ;;
    10) set_local_rtc ;;
    11)
      echo -e "${purple}退出程序"
      exit 0
      ;;
    *) echo -e "${purple}无效选项，请重新选择" ;;
  esac
  echo -e "${orange}"
  read -r -p "按回车键继续..."
done
