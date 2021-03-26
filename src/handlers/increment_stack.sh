#!/usr/bin/env bash

# The code handles increment/decrement. These are internal operations
# acting on a fixed set of nodes
# Outside operations also influence the increment stack if present.
# Examples: Node add, node remove

# Map from orientation to its below position
declare -A _to_below=(["$DIR_WEST"]="$DIR_SOUTH" \
    ["$DIR_NORTH"]="$DIR_EAST" \
    ["$DIR_EAST"]="$DIR_SOUTH" \
    ["$DIR_SOUTH"]="$DIR_EAST");

# Map from orientation to its ontop position
declare -A _to_ontop=(["$DIR_WEST"]="$DIR_NORTH" \
    ["$DIR_NORTH"]="$DIR_WEST" \
    ["$DIR_EAST"]="$DIR_NORTH" \
    ["$DIR_SOUTH"]="$DIR_WEST");

NR_INCREMENTS=0;
MEMBERS=();

# $1 source node id to be transferred
# $2 target node id  to transfer to
_transfer_and_add_to_members(){
    local source_id=$1;
    local target_id=$2;
    # echo "_transfer_and_add starting, source[$source_id]";

    transfer $source_id $target_id;
    MEMBERS+=("$source_id");
    NR_INCREMENTS="${#MEMBERS[@]}";
    # echo "_transfer_and_add: counter[$NR_INCREMENTS], [${MEMBERS[@]}]";
}

# $1 source node id to be transferred
# $2 path to transfer to
_transfer_and_remove_from_members(){
    local source_id=$1;
    local target_path=$2;
    # echo "_transfer_and_remove starting, source[$source_id]";

    transfer $source_id $target_path;
    _remove_from_members $source_id;
}

# $1 node id to remove
# Remove node from internal members array of increment stack
_remove_from_members(){
    local node_id=$1;
    local index="";

    # echo "Remove member [$node_id]";
    for i in "${!MEMBERS[@]}"; do
        if [[ ${MEMBERS[$i]} == $node_id ]]; then
            index=$i;
            break;
        fi
    done

    if [[ -n $index ]]; then
        # echo "remove [$node_id] on index [$index]";
        unset MEMBERS[$index];
        NR_INCREMENTS="${#MEMBERS[@]}";
    fi
    # echo  "_remove_from_members: counter[$NR_INCREMENTS], [${MEMBERS[@]}]";
}

# $1 node to test
# $2 boolean is node from master
_is_member_of_increment_stack(){
    local node_to_test=$1;
    local is_master=$2;
    local result=false;

    if ! $is_master; then
        for node in "${MEMBERS[@]}"; do
            if [[ $node == $node_to_test ]]; then
                result=true;
                break;
            fi
        done
    fi
    echo $result;
}

# $1 boolean is master node
# $2 boolean is member node
_is_node_from_dynamic_stack(){
    local result=true;
    ($1 || $2) && result=false;
    echo $result;
}

# On the last increment the stack becomes empty. 
# Bspwm will remove the internal node thereby invalidating the global variables.
# Make sure the stack remains part of the tree by adding a small receptacle
_protect_stack_with_receptacle(){
    # echo "Retain stack position using receptacle on [$DESKTOP_ROOT]";
    create_receptacle $DESKTOP_ROOT "$STACK_ORIENTATION" $STACK_PROTECTION_RATIO;
}

# Desktop contains one leaf: Remove receptacle
_unprotect_stack_with_receptacle(){
    # echo "Remove all receptacles on [$DESKTOP_ROOT]";
    remove_all_receptacles $DESKTOP_ROOT;
}

# User action: Deletes last item from the *dynamic* stack
# Result: Increment stack is now positioned on dynamic stack...
# Solve this case with a receptacle
_protect_dynamic_stack(){
    local nr_in_increment="$(query_number_of_leaves $MASTER_INCREMENT)";

    # registered increments should equal actual increments
    # because node is not deleted from increment stack
    [[ $nr_in_increment -ne $NR_INCREMENTS ]] && \
        _protect_stack_with_receptacle;
    balance $STACK;
}

