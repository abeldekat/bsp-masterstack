STATE_DIR="/tmp/bsp-masterstack.state";
DESKTOP_STATE="$STATE_DIR/desktops";
GUARD_FILE_NAME="GUARD";

# (Data ->) :: Key -> Value -> Data
append_option() { sed "/^$1:/d"; echo "$1:$2"; }

# (Data ->) :: Key -> Data[Key]
valueof() { awk -F':' "/^$1:/ {print \$2}"; }

# :: List[DesktopName]
list_desktops() { ls -1 "$DESKTOP_STATE"; }

# :: DesktopName -> Data
get_desktop_options() { cat "$DESKTOP_STATE/$1" 2> /dev/null || true; }
# :: DesktopName -> Key -> Value -> ()
set_desktop_option() {
    local new_options=$(get_desktop_options "$1" | append_option $2 $3);
    echo "$new_options" > "$DESKTOP_STATE/$1";
}
# :: DesktopName
remove_desktop_options(){
    [[ -f "$DESKTOP_STATE/$1" ]] && \rm "$DESKTOP_STATE/$1";
}

get_guard_data() { cat "$STATE_DIR/$GUARD_FILE_NAME" 2> /dev/null || true; }
set_guard_data() {
    local new_options=$(get_guard_data | append_option $1 $2);
    echo "$new_options" > "$STATE_DIR/$GUARD_FILE_NAME";
}
 mkdir -p "$DESKTOP_STATE";
