get_focused_desktop(){ 
    bspc query -D -d 'focused' --names; 
}
get_desktop_name_from_id(){ 
    bspc query -D -d "$1" --names; 
}
# $1 The name of the desktop
desktop_is_empty(){
    local result=false;
    local desktopid="$(bspc query -D -d $1.\!occupied)";
    [[ -n $desktopid ]] && result=true;
    echo $result;
}
# Empty desktop or root is a leaf
# $1 The name of the desktop
has_no_master(){
    local result=false;
    if "$(desktop_is_empty $1)" || "$(is_leaf "@$1:/")"; then
        result=true;
    fi
    echo $result;
}
