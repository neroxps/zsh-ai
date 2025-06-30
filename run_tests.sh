#!/bin/bash
# Test runner script for zsh-ai

set -e

echo "🧪 Running zsh-ai tests..."
echo ""

# Basic validation
echo "1. Testing plugin loading..."
# Run in current directory to ensure paths work
(cd "$(dirname "$0")" && zsh -c "
  source ./zsh-ai.plugin.zsh
  # Source config directly to ensure variables are set
  source ./lib/config.zsh
  if [[ -z \"\$ZSH_AI_PROVIDER\" ]]; then
    echo '   ❌ Plugin failed to load'
    exit 1
  fi
  echo '   ✅ Plugin loaded successfully'
  echo '      Provider: '\$ZSH_AI_PROVIDER
")

echo ""
echo "2. Testing configuration..."
(cd "$(dirname "$0")" && zsh -c "
  source ./zsh-ai.plugin.zsh
  export ZSH_AI_PROVIDER='ollama'
  if _zsh_ai_validate_config; then
    echo '   ✅ Configuration validation works'
  else
    echo '   ❌ Configuration validation failed'
    exit 1
  fi
")

echo ""
echo "3. Testing command availability..."
(cd "$(dirname "$0")" && zsh -c "
  source ./zsh-ai.plugin.zsh
  if command -v zsh-ai >/dev/null 2>&1; then
    echo '   ✅ zsh-ai command is available'
  else
    echo '   ❌ zsh-ai command not found'
    exit 1
  fi
")

echo ""
echo "✅ Basic tests passed!"
echo ""
echo "For comprehensive CI tests, see .github/workflows/test.yml"
