#!/usr/bin/env bash
#
# The idea: A rotation results in a new orientation

declare -A _rotations=(["$DIR_WEST"]="$DIR_NORTH" \
    ["$DIR_NORTH"]="$DIR_EAST" \
    ["$DIR_EAST"]="$DIR_SOUTH" \
    ["$DIR_SOUTH"]="$DIR_WEST");

rotate_to_new_orientation(){
    "$(has_no_master $DESKTOPNAME)" && return;

    local new_orientation=${_rotations["$ORIENTATION"]};
    local old_master_position=$MASTER_POSITION;

    # echo "changing [$ORIENTATION] into [$new_orientation]"; 
    rotate "$DESKTOP/" 90;

    # echo "Setting runtime globals for $new_orientation"; 
    set_runtime_globals $new_orientation;
    # echo "Saving orientation [$new_orientation]";
    set_desktop_option $DESKTOPNAME 'orientation' "$ORIENTATION";

    # echo "Always correct master[$MASTER] order if any";
    rotate "$MASTER" 180;
    if [[ $old_master_position == $MASTER_POSITION ]]; then
        # echo "Correcting stack order [$STACK]";
        rotate $STACK 180;
    fi
    focus_master_node;
}
