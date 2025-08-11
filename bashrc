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

# cd to git root first then home directory.

case $SHELL_ENVIRONMENT in

  chromeos|wsl|debian)
    # Overload cd to put git root directories onto the directory stack.
    function cd {
      local target_dir next_gitroot prev_gitroot
      # If the target directory exists.
      if target_dir=$(readlink -e "${1}")
      then
        # And if the target directory is inside a git repo.
        if next_gitroot=$(git -C "${target_dir}" rev-parse --show-toplevel 2>/dev/null)
        then
          # Pop the previous git root directory from the directory stack if it
          # is not a parent directory of this git root directory.
          if prev_gitroot=$(dirs -l +1 2>/dev/null)
          then
            echo "${next_gitroot}" | grep "^${prev_gitroot}." &>/dev/null || popd -n &>/dev/null
          fi
          # Push the next git root directory onto the stack.
          pushd -n "${next_gitroot}" &>/dev/null
        fi
      fi
      # Decide how to cd now that the git root directories have been handled.
      if [ $# -gt 0 ]
      then
        builtin cd $@
      else
        if ! popd &>/dev/null
        then
          builtin cd
        fi
      fi
    }

esac

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

export PROMPT_COLOUR_RED='\[\033[00;31m\]'
export PROMPT_COLOUR_GREEN='\[\033[00;32m\]'
export PROMPT_COLOUR_YELLOW='\[\033[00;33m\]'
export PROMPT_COLOUR_PURPLE='\[\033[00;35m\]'
export PROMPT_COLOUR_CYAN='\[\033[00;36m\]'
export PROMPT_COLOUR_CLEAR='\[\033[00m\]'

# Set up git prompt.

case $SHELL_ENVIRONMENT in
  chromeos|wsl|debian) source /usr/lib/git-core/git-sh-prompt;;
  redhat)              source /usr/share/git-core/contrib/completion/git-prompt.sh;;
esac

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

GIT_PROMPT="$PROMPT_COLOUR_CYAN\$(__git_ps1)$PROMPT_COLOUR_CLEAR"

# Set up directory prompt.

case $SHELL_ENVIRONMENT in
  gitbash)
    function __dir_ps1 {
      local gitroot=$(git rev-parse --show-toplevel 2>/dev/null | sed 's#[^/][^/]*$##')
      if [ "${gitroot}" != "" ]
      then
        cygpath -m $PWD | sed "s#^${gitroot}##"
      else
        echo "$PWD" | sed "s#${HOME}#~#"
      fi
    }
    ;;
  *)
    function __dir_ps1 {
      local gitroot=$(git rev-parse --show-toplevel 2>/dev/null | sed 's#[^/][^/]*$##')
      if [ "${gitroot}" != "" ]
      then
        echo $PWD | sed "s#^${gitroot}##"
      else
        echo "$PWD" | sed "s#${HOME}#~#"
      fi
    }
    ;;
esac

DIR_PROMPT="$PROMPT_COLOUR_YELLOW\$(__dir_ps1)$PROMPT_COLOUR_CLEAR"

# Set up the submodule prompt

function __sub_ps1 {
  if [ "${parentgitroot}" != "" ]
  then
    echo "(s) "
  fi
}

SUB_PROMPT="$PROMPT_COLOUR_PURPLE\$(__sub_ps1)$PROMPT_COLOUR_CLEAR"

# Make sure the hostname is lowercase.

HOSTNAME=`uname -n | tr '[:upper:]' '[:lower:]'`

# Set up a window title prompt.

TITLE_PROMPT="\[\e]0;\u@${HOSTNAME}\$(__git_ps1) \W\a\]"

# Set the entire prompt.

PS1="${TITLE_PROMPT}${debian_chroot:+($debian_chroot)}${PROMPT_COLOUR_CLEAR}\u@${HOSTNAME}${GIT_PROMPT} ${SUB_PROMPT}${DIR_PROMPT} \\$ "

# Completions for git aliases.

if [ -s /usr/share/bash-completion/completions/git ]
then
  __git_complete ch _git_checkout
fi

# Shell aliases.

alias c=clear
alias ls="command ls -F --color=auto"
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

# Eyaml aliases for Puppet.

alias pencrypt="eyaml encrypt --quiet --output=block --pkcs7-public-key=$HOME/.local/share/isapps_puppet_public_key.pkcs7.pem --password"
alias fencrypt="eyaml encrypt --quiet --output=block --pkcs7-public-key=$HOME/.local/share/isapps_puppet_public_key.pkcs7.pem --file"

# Git aliases.

alias br="git branch"
alias bra="git branch -a"
alias ch="git checkout"
alias chd="git checkout develop"
alias chm="git checkout main"
alias chp="git checkout production"
alias cl="git clone"
alias co="git commit -a"
alias dh="git diff HEAD^"
alias di="git diff"
alias ds="git diff --staged"
alias fe="git fetch"
alias gsa="git submodule add"
alias gsu="git submodule update --init --recursive"
alias lo="git log"
alias pl="git pull"
alias pu="git push"
alias st="git status"

# Git flow aliases.

alias feature="git flow feature"
alias publish="git flow feature publish"
alias bugfix="git flow bugfix"
alias release="git flow release"
alias hotfix="git flow hotfix"
alias support="git flow support"
