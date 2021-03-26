#!/usr/bin/env bash

# On ps -ef | grep "bsp" the following processes will be visible
# 1. A (parent 1) Main process, saved by the caller  
# 2. B (parent A) Reads and handles commands from queue
# 3. C (parent A) Reads bwpm events, this is the last statement in the script
# 4. D (parent C) bspc subscribe, process substitution

source "$ROOT/lib/state.sh";
source "$ROOT/lib/desktop.sh";
source "$ROOT/lib/bspc.sh";
#
source "$ROOT/handlers/config.sh";
source "$ROOT/handlers/runtime_globals.sh";
source "$ROOT/handlers/dump.sh";
source "$ROOT/handlers/master.sh";
source "$ROOT/handlers/transform.sh";
source "$ROOT/handlers/rotate.sh";
source "$ROOT/handlers/equalize.sh";
#
source "$ROOT/handlers/increment_stack.sh";
source "$ROOT/handlers/zoom.sh";
source "$ROOT/handlers/on_event.sh";

# The command listener needs to be killed explicitly
_on_kill_main_process(){
    # Remove process id from state
    clear_pid $DESKTOPNAME;
    # echo "[$$} Main process killed, kill command process [$COMMAND_PID]...";
    kill $COMMAND_PID 2> /dev/null | true;
}

# If the command listener is killed than also remove the fifos
_on_kill_command_process(){
    # echo "[$$] Command process killed, remove fifos...";
    rm -f "$THIS_FIFO";
    rm -f "$THIS_REPLY_FIFO";
}

# The desktop id in the events do not always share the same position
# Can return an empty string in case node_transfer originates from this desktop
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
        local desktop=$(get_desktop_name_from_id "$desktop_id");
        [[ "$desktop" == "$DESKTOPNAME" ]] && result=true;
    fi;
    echo $result;
}

# Executes commands
_execute_command(){
    local cmd=$1; shift;
    case "$cmd" in
      node_add) on_node_add "$@" ;;
      node_remove) on_node_remove "$@" ;;
      node_transfer) on_node_transfer "$@" ;;
      zoom) zoom ;;
      rotate) rotate_to_new_orientation ;;
      equalize) equalize ;;
      increment) increment ;;
      decrement) decrement ;;
      dump) dump ;;
      acknowledge) transform_if_needed; _acknowledge ;;
      *) ;;
    esac;
}

# Reads and handles all commands aimed at this desktop
_listen_for_commands(){
    trap "_on_kill_command_process" EXIT;

    while true; do 
        if read -r -a line; then
            _execute_command ${line[@]};
        fi
    done < "$THIS_FIFO"
}

# Read bspwm events
# When aimed at this desktop: Write to command queue
_listen_for_events(){
    trap "_on_kill_main_process" EXIT;
    local subscriptions=(node_add node_remove node_transfer);

    while read -r -a line; do
        if "$(_should_add_event ${line[@]})"; then
            echo "${line[*]}" > "$THIS_FIFO";
        fi;
    done < <(bspc subscribe ${subscriptions[*]})
}

# Acknowledges to the caller that the listener is ready
_acknowledge(){
        echo "$READY_REPLY" > "$THIS_REPLY_FIFO";
}

# Global variables
DESKTOPNAME="$1"; shift;
# Globals are based on orientation 
set_runtime_globals "$1"; shift;
# Fifo
THIS_REPLY_FIFO="$1"; shift;
THIS_FIFO="$(get_command_fifo $DESKTOPNAME)";
[[ ! -p $THIS_FIFO ]] && mkfifo $THIS_FIFO;

# Start listening for commands
_listen_for_commands &
COMMAND_PID=$!;

# Transform an existing desktop if needed and acknowledge to caller
echo "acknowledge" > "$THIS_FIFO";

# Start listening for bspwm events
_listen_for_events;
