#!/bin/bash
# init-workspace.sh — Create workspace directory structure for all agents
# Run AFTER setup-wizard.sh to create directories that agents expect
set -euo pipefail

WORKSPACE="${WORKSPACE_PATH:-$HOME/workspace}"

echo "📁 Creating workspace structure in $WORKSPACE"
echo ""

# Core directories
mkdir -p "$WORKSPACE/projects"
mkdir -p "$WORKSPACE/references"
mkdir -p "$WORKSPACE/memory"
mkdir -p "$WORKSPACE/memory/archive/daily"

# Gus (Kaizen) directories
mkdir -p "$WORKSPACE/goals"
mkdir -p "$WORKSPACE/strategy"
mkdir -p "$WORKSPACE/kaizen/daily"
mkdir -p "$WORKSPACE/kaizen/insights"
mkdir -p "$WORKSPACE/kaizen/reviews"
mkdir -p "$WORKSPACE/habits"
mkdir -p "$WORKSPACE/obsidian/daily"

# Skyler (Finance) directories
mkdir -p "$WORKSPACE/data"
mkdir -p "$WORKSPACE/data/monthly-reports"
mkdir -p "$WORKSPACE/data/subscribers"
mkdir -p "$WORKSPACE/data/secrets"

# Create starter files if they don't exist
[ -f "$WORKSPACE/goals/2-monthly.md" ] || echo "# Monthly Goals

## $(date +%B\ %Y)

| Goal | Target | Current | Status |
|------|--------|---------|--------|
| — | — | — | — |
" > "$WORKSPACE/goals/2-monthly.md"

[ -f "$WORKSPACE/goals/3-weekly.md" ] || echo "# Weekly Plan

## Week of $(date +%Y-%m-%d)

- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
" > "$WORKSPACE/goals/3-weekly.md"

echo "✅ Workspace ready:"
echo ""
echo "  projects/         — project files"
echo "  references/       — team board, standards"
echo "  memory/           — agent memory, archive"
echo "  goals/            — monthly + weekly goals (Gus)"
echo "  strategy/         — strategy sessions (Gus)"
echo "  kaizen/           — daily notes, insights (Gus)"
echo "  habits/           — habit tracker (Gus)"
echo "  obsidian/         — Obsidian vault (Gus)"
echo "  data/             — financial data (Skyler)"
echo ""
echo "Next: copy references/team-board.md.example → \$WORKSPACE/references/team-board.md"
