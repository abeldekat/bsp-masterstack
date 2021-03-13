#!/usr/bin/env bash

# A first attempt at maintaining master state
# This is required when using removal_adjustment=false
# The removal adjustment setting is important for a better UI

# For now, only one masterid exists
_masterid="";

save_master_node(){
    _masterid=$1;
    # echo "New masterid [$_masterid]";
}
forget_master_node(){
    echo "Todo forgetting master node";
}
is_master_node(){
    local result=false;
    [[ $1 == $_masterid ]] && result=true; 
    echo $result;
}
