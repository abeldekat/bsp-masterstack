#!/usr/bin/env bash

# Master orientation to increment position
declare -A _orientation_to_increment=(["$DIR_WEST"]="$DIR_SOUTH" \
    ["$DIR_NORTH"]="$DIR_EAST" \
    ["$DIR_EAST"]="$DIR_NORTH" \
    ["$DIR_SOUTH"]="$DIR_WEST");

NR_INCREMENTS=0;

# $1 target leaf in increment section
# $2 number of leafs in $STACK
_move_top_of_stack_to_increment_section(){
    local target=$1;
    local nr_in_stack=$2;

    create_receptacle $target ${_orientation_to_increment[$ORIENTATION]} \
        $PRESEL_RATIO;
    local receptacle_id="$(get_receptacle $MASTER_INCREMENT)";

    echo "increment: Move top of the stack to receptacle [$receptacle_id]";
    if [[ $nr_in_stack -eq 1 ]]; then
        echo "increment: stack will be removed";
        transfer $STACK $receptacle_id;
        balance $DESKTOP_ROOT;
    else
        transfer $STACK_NEWNODE $receptacle_id;
        balance $MASTER;
    fi
}

# $1 number of leafs in $STACK
# $2 number of leafs in $MASTER_INCREMENT
_move_last_of_increment_to_top_of_stack(){
    local nr_in_stack=$1;
    local nr_in_increment=$2;

    local last_leaf="";
    if "$(_all_is_incremented $nr_in_stack $nr_in_increment)"; then
        echo "decrement: use receptacle to restore stack";
        create_receptacle $DESKTOP_ROOT "$STACK_ORIENTATION" $PRESEL_RATIO;
        last_leaf="${leaves_in_stack[0]}";
    else
        last_leaf="${leaves_in_increment[0]}";
    fi

    echo "Move last_leaf [$last_leaf] of increment to top of the stack";
    transfer $last_leaf $STACK;
}

# When all available windows in the stack are incremented,
# the increment section, originally on $MASTER_INCREMENT,
# will fallback to position $STACK
# $1 Number of windows in the stack
# $2 Number of windows in the increment section
_all_is_incremented(){
    local nr_in_stack=$1;
    local nr_in_increment=$2;
    local result=false;

    # No windows in increment section because it does not exist
    if [[ $nr_in_increment -eq 0 ]]; then
        # Number of windows in stack now containing the increments 
        # and that number is equal to recorded increments
        [[ $nr_in_stack -eq $NR_INCREMENTS ]] && result=true
    fi
    echo $result;
}
# For now, the stack always exists.
# An example of master with three leaves:
# @/1/1 @/1/2/1 @/1/2/2/1 @/1/2/2/2 
increment(){
    echo "increment: counter start [$NR_INCREMENTS]";
    "$(has_no_master $DESKTOPNAME)" && return;

    echo "increment: retrieve leaves in stack [$STACK]";
    local nr_in_stack="$(query_number_of_leaves $STACK)";
    echo "increment: retrieve leaves in increment [$MASTER_INCREMENT]";
    local leaves_in_increment=($(query_leaves_reversed $MASTER_INCREMENT));
    local nr_in_increment=${#leaves_in_increment[@]};
    "$(_all_is_incremented $nr_in_stack $nr_in_increment)" && return;

    local last_leaf="$MASTER";
    [[ $nr_in_increment -gt 0 ]] && last_leaf="${leaves_in_increment[0]}";

    echo "increment: [$nr_in_increment] leaves. Last leaf [$last_leaf]";
    _move_top_of_stack_to_increment_section $last_leaf $nr_in_stack;

    NR_INCREMENTS="$(( $NR_INCREMENTS + 1 ))";
    echo "increment: counter end [$NR_INCREMENTS]";
}

decrement(){
    echo "decrement: counter start [$NR_INCREMENTS]. Require at least 1.";
    [[ $NR_INCREMENTS -eq 0 ]] && return;

    echo "decrement: retrieve leaves in stack [$STACK]";
    local leaves_in_stack=($(query_leaves_reversed $STACK));
    local nr_in_stack=${#leaves_in_stack[@]};
    echo "decrement: retrieve leaves in increment [$MASTER_INCREMENT]";
    local leaves_in_increment=($(query_leaves_reversed $MASTER_INCREMENT));
    local nr_in_increment=${#leaves_in_increment[@]};

    _move_last_of_increment_to_top_of_stack $nr_in_stack $nr_in_increment;
    balance $MASTER;
    balance $STACK;

    NR_INCREMENTS="$(( $NR_INCREMENTS - 1 ))";
    echo "decrement: counter end [$NR_INCREMENTS]";
}
