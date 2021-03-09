#!/usr/bin/env bash

# TODO Now, this process is ran inside the main listener
# Could also be standalone against the main listener

# $1: The path containing the leaves to send
# $2: The receiving desktop
_send_all_leaves_from_path_reversed_to_desktop(){
    for anode in $(_query_all_leaves_reversed $1); do
        # echo "Sending anode [$anode] from [$1] to [$2]";
        bspc node $anode -d $2;
    done
}

# Use case: User has an existing layout he wants to transform
# Sends root to a temporary desktop. 
# Returns each leaf to the focused desktop one by one simulating user interaction
# Command
replay(){
    # Capture master to regain focus
    local masterid="$(bspc query -N -n $MASTER)";
    echo "Masterid is [$masterid]";

    # Move root to a temp desktop
    local desktop_tmp="BSPTMP";
    bspc monitor -a $desktop_tmp;
    bspc node "$DESKTOP/" -d $desktop_tmp;

    # Return to sender: First the stack, than the remaining master
    _send_all_leaves_from_path_reversed_to_desktop "@$desktop_tmp:/" $DESKTOPNAME;
    bspc desktop $desktop_tmp -r;

    # Regain focus
    [[ -n $masterid ]] && bspc node -f $masterid;
}
