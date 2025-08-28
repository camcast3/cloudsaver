#!/bin/bash
# Quick build and test script for CloudSaver

set -e  # Exit on any error

echo "📦 Building CloudSaver..."
npm run build

echo "🧪 Running basic tests..."
npm test

echo "✨ Testing emulator detection..."
node dist/cli/index.js detect

echo "🔍 Getting current configuration..."
node dist/cli/index.js config get

echo ""
echo "✅ Build and test complete!"
echo ""
echo "Next steps:"
echo "  1. Configure a cloud provider: node dist/cli/index.js config set cloudProvider <your-provider>"
echo "  2. Run a sync: node dist/cli/index.js advanced-sync"
echo "  3. Try a wrapper script: ./cloudsaver-wrapper.sh <emulator> <emulator-command>"
echo ""
