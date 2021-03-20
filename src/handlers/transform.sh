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

    # echo "transform, orientation is [$ORIENTATION]";
    local leaves=($(_merge_current_stack_and_master_reversed));
    local new_master_id="${leaves[-1]}";
    unset leaves[-1];

    # echo "transform, replace stack [$STACK] with a receptacle";
    create_receptacle $DESKTOP_ROOT "$STACK_ORIENTATION" $PRESEL_RATIO;

    # echo "transform, send all leaves to new stack [$STACK]";
    set_removal_adjustment true;
    for leaf in "${leaves[@]}"; do
        transfer $leaf $STACK;
    done
    set_removal_adjustment false;
    balance $STACK;

    # echo "transform, save node [$new_master_id] as master";
    save_master_node $new_master_id;
    $(desktop_has_focus $DESKTOPNAME) && focus_master_node;
}
