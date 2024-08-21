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

  branch_name=$(git config --global --get init.defaultBranch)
  echo -e "${purple}您当前的全局默认分支名为$branch_name"

  if [[ -z $branch_name || $branch_name == 'master' ]]; then
    echo -e "${purple}将git的默认分支名从master改为main..."
    git config --global init.defaultBranch main
  fi

  echo -e "${purple}设置git日志格式"
  git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ci %cr) %C(bold blue)<%an>%Creset'"
  git config --global alias.br "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate"
  git config --global alias.pu "push origin HEAD"
  git config --global alias.save "add -A && git commit -m 'chore: savepoint'"
  git config --global alias.undo "reset HEAD~1 --mixed"

  echo -e "${purple}您当前的git配置为: "
  git config --list

  echo -e "${orange}按下任意键以继续..."
  read -n 1 -s -r
}

function init_pacman
{
  if ! pacman -Q reflector; then
    echo -e "${purple}安装reflector..."
    sudo pacman -S --noconfirm reflector
  fi

  echo -e "${purple}添加国内源:"
  sudo reflector --verbose --country 'China' --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

  if pacman -Q paru; then
    echo -e "${purple}已安装paru!"
  else
    echo -e "${purple} 安装AUR包管理器paru..."
    sudo pacman -S --needed base-devel
    git clone https://aur.archlinux.org/paru.git
    cd paru || echo "${red}无法进入 paru目录"
    makepkg -si
  fi

  echo -e "${purple}请您手动将 Color、ILoveCandy、VerbosePkgLists 添加到/etc/pacman.conf 中的[options] 下"
  echo -e "${purple}请您手动将 BottomUp 添加到/etc/paru.conf 中的[options] 下"

  echo -e "${orange}按下任意键以继续..."
  read -n 1 -s -r
}

function install_zsh
{
  if pacman -Q zsh; then
    echo -e "${purple}已安装zsh..."
  else
    echo -e "${purple}安装zsh..."
    sudo pacman -S --noconfirm zsh
  fi

  echo -e "${purple}您当前使用的shell为 $SHELL"

  if [[ $(basename "$SHELL") != 'zsh' ]]; then
    echo -e "${purple}将 $USER 使用的shell切换为zsh..."
    chsh -s "$(which zsh)"
    echo -e "将 root 使用的shell切换为zsh..."
    sudo chsh -s "$(which zsh)" root
  fi

  if pacman -Q zsh-autosuggestions zsh-fast-syntax-highlighting zsh-completions; then
    echo -e "${purple}zsh插件已安装..."
  else
    echo -e "${purple}安装zsh插件..."
    sudo pacman -S --noconfirm zsh-autosuggestions zsh-completions
    paru -S --noconfirm zsh-fast-syntax-highlighting
  fi

  echo -e "${purple}" "已安装插件: "
  ls /usr/share/zsh/plugins

  echo -e "${orange}按下任意键以继续..."
  read -n 1 -s -r

  if [ -f "$HOME/.zshrc" ]; then
    echo -e "${purple}已存在旧的.zshrc配置文件。您想要备份它还是直接覆盖 ?"
    echo -e "1) 备份后覆盖"
    echo -e "2) 直接覆盖"
    echo -e '请输入您的选择 (1/2): '
    read -r choice

    if [ "$choice" -eq 1 ]; then
      echo -e "${purple}备份旧配置..."
      backup_file_name=".zshrc_$(date +'%Y-%m-%d-%H-%M-%S')"
      mv ~/.zshrc "$HOME/$backup_file_name"
      echo -e "${purple}将.zshrc 文件备份为 $HOME/$backup_file_name..."
      cp -pv ./zsh_config/.zshrc ~/.zshrc
    elif [ "$choice" -eq 2 ]; then
      echo -e "${purple}直接覆盖.zshrc配置文件..."
      cp -pv ./zsh_config/.zshrc ~/.zshrc
    else
      echo -e "${red}无效的选择, 请输入1或2."
    fi
  else
    cp -pv ./zsh_config/.zshrc ~/.zshrc
  fi

  if [ -d "/usr/share/zsh/zsh_scripts" ]; then
    echo -e "${purple}检测到旧的zsh_scripts目录，选择以下操作："
    echo "1. 合并"
    echo "2. 删除旧目录"
    echo "3. 备份旧目录"
    echo "请输入您的选择 (1/2/3): "
    read -r choice

    case $choice in
      1)
        echo -e "${purple}合并目录..."
        sudo cp -rpiv ./zsh_config/zsh_scripts /usr/share/zsh/zsh_scripts
        ;;
      2)
        echo -e "${purple}删除旧目录..."
        sudo rm -rf /usr/share/zsh/zsh_scripts
        sudo cp -rpv ./zsh_config/zsh_scripts /usr/share/zsh/zsh_scripts
        ;;
      3)
        backup_file_name="$(date +'%Y-%m-%d-%H-%M-%S')"
        echo -e "${purple}备份旧目录为 /usr/share/zsh/zsh_scripts_$backup_file_name"
        sudo mv /usr/share/zsh/zsh_scripts "/usr/share/zsh/zsh_scripts_$backup_file_name"
        sudo cp -rpv ./zsh_config/zsh_scripts /usr/share/zsh/zsh_scripts
        ;;
      *)
        echo -e "${purple}无效的选择，退出脚本。"
        exit 1
        ;;
    esac
  else
    sudo cp -rpv ./zsh_config/zsh_scripts /usr/share/zsh/zsh_scripts
  fi
}

