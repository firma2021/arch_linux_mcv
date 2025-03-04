for file in /usr/share/zsh/zsh_scripts/*.zsh; do
  source $file
done

export PATH="$PATH:/usr/share/shell_scripts"
export PATH="$PATH:/usr/share/cheatsheets"
