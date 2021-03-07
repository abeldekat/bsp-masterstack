#!/usr/bin/env bash
source "$ROOT/utils/common.sh";
source "$ROOT/utils/desktop.sh";
source "$ROOT/utils/state.sh";

# Gatekeeper: Only handle event if:
# Event target desktop is a match
# In case event is node_transfer: Event src desktop is not a match
_should_handle_event(){
    local result=false;

    local desktop_id="";
    if [[ "$1" == "node_transfer" ]]; then
        [[ "$3" != "$6" ]] && desktop_id="$6";
    else
        desktop_id="$3";
    fi;

    if [[ -n "$desktop_id" ]]; then
        local desktop_name_event=$(get_desktop_name_from_id "$desktop_id");
        [[ "$desktop_name_event" == "$desktop_name" ]] && result=true;
    fi;
    echo $result;
}

# Acitvates listener for a specific desktop
_start() {
    local subscriptions=(node_add node_remove node_transfer);

    while read -r -a line; do
    if "$(_should_handle_event ${line[@]})"; then
        bash "$(get_adapter_file)" $desktop_name "${line[@]}" 2> /dev/null || true;
    fi;
    done < <(bspc subscribe ${subscriptions[@]}) &

    # Handle processid and save 
    local ADAPTER_PID=$!; # PID of the listener in the background
    disown;
    set_desktop_option $desktop_name 'pid' "$ADAPTER_PID";
    echo "[$ADAPTER_PID]";
}

desktop_name="$1";
_start;
