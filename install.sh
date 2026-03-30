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

echo "Done."
