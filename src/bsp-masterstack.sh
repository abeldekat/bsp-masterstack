#!/usr/bin/env bash
# Design: A stateless frontend providing interaction with desktop processes listening in the background.

export VERSION="{{VERSION}}";
# export ROOT="{{SOURCE_PATH}}";
export ROOT="$HOME/builds/bsp-masterstack/src";

source "$ROOT/utils/desktop.sh";
source "$ROOT/utils/state.sh";

GUARD="$ROOT/bsp-guard.sh";
MASTERLISTENER="$ROOT/listeners/masterlistener.sh";

# Get desktop argument or use focussed
_get_desktop_argument(){
    local result="$1";
    [[ "$result" == "--" ]] && result="";
    [[ -z "$result" ]] && result=$(get_focused_desktop);
    echo "$result";
}

_get_adapter_process() {
    echo "$(get_desktop_options "$1" | valueof pid)";
}

# Kill old process and remove saved state
# Removes desktop from GUARD. GUARD stops if there are no more desktops
# Command
stop() {
    local desktop_name="$(_get_desktop_argument $1)";
    local old_pid="$(_get_adapter_process $desktop_name)";
    [[ -n $old_pid ]] && kill $old_pid;
    remove_desktop_options $desktop_name;

    bash $GUARD;
}

# Activates listener maintaining a specific desktop.
# If a process for the desktop is already running no action is taken.
# Command
start() {
    local desktop_name="$(_get_desktop_argument $1)";
    local old_pid="$(_get_adapter_process $desktop_name)";
    [[ -n $old_pid ]] && return;
    
    # Announce intention for a new listener to guard... 
    set_desktop_option $desktop_name 'pid' "";
    bash $GUARD;

    bash $MASTERLISTENER $desktop_name $DIR_WEST;
}

# Use case: Send a node from stack to master.
# Use case: Swap master with top of the stack.
# Command
zoom(){
    local desktop_name="$(get_focused_desktop)";
    echo "zoom" > "$(get_desktop_fifo $desktop_name)" 2> /dev/null || true;
}

rotate(){
    local desktop_name="$(get_focused_desktop)";
    echo "rotate" > "$(get_desktop_fifo $desktop_name)" 2> /dev/null || true;
}

dump(){
    local desktop_name="$(get_focused_desktop)";
    echo "dump" > "$(get_desktop_fifo $desktop_name)" 2> /dev/null || true;
}

replay(){
    # local desktop_name="$(get_focused_desktop)";
    # local old_pid="$(_get_adapter_process $desktop_name)";
    # [[ -z $old_pid ]] && start;

    # echo "replay" > "$(get_desktop_fifo $desktop_name)" 2> /dev/null || true;
    echo "Todo replay";
}

# Check for dependencies
for dep in bspc man tac; do
    !(which $dep >/dev/null 2>&1) && echo "[Missing dependency] bsp-masterstack needs $dep installed" && exit 1;
done;

# Note: Parameter desktop needs to be in classic style
action=$1; shift;
case "$action" in
    start)      start "$1" ;;
    stop)       stop "$1" ;;
    zoom)       zoom ;;
    rotate)     rotate ;;
    replay)     replay ;;
    dump)       dump ;;
    help)       man bsp-masterstack ;;
    version)    echo "$VERSION" ;;
    *)          echo -e "Unknown subcommand. Run bsp-masterstack help" && exit 1 ;;
esac
