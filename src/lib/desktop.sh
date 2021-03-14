get_focused_desktop(){ 
    bspc query -D -d 'focused' --names; 
}
# $1 The name of the desktop
get_desktop_name_from_id(){ 
    bspc query -D -d "$1" --names; 
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
# $1 path to test
is_leaf(){
    local result=false;
    [[ -n "$(bspc query -N -n $1/.leaf)" ]] && result=true;
    echo $result;
}
# $1 The name of the desktop
_desktop_is_empty(){
    local result=false;
    local desktopid="$(bspc query -D -d $1.\!occupied)";
    [[ -n $desktopid ]] && result=true;
    echo $result;
}
