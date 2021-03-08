#!/usr/bin/env bash

# TODO: Test the impact of flags 
# Precondition: automatic_scheme alternate
# initial_polarity first_child

source "$ROOT/utils/adapter.sh";

_query_focused_node(){
    echo "$(bspc query -N -n focused -d $DESKTOPNAME)";
}

_query_all_leaves_in_stack_reversed(){
    echo "$(bspc query -N $STACK -n .descendant_of.leaf | tac)";
}

# $1 node_to_zoom 
_bubble_node_in_stack_to_top(){
    local node_to_bubble=$1;
    # echo "bubble node $node_to_bubble to top of the stack";

    local stack_leaves=($(_query_all_leaves_in_stack_reversed));
    # echo "_bubble: leafs [${stack_leaves[*]}]"

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

# $1 desktoppath
_does_not_have_at_least_three_leafs(){
    local result=false;
    [[ -z "$( \
        bspc query -N $1/ -n $1/2.!leaf \
        || \
        bspc query -N $1/ -n $1/1.!leaf \
        )" ]] && result=true;
    echo $result;
}

# Use case: New nodes are spawned from master
# ---- This use case will be most used
# Use case: New nodes are spawned from stack
# node_add <monitor_id> <desktop_id> <ip_id> <node_id>
node_add(){
    local nodeid=$4;
    if "$(_does_not_have_at_least_three_leafs $DESKTOP)"; then
        return;
    fi
    if "$(is_node_in_stack $nodeid $MASTER)"; then
        # echo "Add: Moving to master";
        transfer $nodeid $MASTER;
    fi;
    # echo "Add: Moving brother of master to top of the stack";
    transfer $MASTER_NEWNODE/brother $STACK;
    balance $STACK;
}

# Use case: Node is deleted from master
# Use case: Node is deleted from stack
# Note: At the moment no reliable way to distinguish between the two use cases
# Recreates stack by moving all nodes against the top in reversed order
# Not necessary if there are only two leafs
# node_add <monitor_id> <desktop_id> <ip_id> <node_id>
node_remove(){
    local stack_leaves=($(_query_all_leaves_in_stack_reversed));
    # echo "node_remove: leafs [${stack_leaves[*]}]"
    if [[ ${#stack_leaves[@]} -ge 3 ]]; then
        for leaf in ${stack_leaves[@]}; do
            transfer $leaf $STACK;
        done
    fi;
    # TODO Bug in bspwm? : Equalize should not be necessary
    equalize_and_balance "$DESKTOP/" $STACK;
}

# Use case: This desktop receives a node from another desktop
# Delegates to node_add
# -> Used indirectly by replay
# node_transfer <src_monitor_id> <src_desktop_id> <src_node_id> <dst_monitor_id> <dst_desktop_id> <dst_node_id>
node_transfer(){
    # node_add <monitor_id> <desktop_id> <ip_id> <node_id>
    node_add $4 $5 "" $3;
}

# Use case: Zoom an item from stack into master
# Use case: Zoom the top of the stack into master
zoom(){
    if "$(_root_is_leaf $DESKTOP)"; then
        # echo "zoom: no work to be done";
        return;
    fi;

    node_to_zoom="$(_query_focused_node)"; 
    if [[ -z $node_to_zoom ]]; then
        # echo "zoom: no focused node to select";
        return;
    fi;

    if "$(is_node_in_stack $node_to_zoom $MASTER)"; then
        _bubble_node_in_stack_to_top $node_to_zoom;
    fi;
    # echo "zoom: swap master with top of the stack and focus master";
    swap $STACK_TOP $MASTER || swap $STACK $MASTER;
    bspc node $MASTER -f;
}
