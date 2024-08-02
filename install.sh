#!/usr/bin/env bash
set -o nounset
set -o pipefail

# ANSI 颜色代码，24位真彩色,38表示前景色，2表示真彩色，中间的3位是RGB, 最后的1表示粗体
orange="\033[38;2;255;102;0;1m"
red='\033[38;2;255;0;0;1m'
purple='033[38;2;63;13;164;1m'
reset="\033[0m"

function make_a_choice
{
  echo -e "$purple$1" # 输出提示信息

  local timeout=10

  echo -e "$orange"

  for ((i = timeout; i > 0; --i)); do

    printf "\r按任意键确认 (%d seconds left) " $i

    if read -r -t 1 -n 1; then
      echo ""
      return 0
    fi
  done

  echo -e "$reset"

  return 1
}

if wait_for_input; then
  echo "Input received"
else
  echo "No input received within the timeout"
fi

function install_zsh
{
  echo -e "$orange"

  if pacman -Q zsh; then
    echo -e "已安装zsh..."
  else
    echo -e "安装zsh..."
    sudo pacman -S --noconfirm zsh
  fi

  if pacman -Q zsh-autosuggestions zsh-fast-syntax-highlighting zsh-completions zsh-history-substring-search; then
    echo -e "zsh插件已安装..."
  else
    echo -e "安装zsh插件..."
    sudo pacman -S --noconfirm zsh-autosuggestions zsh-completions zsh-history-substring-search
    yay -S --noconfirm zsh-fast-syntax-highlighting
  fi

  echo -e "${purple}" "已安装插件: "
  ls /usr/share/zsh/plugins

  echo -e "您当前使用的shell为 $SHELL"

  if [[ $(basename "$SHELL") != 'zsh' ]]; then
    echo -e "${orange}将 $USER 使用的shell切换为zsh..."
    echo -e "将 root 使用的shell切换为zsh..."
    chsh -s "$(which zsh)"
    sudo chsh -s "$(which zsh)" root
  fi
  echo -e "${purple}您当前使用的shell为 $SHELL"

  if [ -f "$HOME/.zshrc" ]; then
    if make_a_choice '已存在旧的.zshrc配置文件, 是否备份旧配置?'; then
      backup_file_name=".zshrc_$(date +'%Y-%m-%d-%H-%M-%S')"
      echo -e "${orange}将.zshrc 文件备份为 $HOME/$backup_file_name..."
      cp ~/.zshrc "$HOME/$backup_file_name"

      backup_file_name="zsh_$(date +'%Y-%m-%d-%H-%M-%S')"
      echo -e "将/usr/share/zsh/zsh_scripts备份为 /usr/share/zsh_scripts/$backup_file_name"
      sudo cp -r -v /usr/share/zsh/zsh_scripts "/usr/share/zsh_scripts/$backup_file_name"
    fi
    rm -rf ~/.zshrc
    sudo rm -rf /usr/share/zsh/zsh_scripts
  fi

  echo -e "${orange}复制zsh配置文件..."
  cp -r -v ./zsh_config/.zshrc ~/.zshrc
  if [ ! -d /usr/share/zsh ]; then
    sudo mkdir /usr/share/zsh
  fi
  sudo cp -r -v ./zsh_config/zsh_scripts /usr/share/zsh/zsh_scripts
}

function install_cli_tools
{
  local python_packages=('python' 'python-pip')
  local cpp_packages=('gcc' 'clang-git' 'gdb' 'make' 'cmake' 'ninja' 'boost')
  local dev_packages=('man-db' 'man-pages')
  local cli_tools=('bat' 'eza' 'fd' 'procs' 'gping' 'fzf' 'ripgrep' 'procs' 'dust' 'duf' 'lf' 'choose' 'sd' 'zoxide' 'fastfetch')

  sudo pacman -S "${cli_tools[@]}"
  sudo pacman -S "${dev_packages[@]}"
  sudo pacman -S "${cpp_packages[@]}"
  sudo pacman -S "${python_packages[@]}"

  function setup_bat_theme
  {
    local bat_dir="$HOME/bat"

    # Check if bat directory exists
    if [ -d "$bat_dir" ]; then
      echo "Updating existing bat repository..."
      cd "$bat_dir"
      git pull
    else
      echo "Cloning bat repository..."
      git clone https://github.com/catppuccin/bat.git "$bat_dir"
    fi

    # Create the themes directory
    mkdir -p "$(bat --config-dir)/themes"

    # Copy the theme files
    cp *.tmTheme "$(bat --config-dir)/themes"

    # Build the bat cache
    bat cache --build

    # Export the BAT_THEME environmental variable
    echo 'export BAT_THEME="Catppuccin-mocha"' >> ~/.bashrc
    echo 'export BAT_THEME="Catppuccin-mocha"' >> ~/.zshrc

    # Reload the shell configuration
    source ~/.bashrc
    source ~/.zshrc
  }
  setup_bat_theme
  config_dir=$(bat --config-dir)
  if [ ! -d "$config_dir/themes" ]; then
    git clone https://github.com/catppuccin/bat.git "$config_dir/themes"
    bat cache --build
    bat --generate-config-file
    echo '--theme="Catppuccin Latte"' >> "$config_dir/config"
  fi

  make_a_choice "执行pacman -Qe命令, 查看您安装的包"
}

