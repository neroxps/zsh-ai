# 🪄 zsh-ai

> The lightweight AI assistant that lives in your terminal

Transform natural language into shell commands instantly. Works with cloud-based AI (Anthropic Claude, Google Gemini) and local models (Ollama). No dependencies, no complex setup - just type what you want and get the command you need.

<img src="https://img.shields.io/github/v/release/matheusml/ai-zsh?label=version&color=yellow" alt="Version"> <img src="https://img.shields.io/badge/dependencies-zero-brightgreen" alt="Zero Dependencies"> <img src="https://img.shields.io/badge/size-<5KB-blue" alt="Tiny Size"> <img src="https://img.shields.io/github/license/matheusml/ai-zsh?color=purple" alt="License"> <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey" alt="Platform">

## Why zsh-ai?

**🪶 Featherweight** - A single 5KB shell script. No Python, no Node.js, etc.

**🚀 Lightning Fast** - Starts instantly with your shell.

**🎯 Dead Simple** - Just type `# what you want to do` and press Enter. That's it.

**🔒 Privacy First** - Use local Ollama models for complete privacy, or bring your own API keys. Your commands stay local, API calls only when you trigger them.

**🛠️ Zero Dependencies** - Optionally `jq` for reliability.

**🧠 Context Aware** - Automatically detects project type, git status, and current directory for smarter suggestions.

## Demo


https://github.com/user-attachments/assets/2d20b4ee-fe1a-466a-af9f-bb04b2bc4f71


### Method 1: Comment Syntax (Recommended)
```bash
$ # find all large files modified this week
$ find . -type f -size +50M -mtime -7

$ # kill process using port 3000  
$ lsof -ti:3000 | xargs kill -9

$ # compress images in current directory
$ for img in *.{jpg,png}; do convert "$img" -quality 85 "$img"; done
```

### Method 2: Direct Command
```bash
$ zsh-ai "find all large files modified this week"
$ find . -type f -size +50M -mtime -7

$ zsh-ai "kill process using port 3000"
$ lsof -ti:3000 | xargs kill -9

$ zsh-ai "compress images in current directory"
$ for img in *.{jpg,png}; do convert "$img" -quality 85 "$img"; done
```

Just type what you want in plain English, get the exact command you need.

### AI-Powered Command Fix Suggestions 🤖 (Optional)

Made a typo? Enable auto-fix to get AI-powered suggestions when commands fail.

Enable it by adding to your `~/.zshrc`:
```bash
export ZSH_AI_AUTO_FIX="true"
```

Example:
```bash
$ git statu
git: 'statu' is not a git command. See 'git --help'.

🤖 [zsh-ai] Did you mean: git status

$ l -la
zsh: command not found: l

🤖 [zsh-ai] Did you mean: ls -la
```

Simply copy and run the suggested command. No more manual corrections!

## Quick Start

1. **Install** - Choose your preferred method:
   ```bash
   # Homebrew (recommended)
   brew tap matheusml/zsh-ai && brew install zsh-ai
   ```
   
2. **Configure** - Set up your AI provider (Anthropic, Gemini, or Ollama)

3. **Use** - Type `# your command` and press Enter!

📚 **[Full Installation Guide →](INSTALL.md)**

## Documentation

- 📦 **[Installation & Setup](INSTALL.md)** - Detailed installation instructions for all package managers
- 🔧 **[Configuration](INSTALL.md#configuration)** - API keys, providers, and customization options  
- 🚨 **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions
- 🤝 **[Contributing](CONTRIBUTING.md)** - Help make zsh-ai better!
