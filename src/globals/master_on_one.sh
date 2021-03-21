#!/usr/bin/env bash
# Master position below root
MASTER_POSITION="1";
# Stack position below root
STACK_POSITION="2";
# The split ratio will be used for receptacles
PRESEL_RATIO="$SPLIT_RATIO";
# The split ratio will be used to equalize all windows on the desktop
RESET_RATIO="$SPLIT_RATIO";
# On the last incrementation the stack is empty. Bspwm will remove
# that internal node thereby invalidating the global variables.
# Make sure the stack remains part of the tree by adding a small
# receptacle
STACK_PROTECTION_RATIO=0.99;
