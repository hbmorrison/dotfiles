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

# Start SSH agent relay on WSL.

case $SHELL_ENVIRONMENT in
  wsl)
    if ! systemctl --user is-enabled ssh-agent-relay.service &>/dev/null
    then
      systemctl --user daemon-reload \
       && systemctl --user enable ssh-agent-relay.service \
       && systemctl --user start ssh-agent-relay.service
      source $AGENT_ENV &>/dev/null
    fi
    source "${HOME}/.ssh/agent.env" &>/dev/null
    ;;
  *)
    if systemctl --user is-enabled ssh-agent-relay.service &>/dev/null
    then
      systemctl --user daemon-reload \
       && systemctl --user stop ssh-agent-relay.service \
       && systemctl --user disable ssh-agent-relay.service
    fi
esac

# Tell GPG which tty this session is running on.

export GPG_TTY=$(/bin/tty)

# Set the default editor.

export EDITOR=vi
export VISUAL=vi
export LESS=-FRX
export LESSHISTFILE=-

# Set the default fzf options.

export FZF_DEFAULT_OPTS="-0 -1 --multi --keep-right --border=none --info=hidden \
  --bind start:select-all,ctrl-a:toggle-all \
  --color=bg+:-1,fg+:-1,prompt:-1,pointer:-1,hl:111,hl+:111 \
  --prompt='$ ' --pointer='>' --marker='*'"

# Source the bashrc.

if [ -r "${HOME}/.bashrc" ]
then
  source $HOME/.bashrc
fi
