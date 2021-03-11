# Note: The code tests against master as master normally would contain
# the least amount of nodes.
#
# $1 the nodeid to test
# $2 the absolute path to master
# Returns: true if nodeid is part of the stack node.
is_node_in_stack(){
    local result=false;
    [[ -z "$(bspc query -N $1 -n $2.ancestor_of)" ]] && result=true; 
    echo $result;
}

# See is_node_in_stack
# Returns: true if nodeid is part of the master node.
is_node_in_master(){
    local result=false;
    [[ -n "$(bspc query -N $1 -n $2.ancestor_of)" ]] && result=true; 
    echo $result;
}

# $1 path to test
is_leaf(){
    local result=false;
    [[ -n "$(bspc query -N -n $1/.leaf)" ]] && result=true;
    echo $result;
}

# $1 The source node
# $2 The target node
swap(){
    bspc node $1 -s $2;
}

# $1 The source node
# $2 The target node
transfer(){
    bspc node $1 -n $2;
}

# $1 path to rotate
# $2 rotation
rotate(){
    bspc node $1 -R $2;
}

# All nodes in $1 will occupy the same space
balance(){
    bspc node "$1" -B;
}

# All nodes in $1 will restore based on split_ratio
equalize(){
    bspc node "$1" -E
}

equalize_and_balance() {
    equalize $1;
    balance $2;
}

# $1 Node to query
# Result: All leaves in node in reversed order
_query_all_leaves_reversed(){
    echo "$(bspc query -N $1 -n .descendant_of.leaf | tac)";
}

# $1 desktopname
# Result: the focussed node
_query_focused_node(){
    echo "$(bspc query -N -n focused -d $1)";
}
