#!/usr/bin/env bash

declare -A _orientations=(["$DIR_WEST"]="$DIR_NORTH" ["$DIR_NORTH"]="$DIR_EAST" \
    ["$DIR_EAST"]="$DIR_SOUTH" ["$DIR_SOUTH"]="$DIR_WEST");

change_orientation(){
    local new_orientation=${_orientations["$ORIENTATION"]};
    local old_stack_position=$STACK_POSITION;

    # echo "changing [$ORIENTATION] into [$new_orientation]"; 
    rotate "$DESKTOP/" 90;

    # echo "Setting runtime globals for $new_orientation"; 
    set_runtime_globals $new_orientation;
    set_desktop_option $DESKTOPNAME 'orientation' "$ORIENTATION";

    if [[ $old_stack_position == $STACK_POSITION ]]; then
        # echo "Correcting stack order [$STACK]";
        rotate $STACK 180;
    fi
}

# A specific case when the desktop changes from containing one node
# into containing two nodes. It the ORIENTATION is not west,
# the ORIENTATION needs to be restored.
# Default BSPWM operation resembles the WEST orientation.
restore_orientation_if_needed(){
    [[ $ORIENTATION == $DIR_WEST ]] && return;
    local rotation="90";

    [[ $ORIENTATION == $DIR_EAST ]] && rotation="180";
    [[ $ORIENTATION == $DIR_SOUTH ]] && rotation="270";

    # echo "Restoring orientation for [$ORIENTATION]";
    rotate "$DESKTOP/" $rotation;
}
