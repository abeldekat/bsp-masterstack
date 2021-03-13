XDG_CONF=${XDG_CONFIG_DIR:-"$HOME/.config"};
CONFIG_DIR="$XDG_CONF/bsp-masterstack";

# Default config
export SPLIT_RATIO=0.6;

source "$CONFIG_DIR/masterstackrc" 2> /dev/null || true;
