#!/usr/bin/env bash

# Given an existing desktop with at least two leaves:
# Find all leaves in reversed order. Replace the stack with receptacle.
# Send the leaves to the receptacle.
# The last leaf will remain and become master

_merge_current_stack_and_master_reversed(){
    local leaves_in_stack=($(query_leaves_reversed $STACK));
    # echo "Stack: [$STACK]: ${leaves_in_stack[@]}";
    local leaves_in_master=($(query_leaves_reversed $MASTER));
    # echo "Master [$MASTER]: ${leaves_in_master[@]}";

    local leaves_result=(${leaves_in_stack[@]} ${leaves_in_master[@]});
    echo "${leaves_result[@]}"
}

transform_if_needed(){
    "$(has_no_master $DESKTOPNAME)" && return;

    # echo "Transforming an existing layout. Orientation: [$ORIENTATION]";
    local leaves=($(_merge_current_stack_and_master_reversed));
    local new_master_id="${leaves[-1]}";
    unset leaves[-1];

    # echo "Replace stack [$STACK] with a receptacle";
    receptacle $DESKTOP "$(find_stack_orientation)" $PRESEL_RATIO;

    # Send all leaves the new stack
    for leaf in "${leaves[@]}"; do
        transfer $leaf $STACK;
    done
    balance $STACK;
    save_master_node $new_master_id;
    focus_node $new_master_id;
}
