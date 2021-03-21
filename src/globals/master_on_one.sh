#!/usr/bin/env bash
# Master position below root
MASTER_POSITION="1";
# Stack position below root
STACK_POSITION="2";
# On increment, the increment stack will be second child
# For example: @/1/2, with master on @/1/1
INCREMENT_POSITION="2"
# On increment, which node in the increment stack will receive a
# receptacle. 
# On decrement, which node in the increment stack will be transferred
# back to the dynamic stack
# -1 means last
INCREMENT_TAIL_INDEX="-1"
# The split ratio will be used for receptacles
PRESEL_RATIO="$SPLIT_RATIO";
# The split ratio will be used to equalize all windows on the desktop
RESET_RATIO="$SPLIT_RATIO";
