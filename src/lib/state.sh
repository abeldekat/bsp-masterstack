STATE_DIR="/tmp/bsp-masterstack.state";

DESKTOP_STATE="$STATE_DIR/desktops";
DESKTOP_FIFO="$STATE_DIR/fifo";
GUARD_FILE="$STATE_DIR/GUARD";

# West resembles the default way bspwm operates on alternate with first_child
DIR_WEST="west";
DIR_NORTH="north";
DIR_EAST="east";
DIR_SOUTH="south";

# IPC 
READY_REPLY="ready";

# $1 key
# $2 value
# Adds or replaces "key":"value" in data stream
append_option() { sed "/^$1:/d"; echo "$1:$2"; }

# $1 key
# Returns value of key in data stream
valueof() { awk -F':' "/^$1:/ {print \$2}"; }

# Lists all desktops present in DESKTOP_STATE
list_desktops() { ls -1 "$DESKTOP_STATE"; }

# Returns all data stored for desktop $1
get_desktop_options() { cat "$DESKTOP_STATE/$1" 2> /dev/null || true; }

# $1 desktopname
# $2 key
# $3 value
# Inserts or replaces the line with "key" with the new "value"
set_desktop_option() {
    local new_options=$(get_desktop_options "$1" | append_option $2 $3);
    echo "$new_options" > "$DESKTOP_STATE/$1";
}

# Save pid $2 for desktopname $1
save_pid(){
    set_desktop_option "$1" 'pid' "$2";
}

# Clears pid for desktopname $1
clear_pid(){
    set_desktop_option "$1" 'pid' "";
}

# Returns pid for desktopname $1
get_pid(){
    echo "$(get_desktop_options "$1" | valueof pid)"
}

# Returns the full path to the fifo used by the command listener 
# in desktop $1
get_command_fifo() { echo "$DESKTOP_FIFO/$1"; }

# Returns the full path to the fifo used by desktop $1 to 
# reply to a command.
get_reply_fifo() { echo "$DESKTOP_FIFO/$1-reply"; }

# Returns all data stored for the GUARD
get_guard_data() { cat "$GUARD_FILE" 2> /dev/null || true; }

# $1 key
# $2 value
# Inserts or replaces the line with "key" with the new "value"
set_guard_data() {
    local new_options=$(get_guard_data | append_option $1 $2);
    echo "$new_options" > "$GUARD_FILE";
}

# Save pid $1 for the guard
save_guard_id(){
    set_guard_data 'pid' "$1";
}

# Clears pid for the guard
clear_guard_id(){
    set_guard_data 'pid' "";
}

# Returns pid for the guard
get_guard_id(){
    echo "$(get_guard_data | valueof pid)";
}

# Make sure all directories exist
mkdir -p "$DESKTOP_STATE";
mkdir -p "$DESKTOP_FIFO";
