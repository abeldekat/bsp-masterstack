#!/usr/bin/env bash

# TODO: Test the impact of flags 

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
on_node_add(){
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
on_node_remove(){
    local stack_leaves=($(_query_all_leaves_reversed $STACK));
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
on_node_transfer(){
    # node_add <monitor_id> <desktop_id> <ip_id> <node_id>
    on_node_add $4 $5 "" $3;
}
