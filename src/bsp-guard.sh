#!/usr/bin/env bash

# Use case: Consistenly set global values for desktops managed by bspwm-dynamic
# The code will set the following globals on each new desktop focus to either 
# initial values or to the values required by bspwm-dynamic:
# automatic_scheme
# initial_polarity
# split_ratio

# export ROOT="{{SOURCE_PATH}}";
export ROOT="$HOME/builds/bsp-masterstack/src";

source "$ROOT/utils/desktop.sh";
source "$ROOT/utils/state.sh";

GUARDLISTENER="$ROOT/listeners/guardlistener.sh";

# The kill command invokes a trap on the process reverting 
# the globals back to their initial values
_remove_listener_and_revert_globals() {
      local old_pid="$(get_guard_data | valueof pid)";
      [[ -n $old_pid ]] && kill $old_pid; 
      set_guard_data 'pid' "";
}
_start(){
    local desktops_to_guard=($(list_desktops));

    if [[ ${#desktops_to_guard[@]} -gt 0 ]]; then
        # echo "Starting listener for desktops[${desktops_to_guard[@]}]";
        bash $GUARDLISTENER ${desktops_to_guard[@]};
    fi;
}
_remove_listener_and_revert_globals;
_start;
