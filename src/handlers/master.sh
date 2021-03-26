#!/usr/bin/env bash

save_master_node(){
    MASTER_ID=$1;
    # echo "Saved new masterid [$MASTER_ID]";
}

is_master_node(){
    local result=false;
    [[ $1 == $MASTER_ID ]] && result=true; 
    echo $result;
}

focus_master_node(){
    focus_node $MASTER_ID;
}

is_brother_of_master_node(){
    local test_node=$1;
    local result=false;

    local brother_node="$(query_brother $MASTER_ID)";
    [[ $test_node == $brother_node ]] && result=true;
    echo $result;
}
