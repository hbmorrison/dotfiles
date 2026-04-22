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

# Set HOME if this is root.

if [ `id -u` -eq 0 ]
then
  export HOME=/root
fi

# Additional paths.

pathprepend () {
  if [ -n "${1}" ]
  then
    REMOVED=$(/bin/echo ":${PATH}" | /bin/sed "s#:${1}##")
    PATH="${1}${REMOVED}"
  fi
}

pathappend () {
  if [ -n "$1" ]
  then
    REMOVED=$(/bin/echo "${PATH}:" | /bin/sed "s#${1}:##")
    PATH="${REMOVED}${1}"
  fi
}

pathprepend "/usr/sbin"
pathprepend "/usr/bin"
pathprepend "${HOME}/.local/bin"
pathappend  "/opt/puppetlabs/sbin"

# Set the default editor.

export EDITOR=vi
export VISUAL=vi

# Tidy up less output.

export LESS=-FRX
export LESSHISTFILE=-

# Use gpg for ssh agent.

export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR/%\/}/openssh_agent"

# Don't put duplicate lines or lines starting with space in the history.

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

# Set the default fzf options.

export FZF_DEFAULT_OPTS="-0 -1 --multi --keep-right --border=none --info=hidden \
  --bind start:select-all,ctrl-a:toggle-all \
  --color=bg+:-1,fg+:-1,prompt:-1,pointer:-1,hl:111,hl+:111 \
  --prompt='$ ' --pointer='>' --marker='*'"

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
  local gitroot
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

# Source the bashrc.

if [ -r "${HOME}/.bashrc" ]
then
  source $HOME/.bashrc
fi
