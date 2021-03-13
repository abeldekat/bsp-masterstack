#!/usr/bin/env bash

# Use case: New nodes are spawned from master
# ---- This use case will be most used
# Use case: New nodes are spawned from stack
# node_add <monitor_id> <desktop_id> <ip_id> <node_id>
on_node_add(){
    local nodeid=$4;
    # The new node will always become the master
    save_master_node $nodeid; 

    # User added a leaf to an empty desktop: One leaf
    "$(is_leaf $DESKTOP)" && return;

    # User added a leaf to a desktop containing only one leaf: Two leaves
    if "$(is_leaf $MASTER)" && "$(is_leaf $STACK)"; then
        restore_orientation_if_needed;
        return;
    fi;

    # Generic algorithm for three or more leaves
    if "$(is_node_in_stack $nodeid $MASTER)"; then
        # echo "Add: Moving to master";
        transfer $nodeid $MASTER;
    fi;
    # echo "Add: Moving brother of master to top of the stack";
    transfer $MASTER_NEWNODE/brother $STACK;
    balance $STACK;
}

# Use case: Node is deleted
# node_add <monitor_id> <desktop_id> <node_id>
on_node_remove(){
    local removed_id=$3;
    if "$(has_no_master $DESKTOPNAME)"; then
        save_master_node "";
        return;
    fi

    # Root is not a leaf and master was deleted
    # There were at least three nodes
    if "$(is_master_node $removed_id)"; then
        # Create a new master area
        receptacle $DESKTOP $ORIENTATION $PRESEL_RATIO;
        # Move top of the stack to this new area
        transfer $STACK_NEWNODE $MASTER;
        focus_node $MASTER;
    fi
    save_master_node "$(query_node $MASTER)"; 
    balance $STACK;
}

# Use case: This desktop receives a node from another desktop
# Delegates to node_add
# -> Used indirectly by replay
# node_transfer <src_monitor_id> <src_desktop_id> <src_node_id> <dst_monitor_id> <dst_desktop_id> <dst_node_id>
on_node_transfer(){
    # node_add <monitor_id> <desktop_id> <ip_id> <node_id>
    on_node_add $4 $5 "" $3;
}
