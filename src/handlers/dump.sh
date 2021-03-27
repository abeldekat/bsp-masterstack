#!/usr/bin/env bash

dump(){
    # save stdout to fd 3 and redirect output to outfile
    exec 3>&1 >> $(get_dump_file $DESKTOPNAME);

    echo "*************************************************";
    echo "Dump runtime state for desktopname [$DESKTOPNAME]";
    date;
    echo "*************************************************";

    echo "ORIENTATION=$ORIENTATION";
    echo "STACK_ORIENTATION=$STACK_ORIENTATION";

    echo "DESKTOP=$DESKTOP";
    echo "DESKTOP_ROOT=$DESKTOP_ROOT";
    echo "MASTER=$MASTER";
    echo "STACK=$STACK";
    echo "STACK_TOP=$STACK_TOP";

    echo "MASTER_TOP=$MASTER_TOP";
    echo "MASTER_INCREMENT=$MASTER_INCREMENT";
    echo "MASTER_INCREMENT_TOP=$MASTER_INCREMENT_TOP";

    echo "Current master id[$MASTER_ID]";
    echo "Has increment stack[$(has_increment_stack)]";
    echo "Increment stack members[$(reveal_members_in_increment_stack)]";

    # restore stdout from fd 3 -- and close fd 3
    exec 1>&3 >&3-
}
