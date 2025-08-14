# If not running interactively, don't do anything.

case $- in
  *i*) ;;
    *) return;;
esac

# Figure out which OS and terminal is being used.

case $(cat /proc/version 2>/dev/null) in
  MSYS*|MINGW64*)            SHELL_ENVIRONMENT="gitbash";;
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos";;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl";;
  *Debian*)                  SHELL_ENVIRONMENT="debian";;
  *Ubuntu*)                  SHELL_ENVIRONMENT="debian";;
  *Red\ Hat*)                SHELL_ENVIRONMENT="redhat";;
esac

# Work out the location of the system32 directory on Windows.

case $SHELL_ENVIRONMENT in
  wsl)     SYSTEM_DIR="/mnt/c/Windows/System32";;
  gitbash) SYSTEM_DIR="/c/Windows/System32";;
esac

# Don't put duplicate lines or lines starting with space in the history.

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

# Append to the history file, don't overwrite it

shopt -s histappend

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.

shopt -s checkwinsize

# Enable color support.

if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Enable programmable completion features.

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

# cd to git root first then home directory. This overloads the cd command to put
# git root directories onto the directory stack, then pops them out of the
# stack when cd is run with no arguments.

case $SHELL_ENVIRONMENT in

  chromeos|wsl|debian)
    function cd {
      local target_dir next_gitroot prev_gitroot
      # If the target directory exists.
      if target_dir=$(readlink -e "${1}")
      then
        # And if the target directory is inside a git repo.
        if next_gitroot=$(git -C "${target_dir}" rev-parse --show-toplevel 2>/dev/null)
        then
          # Check the previous git root directory from the directory stack. If
          # it is not a parent directory of this git root directory, remove it.
          if prev_gitroot=$(dirs -l +1 2>/dev/null)
          then
            echo "${next_gitroot}" | grep "^${prev_gitroot}." &>/dev/null || popd -n &>/dev/null
          fi
          # Push the git root directory onto the stack.
          pushd -n "${next_gitroot}" &>/dev/null
        fi
      fi
      # Decide how to cd now that the git root directories have been handled.
      if [ $# -gt 0 ]
      then
        # If a directory has been specified, then change to it.
        builtin cd $@
      else
        # If the next directory on the stack is actually the current directory,
        # remove it since cd with no arguments should always go to a parent
        # directory.
        local next_dir=$(dirs -l +1 2>/dev/null)
        if [ "${next_dir}" == "${PWD}" ]
        then
          popd -n &>/dev/null
        fi
        # Pop the next directory from the stack. If that fails there are no
        # more git roots so just use the built in cd to change to the home
        # directory.
        if ! popd &>/dev/null
        then
          builtin cd
        fi
        # If the new working directory is a git root, it will not have been
        # added in the first section of this function since we got here with a
        # bare cd, so add it to the stack.
        if next_gitroot=$(git rev-parse --show-toplevel 2>/dev/null)
        then
          pushd -n "${next_gitroot}" &>/dev/null
        fi
      fi
    }

esac

# Password Manager Pro integration.

case $SHELL_ENVIRONMENT in
  gitbash|wsl)
    if [ -f $HOME/.pmp_api_authtoken ]
    then

      function pmp {
        if [ -z "$PMP_API_AUTHTOKEN" ]
        then
          export PMP_API_AUTHTOKEN=`cat $HOME/.pmp_api_authtoken 2>/dev/null`
        fi
        if [ "$1" = "" -a "$PMP_LASTHOST" != "" ]
        then
          $HOME/bin/pmp_lookup.rb "$PMP_LASTHOST" | $SYSTEM_DIR/clip.exe
        else
          $HOME/bin/pmp_lookup.rb "$1" | $SYSTEM_DIR/clip.exe
        fi
        if [ "$(jobs -s)" != "" ]
        then
          fg
        fi
      }

      function ssh {
        if echo "${1}" | grep '\.'
        then
          local userhost=$1
        else
          local userhost="${1}.is.ed.ac.uk"
        fi
        if [ -z "$PMP_API_AUTHTOKEN" ]
        then
          export PMP_API_AUTHTOKEN=$(cat $HOME/.pmp_api_authtoken 2>/dev/null)
        fi
        $HOME/bin/pmp_lookup.rb $1 2> /dev/null | $SYSTEM_DIR/clip.exe
        PMP_LASTHOST=$1
        $SYSTEM_DIR/OpenSSH/ssh.exe $userhost
      }

    fi
esac

# Tell git to use the real ssh command.

export GIT_SSH_COMMAND="/usr/bin/ssh"

# Set shell prompt colours.

COLOUR_RED='\[\033[00;31m\]'
COLOUR_GREEN='\[\033[00;32m\]'
COLOUR_YELLOW='\[\033[00;33m\]'
COLOUR_PURPLE='\[\033[00;35m\]'
COLOUR_CYAN='\[\033[00;36m\]'
COLOUR_CLEAR='\[\033[00m\]'

