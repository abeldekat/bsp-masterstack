#!/usr/bin/env bash
# Master position below root
MASTER_POSITION="2";
# Stack position below root
STACK_POSITION="1";
# On increment, the increment stack will be first child
# For example: @/2/1, with master on @/2/2
INCREMENT_POSITION="1"
# On increment, which node in the increment stack will receive a
# receptacle. 
# On decrement, which node in the increment stack will be transferred
# back to the dynamic stack
# 0 means first
INCREMENT_TAIL_INDEX="0"
# The split ratio will be used for receptacles
# For master on /2 it needs to be inversed
PRESEL_RATIO="$(echo "1 - $SPLIT_RATIO" | bc)";
# The split ratio will be used to equalize all windows on the desktop
# For master on /2 it needs to be inversed
RESET_RATIO="$PRESEL_RATIO";
