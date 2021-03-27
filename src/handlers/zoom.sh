#!/usr/bin/env bash

# $1 node_to_bubble 
_bubble_node_in_stack_to_top(){
    local node_to_bubble=$1;
    local use_increment_stack=$2
    # echo "bubble node[$node_to_bubble] to top of the stack";

    local leaves=($(query_leaves_reversed $STACK));
    if $use_increment_stack; then
        increment_leaves=($(on_zoom_query_increment_stack));
        local leaves=(${leaves[@]} ${increment_leaves[@]});
    fi
    # echo "_bubble: leaves [${leaves[*]}]"

    local start_swap=false;
    local index_last=$(( ${#leaves[@]} - 1 ));
    if [[ $index_last -le 0 ]]; then return; fi;

    for i in "${!leaves[@]}"; do
        if [[ "${leaves[$i]}" = "$node_to_bubble" ]]; then
            start_swap=true;
        fi;
        if "$start_swap" && [[ $i -lt $index_last ]]; then 
            index_to_swap=$(( $i + 1 ));
            swap $node_to_bubble ${leaves[$index_to_swap]};
        fi;
    done
}

# Use case: Zoom an item from stack into master
# Use case: Zoom the top of the stack into master
zoom(){
    "$(is_leaf $DESKTOP)" && return;

    local node_to_zoom="$(query_focused_node $DESKTOPNAME)"; 
    [[ -z $node_to_zoom ]] && return;

    local use_increment_stack=$(has_increment_stack);
    if ! $(is_master_node $node_to_zoom); then
        _bubble_node_in_stack_to_top $node_to_zoom $use_increment_stack;
    fi

    # echo "zoom: swap master with top of the stack and focus master";
    if $use_increment_stack; then
        on_zoom_swap_top_member_with_master;
    else
        swap $STACK_TOP $MASTER || swap $STACK $MASTER;
        save_master_node "$(query_node $MASTER)";
        bspc node $MASTER -f;
    fi
}
