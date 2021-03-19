#!/usr/bin/env bash

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
