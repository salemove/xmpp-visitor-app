#!/usr/bin/env bash

set -e

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 UserJID Password OperatorJID"
  exit 1
fi

echo "Starting cobrowsing session for you in 2 seconds"
sleep 2

CWD=`pwd`
SOCK_PATH=/tmp/tmate.sock

# Start tmate session
tmate -S $SOCK_PATH new-session -d
tmate -S $SOCK_PATH wait tmate-ready
COBROWSING_LINK=`tmate -S $SOCK_PATH display -p '#{tmate_web}'`

tmate -S $SOCK_PATH send-keys "cd $CWD; ./chat/cli.rb $* $COBROWSING_LINK" Enter
tmate -S $SOCK_PATH split-window "/bin/bash -l"
tmate -S $SOCK_PATH select-layout main-vertical
tmate -S $SOCK_PATH attach-session