function init_git
{

  if ! git config user.name; then
    read -r -p "请输入您的 Git 用户名称: " USER_NAME # -r将\视为普通字符
    git config --global user.name "$USER_NAME"
  fi

  if ! current_user_email; then
    read -r -p "请输入您的 Git 邮箱地址: " USER_EMAIL
    git config --global user.email "$USER_EMAIL"
  fi

  branch_name=$(git config --global --get init.defaultBranch)
  blue_print "您当前的全局默认分支名为$branch_name"

  if [[ $branch_name == 'master' ]]; then
    blue_print "将git的默认分支名从master改为main..."
    git config --global init.defaultBranch main
  fi

  blue_print "您当前的git配置为: "
  git config --list

  read -p "Press any key to continue... " -n 1 -s -r
  echo
}

function init_install
{
  local mirror="[archlinuxcn]"
  local server='Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch'
  local pacman_conf="/etc/pacman.conf"

  if grep -Fxq "$mirror" "$pacman_conf"; then # 检查是否已经存在相同的镜像配置
    echo -e "pacman.conf中已存在待添加的镜像"
    return
  else
    echo -e "将 $mirror 添加到$pacman_conf ..."
  fi

  echo -e "\n$mirror\n$server" | sudo tee -a "$pacman_conf" > /dev/null # tee -a :将标准输入的内容追加到一个文件中
  echo -e "镜像添加完成"

  red_echo "软件包维护者使用私钥对软件包进行签名，你需要下载公钥来验证软件包的来源"
  echo -e "删除旧的密钥环境..."
  sudo rm -rf /etc/pacman.d/gnupg
  sync
  echo -e "初始化pacman密钥环境..."
  sudo pacman-key --init
  sync
  echo -e "更新pacman密钥环境..."
  sudo pacman-key --populate archlinux
  sync
  echo -e "安装ArchLinux密钥环..."
  sudo pacman -Sy --noconfirm archlinux-keyring
  sync
  echo -e "安装ArchLinuxCN密钥环..."
  sudo pacman -Sy --noconfirm archlinuxcn-keyring
  sync
  echo -e "更新系统中所有软件包..."
  sudo pacman -Syyu --noconfirm --disable-download-timeout

  echo -e "将git的默认分支名从master改为main..."
  git config --global init.defaultBranch main

  if pacman -Q git; then
    echo -e "已安装git..."
  else
    echo -e "安装git..."
    sudo pacman -S --noconfirm zsh
  fi

  echo -e "${orange} 安装包管理器paru..."
  sudo pacman -S --needed base-devel
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si

  pacman_conf='/etc/pacman.conf'

  if grep -q "^Color$" "$pacman_conf"; then
    :
  elif grep -q "^#Color$" "$pacman_conf"; then
    sudo sed -i 's/^#Color$/Color/' "$pacman_conf"
  else
    echo "Color" >> "$pacman_conf"
  fi

  if ! grep -q '\[archlinuxcn\]' $pacman_conf; then
    sudo sed -i '$a\[archlinuxcn\]' $pacman_conf
    sudo sed -i '$aServer = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch' $pacman_conf

    sudo pacman-key --lsign-key "farseerfc@archlinux.org"
    sudo pacman -Sy archlinuxcn-keyring --noconfirm
  fi

  if pacman -Q paru; then
    blue_print "已安装paru..."
  else
    blue_print "安装paru..."
    sudo pacman -S --noconfirm paru
  fi

  paru_conf='/etc/paru.conf'
  if grep -q "^BottomUp$" "$paru_conf"; then
    :
  elif grep -q "^#BottomUp$" "$paru_conf"; then
    sudo sed -i 's/^#BottomUp$/BottomUp/' "$paru_conf"
  else
    :
  fi

  # grep -q: 不输出匹配行，只返回退出状态码
  # grep -c: count
  # sed -i:直接操作源文件。 $a:在文件末尾追加
  # \[：转义[
}

function install_shell_scripts
{
  for file in ./shell_scripts/*.sh; do
    sudo cp -v -i "$file" /usr/local/bin/
  done
}

blue_print '将RTC时间（Real Time Clock time，即BIOS时间）与系统时间同步'
timedatectl set-local-rtc 1
timedatectl status

echo '添加国内源:'
sudo reflector --verbose --country 'China' --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

#  echo "请您在 konsole设置 > 配置konsole > 配置方案 > 新建 > 外观 中，应用您刚才选择的主题"
#   echo "重启konsole后主题才会生效"
#   read -p "输入任意键以继续..." -n 1
plugin_clone 'zsh-users/zsh-syntax-highlighting' 'zsh-users/zsh-autosuggestions' 'zsh-users/zsh-history-substring-search' 'zsh-users/zsh-completions'
