#!/usr/bin/env bash

# $1 node_to_bubble 
_bubble_node_in_stack_to_top(){
    local node_to_bubble=$1;
    # echo "bubble node $node_to_bubble to top of the stack";

    local stack_leaves=($(query_leaves_reversed $STACK));
    # echo "_bubble: leaves [${stack_leaves[*]}]"

    local start_swap=false;
    local index_last=$(( ${#stack_leaves[@]} - 1 ));
    if [[ $index_last -le 0 ]]; then return; fi;

    for i in "${!stack_leaves[@]}"; do
        if [[ "${stack_leaves[$i]}" = "$node_to_bubble" ]]; then
            start_swap=true;
        fi;
        if "$start_swap" && [[ $i -lt $index_last ]]; then 
            index_to_swap=$(( $i + 1 ));
            swap $node_to_bubble ${stack_leaves[$index_to_swap]};
        fi;
    done
}

# Use case: Zoom an item from stack into master
# Use case: Zoom the top of the stack into master
zoom(){
    if "$(is_leaf $DESKTOP)"; then
        # echo "zoom: nothing todo";
        return;
    fi;

    node_to_zoom="$(query_focused_node $DESKTOPNAME)"; 
    if [[ -z $node_to_zoom ]]; then
        # echo "zoom: no focused node to select";
        return;
    fi;

    if "$(is_node_in_stack $node_to_zoom $MASTER)"; then
        _bubble_node_in_stack_to_top $node_to_zoom;
    fi;
    # echo "zoom: swap master with top of the stack and focus master";
    swap $STACK_NEWNODE $MASTER || swap $STACK $MASTER;
    bspc node $MASTER -f;
}
