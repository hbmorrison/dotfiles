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

# Set the default editor.

export EDITOR=vi
export VISUAL=vi
export LESS=-FRX

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

if [ "${SHELL_ENVIRONMENT}" == "wsl" ]
then
  export SSH_AUTH_SOCK=/tmp/wincrypt-hv.sock
  ss -lnx | grep -q $SSH_AUTH_SOCK
  if [ $? -ne 0 ]
  then
    rm -f $SSH_AUTH_SOCK
    (setsid nohup socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork SOCKET-CONNECT:40:0:x0000x33332222x02000000x00000000 >/dev/null 2>&1 & disown)
  fi
else
  AGENT_ENV=$HOME/.ssh/agent-env
  if [ -f "$AGENT_ENV" ]
  then
    source $AGENT_ENV > /dev/null
  fi
  AGENT_RUN_STATE=$(ssh-add -l >& /dev/null; echo $?)
  if [ -z "$SSH_AUTH_SOCK" -o $AGENT_RUN_STATE -gt 1 ]
  then
    ssh-agent > $AGENT_ENV
    chmod 600 $AGENT_ENV
    source $AGENT_ENV > /dev/null
  fi
fi

# Source the bashrc.

if [ -r "${HOME}/.bashrc" ]
then
  source $HOME/.bashrc
fi
