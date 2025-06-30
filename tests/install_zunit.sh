#!/bin/bash
# Install zunit testing framework

ZUNIT_VERSION="v0.8.2"
INSTALL_DIR="tests/.zunit"

if [ -d "$INSTALL_DIR" ]; then
    echo "zunit is already installed in $INSTALL_DIR"
    exit 0
fi

echo "Installing zunit $ZUNIT_VERSION..."
mkdir -p "$INSTALL_DIR"

# Download zunit
curl -sL "https://github.com/zunit-zsh/zunit/releases/download/$ZUNIT_VERSION/zunit" -o "$INSTALL_DIR/zunit"
chmod +x "$INSTALL_DIR/zunit"

echo "zunit installed successfully!"