#!/usr/bin/env bash
export VERSION="{{VERSION}}";

# export ROOT="{{SOURCE_PATH}}";
export ROOT="$HOME/builds/bsp-masterstack/src";

source "$ROOT/utils/common.sh";
source "$ROOT/utils/desktop.sh";
source "$ROOT/utils/state.sh";

GUARD="$ROOT/bsp-guard.sh";
MASTERLISTENER="$ROOT/listeners/masterlistener.sh";

# $1: The path containing the leaves to send
# $2: The receiving desktop
_send_all_leaves_from_path_reversed_to_desktop(){
    for anode in $(bspc query -N $1 -n .descendant_of.leaf | tac); do
        # echo "Sending node $anode";
        bspc node $anode -d $2; 
    done
}

# TODO For now: the stack is fixed. Code needs to be moved!
# TODO Start listener if it does not exist
# Use case: User has an existing layout and wants to start using this adapter
# Sends root to a temporary desktop. Returns the leafs to the selected desktop
# $1 desktopname if supplied
# Command
replay(){
    local desktop_name="$(_get_desktop_argument $1)";
    # echo "Start replaying $desktop_name";

    # Capture master to regain focus
    local master="$(bspc query -N -n @/1)";

    # Move root to a temp desktop
    local desktop_tmp="BSPTMP";
    bspc monitor -a $desktop_tmp;
    bspc node "@$desktop_name:/" -d $desktop_tmp;

    # Return to sender: First the stack, than the remaining master
    _send_all_leaves_from_path_reversed_to_desktop "@$desktop_tmp:/2" $desktop_name;
    _send_all_leaves_from_path_reversed_to_desktop "@$desktop_tmp:/" $desktop_name;
    bspc desktop $desktop_tmp -r;

    # Regain focus
    [[ -n $master ]] && bspc node -f $master;
}

# Get desktop argument or revert to focussed
_get_desktop_argument(){
    local result="$1";
    [[ "$result" == "--" ]] && result="";
    [[ -z "$result" ]] && result=$(get_focused_desktop);
    echo "$result";
}

_get_adapter_process() {
    echo "$(get_desktop_options "$1" | valueof pid)";
}

_kill_adapter_process() {
    local old_pid=$1;
    [[ -n $old_pid ]] && kill $old_pid;
}

# Kill old process and remove saved state
# Removes desktop from GUARD. GUARD stops if there are no more desktops
# Command
stop() {
    local desktop_name="$(_get_desktop_argument $1)";
    local old_pid="$(_get_adapter_process $desktop_name)";
    _kill_adapter_process $old_pid;
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

    bash $MASTERLISTENER $desktop_name;
}

# Use case: Send a node from stack to master.
# Use case: Swap master with top of the stack.
# Command
zoom(){
    local desktop_name="$(_get_desktop_argument $1)";
    bash "$(get_adapter_file)" $desktop_name "zoom" 2> /dev/null || true;
}

# Check for dependencies
for dep in bspc man tac; do
    !(which $dep >/dev/null 2>&1) && echo "[Missing dependency] bsp-dynamic needs $dep installed" && exit 1;
done;

# Note: Parameter desktop needs to be in classic style
action=$1; shift;
case "$action" in
    start)      start "$@" ;;
    stop)       stop "$1" ;;
    zoom)       zoom "$1" ;;
    replay)     replay "$1" ;;
    help)       man bspwm-dynamic ;;
    version)    echo "$VERSION" ;;
    *)          echo -e "Unknown subcommand. Run bspwm-dynamic help" && exit 1 ;;
esac
