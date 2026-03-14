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

# Location of the ssh agent environment.

AGENT_ENV="${HOME}/.ssh/agent.env"
source $AGENT_ENV &>/dev/null

# Start the ssh agent if needed.

case $SHELL_ENVIRONMENT in
  wsl)
    if ! systemctl --user is-enabled ssh-agent-relay.service
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

# Start gpg-agent.

export GPG_TTY=$(/bin/tty)
export GPG_AGENT_INFO="${HOME}/.gnupg/agent-env"

# Source the bashrc.

if [ -r "${HOME}/.bashrc" ]
then
  source $HOME/.bashrc
fi
