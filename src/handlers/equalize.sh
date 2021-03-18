#!/usr/bin/env bash


# Resets master to default split-ratio and balances the stack 
# The default split ratio should temporarily be inversed 
# for south and east
#
# orientation west and north are on first child.
# orientation east and south are on second child.
equalize(){
    bspc config split_ratio $RESET_RATIO;
    bspc node "$DESKTOP/" -E;
    bspc node "$STACK" -B;
    bspc config split_ratio $SPLIT_RATIO;
}
