#!/usr/bin/env bash

# Given a desktop with nodes, simulate user action by resending each node from 
# a temporary desktop.
# This will trigger the algorithm running in the listener process

source "$ROOT/lib/desktop.sh";
source "$ROOT/lib/bspc.sh";
source "$ROOT/handlers/runtime_globals.sh";
# source "$ROOT/handlers/dump.sh";

# Note: This needs a sleep between sending each node because:
# 1. The listener needs to be able restore orientation
# 2. Reduce screen flashing
# $1: The path containing the leaves to send
# $2: The desktop under replay
_send_leaves_reversed_back_to_desktop(){
    for leaf in $(query_leaves_reversed $1); do
        # echo "Sending leaf [$leaf] from [$1] to [$2]";
        send_node_to_desktop $leaf $2;
        sleep 0.2;
    done
}

_replay(){
    local desktop_tmp="BSPTMP";
    bspc monitor -a $desktop_tmp;

    # Capture master to regain focus
    local masterid="$(get_node $MASTER)";

    # Move root to a temp desktop
    send_node_to_desktop "$DESKTOP/" $desktop_tmp;

    # Return to sender: First the stack, than the remaining master
    _send_leaves_reversed_back_to_desktop "@$desktop_tmp:/$STACK_POSITION" $DESKTOPNAME;
    _send_leaves_reversed_back_to_desktop "@$desktop_tmp:/" $DESKTOPNAME;

    # echo "Removing temporary desktop";
    bspc desktop $desktop_tmp -r;
    # echo "Regain focus";
    focus_node $masterid;
}

# Replay global variables
DESKTOPNAME="$1"; shift; 
set_runtime_globals "$1"; shift;
# dump;

_replay;
