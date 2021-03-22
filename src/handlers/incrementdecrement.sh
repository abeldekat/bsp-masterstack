#!/usr/bin/env bash

# Map from orientation to its below position
declare -A _to_below=(["$DIR_WEST"]="$DIR_SOUTH" \
    ["$DIR_NORTH"]="$DIR_EAST" \
    ["$DIR_EAST"]="$DIR_SOUTH" \
    ["$DIR_SOUTH"]="$DIR_EAST");

# Map from orientation to its ontop position
declare -A _to_ontop=(["$DIR_WEST"]="$DIR_NORTH" \
    ["$DIR_NORTH"]="$DIR_WEST" \
    ["$DIR_EAST"]="$DIR_NORTH" \
    ["$DIR_SOUTH"]="$DIR_WEST");

NR_INCREMENTS=0;

# $1 source leaf in master increment section
_transfer_to_top_of_stack(){
    local src_leaf=$1;

    # echo "retrieve leaves in stack [$STACK]";
    local leaves_in_stack=($(query_leaves $STACK));
    local nr_in_stack=${#leaves_in_stack[@]};

    # echo "transfer [$src_leaf] to stack containing [$nr_in_stack]";
    transfer $src_leaf $STACK;

    if "$(_all_is_incremented $nr_in_stack)"; then
        equalize;
    else
        balance $MASTER
        balance $STACK;
    fi
}

# On the last incrementation the stack is empty. Bspwm will remove
# that internal node thereby invalidating the global variables.
# Make sure the stack remains part of the tree by adding a small
# receptacle
_protect_stack_with_receptacle(){
    create_receptacle $DESKTOP_ROOT "$STACK_ORIENTATION" $STACK_PROTECTION_RATIO;
}

# $1 target leaf in master increment section
# $2 number of leafs in $STACK
_transfer_to_increment_section(){
    local target_leaf=$1;
    local nr_in_stack=$2;

    create_receptacle $target_leaf ${_to_below[$ORIENTATION]} $PRESEL_RATIO;
    local receptacle_id="$(query_receptacle $MASTER_INCREMENT)";

    # echo "increment: Move top of the stack to receptacle [$receptacle_id]";
    if [[ $nr_in_stack -eq 1 ]]; then
        transfer $STACK $receptacle_id;
        _protect_stack_with_receptacle;
    else
        transfer $STACK_NEWNODE $receptacle_id;
    fi
    balance $MASTER;
}

# $1 Number of windows in the stack
_all_is_incremented(){
    local nr_in_stack=$1;
    local result=false;
    [[ $nr_in_stack -eq 0 ]] && result=true;
    echo $result;
}

# Is the increment stack present
has_increment_stack(){
    local result=false;
    [[ $NR_INCREMENTS -ne 0 ]] && result=true;
    echo $result;
}

# $1 nodeid to transfer into the increment stack
handle_node_into_increment_stack(){
    local nodeid=$1;
    local leaves_in_increment=($(query_leaves $MASTER_INCREMENT));
    local head_leaf="${leaves_in_increment[$INCREMENT_HEAD_INDEX]}"

    echo "create receptacle on top of [$head_leaf]";
    create_receptacle $head_leaf ${_to_ontop[$ORIENTATION]} $PRESEL_RATIO;
    local receptacle_id="$(query_receptacle $MASTER_INCREMENT)";
    # echo "transfer node [$nodeid] to top of the increment stack"
    transfer $nodeid $receptacle_id;

    local tail_leaf="${leaves_in_increment[$INCREMENT_TAIL_INDEX]}"
    # echo "transfer node [$tail_leaf] to top of the dynamic stack"
    _transfer_to_top_of_stack $tail_leaf;
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

    # echo "increment: [$nr_in_increment] leaves, target leaf [$target_leaf]";
    _transfer_to_increment_section $target_leaf $nr_in_stack;

    NR_INCREMENTS="$(( $NR_INCREMENTS + 1 ))";
    # echo "increment: counter end [$NR_INCREMENTS]";
}

decrement(){
    # echo "decrement: counter start [$NR_INCREMENTS], require at least 1";
    [[ $NR_INCREMENTS -eq 0 ]] && return;

    # echo "decrement: retrieve leaves in master increment [$MASTER_INCREMENT]";
    local leaves_in_increment=($(query_leaves $MASTER_INCREMENT));
    local nr_in_increment=${#leaves_in_increment[@]};

    local src_leaf="${leaves_in_increment[$INCREMENT_TAIL_INDEX]}";

    # echo "decrement: [$nr_in_increment] leaves, source leaf [$src_leaf]";
    _transfer_to_top_of_stack $src_leaf;

    NR_INCREMENTS="$(( $NR_INCREMENTS - 1 ))";
    # echo "decrement: counter end [$NR_INCREMENTS]";
}
