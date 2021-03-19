#!/usr/bin/env bash

# Master orientation to increment position
declare -A _increment_to_orientation=(["$DIR_WEST"]="$DIR_SOUTH" \
    ["$DIR_NORTH"]="$DIR_EAST" \
    ["$DIR_EAST"]="$DIR_SOUTH" \
    ["$DIR_SOUTH"]="$DIR_EAST");

NR_INCREMENTS=0;

# An example of master with three leaves:
# @/1/1 @/1/2/1 @/1/2/2/1 @/1/2/2/2 
increment(){
    echo "increment: test for master and stack. Counter [$NR_INCREMENTS]";
    "$(has_no_master $DESKTOPNAME)" && return;

    echo "increment: retrieve stack";
    local leaves_in_stack=($(query_leaves_reversed $STACK));
    local nr_in_stack=${#leaves_in_stack[@]};
    echo "increment: always keep 1 leaf in stack";
    [[ $nr_in_stack -eq 1 ]] && return;

    echo "increment: retrieve leaves in master";
    local leaves_in_master=($(query_leaves_reversed $MASTER));
    local nr_in_master=${#leaves_in_master[@]};
    local last_leaf="${leaves_in_master[0]}";

    echo "increment: master has [$nr_in_master] leaves. Last is [$last_leaf]";
    create_receptacle $last_leaf ${_increment_to_orientation[$ORIENTATION]} \
        $PRESEL_RATIO;
    local receptacle_id="$(get_receptacle $MASTER)";

    echo "increment: Move top of the stack to receptacle [$receptacle_id]";
    transfer $STACK_NEWNODE $receptacle_id;
    balance $MASTER;

    NR_INCREMENTS="$(( $NR_INCREMENTS + 1 ))";
    echo "increment: counter [$NR_INCREMENTS]";
}

decrement(){
    echo "TODO decrement";
}
