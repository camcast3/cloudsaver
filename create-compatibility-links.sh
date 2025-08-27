#!/bin/bash

# Backward Compatibility Setup
# Creates symlinks for existing EmuDeck users so their existing scripts continue to work

SCRIPT_DIR="$(dirname "$0")"

echo "Creating backward compatibility symlinks for EmuDeck users..."

# Create symlinks for renamed scripts
ln -sf "$SCRIPT_DIR/emulation-save-sync.sh" "$SCRIPT_DIR/emudeck-sync.sh"
ln -sf "$SCRIPT_DIR/emulation-save-setup.sh" "$SCRIPT_DIR/emudeck-setup.sh"  
ln -sf "$SCRIPT_DIR/emulation-save-wrapper.sh" "$SCRIPT_DIR/emudeck-wrapper.sh"
ln -sf "$SCRIPT_DIR/emulation-steam-launcher.sh" "$SCRIPT_DIR/emudeck-steam-launch.sh"

# Create config directory symlink if it doesn't exist
if [ ! -d "$HOME/.config/emudeck-sync" ] && [ -d "$HOME/.config/emulation-save-sync" ]; then
    ln -sf "$HOME/.config/emulation-save-sync" "$HOME/.config/emudeck-sync"
fi

echo "Backward compatibility setup complete!"
echo "Existing EmuDeck scripts will continue to work."
