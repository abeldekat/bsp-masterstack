#!/usr/bin/env bash

source "$ROOT/utils/desktop.sh";
source "$ROOT/utils/state.sh";

# Gathers the values to work with
_fill_dicts(){
    _fill_globals backup_dict "$(bspc config automatic_scheme)" \
        "$(bspc config initial_polarity)" \
        "$(bspc config split_ratio)";
    _fill_globals required_dict "alternate" "first_child" "0.6";
}
_fill_globals(){
    local -n globals_ref=$1;
    globals_ref+=(["automatic_scheme"]="$2");
    globals_ref+=(["initial_polarity"]="$3");
    globals_ref+=(["split_ratio"]="$4");
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
    {
        trap '_apply_globals backup_dict' EXIT;
        while read -r -a line; do
            desktop_name=$(get_desktop_name_from_id ${line[2]});
            _handle_event $desktop_name;
        done < <(bspc subscribe desktop_focus)
    } &
    GUARD_PID=$!;
    disown;
    set_guard_data 'pid' "$GUARD_PID";
    echo "[$GUARD_PID]";
}

# Dictionaries keeping values for the global settings of interest
declare -A backup_dict required_dict;
desktops_to_guard=($@);
_fill_dicts;
# echo "Start listener: desktops[${desktops_to_guard[@]}] backup[${backup_dict[@]}] required[${required_dict[@]}]";

# Change globals if activated from focused desktop.
if $(_should_be_guarded $(bspc query --desktops -d --names)); then 
    _apply_globals required_dict; 
fi;
_start;
