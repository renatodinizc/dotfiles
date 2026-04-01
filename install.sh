#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

link() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "  Backing up $dest -> ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi
  ln -s "$src" "$dest"
  echo "  $dest -> $src"
}

echo "Installing dotfiles..."

# Claude Code
for file in $(find "$DOTFILES_DIR/claude" -type f 2>/dev/null); do
  relative="${file#$DOTFILES_DIR/claude/}"
  link "$file" "$HOME/.claude/$relative"
done

# Clean up dead symlinks (from deleted source files)
find "$HOME/.claude" -type l ! -exec test -e {} \; -print 2>/dev/null | while read -r dead; do
  rm "$dead"
  echo "  Removed stale symlink: $dead"
done

# Git
link "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

# Neovim
link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# VS Code
link "$DOTFILES_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

# GitHub CLI
link "$DOTFILES_DIR/gh/config.yml" "$HOME/.config/gh/config.yml"

# macOS keyboard repeat rate (fastest settings, requires logout to take effect)
if [ "$(uname)" = "Darwin" ]; then
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  echo "  macOS: keyboard repeat rate set (logout to apply)"
fi

# iTerm2 color scheme
ITERM2_THEME="$DOTFILES_DIR/iterm2/Night-Owl.itermcolors"
ITERM2_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
if [ -f "$ITERM2_THEME" ] && [ -f "$ITERM2_PLIST" ]; then
  PBUDDY=/usr/libexec/PlistBuddy

  # Add preset to Custom Color Presets (available in dropdown)
  "$PBUDDY" -c "Delete ':Custom Color Presets:Night%20Owl'" "$ITERM2_PLIST" 2>/dev/null || true
  "$PBUDDY" -c "Delete ':Custom Color Presets:Night Owl'" "$ITERM2_PLIST" 2>/dev/null || true
  "$PBUDDY" -c "Add ':Custom Color Presets:Night Owl' dict" "$ITERM2_PLIST" 2>/dev/null
  "$PBUDDY" -c "Merge '$ITERM2_THEME' ':Custom Color Presets:Night Owl'" "$ITERM2_PLIST" 2>/dev/null

  # Apply to Default profile: delete existing color keys, then merge fresh
  while IFS= read -r key; do
    "$PBUDDY" -c "Delete ':New Bookmarks:0:$key'" "$ITERM2_PLIST" 2>/dev/null || true
  done < <("$PBUDDY" -c "Print" "$ITERM2_THEME" 2>/dev/null | grep " = Dict" | sed 's/ = Dict.*//' | sed 's/^    //')
  "$PBUDDY" -c "Merge '$ITERM2_THEME' ':New Bookmarks:0'" "$ITERM2_PLIST" 2>/dev/null

  echo "  iTerm2: Night Owl theme installed and set as default"
else
  echo "  iTerm2: skipped ($([ ! -f "$ITERM2_PLIST" ] && echo "iTerm2 not installed" || echo "theme file missing"))"
fi

# MCP servers (requires API keys in .env)
if [ -f "$DOTFILES_DIR/.env" ]; then
  source "$DOTFILES_DIR/.env"

  if command -v claude &> /dev/null; then
    if [ -n "$TAVILY_API_KEY" ]; then
      claude mcp add -s user tavily -e TAVILY_API_KEY="$TAVILY_API_KEY" -- npx -y tavily-mcp@latest 2>/dev/null
      echo "  MCP: tavily configured"
    else
      echo "  MCP: tavily skipped (TAVILY_API_KEY not set in .env)"
    fi

  else
    echo "  MCP: claude CLI not found, skipping MCP server setup"
  fi
else
  echo "  MCP: no .env file found, skipping MCP server setup (see .env.example)"
fi

echo ""
echo "Recommended: add to your shell profile (~/.zshrc):"
echo "  export CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1"
echo "  # Prevents API keys from leaking to Claude Code subprocesses"
echo ""
echo "Done."
