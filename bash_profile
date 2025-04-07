# Figure out which OS and terminal is being used.

case $(cat /proc/version 2>/dev/null) in
  MSYS*|MINGW64*)            SHELL_ENVIRONMENT="gitbash";;
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos";;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl";;
  *Ubuntu*)                  SHELL_ENVIRONMENT="debian";;
  *Red\ Hat*)                SHELL_ENVIRONMENT="redhat";;
esac

# Set local home directory if a roaming profile is in use.

if [ "${SHELL_ENVIRONMENT}" = "gitbash" ]
then
  PROFILEDRIVE=`echo $USERPROFILE | cut -d'\' -f1`
  if [ "$PROFILEDRIVE" != "$HOMEDRIVE" ]
  then
    export HOME=`cygpath $USERPROFILE`
    cd
  fi
fi

# Change to home directory if the shell starts in the root directory.

if [ "${PWD}" == "/" ]
then
  cd $HOME
fi

# Set the default editor.

export EDITOR=vi
export VISUAL=vi

# Additional paths.

pathadd () {
  if [ -n "$1" ]
  then
    REMOVED=$(echo ":$PATH:" | sed "s#:$1:#:#")
    if [ "$REMOVED" = ":$PATH:" ]
    then
      PATH=$PATH:$1
    fi
  fi
}

case $SHELL_ENVIRONMENT in
  chromeos|debian)
    pathadd "/usr/sbin"
    pathadd "${HOME}/bin"
    pathadd "${HOME}/.local/bin"
    ;;
  wsl|redhat)
    pathadd "/usr/sbin"
    pathadd "/opt/puppetlabs/sbin"
    pathadd "${HOME}/bin"
    pathadd "${HOME}/.local/bin"
    ;;
  gitbash)
    pathadd "/c/ProgramData/chocolatey/bin"
    pathadd "/c/Program Files/Git/cmd"
    pathadd "/c/HashiCorp/Vagrant/bin"
    pathadd "/c/Program Files/Puppet Labs/Puppet/bin"
    pathadd "/c/Program Files (x86)/Nmap"
    pathadd "/c/Program Files/Microsoft VS Code/bin"
    PATHADD_RUBY=$(/bin/ls -1d /c/tools/ruby* 2> /dev/null | tail -1)
    if [ "${PATHADD_RUBY}" != "" ]
    then
      pathadd "${PATHADD_RUBY}/bin"
    fi
    pathadd "${HOME}/bin"
    ;;
esac

# Connect to an ssh-agent.

case $SHELL_ENVIRONMENT in
  chromeos|redhat)
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
    ;;
  wsl)
    export SSH_AUTH_SOCK=/tmp/wincrypt-hv.sock
    ss -lnx | grep -q $SSH_AUTH_SOCK
    if [ $? -ne 0 ]; then
      rm -f $SSH_AUTH_SOCK
      (setsid nohup socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork SOCKET-CONNECT:40:0:x0000x33332222x02000000x00000000 >/dev/null 2>&1 & disown)
    fi
    ;;
  gitbash)
    export SSH_AUTH_SOCK=`cygpath -w "${HOME}/wincrypt-cygwin.sock"`
    unset GIT_SSH_COMMAND
    ;;
esac

# Source the bashrc.

if [ -r "${HOME}/.bashrc" ]
then
  source $HOME/.bashrc
fi