function install_cli_tools
{
  local python_packages=('python' 'python-pip')
  local cpp_packages=('gcc' 'clang' 'gdb' 'make' 'cmake' 'ninja' 'boost')
  local dev_packages=('man-db' 'man-pages' 'man-pages-zh_cn')
  local cli_tools=('bat' 'eza' 'fd' 'procs' 'gping' 'fzf' 'ripgrep' 'procs' 'dust' 'duf' 'cloc')

  local fetch=('fastfetch' 'cpufetch')
  paru -S "${cli_tools[@]}"
  paru -S "${dev_packages[@]}"
  paru -S "${cpp_packages[@]}"
  paru -S "${python_packages[@]}"
  paru -S "${fetch[@]}"

  config_dir=$(bat --config-dir)
  if [ ! -d "$config_dir/themes" ]; then
    git clone https://github.com/catppuccin/bat.git "$config_dir/themes"
    bat cache --build
    bat --generate-config-file
    echo '--theme="Catppuccin Latte"' >> "$config_dir/config"
  fi

  echo -e "${purple}"
  echo "执行pacman -Qe命令, 查看您安装的包"
  echo -e "${orange}"
  read -r -p "按回车键继续..."
}

function install_fonts
{

  local fonts=('otf-monaspace' 'otf-monaspace-nerd' 'ttf-lxgw-wenkai')

  paru -S "${fonts[@]}"

  echo -e "${purple}"
  echo "执行pacman -Qe命令, 查看您安装的包"
  echo -e "${orange}"
  read -r -p "按回车键继续..."
}

function install_input_method
{

  local input_method=('fcitx5-im' 'fcitx5-chinese-addons' 'fcitx5-pinyin-moegirl' 'fcitx5-pinyin-zhwiki' 'fcitx5-material-color')

  paru -S "${input_method[@]}"

  echo -e "${purple}"
  echo "执行pacman -Qe命令, 查看您安装的包"
  echo -e "${orange}"
  read -r -p "按回车键继续..."
}

