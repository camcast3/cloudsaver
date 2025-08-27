#!/bin/bash

# EmuDeck Save Sync Installation Script
# Makes all scripts executable and shows usage information

echo "EmuDeck Save Sync - Installation"
echo "================================"
echo ""

# Make all scripts executable
echo "Making scripts executable..."
chmod +x emudeck-sync.sh
chmod +x emudeck-wrapper.sh
chmod +x emudeck-setup.sh
chmod +x emudeck-steam-launch.sh
chmod +x install.sh

echo "✅ Scripts are now executable"
echo ""

echo "Next steps:"
echo "1. Run the setup script to configure rclone:"
echo "   ./emudeck-setup.sh"
echo ""
echo "2. Test the configuration:"
echo "   ./emudeck-sync.sh status"
echo ""
echo "3. Read the full documentation:"
echo "   cat README-EmuDeck-Sync.md"
echo ""
echo "Installation complete!"
