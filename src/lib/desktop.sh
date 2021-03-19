get_focused_desktop(){ 
    bspc query -D -d 'focused' --names; 
}
# $1 The name of the desktop
get_desktop_name_from_id(){ 
    bspc query -D -d "$1" --names; 
}
# Sending multiple leaves inside an unfocused desktop:
# The computer refuses to shut down later on.....
# Is related to setting removal_adjustment
# $1 true or false
set_removal_adjustment(){
    bspc config removal_adjustment $1;
}