function install_shell_scripts
{
  if [ -d "/usr/share/shell_scripts" ]; then
    echo -e "${purple}检测到旧的shell脚本目录，选择以下操作："
    echo "1. 合并"
    echo "2. 删除旧目录"
    echo "3. 备份旧目录"
    echo "请输入您的选择 (1/2/3): "
    read -r choice

    case $choice in
      1)
        echo -e "${purple}合并目录..."
        sudo cp -rpi ./shell_scripts /usr/share/shell_scripts
        ;;
      2)
        echo -e "${purple}删除旧目录..."
        sudo rm -rf /usr/share/shell_scripts
        sudo cp -rp ./shell_scripts /usr/share/shell_scripts
        ;;
      3)
        backup_file_name="$(date +'%Y-%m-%d-%H-%M-%S')"
        echo -e "${purple}备份旧目录为 /usr/share/zsh/zsh_scripts_$backup_file_name"
        sudo mv /usr/share/shell_scripts "/usr/share/shell_scripts_$backup_file_name"
        sudo cp -rp ./shell_scripts /usr/share/shell_scripts
        ;;
      *)
        echo -e "${purple}无效的选择，退出脚本。"
        exit 1
        ;;
    esac
  else
    sudo cp -rpv ./shell_scripts /usr/share/shell_scripts
  fi

  if [ -d "/usr/share/cheatsheets" ]; then
    echo -e "${purple}检测到旧的cheatsheets目录，选择以下操作："
    echo "1. 合并"
    echo "2. 删除旧目录"
    echo "3. 备份旧目录"
    echo "请输入您的选择 (1/2/3): "
    read -r choice

    case $choice in
      1)
        echo -e "${purple}合并目录..."
        sudo cp -rpi ./cheatsheets /usr/share/cheatsheets
        ;;
      2)
        echo -e "${purple}删除旧目录..."
        sudo rm -rf /usr/share/cheatsheets
        sudo cp -rp ./cheatsheets /usr/share/cheatsheets
        ;;
      3)
        backup_file_name="$(date +'%Y-%m-%d-%H-%M-%S')"
        echo -e "${purple}备份旧目录为 /usr/share/cheatsheets_$backup_file_name"
        sudo mv /usr/share/cheatsheets "/usr/share/cheatsheets_$backup_file_name"
        sudo cp -rp ./cheatsheets /usr/share/cheatsheets
        ;;
      *)
        echo -e "${purple}无效的选择，退出脚本。"
        exit 1
        ;;
    esac
  else
    sudo cp -rpv ./cheatsheets /usr/share/cheatsheets
  fi

  bashrc="$HOME/.bashrc"
  zshrc="$HOME/.zshrc"

  if ! grep -q 'export PATH="$PATH:/usr/share/shell_scripts"' "$bashrc"; then
    echo 'export PATH="$PATH:/usr/share/shell_scripts"' >> "$bashrc"
  fi
  if ! grep -q 'export PATH="$PATH:/usr/share/cheatsheets"' "$bashrc"; then
    echo 'export PATH="$PATH:/usr/share/cheatsheets"' >> "$bashrc"
  fi

  if ! grep -q 'export PATH="$PATH:/usr/share/shell_scripts"' "$zshrc"; then
    echo 'export PATH="$PATH:/usr/share/shell_scripts"' >> "$zshrc"
  fi
  if ! grep -q 'export PATH="$PATH:/usr/share/cheatsheets"' "$zshrc"; then
    echo 'export PATH="$PATH:/usr/share/cheatsheets"' >> "$zshrc"
  fi
}

function set_chinese_locale
{
  sed -i '/^#\(en_US.UTF-8\|zh_CN.UTF-8\)/s/^#//' /etc/locale.gen # Open /etc/locale.gen and uncomment the lines
  sudo locale-gen # Generate locales

  sudo echo "LANG=en_US.UTF-8" > /etc/locale.conf   # Note: It's not recommended to set the global LANG locale to zh_CN.UTF-8 in /etc/locale.conf, as it will cause tofu blocks in TTY without CJK fonts.

  sudo echo "export LC_ALL=zh_CN.UTF-8
  export LANG=zh_CN.UTF-8
  export LANGUAGE=zh_CN:en_US" >> /etc/profile

  sudo pacman -S wqy-microhei # Install wqy-microhei font package
}

while true; do
  echo -e "${purple}请选择要执行的功能:"
  echo "1) 安装并初始化git"
  echo "2) 安装并初始化包管理器"
  echo "3) 安装zsh, zsh插件, 实用zsh脚本"
  echo "4) 安装开发环境和命令行工具"
  echo "5) 安装实用 shell 脚本"
   echo "6) 设置中文locale"
  echo "7) 安装字体"
  echo "8) 安装输入法"
  echo "9) 退出"
  echo -e "${reset}"

  read -r -p "请输入选项 (1-6): " choice
  case $choice in
    1) init_git ;;
    2) init_pacman ;;
    3) install_zsh ;;
    4) install_cli_tools ;;
    5) install_shell_scripts ;;
    6) set_chinese_locale ;;
    7) install_fonts ;;
    8) install_input_method ;;
    9)
      echo -e "${purple}退出程序"
      exit 0
      ;;
    *) echo -e "${purple}无效选项，请重新选择" ;;
  esac
  echo -e "${orange}"
  read -r -p "按回车键继续..."
done
