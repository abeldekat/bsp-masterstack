#!/usr/bin/env bash

# Master is leaf and stack is leaf:
# Activate orientation
# Save new master
_activate(){
    local node_id=$1;
    save_master_node $node_id; 

    # echo "Test if orientation is default";
    [[ $ORIENTATION == $DIR_WEST ]] && return;

    # echo "Replace master with a receptacle";
    create_receptacle $DESKTOP_ROOT "$ORIENTATION" $PRESEL_RATIO;
    # echo "Move new master to receptacle";
    transfer $node_id $MASTER;
}

# $1 node_id to transfer into the dynamic stack
_add_node_to_dynamic_stack(){
    local node_id=$1;

    # echo "transfer node [$node_id] to top of the dynamic stack"
    transfer $node_id $STACK;
    balance $STACK;
}

# Master deleted, replace with a node from the dynamic stack
_restore_and_save_master_from_dynamic_stack(){
    # echo "restore master from dynamic stack with receptacle ";
    create_receptacle $DESKTOP_ROOT $ORIENTATION $PRESEL_RATIO;

    # echo "retrieve top of the stack";
    local node_id="$(query_node $STACK_NEWNODE)";

    # echo "dynamic stack: move node [$node_id] to master receptacle";
    transfer $node_id $MASTER;
    balance $STACK;
    save_master_node "$node_id"; 
}

# node_add <monitor_id> <desktop_id> <ip_id> <node_id>
on_node_add(){
    local node_id=$4;

    # echo "on_node_add: test for desktop with exactly one leaf";
    "$(is_leaf $DESKTOP)" && return;

    # echo "on_node_add: test for desktop with exactly two leaves"
    if "$(is_leaf $MASTER)" && "$(is_leaf $STACK)"; then
        _activate $node_id;
        return;
    fi

    # echo "on_node_add, there are three or more leaves"
    if ! $(is_brother_of_master_node $node_id); then
        # echo "on_node_add: move new node from stack to master"
        transfer $node_id $MASTER_ID;
    fi

    $(has_increment_stack) && add_node_to_increment_stack $MASTER_ID || \
        _add_node_to_dynamic_stack $MASTER_ID;

    save_master_node $node_id; 
}

# node_add <monitor_id> <desktop_id> <node_id>
on_node_remove(){
    local removed_id=$3;
    local nr_nodes="$(query_number_of_leaves $DESKTOP_ROOT)";

    # echo "***on_node_remove start: removed[$removed_id] nodes[$nr_nodes] ";
    [[ $nr_nodes -eq 0 ]] && return;

    local is_master="$(is_master_node $removed_id)";
    if $(has_increment_stack); then
        remove_node_from_increment_stack $removed_id $is_master;
    else
        if [[ $nr_nodes -eq 1 ]]; then
            save_master_node "$(query_node $DESKTOP_ROOT)";
        elif "$is_master"; then
            _restore_and_save_master_from_dynamic_stack;
        else
            balance $STACK;
        fi
    fi

    $is_master && focus_master_node;
    # echo "*** on_node_remove finish: master node is [$MASTER_ID]";
}

# Delegates to node_add
# node_transfer <src_monitor_id> <src_desktop_id> <src_node_id> <dst_monitor_id> <dst_desktop_id> <dst_node_id>
on_node_transfer(){
    # node_add <monitor_id> <desktop_id> <ip_id> <node_id>
    on_node_add $4 $5 "" $3;
}
