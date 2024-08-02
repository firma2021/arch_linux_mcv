#!/usr/bin/env bash

function venv_make
{
  if [[ -z $1 ]]; then
    echo "venv_make: Usage venv_make <venv-name>" 1>&2
    return 1
  fi

  local venv_dir
  if [[ -z $PYTHON_VENV_DIR ]]; then
    venv_dir="$PYTHON_VENV_DIR/$1"
  else
    venv_dir="$HOME/.local/share/virtualenvs/$1"
  fi
  echo "make venv in $venv_dir"

  python3 -m venv "$venv_dir"

  venv_activate "$1"
}

function venv_activate
{
  if [[ -z $1 ]]; then
    echo "venv_activate: Usage venv_activate venv-name" 1>&2
    return 1
  fi

  local venv_dir
  if [[ -z $PYTHON_VENV_DIR ]]; then
    venv_dir="$PYTHON_VENV_DIR/$1"
  else
    venv_dir="$HOME/.local/share/virtualenvs/$1"
  fi

  if [[ ! -d $venv_dir ]]; then
    echo "venv_activate: $1 must be a directory " 1>&2
    return 1
  fi

  echo "activate venv in $venv_dir"

  source "${1}venv_dir/bin/activate"
}

function pip_update
{
  pip3 list --outdated | cut -d ' ' -f1 | xargs -n1 pip3 install -U # xargs -n1:将前面的参数逐个传给后面的命令
}

function pip_list
{
  pip list
}

function python_clean
{
  find "${@:-.}" -type f -name "*.py[co]" -delete
  find "${@:-.}" -type d -name "__pycache__" -delete
  find "${@:-.}" -depth -type d -name ".mypy_cache" -exec rm -r "{}" +
  find "${@:-.}" -depth -type d -name ".pytest_cache" -exec rm -r "{}" +
}
