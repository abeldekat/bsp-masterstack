#!/usr/bin/env bash

# Master orientation to its increment position mapping
declare -A _to_increment_position=(["$DIR_WEST"]="$DIR_SOUTH" \
    ["$DIR_NORTH"]="$DIR_EAST" \
    ["$DIR_EAST"]="$DIR_SOUTH" \
    ["$DIR_SOUTH"]="$DIR_EAST");

NR_INCREMENTS=0;

# On the last incrementation the stack is empty. Bspwm will remove
# that internal node thereby invalidating the global variables.
# Make sure the stack remains part of the tree by adding a small
# receptacle
_protect_stack_with_receptacle(){
    create_receptacle $DESKTOP_ROOT "$STACK_ORIENTATION" $STACK_PROTECTION_RATIO;
}

# $1 target leaf in master increment section
# $2 number of leafs in $STACK
_increment_top_of_stack_to_master_section(){
    local target_leaf=$1;
    local nr_in_stack=$2;

    create_receptacle $target_leaf ${_to_increment_position[$ORIENTATION]} \
        $PRESEL_RATIO;
    local receptacle_id="$(get_receptacle $MASTER_INCREMENT)";

    # echo "increment: Move top of the stack to receptacle [$receptacle_id]";
    if [[ $nr_in_stack -eq 1 ]]; then
        transfer $STACK $receptacle_id;

        _protect_stack_with_receptacle;
    else
        transfer $STACK_NEWNODE $receptacle_id;
    fi
    balance $MASTER;
}

# $1 source leaf in master increment section
# $2 number of leafs in $STACK
_decrement_to_top_of_stack(){
    local src_leaf=$1;
    local nr_in_stack=$2;

    transfer $src_leaf $STACK;
    if "$(_all_is_incremented $nr_in_stack)"; then
        equalize;
    else
        balance $MASTER
        balance $STACK;
    fi
}

# $1 Number of windows in the stack
_all_is_incremented(){
    local nr_in_stack=$1;
    local result=false;
    [[ $nr_in_stack -eq 0 ]] && result=true;
    echo $result;
}

# For now, the stack always exists.
# An example of master with three leaves:
# @/1/1 @/1/2/1 @/1/2/2/1 @/1/2/2/2 
increment(){
    # echo "increment: counter start [$NR_INCREMENTS]";
    "$(has_no_master $DESKTOPNAME)" && return;

    # echo "increment: retrieve leaves in stack [$STACK]";
    local nr_in_stack="$(query_number_of_leaves $STACK)";
    "$(_all_is_incremented $nr_in_stack)" && return;

    # echo "increment: retrieve leaves in master increment [$MASTER_INCREMENT]";
    local leaves_in_increment=($(query_leaves $MASTER_INCREMENT));
    local nr_in_increment=${#leaves_in_increment[@]};

    local target_leaf="$MASTER";
    [[ $nr_in_increment -gt 0 ]] && \
        target_leaf="${leaves_in_increment[$INCREMENT_TAIL_INDEX]}";

    # echo "increment: [$nr_in_increment] leaves. Target leaf [$target_leaf]";
    _increment_top_of_stack_to_master_section $target_leaf $nr_in_stack;

    NR_INCREMENTS="$(( $NR_INCREMENTS + 1 ))";
    # echo "increment: counter end [$NR_INCREMENTS]";
}

decrement(){
    # echo "decrement: counter start [$NR_INCREMENTS]. Require at least 1.";
    [[ $NR_INCREMENTS -eq 0 ]] && return;

    # echo "decrement: retrieve leaves in stack [$STACK]";
    local leaves_in_stack=($(query_leaves $STACK));
    local nr_in_stack=${#leaves_in_stack[@]};

    # echo "decrement: retrieve leaves in master increment [$MASTER_INCREMENT]";
    local leaves_in_increment=($(query_leaves $MASTER_INCREMENT));
    local nr_in_increment=${#leaves_in_increment[@]};

    local src_leaf="${leaves_in_increment[$INCREMENT_TAIL_INDEX]}";

    # echo "decrement: [$nr_in_increment] leaves. source leaf [$src_leaf]";
    _decrement_to_top_of_stack $src_leaf $nr_in_stack;

    NR_INCREMENTS="$(( $NR_INCREMENTS - 1 ))";
    # echo "decrement: counter end [$NR_INCREMENTS]";
}
