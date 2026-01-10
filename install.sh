#!/bin/bash
# =============================================================================
# WezTerm Parallel Development - Install Script
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZSHRC="$HOME/.zshrc"

echo "Installing WezTerm Parallel Development config..."

# Create config directories
mkdir -p ~/.config/wezterm
mkdir -p ~/.config/zsh
mkdir -p ~/.config/sheldon

# Backup existing configs
if [[ -f ~/.config/wezterm/wezterm.lua ]] && [[ ! -L ~/.config/wezterm/wezterm.lua ]]; then
  echo "Backing up existing wezterm.lua..."
  mv ~/.config/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua.backup
fi

if [[ -f ~/.config/zsh/parallel-dev.zsh ]] && [[ ! -L ~/.config/zsh/parallel-dev.zsh ]]; then
  echo "Backing up existing parallel-dev.zsh..."
  mv ~/.config/zsh/parallel-dev.zsh ~/.config/zsh/parallel-dev.zsh.backup
fi

if [[ -f ~/.config/sheldon/plugins.toml ]] && [[ ! -L ~/.config/sheldon/plugins.toml ]]; then
  echo "Backing up existing sheldon plugins.toml..."
  mv ~/.config/sheldon/plugins.toml ~/.config/sheldon/plugins.toml.backup
fi

# Create symlinks
echo "Creating symlinks..."
ln -sf "$SCRIPT_DIR/wezterm/wezterm.lua" ~/.config/wezterm/wezterm.lua
ln -sf "$SCRIPT_DIR/zsh/parallel-dev.zsh" ~/.config/zsh/parallel-dev.zsh
ln -sf "$SCRIPT_DIR/zsh/.p10k.zsh" ~/.config/zsh/.p10k.zsh
ln -sf "$SCRIPT_DIR/sheldon/plugins.toml" ~/.config/sheldon/plugins.toml

# Update zshrc
echo "Updating ~/.zshrc..."

# Add WezTerm CLI to PATH if not present
if ! grep -q "WezTerm.app/Contents/MacOS" "$ZSHRC" 2>/dev/null; then
  echo "Adding WezTerm CLI to PATH..."
  # Find the path=( block and add WezTerm path
  if grep -q "^path=(" "$ZSHRC"; then
    # Insert after /Library/Apple/usr/bin or at end of path array
    sed -i '' '/\/Library\/Apple\/usr\/bin/a\
  /Applications/WezTerm.app/Contents/MacOS(N-/)
' "$ZSHRC" 2>/dev/null || \
    sed -i '' '/^path=(/,/)/{
      /)/{
        i\
  /Applications/WezTerm.app/Contents/MacOS(N-/)
      }
    }' "$ZSHRC"
  else
    # No path array found, add export
    echo '' >> "$ZSHRC"
    echo '# WezTerm CLI' >> "$ZSHRC"
    echo 'export PATH="/Applications/WezTerm.app/Contents/MacOS:$PATH"' >> "$ZSHRC"
  fi
fi

# Add parallel-dev.zsh source if not present (includes sheldon, fzf, zoxide, colors)
if ! grep -q "parallel-dev.zsh" "$ZSHRC" 2>/dev/null; then
  echo "Adding parallel-dev.zsh source..."
  echo '' >> "$ZSHRC"
  echo '# Parallel Development (sheldon, fzf, zoxide, color settings, commands)' >> "$ZSHRC"
  echo 'source ~/.config/zsh/parallel-dev.zsh' >> "$ZSHRC"
fi

echo ""
echo "Done!"
echo ""

# source は親シェルに反映されないため、実行方法に応じて対応
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] || [[ -n "$ZSH_VERSION" && "$ZSH_EVAL_CONTEXT" =~ :file$ ]]; then
  # source で実行された場合
  echo "Reloading zshrc..."
  source "$ZSHRC"
  echo "Ready!"
else
  # ./install.sh で実行された場合
  echo "Run: source ~/.zshrc"
fi
