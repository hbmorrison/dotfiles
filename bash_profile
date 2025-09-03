# Figure out which OS and terminal is being used.

case $(cat /proc/version 2>/dev/null) in
  MSYS*|MINGW64*)            SHELL_ENVIRONMENT="gitbash";;
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos";;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl";;
  *Debian*)                  SHELL_ENVIRONMENT="debian";;
  *Ubuntu*)                  SHELL_ENVIRONMENT="debian";;
  *Red\ Hat*)                SHELL_ENVIRONMENT="redhat";;
esac

# Set local home directory if a roaming profile is in use.

case $SHELL_ENVIRONMENT in
  gitbash)
    PROFILEDRIVE=`echo $USERPROFILE | cut -d'\' -f1`
    if [ "$PROFILEDRIVE" != "$HOMEDRIVE" ]
    then
      export HOME=`cygpath $USERPROFILE`
      cd
    fi
esac

# Change to home directory if the shell starts in the root directory.

if [ "${PWD}" == "/" ]
then
  cd $HOME
fi

# Set the default editor.

export EDITOR=vi
export VISUAL=vi
export LESS=-FRSX

# Set the default fzf options.

export FZF_DEFAULT_OPTS="-0 -1 --multi --keep-right --border=none --info=hidden \
  --bind start:select-all,ctrl-a:toggle-all \
  --color=bg+:-1,fg+:-1,prompt:-1,pointer:-1,hl:111,hl+:111 \
  --prompt='$ ' --pointer='>' --marker='*'"

# Set the Proxmox backup repository.

export PBS_REPOSITORY=client@pbs@pbs-remote.gerbil-koi.ts.net:u457113.your-storagebox.de

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
    pathadd "/opt/puppetlabs/sbin"
    pathadd "/usr/sbin"
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
  chromeos|debian|redhat)
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
    if [ $? -ne 0 ]
    then
      rm -f $SSH_AUTH_SOCK
      (setsid nohup socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork SOCKET-CONNECT:40:0:x0000x33332222x02000000x00000000 >/dev/null 2>&1 & disown)
    fi
    ;;
  gitbash)
    export SSH_AUTH_SOCK=`cygpath -w "${HOME}/wincrypt-cygwin.sock"`
    unset GIT_SSH_COMMAND
    ;;
esac

# Load the default ssh key if it does not already appear in the agent.

for key in $(basename -s .pub ${HOME}/.ssh/*.pub)
do
  case $key in
    id_rsa|id_ecdsa|id_ecdsa_sk|id_ed25519|id_ed25519_sk)
      ssh-add -T "${HOME}/.ssh/${key}" &>/dev/null || ssh-add "${HOME}/.ssh/${key}"
  esac
done

# Source the bashrc.

if [ -r "${HOME}/.bashrc" ]
then
  source $HOME/.bashrc
fi
