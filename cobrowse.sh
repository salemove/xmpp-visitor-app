#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 UserJID Password OperatorJID"
  exit 1
fi

echo "Starting cobrowsing session for you in 2 seconds"
sleep 2

CWD=`pwd`

tmux new-session '/bin/bash -l'\; \
     send-keys "cd $CWD" Enter\; \
     send-keys "./chat/cli.rb $*" Enter\; \
     split-window '/bin/bash -l'\; \
     select-layout main-vertical

#tmux new-session "./chat/cli.rb $*" \; \
#     split-window '/bin/bash -l'\; \
#     select-layout main-vertical
