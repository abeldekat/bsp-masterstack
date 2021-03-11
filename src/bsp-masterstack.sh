#!/usr/bin/env bash
# Design: A stateless frontend providing interaction with desktop processes listening in the background.

export VERSION="{{VERSION}}";
# export ROOT="{{SOURCE_PATH}}";
export ROOT="$HOME/builds/bsp-masterstack/src";

source "$ROOT/lib/desktop.sh";
source "$ROOT/lib/state.sh";

GUARD="$ROOT/standalone/bsp-guard.sh";
REPLAY="$ROOT/standalone/replay.sh";

MASTERLISTENER="$ROOT/listeners/masterlistener.sh";

# Get desktop argument or return the name of the focused desktop
_get_desktop_argument(){
    local result="$1";
    [[ "$result" == "--" ]] && result="";
    [[ -z "$result" ]] && result=$(get_focused_desktop);
    echo "$result";
}
# Returns the orientation which the listener has registered 
_get_orientation_or_use_west(){
    local orientation="$(get_desktop_options "$1" | valueof orientation)";
    [[ -z $orientation ]] && orientation=$DIR_WEST;
    echo $orientation;
}
# Returns the processid which the listener has registered
_get_listener_process() {
    echo "$(get_desktop_options "$1" | valueof pid)";
}

# Kill old process and remove saved state
# Removes desktop from GUARD. GUARD stops if there are no more desktops
stop() {
    local desktop_name="$(_get_desktop_argument $1)";
    local old_pid="$(_get_listener_process $desktop_name)";
    [[ -n $old_pid ]] && kill $old_pid;
    set_desktop_option $desktop_name 'pid' "";

    bash $GUARD;
}

# Activates listener maintaining a specific desktop.
# Does nothing if a process for that desktop is already running
start() {
    local desktop_name="$(_get_desktop_argument $1)";
    local old_pid="$(_get_listener_process $desktop_name)";
    [[ -n $old_pid ]] && return;
    
    # Announce intention for a new listener to guard... 
    set_desktop_option $desktop_name 'pid' "DUMMY";
    bash $GUARD;

    local orientation="$(_get_orientation_or_use_west $desktop_name)";
    # echo "Start listener for [$desktop_name] using [$orientation]";
    bash $MASTERLISTENER $desktop_name $orientation;
}

# Use case: Correct or transform an existing desktop
# Only operates if desktop has an active listener
replay(){
    local desktop_name="$(get_focused_desktop)";
    if [[ -z "$(_get_listener_process $desktop_name)" ]]; then
        echo "Replay: No listener is active on desktop $desktop_name";
        return;
    fi

    local orientation="$(_get_orientation_or_use_west $desktop_name)";

    # echo "Start replay on desktop [$desktop_name]";
    # echo "Orientation is [$orientation]";
    bash $REPLAY $desktop_name $orientation;
}

# Use case: Send a node from stack to master.
# Use case: Swap master with top of the stack.
zoom(){
    local desktop_name="$(get_focused_desktop)";
    echo "zoom" > "$(get_desktop_fifo $desktop_name)" 2> /dev/null || true;
}

# Use case: User requires a different orientation.
# West is default. Other orientations are north, east and south
rotate(){
    local desktop_name="$(get_focused_desktop)";
    echo "rotate" > "$(get_desktop_fifo $desktop_name)" 2> /dev/null || true;
}

# Use case: Inspect runtime state
dump(){
    local desktop_name="$(get_focused_desktop)";
    echo "dump" > "$(get_desktop_fifo $desktop_name)" 2> /dev/null || true;
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
