# zsh-ai

AI-powered command generation for your terminal. Type natural language, get shell commands.

## Features

- 🚀 Convert natural language to shell commands
- 🎯 Simple syntax: just start with `# ` 
- ✏️ Review and edit commands before execution
- 🔧 Works with any zsh setup

## Prerequisites

- zsh (version 5.0+)
- An [Anthropic API key](https://console.anthropic.com/account/keys)
- `curl` (pre-installed on most systems)
- `jq` (optional, for better JSON parsing)

## Installation

### Oh My Zsh

```bash
git clone https://github.com/yourusername/zsh-ai ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai
```

Add `zsh-ai` to your plugins list in `~/.zshrc`:

```bash
plugins=(... zsh-ai)
```

### Manual Installation

```bash
git clone https://github.com/yourusername/zsh-ai ~/.zsh-ai
echo "source ~/.zsh-ai/zsh-ai.plugin.zsh" >> ~/.zshrc
```

### Setup

Set your Anthropic API key:

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

Add this to your `~/.zshrc` to make it permanent.

## Usage

### Interactive Mode (Recommended)

Simply type `# ` followed by your natural language command:

```bash
# list all PDF files in the current directory
# Generated command: ls *.pdf
# Press Enter to execute, or edit the command first
```

```bash
# find files larger than 100MB modified in the last week
# Generated command: find . -type f -size +100M -mtime -7
# Press Enter to execute, or edit the command first
```

### Function Mode

You can also use the `zsh-ai` function directly:

```bash
zsh-ai "show disk usage sorted by size"
# Generated command: du -sh * | sort -rh
# Execute? [y/N]
```

## Examples

```bash
# Show running Docker containers
# → docker ps

# Count lines of code in Python files
# → find . -name "*.py" -type f -exec wc -l {} + | awk '{sum+=$1} END {print sum}'

# Find and delete empty directories
# → find . -type d -empty -delete

# Show git commits from last week
# → git log --since="1 week ago" --oneline
```

## Tips

- Be specific in your descriptions for better results
- The generated command appears in your terminal for review
- Press Ctrl+C to cancel without executing
- Edit the generated command before pressing Enter if needed

## Troubleshooting

### API Key not found
```bash
zsh-ai: Warning: ANTHROPIC_API_KEY not set. Plugin will not function.
```
Solution: Set your API key as shown in the Setup section.

### Commands not intercepted
Make sure the plugin is properly sourced. Run:
```bash
echo $plugins  # For Oh My Zsh users
# or
which _zsh_ai_accept_line  # Should show the function
```

### JSON parsing errors
Install `jq` for better reliability:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

## License

MIT - See LICENSE file for details

## Contributing

Pull requests welcome! Please open an issue first to discuss major changes.

## Security

- Your API key is never stored by the plugin
- Commands are generated locally, not logged
- Always review generated commands before execution