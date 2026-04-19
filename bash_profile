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

# Location of the ssh agent environment.

AGENT_ENV="${HOME}/.ssh/agent.env"
source $AGENT_ENV &>/dev/null

# Start the ssh agent if needed.

case $SHELL_ENVIRONMENT in
  wsl)
    if ! systemctl --user is-enabled ssh-agent-relay.service &>/dev/null
    then
      systemctl --user daemon-reload \
       && systemctl --user enable ssh-agent-relay.service \
       && systemctl --user start ssh-agent-relay.service
      source $AGENT_ENV &>/dev/null
    fi
    ;;
  *)
    if ! ss -lnx | grep -q $SSH_AUTH_SOCK
    then
      ssh-agent >$AGENT_ENV
      chmod 600 $AGENT_ENV
      source $AGENT_ENV &>/dev/null
    fi
esac

# Let sub-processes know about the SSH socket.

export SSH_AUTH_SOCK

# Source the bashrc.

if [ -r "${HOME}/.bashrc" ]
then
  source $HOME/.bashrc
fi
