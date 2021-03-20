#!/usr/bin/env bash
# Design: A stateless frontend providing interaction with desktop processes listening in the background.
# Start and stop can be invoked from an unfocused desktop( example: bspwmrc ). All other commands act on a focused desktop.

export VERSION="{{VERSION}}";
# export ROOT="{{SOURCE_PATH}}";
export ROOT="$HOME/builds/bsp-masterstack/src";

source "$ROOT/lib/desktop.sh";
source "$ROOT/lib/state.sh"; 

GUARD="$ROOT/standalone/bsp-guard.sh";
MASTERLISTENER="$ROOT/listeners/masterlistener.sh";
DUMMY_PID_FOR_GUARD="DUMMY";

# Kills the process if there is a pid
_kill_process(){
    local pid=$1;
    if [[ -n $pid ]]; then
        kill $pid 2> /dev/null || true;
    fi
}

# $1 The optional desktop argument
# Get desktop argument or return the name of the focused desktop
_get_desktop_argument(){
    local result="$1";
    [[ -z "$result" ]] && result=$(get_focused_desktop);
    echo "$result";
}

# $1 The optional desktop argument supplied by user
# $2 The focused desktop
# This function can be used if the focused desktop is already known
_argument_or_focused_desktop(){
    local result="$2";
    [[ -n "$1" ]] && result="$1";
    echo "$result";
}

# Returns the orientation which the listener has registered 
# Defaults to west
_get_orientation_or_west(){
    local orientation="$(get_desktop_options "$1" | valueof orientation)";
    [[ -z $orientation ]] && orientation=$DIR_WEST;
    echo $orientation;
}

# Returns the fifo used for passing commands to the focused desktop
_get_fifo_for_focused_desktop(){
    local desktop="$(get_focused_desktop)";
    echo "$(get_command_fifo $desktop)";
}

# Returns the fifo used for obtaining results from desktopname $1
_open_and_return_reply_fifo(){
    local reply_fifo="$(get_reply_fifo "$1")";
    [[ ! -p $reply_fifo ]] && mkfifo $reply_fifo;
    echo "$reply_fifo";
}

# Listens on fifo for a reply from the desktop process
# $1 The fifo
_wait_for_reply(){
    local reply_fifo=$1;
    while true; do
        if read answer; then
            if [[ "$answer" == "$READY_REPLY" ]]; then
                break;
            fi
        fi
    done < "$reply_fifo"
}

# $1 The target desktop
# $2 The focused desktop
# Echo true if 
# 1. the script is invoked from another desktop
# 1. that desktop is unguarded and thus acts under default global settings
_should_caller_be_guarded(){
    local desktop=$1;
    local fdesktop=$2;
    local result=false;
    if [[ $desktop != $fdesktop ]]; then
        [[ -z "$(get_pid $fdesktop)" ]] && result=true;
    fi
    echo $result;
}

# $1 Target desktop
# $2 Focused desktop
# Sets dummy pid for desktop
# Sets dummy pid on focused desktop if necessary
# Echo true if focused desktop must also be guarded, false otherwise
_guard_prepare(){
    local desktop=$1;
    local fdesktop=$2;

    local guard_caller="$(_should_caller_be_guarded $desktop $fdesktop)";

    # Indicate a new process to the guard... 
    save_pid $desktop "$DUMMY_PID_FOR_GUARD";
    if "$guard_caller"; then
        #  focused has invoked desktop and is not guarded
        save_pid $fdesktop "$DUMMY_PID_FOR_GUARD";
    fi
    echo $guard_caller;
}

# Kill existing process for the destkop
# Triggers GUARD to refresh and stop if there are no more desktops to guard
stop(){
    local desktop="$(_get_desktop_argument $1)";
    _kill_process "$(get_pid $desktop)";
    clear_pid $desktop;

    bash $GUARD;
}

# Activates listener maintaining state on a specific desktop.
# Explicitly takes into account global settings towards an unfocused desktop
start(){
    local fdesktop="$(get_focused_desktop)";
    local desktop="$(_argument_or_focused_desktop $1 $fdesktop)";

    # echo "Existing process administration";
    local running_pid="$(get_pid $desktop)";
    [[ -n $running_pid ]] && \
        echo "[$desktop]: Already runs on pid [$running_pid]" && return;

    # echo "Prepare guard"
    local guards_caller="$(_guard_prepare $desktop $fdesktop)"; 

    # echo "Trigger guard and start listener for [$desktop]";
    local reply_fifo="$(_open_and_return_reply_fifo $desktop)";
    bash $GUARD;
    bash $MASTERLISTENER $desktop \
        "$(_get_orientation_or_west $desktop)" $reply_fifo &

    # echo "Process administration";
    local LISTENER_PID=$!;
    disown;
    save_pid $desktop "$LISTENER_PID";

    # echo "Wait for process initialization to finish";
    _wait_for_reply $reply_fifo;

    # echo "Guard: release global settings if applicable";
    $guards_caller && clear_pid $fdesktop && bash $GUARD;

    echo "[$LISTENER_PID]";
}

# Use case 1: Send a node from stack to master and send master to top of stack
# Use case 2: Swap master with top of the stack
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

# Use case: Resets all windows in desktop to default size
# Uses equalize and balance
equalize(){
    local dfifo="$(_get_fifo_for_focused_desktop)";
    [[ -p $dfifo ]] && echo "equalize" > "$dfifo";
}

# Use case: Increment master section with one window
increment(){
    local dfifo="$(_get_fifo_for_focused_desktop)";
    [[ -p $dfifo ]] && echo "increment" > "$dfifo";
}

# Use case: Decrement master section with one window
decrement(){
    local dfifo="$(_get_fifo_for_focused_desktop)";
    [[ -p $dfifo ]] && echo "decrement" > "$dfifo";
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
    equalize)   equalize ;;
    increment)  increment ;;
    decrement)  decrement ;;
    dump)       dump ;;
    help)       man bsp-masterstack ;;
    version)    echo "$VERSION" ;;
    *)          echo -e "Unknown subcommand. Run bsp-masterstack help" && exit 1 ;;
esac
