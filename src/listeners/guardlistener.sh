#!/usr/bin/env bash

# On ps -ef | grep "bsp" the following processes will be visible
# 1. A (parent 1) Main guard process, saved by the caller  
# 3. B (parent A) Reads bwpm events, this is the last statement in the script
# 4. C (parent B) bspc subscribe, process substitution

source "$ROOT/handlers/config.sh";
source "$ROOT/lib/state.sh";
source "$ROOT/lib/desktop.sh";

# When the guard stops, restore to the global settings of the user
_on_kill_main_process(){
    # echo "[$$} Guard, main process killed...";
    # Remove process id from state
    clear_guard_id;
    _apply_globals backup_dict;
}

# Gathers the values to work with
_fill_dicts(){
    _fill_globals backup_dict "$(bspc config automatic_scheme)" \
        "$(bspc config initial_polarity)" \
        "$(bspc config removal_adjustment)" \
        "$(bspc config split_ratio)";
    _fill_globals required_dict "alternate" "first_child" "false" "$SPLIT_RATIO";
}

_fill_globals(){
    local -n globals_ref=$1;
    globals_ref+=(["automatic_scheme"]="$2");
    globals_ref+=(["initial_polarity"]="$3");
    globals_ref+=(["removal_adjustment"]="$4");
    globals_ref+=(["split_ratio"]="$5");
}

# Applies the values with bspc config
_apply_globals(){
    local -n globals_ref=$1;
    # echo "Apply globals ${globals_ref[@]}";
    for key in ${!globals_ref[@]}; do
        bspc config $key ${globals_ref[$key]};
    done
}

# Finds out if a desktop is managed by bspwm-dynamic
_should_be_guarded(){
    local desktop_name=$1;
    local result=false;
    for guarded in ${desktops_to_guard[@]}; do
        if [[  $desktop_name == $guarded ]]; then
            result=true;
            break;
        fi;
    done
    echo $result;
}

# Handles each desktop_focus event
_handle_event(){
    local desktop_name=$1;
    if $(_should_be_guarded $desktop_name); then
        # echo "Guarding $desktop_name";
        _apply_globals required_dict;
    else
        # echo "Not guarding $desktop_name";
        _apply_globals backup_dict;
    fi;
}

# Starts listening to desktop events.
_start(){
    trap '_on_kill_main_process' EXIT;
    while read -r -a line; do
        desktop_name=$(get_desktop_name_from_id ${line[2]});
        _handle_event $desktop_name;
    done < <(bspc subscribe desktop_focus)
}

# Dictionaries keeping values for the global settings of interest
declare -A backup_dict required_dict;
desktops_to_guard=($@);
_fill_dicts;

# Change globals if activated from focused desktop.
if $(_should_be_guarded $(get_focused_desktop)); then 
    _apply_globals required_dict; 
fi;
# Start guarding global settings
_start;
