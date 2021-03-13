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
