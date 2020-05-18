#!/usr/bin/dumb-init /bin/bash

if [ -z "$PULSE_COOKIE_DATA" ]; then
    echo -ne $(echo $PULSE_COOKIE_DATA | sed -e 's/../\\x&/g') >$HOME/pulse.cookie
    export PULSE_COOKIE=$HOME/pulse.cookie
fi

SUPERVISE_INTERVAL=2
# supervise <unitname> your command string 
function supervise() {
  local _unit=$1
  shift
  local _cmd=$@
  while sleep $SUPERVISE_INTERVAL; do
    # run command
    exec ${_cmd}&
    local _pid=$!
    # Drop pid to manage process
    echo $_pid > /tmp/${_unit}.pid
    # Resume waiting for process
    tail --pid $_pid -f /dev/null
    echo "Restarting ${_unit}.."
  done
}

/tokenize.sh
exec "$@"
