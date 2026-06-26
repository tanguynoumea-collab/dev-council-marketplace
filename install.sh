#!/usr/bin/env bash
# install.sh — installe dev-team-council dans ~/.claude (macOS / Linux)
# Usage : depuis la racine du repo, lancer  ./install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/dev-team-council"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

if [ ! -f "$SRC/skills/dev-team-council/SKILL.md" ]; then
  echo "Erreur : dossier 'dev-team-council' introuvable a cote du script." >&2
  echo "Lance install.sh depuis la racine du repo." >&2
  exit 1
fi

echo "Installation de dev-team-council dans $CLAUDE_DIR ..."

# 1. Skill (constitution) - dans son propre dossier
mkdir -p "$CLAUDE_DIR/skills/dev-team-council"
cp "$SRC/skills/dev-team-council/SKILL.md" "$CLAUDE_DIR/skills/dev-team-council/"

# 2. Agents
mkdir -p "$CLAUDE_DIR/agents"
cp "$SRC"/agents/*.md "$CLAUDE_DIR/agents/"

# 3. Commandes
mkdir -p "$CLAUDE_DIR/commands"
cp "$SRC"/commands/*.md "$CLAUDE_DIR/commands/"

n_agents=$(ls "$SRC"/agents/*.md | wc -l | tr -d ' ')
n_cmds=$(ls "$SRC"/commands/*.md | wc -l | tr -d ' ')

echo ""
echo "OK :"
echo "  - skill     -> $CLAUDE_DIR/skills/dev-team-council/SKILL.md"
echo "  - agents    -> $CLAUDE_DIR/agents/ ($n_agents fichiers)"
echo "  - commandes -> $CLAUDE_DIR/commands/ ($n_cmds fichiers)"
echo ""
echo "Redemarre Claude Code, puis verifie avec : /skills  /agents  (et tape /dev- )"
