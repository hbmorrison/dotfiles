#!/bin/bash

# Configuration.

SSH_AUTH_SOCK="${HOME}/.ssh/agent.sock"
LOCAL_SOCKET="UNIX-LISTEN:${SSH_AUTH_SOCK},fork"
WINDOWS_SOCKET="EXEC:npiperelay -ei -s //./pipe/openssh-ssh-agent,nofork"

# Define the socket.

echo "SSH_AUTH_SOCK=${SSH_AUTH_SOCK}" > "${HOME}/.ssh/agent.env"

# Start the agent relay.

if ! pgrep --full --exact --uid="${UID}" "socat ${LOCAL_SOCKET}.*" >/dev/null
then
  rm -f "${SSH_AUTH_SOCK}"
  (setsid nohup socat "${LOCAL_SOCKET}" "${WINDOWS_SOCKET}" >&/dev/null & disown)
fi
