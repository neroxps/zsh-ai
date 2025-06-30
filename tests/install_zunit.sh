#!/bin/bash
# Install zunit testing framework

ZUNIT_VERSION="v0.8.2"
REVOLVER_VERSION="v0.2.5"

# Determine the correct install directory based on where we're running from
if [[ "$PWD" == */tests ]]; then
    INSTALL_DIR=".zunit"
else
    INSTALL_DIR="tests/.zunit"
fi

if [ -d "$INSTALL_DIR" ]; then
    echo "zunit is already installed in $INSTALL_DIR"
    exit 0
fi

echo "Installing zunit $ZUNIT_VERSION..."
mkdir -p "$INSTALL_DIR"

# Download and install revolver (required dependency)
echo "Installing revolver dependency..."
curl -sL "https://github.com/molovo/revolver/archive/${REVOLVER_VERSION}.tar.gz" | tar xz -C "$INSTALL_DIR"
mv "$INSTALL_DIR/revolver-${REVOLVER_VERSION#v}/revolver" "$INSTALL_DIR/"
rm -rf "$INSTALL_DIR/revolver-${REVOLVER_VERSION#v}"

# Download zunit
curl -sL "https://github.com/zunit-zsh/zunit/releases/download/$ZUNIT_VERSION/zunit" -o "$INSTALL_DIR/zunit"
chmod +x "$INSTALL_DIR/zunit"

echo "zunit installed successfully!"