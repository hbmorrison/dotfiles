# If not running interactively, don't do anything.

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

# Work out the location of the system32 directory on Windows.

SYSTEM_DIR="/mnt/c/Windows/System32"

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

# Change directory to git root first then home directory.

function cd {
  if [ $# -eq 0 ]
  then
    local gitroot
    if gitroot=$(git rev-parse --show-toplevel 2>/dev/null)
    then
      if [ "${gitroot}" != "${PWD}" ]
      then
        builtin cd "${gitroot}"
      else
        builtin cd
      fi
    else
      builtin cd
    fi
  else
    builtin cd "$@"
  fi
}

# Password Manager Pro integration.

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
    command ssh $userhost
  }

fi

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

if ! declare -F __git_ps1 &>/dev/null
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

function __dir_ps1 {
  local gitroot unixgitroot
  if gitroot=$(git rev-parse --show-toplevel 2>/dev/null)
  then
    pwd | sed "s#^$(dirname "${gitroot}")/##"
  else
    pwd | sed "s#${HOME}#~#"
  fi
}

DIR_PROMPT="$COLOUR_YELLOW\$(__dir_ps1)$COLOUR_CLEAR"

# Make sure the hostname is lowercase.

HOSTNAME=`uname -n | tr '[:upper:]' '[:lower:]'`

# Set up a window title prompt.

TITLE_PROMPT="\[\e]0;\u@${HOSTNAME}\$(__git_ps1) \W\a\]"

# Set the entire prompt.

PS1="${TITLE_PROMPT}${COLOUR_CLEAR}\u@${HOSTNAME}${GIT_PROMPT} ${DIR_PROMPT} \\$ "

# Basic shell aliases.

alias c=clear
alias ls="LC_COLLATE=C command ls -F --color=auto"
alias more=less

# Git aliases.

alias br="git branch"
alias bra="git branch -a"
alias ch="git checkout"
alias chd="git checkout develop"
alias chm="git checkout main"
alias chp="git checkout production"
alias co="git commit"
alias coa="git commit -a"
alias dh="git diff HEAD^"
alias di="git diff"
alias ds="git diff --staged"
alias fe="git fetch"
alias gsa="git submodule add"
alias gsu="git submodule update --recursive"
alias lo="git log --no-merges"
alias pl="git pull"
alias pu="git push"
alias st="git status"
alias amend="git commit --amend"
alias fixup="git commit --fixup"

# Git flow aliases.

alias fb="git branch -a | grep feature-"
alias fc="git flow feature checkout"
alias ff="git flow feature finish -S"
alias fp="git flow feature publish"
alias fs="git flow feature start"
alias ft="git flow feature track"

# Re-declare bash completion functions for git flow branch lookups to allow wildcards.

if declare -F __git_flow_init &>/dev/null
then

  function __git_flow_list_local_branches () {
    if [ -n "$1" ]; then
        local prefix="$(__git_flow_prefix $1)";
        git for-each-ref --shell --format="ref=%(refname:short)" refs/heads/$prefix\* | while read -r entry; do
            eval "$entry";
            ref="${ref#$prefix}";
            echo "$ref";
        done | sort;
    else
        git for-each-ref --format="ref=%(refname:short)" refs/heads/ | sort;
    fi
  }

  function __git_flow_list_remote_branches () {
    if [ -n "$1" ]; then
        local prefix="$(__git_flow_prefix $1)";
        local origin="$(git config gitflow.origin 2> /dev/null || echo "origin")";
        git for-each-ref --shell --format="ref=%(refname:short)" refs/remotes/$origin/$prefix\* | while read -r entry; do
            eval "$entry";
            ref="${ref#$origin/$prefix}";
            echo "$ref";
        done | sort;
    else
        git for-each-ref --format="ref=%(refname:short)" refs/heads/ | sort;
    fi
  }

fi

# Completions for git aliases.

if declare -f __git_complete &>/dev/null
then

  __git_complete brd _git_branch
  __git_complete ch _git_checkout
  __git_complete co _git_commit
  __git_complete fe _git_fetch
  __git_complete gsa _git_submodule
  __git_complete gsu _git_submodule
  __git_complete lo _git_log
  __git_complete pu _git_push

  # Only complete git flow shortcuts if bash completion for git flow is present.

  if declare -F __git_flow_init &>/dev/null
  then

    __git_complete feature __git_flow_feature
    __git_complete bugfix __git_flow_bugfix
    __git_complete release __git_flow_release
    __git_complete hotfix __git_flow_hotfix
    __git_complete support __git_flow_support

    # Add completion functions for git flow feature checkout, publish and
    # finish. These mirror what appears in the case statement in the
    # __git_flow_feature completion function for each command.

    function __git_flow_feature_checkout () {
      __gitcomp_nl "$(__git_flow_list_local_branches 'feature')";
      return
    }

    function __git_flow_feature_finish () {
      case "$cur" in
        --*)
          __gitcomp "
            --nofetch --fetch
            --norebase --rebase
            --nopreserve-merges --preserve-merges
            --nokeep --keep
            --keepremote
            --keeplocal
            --noforce_delete --force_delete
            --nosquash --squash
            --no-ff
          ";
          return
          ;;
      esac;
      __gitcomp_nl "$(__git_flow_list_local_branches 'feature')";
      return
    }

    function __git_flow_feature_publish () {
      __gitcomp_nl "$(__git_flow_list_local_branches 'feature')";
      return
    }

    function __git_flow_feature_track () {
      __gitcomp_nl "$(__git_flow_list_remote_branches 'feature')";
      return
    }

    __git_complete fc __git_flow_feature_checkout
    __git_complete ff __git_flow_feature_finish
    __git_complete fp __git_flow_feature_publish
    __git_complete ft __git_flow_feature_track

  fi

fi

# Eyaml aliases for Puppet.

alias pencrypt="eyaml encrypt --quiet --output=block --pkcs7-public-key=$HOME/.local/share/isapps_puppet_public_key.pkcs7.pem --password"
alias fencrypt="eyaml encrypt --quiet --output=block --pkcs7-public-key=$HOME/.local/share/isapps_puppet_public_key.pkcs7.pem --file"

# QMK aliases.

alias qcferris="qmk compile -kb ferris/sweep -e CONVERT_TO=rp2040_ce"

# Open vim with results from fuzzy find in buffers.

function vf {
  if [ "$#" -eq 0 ]
  then
    fzf --bind 'start:select-all,ctrl-a:toggle-all,enter:become(vim {+})'
  else
    fzf --bind 'start:select-all,ctrl-a:toggle-all,enter:become(vim {+})' -q "$*"
  fi
}

# Open vim with a list of modified files in the quickfix list.

alias vm="vim -q <(git ls-files -m)"

# Open vim with results from ripgrep search in the quickfix list.

function vg {
  vim -c "let @/='\<$*\>'" -c "set hls" -q <(rg --vimgrep --smart-case "$*")
}
