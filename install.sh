#!/bin/bash
# =============================================================================
# WezTerm Parallel Development - Install Script
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing WezTerm Parallel Development config..."

# Create config directories
mkdir -p ~/.config/wezterm
mkdir -p ~/.config/zsh

# Backup existing configs
if [[ -f ~/.config/wezterm/wezterm.lua ]] && [[ ! -L ~/.config/wezterm/wezterm.lua ]]; then
  echo "Backing up existing wezterm.lua..."
  mv ~/.config/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua.backup
fi

if [[ -f ~/.config/zsh/parallel-dev.zsh ]] && [[ ! -L ~/.config/zsh/parallel-dev.zsh ]]; then
  echo "Backing up existing parallel-dev.zsh..."
  mv ~/.config/zsh/parallel-dev.zsh ~/.config/zsh/parallel-dev.zsh.backup
fi

# Create symlinks
echo "Creating symlinks..."
ln -sf "$SCRIPT_DIR/wezterm/wezterm.lua" ~/.config/wezterm/wezterm.lua
ln -sf "$SCRIPT_DIR/zsh/parallel-dev.zsh" ~/.config/zsh/parallel-dev.zsh

echo ""
echo "Done! Add the following to your ~/.zshrc if not already present:"
echo ""
echo "  # WezTerm CLI path (in your path array)"
echo "  /Applications/WezTerm.app/Contents/MacOS(N-/)"
echo ""
echo "  # Parallel Development Commands"
echo "  source ~/.config/zsh/parallel-dev.zsh"
echo ""
echo "Then run: source ~/.zshrc"
