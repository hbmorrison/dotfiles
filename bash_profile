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

pathadd () {
  if [ -n "$1" ]
  then
    REMOVED=$(/bin/echo ":$PATH:" | /bin/sed "s#:$1:#:#")
    if [ "$REMOVED" = ":$PATH:" ]
    then
      PATH=$PATH:$1
    fi
  fi
}

pathadd "/usr/sbin"
pathadd "/opt/puppetlabs/sbin"
pathadd "${HOME}/bin"
pathadd "${HOME}/.local/bin"

# Connect to an ssh-agent.

case $SHELL_ENVIRONMENT in
  wsl)
    export SSH_AUTH_SOCK=/tmp/wincrypt-hv.sock
    if ! ss -lnx | grep -q $SSH_AUTH_SOCK
    then
      rm -f $SSH_AUTH_SOCK
      LOCAL_SOCKET="UNIX-LISTEN:${SSH_AUTH_SOCK},fork"
      WINDOWS_SOCKET="SOCKET-CONNECT:40:0:x0000x33332222x02000000x00000000"
      (setsid nohup socat $LOCAL_SOCKET $WINDOWS_SOCKET >&/dev/null & disown)
    fi
    ;;
  *)
    AGENT_ENV="${HOME}/.ssh/agent-env"
    source $AGENT_ENV &>/dev/null
    if ! ss -lnx | grep -q $SSH_AUTH_SOCK
    then
      ssh-agent >$AGENT_ENV
      chmod 600 $AGENT_ENV
    fi
    source $AGENT_ENV &>/dev/null
esac

# Start gpg-agent.

export GPG_TTY=$(/bin/tty)
export GPG_AGENT_INFO="${HOME}/.gnupg/agent-env"

# Source the bashrc.

if [ -r "${HOME}/.bashrc" ]
then
  source $HOME/.bashrc
fi
