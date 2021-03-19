#!/usr/bin/env bash

# There are four orientations
# Opposite orientations share the same global variables 

_global_configs="$ROOT/globals";
_new_node="1"; # Initial polarity is enforced

# Orientations to config
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

    DESKTOP="@$DESKTOPNAME:";
    DESKTOP_ROOT="$DESKTOP/";
    MASTER="$DESKTOP/$MASTER_POSITION";
    STACK="$DESKTOP/$STACK_POSITION";
    # For example: @I:/1/1/
    MASTER_NEWNODE="$MASTER/$_new_node";
    # For example: @I:/2/1/
    STACK_NEWNODE="$STACK/$_new_node";
}
