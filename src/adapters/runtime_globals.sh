#!/usr/bin/env bash

_orientation_configs="$ROOT/orientations";
_new_node="1"; # Initial polarity is enforced

set_runtime_globals(){
    ORIENTATION="$1";

    source "$_orientation_configs/$ORIENTATION.sh"; 

    DESKTOP="@$DESKTOPNAME:";
    MASTER="$DESKTOP/$MASTER_POSITION";
    STACK="$DESKTOP/$STACK_POSITION";
    # For example: @I:/1/1/
    MASTER_NEWNODE="$MASTER/$_new_node";
    # For example: @I:/2/1/
    STACK_NEWNODE="$STACK/$_new_node";
}
