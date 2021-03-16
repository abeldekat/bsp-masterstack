#!/usr/bin/env bash

# Use case: Consistenly set global values for desktops managed by bsp-masterstack
# The code will set the following globals on each new desktop focus to either 
# initial values or to the values required by bsp-masterstack:
# automatic_scheme
# initial_polarity
# removal_adjustment
# split_ratio
#
# The initial values are gathered when the guardlistener is started.
# When the user has not changed his global settings the initial values
# will be the same as configured in bspwmrc

source "$ROOT/lib/state.sh";

GUARDLISTENER="$ROOT/listeners/guardlistener.sh";

# The kill command invokes a trap on the process of the guardlistener
# reverting the globals back to their initial values
_stop_listener_and_revert_globals() {
    local pid="$(get_guard_data | valueof pid)";
    [[ -n $pid ]] && kill $pid 2> /dev/null || true; 
    set_guard_data 'pid' "";
}

# finds all desktops whose pid is not empty
_get_desktops_to_guard(){
    local result=();
    while read -r desktop; do
        pid=$(get_desktop_options "$desktop" | valueof pid);
        [[ -n "$pid" ]] && result+=($desktop);
    done < <(list_desktops)
    echo "${result[@]}";
}

# start the listener if there are desktops to guard
_start(){
    local desktops_to_guard=($(_get_desktops_to_guard));

    if [[ ${#desktops_to_guard[@]} -gt 0 ]]; then
        # echo "Starting guardlistener for desktops[${desktops_to_guard[@]}]";
        bash $GUARDLISTENER ${desktops_to_guard[@]} &
        GUARD_PID=$!;
        disown;
        set_guard_data 'pid' "$GUARD_PID";
        echo "GUARD: [$GUARD_PID]";
    fi;
}
_stop_listener_and_revert_globals;
_start;
