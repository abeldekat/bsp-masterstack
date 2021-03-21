#!/usr/bin/env bash
# Master position below root
MASTER_POSITION="2";
# Stack position below root
STACK_POSITION="1";
# The split ratio will be used for receptacles
# For master on /2 it needs to be inversed
PRESEL_RATIO="$(echo "1 - $SPLIT_RATIO" | bc)";
# The split ratio will be used to equalize all windows on the desktop
# For master on /2 it needs to be inversed
RESET_RATIO="$PRESEL_RATIO";
# On the last incrementation the stack is empty. Bspwm will remove
# that internal node thereby invalidating the global variables.
# Make sure the stack remains part of the tree by adding a small
# receptacle
STACK_PROTECTION_RATIO=0.01;
