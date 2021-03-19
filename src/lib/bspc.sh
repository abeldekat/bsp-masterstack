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

# $1 Path to node
# Returns nodeid if path exists
query_node(){
    bspc query -N -n $1;
}

# $1 path to test
is_leaf(){
    local result=false;
    [[ -n "$(bspc query -N -n $1/.leaf)" ]] && result=true;
    echo $result;
}

# $1 The node to focus
focus_node(){
    bspc node -f $1;
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

# Note: Rotate exits cleanly if applied to a leaf
# $1 path to rotate
# $2 rotation
rotate(){
    bspc node $1 -R $2;
}

# All nodes in $1 will occupy the same space
balance(){
    bspc node "$1" -B;
}

# $1 path to query
# Result: All leaves in path in reversed order
query_leaves_reversed(){
    echo "$(bspc query -N $1 -n .descendant_of.leaf.window | tac)";
}

# $1 desktopname
# Result: the focused node
query_focused_node(){
    echo "$(bspc query -N -n focused -d $1)";
}

# $1 desktoppath
# $2 orientation
# $3 presel_ratio
receptacle(){
    bspc node "$1/" -p $2 -o $3 -i;
}

# $1 The name of the desktop
desktop_has_focus(){
    local result=true;
    local focused="$(get_focused_desktop)";
    [[ "$focused" != "$1" ]] && result=false;
    echo $result;
}

# Empty desktop or root is a leaf
# $1 The name of the desktop
has_no_master(){
    local result=false;
    if "$(_desktop_is_empty $1)" || "$(is_leaf "@$1:/")"; then
        result=true;
    fi
    echo $result;
}

# $1 The name of the desktop
has_master(){
    local result=true;
    if "$(has_no_master $1)"; then result=false; fi
    echo $result;
}

# $1 The name of the desktop
_desktop_is_empty(){
    local result=false;
    local desktopid="$(bspc query -D -d $1.\!occupied)";
    [[ -n $desktopid ]] && result=true;
    echo $result;
}
