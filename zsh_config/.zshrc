export ZSH_DOT_DIR="/usr/share/zsh"
export ZSH_PLUGIN_DIR="$ZSH_DOT_DIR/plugins"

for file in $ZSH_DOT_DIR/zsh_scripts/*.zsh; do
  source $file
done

source /usr/local/bin/greeting.sh

# source /usr/share/autojump/autojump.zsh
