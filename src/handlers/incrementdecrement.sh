#!/usr/bin/env bash

# Master orientation to increment position
declare -A _increment_to_orientation=(["$DIR_WEST"]="$DIR_SOUTH" \
    ["$DIR_NORTH"]="$DIR_EAST" \
    ["$DIR_EAST"]="$DIR_SOUTH" \
    ["$DIR_SOUTH"]="$DIR_EAST");

NR_INCREMENTS=0;

# For now, the stack always exists.
# An example of master with three leaves:
# @/1/1 @/1/2/1 @/1/2/2/1 @/1/2/2/2 
increment(){
    echo "increment: counter [$NR_INCREMENTS]. Test for master and stack. ";
    "$(has_no_master $DESKTOPNAME)" && return;

    echo "increment: retrieve stack";
    local leaves_in_stack=($(query_leaves_reversed $STACK));
    local nr_in_stack=${#leaves_in_stack[@]};
    echo "increment: always keep 1 leaf in stack";
    [[ $nr_in_stack -eq 1 ]] && return;

    echo "increment: retrieve leaves in increment [$MASTER_INCREMENT]";
    local leaves_in_increment=($(query_leaves_reversed $MASTER_INCREMENT));
    local nr_in_increment=${#leaves_in_increment[@]};
    local last_leaf="$MASTER";
    [[ $nr_in_increment -gt 0 ]] && last_leaf="${leaves_in_increment[0]}";

    echo "increment: increment has [$nr_in_increment] leaves. Last is [$last_leaf]";
    create_receptacle $last_leaf ${_increment_to_orientation[$ORIENTATION]} \
        $PRESEL_RATIO;
    local receptacle_id="$(get_receptacle $MASTER_INCREMENT)";

    echo "increment: Move top of the stack to receptacle [$receptacle_id]";
    transfer $STACK_NEWNODE $receptacle_id;
    balance $MASTER;

    NR_INCREMENTS="$(( $NR_INCREMENTS + 1 ))";
    echo "increment: counter [$NR_INCREMENTS]";
}

decrement(){
    echo "decrement: there should be at least one incrementation";
    [[ $NR_INCREMENTS -eq 0 ]] && return;

    echo "decrement: retrieve leaves in increment [$MASTER_INCREMENT]";
    local leaves_in_increment=($(query_leaves_reversed $MASTER_INCREMENT));
    local last_leaf="${leaves_in_increment[0]}";

    echo "decrement: counter [$NR_INCREMENTS] last_leaf [$last_leaf]";
    transfer $last_leaf $STACK;
    balance $MASTER;
    balance $STACK;

    NR_INCREMENTS="$(( $NR_INCREMENTS - 1 ))";
    echo "decrement: counter [$NR_INCREMENTS]";

}
