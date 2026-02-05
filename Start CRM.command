#!/bin/bash
#
# Start CRM.command
#
# Double-click this file to launch the CRM app on your local network.
# No terminal commands required.
#

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to project directory
cd "$SCRIPT_DIR" || {
  echo "❌ ERROR: Cannot access project directory"
  echo "Press any key to exit..."
  read -n 1
  exit 1
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "❌ ERROR: Node.js is not installed"
  echo "═══════════════════════════════════════════════"
  echo ""
  echo "Please install Node.js to run the CRM app."
  echo ""
  echo "Download from: https://nodejs.org"
  echo ""
  echo "Or install via Homebrew:"
  echo "  brew install node"
  echo ""
  echo "Press any key to exit..."
  read -n 1
  exit 1
fi

# Display Node version
NODE_VERSION=$(node --version)
echo ""
echo "═══════════════════════════════════════════════"
echo "  CRM Local Network Launcher"
echo "═══════════════════════════════════════════════"
echo "Node.js: $NODE_VERSION"
echo ""

# Check if frontend is built
if [ ! -d "crm-web/dist" ]; then
  echo "⚠️  Frontend not built. Building now..."
  echo ""
  cd crm-web || exit 1
  npm run build || {
    echo ""
    echo "❌ ERROR: Frontend build failed"
    echo "Press any key to exit..."
    read -n 1
    exit 1
  }
  cd "$SCRIPT_DIR" || exit 1
  echo ""
fi

# Run the local server
echo "Starting CRM..."
echo ""
node run-local.cjs

# Keep terminal open if there's an error
if [ $? -ne 0 ]; then
  echo ""
  echo "❌ CRM stopped with errors"
  echo "Press any key to exit..."
  read -n 1
fi