# Set up git prompt.

case $SHELL_ENVIRONMENT in
  chromeos|wsl|debian) source /usr/lib/git-core/git-sh-prompt;;
  redhat)              source /usr/share/git-core/contrib/completion/git-prompt.sh;;
esac

# If there are no git prompt helper functions, use this simple one.

if [ -z "$(declare -F __git_ps1 2> /dev/null)" ]
then
  function __git_ps1 {
    local head=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    if [ ! -z ${head:+x} ]
    then
      local merging=$(git rev-parse --quiet --verify MERGE_HEAD 2> /dev/null)
      if [ -n ${merging:+x} ]
      then
        echo " (${head})"
      else
        echo " (${head}|MERGING)"
      fi
    fi
  }
fi

GIT_PROMPT="$COLOUR_CYAN\$(__git_ps1)$COLOUR_CLEAR"

# Set up directory prompt.

case $SHELL_ENVIRONMENT in
  gitbash)
    function __dir_ps1 {
      local gitroot gitparent
      gitroot=$(dirs -l +1 2>/dev/null)
      if gitparent=$(dirname $gitroot 2>/dev/null)
      then
        cygpath -m "${PWD}" | sed "s#^${gitparent}/##"
      else
        cygpath -m "${PWD}" | sed "s#${HOME}#~#"
      fi
    }
    ;;
  *)
    function __dir_ps1 {
      local gitroot gitparent
      gitroot=$(dirs -l +1 2>/dev/null)
      if gitparent=$(dirname $gitroot 2>/dev/null)
      then
        pwd | sed "s#^${gitparent}/##"
      else
        pwd | sed "s#${HOME}#~#"
      fi
    }
    ;;
esac

DIR_PROMPT="$COLOUR_YELLOW\$(__dir_ps1)$COLOUR_CLEAR"

# Make sure the hostname is lowercase.

HOSTNAME=`uname -n | tr '[:upper:]' '[:lower:]'`

# Set up a window title prompt.

TITLE_PROMPT="\[\e]0;\u@${HOSTNAME}\$(__git_ps1) \W\a\]"

# Set the entire prompt.

PS1="${TITLE_PROMPT}${COLOUR_CLEAR}\u@${HOSTNAME}${GIT_PROMPT} ${DIR_PROMPT} \\$ "

# Basic shell aliases.

alias c=clear
alias ls="command ls -F --color=auto"

# Git aliases.

alias br="git branch"
alias bra="git branch -a"
alias brd="git branch -D"
alias ch="git checkout"
alias chd="git checkout develop"
alias chm="git checkout main"
alias chp="git checkout production"
alias cl="git clone"
alias co="git commit"
alias dh="git diff HEAD^"
alias di="git diff"
alias ds="git diff --staged"
alias gsa="git submodule add"
alias gsu="git submodule update --init --recursive"
alias lo="git log"
alias pl="git pull"
alias pu="git push"
alias puo="git push -u origin"
alias st="git status"

alias amend="git commit --amend"
alias fixup="git commit --fixup"

# Git flow aliases.

alias feature="git flow feature"
alias publish="git flow feature publish"
alias bugfix="git flow bugfix"
alias release="git flow release"
alias hotfix="git flow hotfix"
alias support="git flow support"

# Completions for git aliases.

if declare -f __git_complete &>/dev/null
then
  __git_complete brd _git_branch
  __git_complete ch _git_checkout
  __git_complete gsa _git_submodule
  __git_complete gsu _git_submodule
  __git_complete lo _git_log
  __git_complete pu _git_push
  __git_complete puo _git_push
  __git_complete feature __git_flow_feature
  __git_complete bugfix __git_flow_bugfix
  __git_complete release __git_flow_release
  __git_complete hotfix __git_flow_hotfix
  __git_complete support __git_flow_support
fi

# Eyaml aliases for Puppet.

alias pencrypt="eyaml encrypt --quiet --output=block --pkcs7-public-key=$HOME/.local/share/isapps_puppet_public_key.pkcs7.pem --password"
alias fencrypt="eyaml encrypt --quiet --output=block --pkcs7-public-key=$HOME/.local/share/isapps_puppet_public_key.pkcs7.pem --file"

# QMK aliases.

alias qcferris="qmk compile -kb ferris/sweep -e CONVERT_TO=rp2040_ce"

# Open vim with results from fuzzy find.

function vf {
  if [ "$#" -eq 0 ]
  then
    fzf --bind 'start:select-all,ctrl-a:toggle-all,enter:become(vim {+})'
  else
    fzf --bind 'start:select-all,ctrl-a:toggle-all,enter:become(vim {+})' -q "$*"
  fi
}

# Open vim with results from ripgrep search.

function vg {
  rg -l "$*" | xargs -o vim -c "let @/='\<$*\>'" -c "set hls"
}

# Open vim with all files that have git changes.

function vc {
  git status --porcelain | grep -v ^D | cut -c4- | xargs -o vim
}
