#!/usr/bin/env bash

# There are four orientations
# Opposite orientations share the same global variables 

# Master id is global and kept up to date on every applicable event
MASTER_ID="";

_global_configs="$ROOT/globals";
_new_node="1"; # Initial polarity is enforced

# Orientations to global configs
declare -A _configs=(["$DIR_WEST"]="master_on_one" \
    ["$DIR_NORTH"]="master_on_one" \
    ["$DIR_EAST"]="master_on_two" \
    ["$DIR_SOUTH"]="master_on_two");

# Master orientation to stack orientation
declare -A _master_to_stack=(["$DIR_WEST"]="$DIR_EAST" \
    ["$DIR_NORTH"]="$DIR_SOUTH" \
    ["$DIR_EAST"]="$DIR_WEST" \
    ["$DIR_SOUTH"]="$DIR_NORTH");

set_runtime_globals(){
    ORIENTATION="$1";

    source "$_global_configs/${_configs[$ORIENTATION]}.sh"; 
    STACK_ORIENTATION=${_master_to_stack["$ORIENTATION"]};

    # Constants
    # On increment, the increment stack will be on second child
    # For example: @/1/2, with master on @/1/1
    # For example: @/2/2, with master on @/2/1
    INCREMENT_POSITION="2"
    # Which node in the increment stack will receive a receptacle. 
    # Which node in the increment stack will be transferred back to stack
    # -1 means last
    INCREMENT_TAIL_INDEX="-1"
    INCREMENT_HEAD_INDEX="0"

    DESKTOP="@$DESKTOPNAME:";
    DESKTOP_ROOT="$DESKTOP/";
    # base master position
    MASTER="$DESKTOP/$MASTER_POSITION";
    # base stack position
    STACK="$DESKTOP/$STACK_POSITION";
    # Top leaf in stack with nr_in_stack > 1
    # For example: @I:/2/1/
    STACK_TOP="$STACK/$_new_node";

    # Increment/decrement
    # For example: @I:/1/1/
    MASTER_TOP="$MASTER/$_new_node";
    # For example: @I:/1/2/
    MASTER_INCREMENT="$MASTER/$INCREMENT_POSITION";
    MASTER_INCREMENT_TOP="$MASTER_INCREMENT/$_new_node";
}