# $1 source leaf in master increment stack to transfer
_transfer_to_top_of_stack(){
    local node_id=$1;
    local leaves_in_stack=($(query_leaves $STACK));
    local nr_in_stack=${#leaves_in_stack[@]};

    # echo "transfer [$node_id] to stack[$STACK] containing [$nr_in_stack]";
    _transfer_and_remove_from_members $node_id $STACK;

    if [[ $nr_in_stack -eq 0 ]]; then
        # Stack was empty before the transfer
        equalize;
    else
        balance $MASTER
        balance $STACK;
    fi
}

# $1 nr_in_stack
_transfer_to_increment_stack(){
    local nr_in_stack=$1;

    # echo "increment: retrieve leaves in master increment [$MASTER_INCREMENT]";
    local leaves_in_increment=($(query_leaves $MASTER_INCREMENT));
    local nr_in_increment=${#leaves_in_increment[@]};
    local target_leaf="$MASTER";
    [[ $nr_in_increment -gt 0 ]] && \
        target_leaf="${leaves_in_increment[$INCREMENT_TAIL_INDEX]}";
    create_receptacle $target_leaf ${_to_below[$ORIENTATION]} $PRESEL_RATIO;
    local receptacle_id="$(query_receptacle $MASTER_INCREMENT)";

    # echo "increment: Move top of the stack to receptacle [$receptacle_id]";
    local path_to_source=$STACK_NEWNODE;
    [[ $nr_in_stack -eq 1 ]] && path_to_source=$STACK;
    local source_id="$(query_node $path_to_source)";

    _transfer_and_add_to_members $source_id $receptacle_id;
    [[ $nr_in_stack -eq 1 ]] && _protect_stack_with_receptacle;

    balance $MASTER;
}

# Removes a member from the members array
# Special case: The removed node was located on master
_remove_node_handle_member(){
    local member_to_remove=$1;
    local is_removed_from_master=$2;

    if $is_removed_from_master; then
        # previous head of increment stack is now on master
        local current_size="${#MEMBERS[@]}";
        local master_path=$MASTER;
        [[ $current_size -gt 1 ]] && master_path=$MASTER_NEWNODE;

        local member_to_remove="$(query_node $master_path)";
        save_master_node "$member_to_remove"; 
    fi
    _remove_from_members $member_to_remove;
}

# Tries to refill the increment stack with one node from the
# dynamic stack
_remove_node_handle_dynamic_stack(){
    local nr_in_stack="$(query_number_of_leaves $STACK)";
    if [[ $nr_in_stack -eq 0 ]]; then
        # echo "remove: dynamic stack is empty";
        if [[ $NR_INCREMENTS -eq 0 ]]; then
            _unprotect_stack_with_receptacle;
        fi
    else
        # echo "remove: add one item from dynamic stack";
        _transfer_to_increment_stack $nr_in_stack;
    fi
}

# Is the increment stack present
has_increment_stack(){
    local result=false;
    [[ $NR_INCREMENTS -ne 0 ]] && result=true;
    echo $result;
}

# Increment master increment stack with leafs from dynamic stack
# An example of master @/1/1 with three increments:
# @/1/2/1 @/1/2/2/1 @/1/2/2/2 
increment(){
    # echo "increment: counter start [$NR_INCREMENTS]";
    "$(has_no_master $DESKTOPNAME)" && return;

    # echo "increment: retrieve leaves in stack [$STACK]";
    local nr_in_stack="$(query_number_of_leaves $STACK)";
    [[ $nr_in_stack -eq 0 ]] && return; 

    _transfer_to_increment_stack $nr_in_stack;
}

# Decrement leafs in increment stack back into dynamic stack
decrement(){
    # echo "decrement: counter start [$NR_INCREMENTS], require at least 1";
    [[ $NR_INCREMENTS -eq 0 ]] && return;

    # echo "decrement: retrieve leaves in master increment [$MASTER_INCREMENT]";
    local leaves_in_increment=($(query_leaves $MASTER_INCREMENT));
    local nr_in_increment=${#leaves_in_increment[@]};

    local src_leaf="${leaves_in_increment[$INCREMENT_TAIL_INDEX]}";

    # echo "decrement: [$nr_in_increment] leaves, source leaf [$src_leaf]";
    _transfer_to_top_of_stack $src_leaf;
}

# A new node (ie old master) must be added to the increment stack
# $1 node_id to transfer into the increment stack
add_node_to_increment_stack(){
    # echo "add_node: counter start [$NR_INCREMENTS]";

    local node_id=$1;
    local leaves_in_increment=($(query_leaves $MASTER_INCREMENT));
    local head_leaf="${leaves_in_increment[$INCREMENT_HEAD_INDEX]}"

    # echo "transfer node [$node_id] to top of the increment stack"
    create_receptacle $head_leaf ${_to_ontop[$ORIENTATION]} $PRESEL_RATIO;
    local receptacle_id="$(query_receptacle $MASTER_INCREMENT)";
    _transfer_and_add_to_members $node_id $receptacle_id;

    local tail_leaf="${leaves_in_increment[$INCREMENT_TAIL_INDEX]}"
    _transfer_to_top_of_stack $tail_leaf;
}

# A node is deleted.
# $1 node_id of deleted node
# $2 boolean: deleted node is master node
remove_node_from_increment_stack(){
    # echo "remove: counter[$NR_INCREMENTS] --> started";
    local removed_id=$1;
    local is_master=$2;
    local is_member="$(_is_member_of_increment_stack $removed_id $is_master)"; 
    local is_dynamic="$(_is_node_from_dynamic_stack $is_master $is_member)";
    # echo  "remove: Node location: [$is_master] [$is_member] [$is_dynamic]";

    if $is_dynamic; then 
        _protect_dynamic_stack;
        return;
    fi

    _remove_node_handle_member $removed_id $is_master;
    _remove_node_handle_dynamic_stack;
    balance $MASTER;
    # echo "remove: counter[$NR_INCREMENTS] --> finished";
}
