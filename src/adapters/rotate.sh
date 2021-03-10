#!/usr/bin/env bash

declare -A _orientations=(["$DIR_WEST"]="$DIR_NORTH" ["$DIR_NORTH"]="$DIR_EAST" \
    ["$DIR_EAST"]="$DIR_SOUTH" ["$DIR_SOUTH"]="$DIR_WEST");

rotate_desktop(){
    local new_orientation=${_orientations["$ORIENTATION"]};
    local old_stack_position=$STACK_POSITION;

    echo "Rotate [$ORIENTATION] to [$new_orientation]"; 
    rotate "$DESKTOP/" 90;

    set_runtime_globals $new_orientation;
    if [[ $old_stack_position == $STACK_POSITION ]]; then
        echo "Rotate stack [$STACK]";
        rotate $STACK 180;
    fi
}
