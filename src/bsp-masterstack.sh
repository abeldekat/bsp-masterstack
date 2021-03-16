#!/usr/bin/env bash
# Design: A stateless frontend providing interaction with desktop processes listening in the background.

export VERSION="{{VERSION}}";
# export ROOT="{{SOURCE_PATH}}";
export ROOT="$HOME/builds/bsp-masterstack/src";

source "$ROOT/lib/desktop.sh";
source "$ROOT/lib/state.sh"; 

GUARD="$ROOT/standalone/bsp-guard.sh";
MASTERLISTENER="$ROOT/listeners/masterlistener.sh";
DUMMY_PID_FOR_GUARD="DUMMY";

# $1 The optional desktop argument
# Get desktop argument or return the name of the focused desktop
_get_desktop_argument(){
    local result="$1";
    [[ -z "$result" ]] && result=$(get_focused_desktop);
    echo "$result";
}

# $1 The focused desktop
# $2 The optional desktop argument supplied by user
# This function can be used if the focused desktop is already retrieved
_return_focused_desktop_or_argument(){
    local result="$1";
    [[ -n "$2" ]] && result="$2";
    echo "$result";
}

# Returns the orientation which the listener has registered 
_get_orientation_or_use_west(){
    local orientation="$(get_desktop_options "$1" | valueof orientation)";
    [[ -z $orientation ]] && orientation=$DIR_WEST;
    echo $orientation;
}

# Returns the processid which the listener has registered
_get_listener_process(){
    echo "$(get_desktop_options "$1" | valueof pid)";
}

# Returns the fifo for the focused desktop
# Returns nothing if there is no process
_get_fifo_for_focused_desktop(){
    local desktop_name="$(get_focused_desktop)";
    echo "$(get_desktop_fifo $desktop_name)";
}

# Kills the process
_kill_process(){
    local pid=$1;
    [[ $DUMMY_PID_FOR_GUARD != $pid ]] && kill $pid 2> /dev/null || true;
}

# $1 The focused desktop
# $2 The target desktop
# Echo true if 
# 1. focused desktop is not equal to target desktop
# 2. focused desktop has no proces running
_is_invoked_from_unguarded_desktop(){
    local result=false;
    if [[ $1 != $2 ]]; then
        [[ -z "$(_get_listener_process $1)" ]] && result=true;
    fi
    echo $result;
}

# $1 The focused desktop
# $2 The target desktop
# Echo true if 
# 1. the target desktop contains at least two leaves
# 2. script is invoked from another desktop which is unguarded
_should_also_be_guarded(){
    local focused_name=$1;
    local desktop_name=$2;
    local result=false;
    $(has_master $desktop_name) && \
        "$(_is_invoked_from_unguarded_desktop $focused_name $desktop_name)" && \
        result=true;
    echo $result;
}

# Kill existing process for the destkop
# Triggers GUARD to refresh and stop if there are no more desktops to guard
stop(){
    local desktop_name="$(_get_desktop_argument $1)";
    local pid="$(_get_listener_process $desktop_name)";
    [[ -n pid ]] && _kill_process $pid;

    set_desktop_option $desktop_name 'pid' "";
    bash $GUARD;
}

# Activates listener maintaining state on a specific desktop.
# Explicitly takes into account global settings towards an unfocused desktop
start(){
    local focused_name="$(get_focused_desktop)";
    local desktop_name="$(_return_focused_desktop_or_argument $focused_name $1)";
    local running_pid="$(_get_listener_process $desktop_name)";
    [[ -n $running_pid ]] && _kill_process $running_pid;

    # Does desktop $focused_name also needs guarding?
    local guard_dummy="$(_should_also_be_guarded $focused_name $desktop_name)";

    # Announce intention for a new listener to the guard... 
    set_desktop_option $desktop_name 'pid' "$DUMMY_PID_FOR_GUARD";
    $guard_dummy && set_desktop_option $focused_name 'pid' "$DUMMY_PID_FOR_GUARD";
    bash $GUARD;

    # Start listener
    local orientation="$(_get_orientation_or_use_west $desktop_name)";
    # echo "Start listener for [$desktop_name] using [$orientation]";
    bash $MASTERLISTENER $desktop_name $orientation &

    # Administer listener
    local LISTENER_PID=$!;
    disown;
    set_desktop_option $desktop_name 'pid' "$LISTENER_PID";

    # Flush global settings back to default if necessary
    $guard_dummy && stop $focused_name;

    # Inform the user
    echo "[$LISTENER_PID]";
}

# Use case: Send a node from stack to master.
# Use case: Swap master with top of the stack.
zoom(){
    local dfifo="$(_get_fifo_for_focused_desktop)";
    [[ -p $dfifo ]] && echo "zoom" > "$dfifo";
}

# Use case: User requires a different orientation.
# West is default. Other orientations are north, east and south
rotate(){
    local dfifo="$(_get_fifo_for_focused_desktop)";
    [[ -p $dfifo ]] && echo "rotate" > "$dfifo";
}

# Use case: Inspect runtime state
dump(){
    local dfifo="$(_get_fifo_for_focused_desktop)";
    [[ -p $dfifo ]] && echo "dump" > "$dfifo";
}

# Check for dependencies
for dep in bspc man tac bc; do
    !(which $dep >/dev/null 2>&1) && echo "[Missing dependency] bsp-masterstack needs $dep installed" && exit 1;
done;

# Note: Parameter desktop needs to be in classic style
action=$1; shift;
case "$action" in
    start)      start "$1" ;;
    stop)       stop "$1" ;;
    zoom)       zoom ;;
    rotate)     rotate ;;
    dump)       dump ;;
    help)       man bsp-masterstack ;;
    version)    echo "$VERSION" ;;
    *)          echo -e "Unknown subcommand. Run bsp-masterstack help" && exit 1 ;;
esac
