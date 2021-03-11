#!/usr/bin/env bash

dump(){
    echo "Dump runtime state for desktopname [$DESKTOPNAME]";

    echo "DESKTOP=$DESKTOP";
    echo "MASTER=$MASTER";
    echo "STACK=$STACK";
    echo "MASTER_NEWNODE=$MASTER_NEWNODE";
    echo "STACK_NEWNODE=$STACK_NEWNODE";
    echo "ORIENTATION=$ORIENTATION";
}
