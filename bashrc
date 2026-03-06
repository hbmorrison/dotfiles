
case $- in
  *i*) ;;
    *) return;;
esac

# Figure out which shell environment is being used.

if [ -f /etc/os-release ]
then
  source /etc/os-release
  SHELL_ENVIRONMENT=$ID
fi

# Deal with special cases.

case $(/bin/cat /proc/version 2>/dev/null) in
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos";;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl";;
esac

# Don't put duplicate lines or lines starting with space in the history.

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

# Append to the history file.

shopt -s histappend

# Check the window size after each command and, if necessary, update the values
# of LINES and COLUMNS.

shopt -s checkwinsize

# Enable color support.

if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Enable completion features.

if ! shopt -oq posix
then
  if [ -f /usr/share/bash-completion/bash_completion ]
  then
    source /usr/share/bash-completion/bash_completion
    if [ -f /usr/share/bash-completion/completions/git ]
    then
      source /usr/share/bash-completion/completions/git
    fi
    if [ -f /usr/share/bash-completion/completions/git-flow ]
    then
      source /usr/share/bash-completion/completions/git-flow
    fi
  elif [ -f /etc/bash_completion ]
  then
    source /etc/bash_completion
  fi
fi

# Change directory to git root first then home directory.

function gitroot {
  local gr=""
  for dir in ${1//\// }
  do
    local path+="/${dir}"
    [ -r "${path}/.git" ] && gr="${path}"
  done
  echo "${gr}"
}

function lastgitroot {
  for dir in ${1//\// }
  do
    local path+="/${dir}"
    [ -r "${path}/.git" ] && echo "${path}" && break
  done
}

function cd {
  if [ $# -eq 0 ]
  then
    local parent=$(dirname "${PWD}")
    builtin cd $(gitroot "${parent}") >/dev/null
  else
    builtin cd "$@" >/dev/null
  fi
  CDPATH="$(lastgitroot "${PWD}")"
}

# Basic shell aliases.

alias c=clear
alias ls="LC_COLLATE=C command ls -F --color=auto"

# Source optional bashrc scripts_

if [ -r "${HOME}/.bashrc_prompt" ]
then
  source $HOME/.bashrc_prompt
fi

if [ -r "${HOME}/.bashrc_aliases" ]
then
  source $HOME/.bashrc_aliases
fi

if [ -r "${HOME}/.bashrc_wsltools" ]
then
  source $HOME/.bashrc_wsltools
fi
