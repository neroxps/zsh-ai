#!/bin/bash
# Test runner script for zsh-ai

set -e

echo "🧪 Running zsh-ai tests..."

# Check if zunit is installed
if [[ ! -f "tests/.zunit/zunit" ]]; then
    echo "📦 Installing zunit..."
    cd tests
    ./install_zunit.sh
    cd ..
fi

# Run all tests
export PATH="$PWD/tests/.zunit:$PATH"
cd tests

echo ""
echo "🏃 Running test suite..."
./.zunit/zunit "$@"

echo ""
echo "✅ All tests completed!"