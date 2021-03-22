#!/usr/bin/env bash

# Master is leaf and stack is leaf:
# Activate orientation
# Save new master
_activate(){
    local nodeid=$1;

    save_master_node $nodeid; 

    # echo "Test if orientation is default";
    [[ $ORIENTATION == $DIR_WEST ]] && return;

    # echo "Replace master with a receptacle";
    create_receptacle $DESKTOP_ROOT "$ORIENTATION" $PRESEL_RATIO;
    # echo "Move new master to receptacle";
    transfer $nodeid $MASTER;
}

# $1 nodeid to transfer into the dynamic stack
_handle_node_into_dynamic_stack(){
    local nodeid=$1;

    # echo "transfer node [$nodeid] to top of the dynamic stack"
    transfer $nodeid $STACK;
    balance $STACK;
}

# node_add <monitor_id> <desktop_id> <ip_id> <node_id>
on_node_add(){
    local nodeid=$4;

    # echo "on_node_add: test for desktop with exactly one leaf";
    "$(is_leaf $DESKTOP)" && return;

    # echo "on_node_add: test for desktop with exactly two leaves"
    if "$(is_leaf $MASTER)" && "$(is_leaf $STACK)"; then
        _activate $nodeid;
        return;
    fi

    # echo "on_node_add, there are three or more leaves"
    if ! "$(is_brother_of_master_node $nodeid)"; then
        # echo "on_node_add: move new node from stack to master"
        transfer $nodeid $MASTER_ID;
    fi
    if "$(has_increment_stack)"; then
        handle_node_into_increment_stack $MASTER_ID;
    else
        _handle_node_into_dynamic_stack $MASTER_ID;
    fi
    save_master_node $nodeid; 
}

# node_add <monitor_id> <desktop_id> <node_id>
on_node_remove(){
    local removed_id=$3;

    # echo "[$$] on_node_remove, test for existance of master and stack";
    if "$(has_no_master $DESKTOPNAME)"; then
        save_master_node "";
        return;
    fi

    # echo "on_node_remove, test if master has been removed";
    if "$(is_master_node $removed_id)"; then
        # echo "on_node_remove, restore master with receptacle ";
        create_receptacle $DESKTOP_ROOT $ORIENTATION $PRESEL_RATIO;

        # echo "on_node_remove, retrieve top of the stack";
        local new_master_id="$(query_node $STACK_NEWNODE)";

        # echo "on_node_remove, move node [$new_master_id] to receptacle ";
        transfer $new_master_id $MASTER;

        # echo "on_node_remove, save new master id [$new_master_id]";
        save_master_node "$new_master_id"; 
        focus_master_node;
    fi
    balance $STACK;
}

# Delegates to node_add
# node_transfer <src_monitor_id> <src_desktop_id> <src_node_id> <dst_monitor_id> <dst_desktop_id> <dst_node_id>
on_node_transfer(){
    # node_add <monitor_id> <desktop_id> <ip_id> <node_id>
    on_node_add $4 $5 "" $3;
}
