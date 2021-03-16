#!/usr/bin/env bash

# On ps -ef | grep "bsp" the following processes will be visible
# 1. A (parent 1) Main process, saved by the caller  
# 2. B (parent A) Reads and handles commands from queue
# 3. C (parent A) Reads bwpm events, this is the last statement in the script
# 4. D (parent C) bspc subscribe, process substitution

source "$ROOT/lib/state.sh";
source "$ROOT/lib/desktop.sh";
source "$ROOT/lib/bspc.sh";
source "$ROOT/handlers/config.sh";
source "$ROOT/handlers/runtime_globals.sh";
source "$ROOT/handlers/transform.sh";
source "$ROOT/handlers/orientation.sh";
source "$ROOT/handlers/master.sh";
source "$ROOT/handlers/dump.sh";
source "$ROOT/handlers/zoom.sh";
source "$ROOT/handlers/on_event.sh";

# The command listener needs to be killed explicitly
_on_kill_main_process(){
    # Remove process id from state
    set_desktop_option $DESKTOPNAME 'pid' "";
    # echo "[$$} Main process killed, kill command process [$COMMAND_PID]...";
    kill $COMMAND_PID 2> /dev/null | true;
}

# If the command listener is killed than also remove the queue
_on_kill_command_process(){
    # echo "[$$] Command process killed, remove queue(fifo)...";
    rm -f "$THIS_DESKTOP_QUEUE";
}

# The desktop id in the events do not always share the same position
_find_desktop_id_in_event(){
    local desktop_id="";
    if [[ "$1" == "node_transfer" ]]; then
        [[ "$3" != "$6" ]] && desktop_id="$6";
    else
        desktop_id="$3";
    fi;
    echo $desktop_id;
}

# Bspc events are marked as relevant when: 
# Event target desktop equals this desktop
# On node_transfer:
# Event src desktop does not equal this desktop
_should_add_event(){
    local result=false;
    local desktop_id="$(_find_desktop_id_in_event $@)";
    if [[ -n "$desktop_id" ]]; then
        local desktop_name_event=$(get_desktop_name_from_id "$desktop_id");
        [[ "$desktop_name_event" == "$DESKTOPNAME" ]] && result=true;
    fi;
    echo $result;
}

# Executes commands
_execute_command(){
    cmd=$1; shift;
    # echo "[$$] Execute command $cmd";

    case "$cmd" in
      node_add) on_node_add "$@" ;;
      node_remove) on_node_remove "$@" ;;
      node_transfer) on_node_transfer "$@" ;;
      zoom) zoom ;;
      rotate) change_orientation ;;
      dump) dump ;;
      *) ;;
    esac;
}

# Reads and handles all commands aimed at this desktop
# The command queue needs to be closed and removed on exit
_listen_for_commands(){
    trap "_on_kill_command_process" EXIT;
    # echo "[$$] Start listening for commands";

    [[ ! -p $THIS_DESKTOP_QUEUE ]] && mkfifo $THIS_DESKTOP_QUEUE;
    while true; do 
        if read -r -a line; then
            _execute_command ${line[@]};
        fi
    done < "$THIS_DESKTOP_QUEUE"
}

# Read bspwm events
# When aimed at this desktop: Write to command queue
_listen_for_events(){
    trap "_on_kill_main_process" EXIT;
    local subscriptions=(node_add node_remove node_transfer);
    # echo "[$$] Start listening for events ${subscriptions[*]}";

    while read -r -a line; do
        if "$(_should_add_event ${line[@]})"; then
            echo "${line[*]}" > "$THIS_DESKTOP_QUEUE";
        fi;
    done < <(bspc subscribe ${subscriptions[*]})
}

# Global variables
DESKTOPNAME="$1"; shift; 
# Globals are based on orientation 
set_runtime_globals "$1"; shift;

# Start listening for commands: user commands and selected bspwm events
THIS_DESKTOP_QUEUE="$(get_desktop_fifo $DESKTOPNAME)";
_listen_for_commands &
COMMAND_PID=$!;
# echo "[$$] Command pid is [$COMMAND_PID]";

# Transform an existing desktop if needed
transform_if_needed;

# Start listening for bspwm events for this desktop
_listen_for_events
