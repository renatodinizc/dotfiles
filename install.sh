#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }

link() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  # Skip if dest resolves to the same file as src (e.g. parent dir is a symlink back to dotfiles)
  local real_src real_dest
  real_src="$(realpath "$src" 2>/dev/null || echo "$src")"
  real_dest="$(realpath "$dest" 2>/dev/null || echo "")"
  if [ "$real_src" = "$real_dest" ]; then
    echo "  Skipping $dest (already resolves to $src)"
    return
  fi
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "  Backing up $dest -> ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi
  ln -s "$src" "$dest"
  echo "  $dest -> $src"
}

# --- Sections ---

install_claude() {
  echo "Claude Code..."
  for file in $(find "$DOTFILES_DIR/claude" -type f 2>/dev/null); do
    relative="${file#$DOTFILES_DIR/claude/}"
    link "$file" "$HOME/.claude/$relative"
  done

  # Clean up dead symlinks (from deleted source files)
  find "$HOME/.claude" -type l ! -exec test -e {} \; -print 2>/dev/null | while read -r dead; do
    rm "$dead"
    echo "  Removed stale symlink: $dead"
  done
}

install_git() {
  echo "Git..."
  link "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
}

install_nvim() {
  echo "Neovim..."
  link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
}

install_vscode() {
  echo "VS Code..."
  link "$DOTFILES_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
}

install_gh() {
  echo "GitHub CLI..."
  link "$DOTFILES_DIR/gh/config.yml" "$HOME/.config/gh/config.yml"
}

install_macos() {
  echo "macOS settings..."
  if [ "$(uname)" != "Darwin" ]; then
    yellow "  Skipped (not macOS)"
    return
  fi
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  # Trackpad: tap to click, three-finger drag, force click
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
  defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 0
  defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0
  defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool true
  echo "  macOS: keyboard and trackpad settings applied (logout to apply)"
}

install_iterm2() {
  echo "iTerm2..."
  ITERM2_THEME="$DOTFILES_DIR/iterm2/Night-Owl.itermcolors"
  ITERM2_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
  if [ -f "$ITERM2_THEME" ] && [ -f "$ITERM2_PLIST" ]; then
    if pgrep -x iTerm2 > /dev/null 2>&1; then
      yellow "  iTerm2: SKIPPED - quit iTerm2 first (it overwrites plist changes on exit)"
    else
      PBUDDY=/usr/libexec/PlistBuddy

      # Add preset to Custom Color Presets (available in dropdown)
      "$PBUDDY" -c "Delete ':Custom Color Presets:Night%20Owl'" "$ITERM2_PLIST" 2>/dev/null || true
      "$PBUDDY" -c "Delete ':Custom Color Presets:Night Owl'" "$ITERM2_PLIST" 2>/dev/null || true
      "$PBUDDY" -c "Add ':Custom Color Presets:Night Owl' dict" "$ITERM2_PLIST" 2>/dev/null
      "$PBUDDY" -c "Merge '$ITERM2_THEME' ':Custom Color Presets:Night Owl'" "$ITERM2_PLIST" 2>/dev/null

      # Apply to Default profile: delete existing color keys, then merge fresh
      while IFS= read -r key; do
        "$PBUDDY" -c "Delete ':New Bookmarks:0:$key'" "$ITERM2_PLIST" 2>/dev/null || true
        "$PBUDDY" -c "Delete ':New Bookmarks:0:$key (Dark)'" "$ITERM2_PLIST" 2>/dev/null || true
      done < <("$PBUDDY" -c "Print" "$ITERM2_THEME" 2>/dev/null | grep " = Dict" | sed 's/ = Dict.*//' | sed 's/^    //')
      "$PBUDDY" -c "Merge '$ITERM2_THEME' ':New Bookmarks:0'" "$ITERM2_PLIST" 2>/dev/null

      # Disable separate light/dark mode colors so the theme applies in both
      "$PBUDDY" -c "Set ':New Bookmarks:0:Use Separate Colors for Light and Dark Mode' false" "$ITERM2_PLIST" 2>/dev/null || true

      echo "  iTerm2: Night Owl theme installed and set as default"
    fi
  else
    yellow "  iTerm2: skipped ($([ ! -f "$ITERM2_PLIST" ] && echo "iTerm2 not installed" || echo "theme file missing"))"
  fi
}

install_mcp() {
  echo "MCP servers..."
  if [ -f "$DOTFILES_DIR/.env" ]; then
    source "$DOTFILES_DIR/.env"

    if command -v claude &> /dev/null; then
      if [ -n "$TAVILY_API_KEY" ]; then
        claude mcp add -s user tavily -e TAVILY_API_KEY="$TAVILY_API_KEY" -- npx -y tavily-mcp@latest 2>/dev/null
        echo "  MCP: tavily configured"
      else
        yellow "  MCP: tavily skipped (TAVILY_API_KEY not set in .env)"
      fi

    else
      red "  MCP: claude CLI not found, skipping MCP server setup"
    fi
  else
    yellow "  MCP: no .env file found, skipping MCP server setup (see .env.example)"
  fi
}

# --- Main ---

ALL_SECTIONS="claude git nvim vscode gh macos iterm2 mcp"

usage() {
  echo "Usage: $0 [--section ...]"
  echo ""
  echo "Sections: $ALL_SECTIONS"
  echo "No flags installs everything."
}

sections=()
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --*) sections+=("${1#--}") ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
  shift
done

if [ ${#sections[@]} -eq 0 ]; then
  sections=($ALL_SECTIONS)
fi

echo "Installing dotfiles..."
for section in "${sections[@]}"; do
  if declare -f "install_$section" > /dev/null; then
    "install_$section"
  else
    red "Unknown section: $section"
    usage
    exit 1
  fi
done

echo ""
echo "Recommended: add to your shell profile (~/.zshrc):"
echo "  export CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1"
echo "  # Prevents API keys from leaking to Claude Code subprocesses"
echo ""
echo "Done."
