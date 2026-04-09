#!/bin/bash
# setup-wizard.sh — Interactive setup for Heisenberg Team
# Guides user through all configuration steps
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Cross-platform sed: macOS uses -i '', Linux uses -i
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE="sed -i ''"
else
  SED_INPLACE="sed -i"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}🧪 Heisenberg Team — Setup Wizard${NC}"
echo "========================================"
echo ""
echo -e "${CYAN}This wizard will configure your multi-agent system.${NC}"
echo -e "${CYAN}It takes about 5 minutes. You can re-run it anytime.${NC}"
echo ""

# ─── Step 1: Check prerequisites ───
echo -e "${BOLD}Step 1/5: Checking prerequisites...${NC}"
echo ""

ERRORS=0

if command -v openclaw >/dev/null 2>&1; then
  echo -e "  ${GREEN}✓${NC} OpenClaw installed ($(openclaw --version 2>/dev/null || echo 'version unknown'))"
else
  echo -e "  ${RED}✗${NC} OpenClaw not found. Install: ${BOLD}npm install -g openclaw${NC}"
  ERRORS=$((ERRORS + 1))
fi

if command -v node >/dev/null 2>&1; then
  NODE_VER=$(node --version)
  echo -e "  ${GREEN}✓${NC} Node.js $NODE_VER"
else
  echo -e "  ${RED}✗${NC} Node.js not found. Install v20+ from https://nodejs.org/"
  ERRORS=$((ERRORS + 1))
fi

if command -v python3 >/dev/null 2>&1; then
  PYTHON_VER=$(python3 --version 2>/dev/null || echo "python3")
  echo -e "  ${GREEN}✓${NC} $PYTHON_VER"
else
  echo -e "  ${RED}✗${NC} python3 not found. Install Python 3.9+ and re-run the wizard."
  ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo -e "${RED}Fix the issues above and re-run this script.${NC}"
  exit 1
fi

echo ""

# ─── Step 2: Collect user data ───
echo -e "${BOLD}Step 2/5: Your information${NC}"
echo -e "${CYAN}This data replaces {{PLACEHOLDER}} values in agent configs.${NC}"
echo ""

# Helper: prompt with default
ask() {
  local var_name="$1"
  local prompt="$2"
  local default="${3:-}"
  local required="${4:-false}"

  if [ -n "$default" ]; then
    read -p "  $prompt [$default]: " value
    value="${value:-$default}"
  else
    if [ "$required" = "true" ]; then
      while true; do
        read -p "  $prompt: " value
        [ -n "$value" ] && break
        echo -e "  ${RED}This field is required.${NC}"
      done
    else
      read -p "  $prompt (skip with Enter): " value
    fi
  fi
  printf -v "$var_name" '%s' "$value"
}

echo -e "${YELLOW}── Required ──${NC}"
ask OWNER_NAME "Your first name" "" true
ask OWNER_USERNAME "Your GitHub/online username" "" true

echo ""
echo -e "${YELLOW}── Team layout ──${NC}"
echo "  Default agents: heisenberg, saul, walter, jesse, skyler, hank, gus, twins"
ask SELECTED_AGENTS "Agents to install (comma-separated)" "heisenberg,saul,walter,jesse,skyler,hank,gus,twins" true
ask TEAM_DIRECTORY "Team root directory" "~/openclaw-agents" true
ask TEAM_DISPLAY_NAME "Team / system name" "Heisenberg Team" true

echo ""
echo -e "${YELLOW}── LLM Provider ──${NC}"
echo ""
echo "  Which LLM provider do you use?"
echo ""
echo "  1) Anthropic (Claude) - recommended"
echo "  2) OpenAI (GPT-4, GPT-4o)"
echo "  3) Google (Gemini)"
echo "  4) Ollama (local models)"
echo "  5) DeepSeek"
echo "  6) Custom endpoint (OpenAI-compatible / Anthropic-compatible / cliproxy / local API)"
echo "  7) Other / I'll configure manually later"
echo ""
read -p "  Choose [1]: " LLM_CHOICE
LLM_CHOICE="${LLM_CHOICE:-1}"

case "$LLM_CHOICE" in
  1)
    LLM_PROVIDER="anthropic"
    MAIN_MODEL="anthropic/claude-opus-4-5"
    AGENT_MODEL="anthropic/claude-sonnet-4-5"
    ask ANTHROPIC_API_KEY "Anthropic API key (or 'max' for Claude Max subscription)" "" true
    if [ "$ANTHROPIC_API_KEY" = "max" ]; then
      ANTHROPIC_API_KEY=""
      echo -e "  ${CYAN}Claude Max detected - no API key needed, uses built-in auth${NC}"
    fi
    ;;
  2)
    LLM_PROVIDER="openai"
    MAIN_MODEL="openai/gpt-4o"
    AGENT_MODEL="openai/gpt-4o"
    ask OPENAI_API_KEY "OpenAI API key" "" true
    ;;
  3)
    LLM_PROVIDER="google"
    MAIN_MODEL="google/gemini-2.5-pro"
    AGENT_MODEL="google/gemini-2.5-flash"
    ask GOOGLE_API_KEY "Google AI API key" "" true
    ;;
  4)
    LLM_PROVIDER="ollama"
    MAIN_MODEL="ollama/llama3"
    AGENT_MODEL="ollama/llama3"
    echo -e "  ${CYAN}Make sure Ollama is running: ollama serve${NC}"
    ask OLLAMA_MODEL "Ollama model name" "llama3" false
    MAIN_MODEL="ollama/$OLLAMA_MODEL"
    AGENT_MODEL="ollama/$OLLAMA_MODEL"
    ;;
  5)
    LLM_PROVIDER="deepseek"
    MAIN_MODEL="deepseek/deepseek-chat"
    AGENT_MODEL="deepseek/deepseek-chat"
    ask DEEPSEEK_API_KEY "DeepSeek API key (from platform.deepseek.com)" "" true
    echo -e "  ${CYAN}Tip: deepseek-reasoner available for complex tasks${NC}"
    ;;
  6)
    LLM_PROVIDER="custom"
    ask CUSTOM_PROVIDER_ID "Custom provider ID (e.g. cliproxy)" "custom" true
    echo ""
    echo "  Which API compatibility does your endpoint expect?"
    echo "  1) OpenAI-compatible chat/completions"
    echo "  2) Anthropic-compatible messages"
    echo ""
    read -p "  Choose [1]: " CUSTOM_COMPAT_CHOICE
    CUSTOM_COMPAT_CHOICE="${CUSTOM_COMPAT_CHOICE:-1}"
    case "$CUSTOM_COMPAT_CHOICE" in
      2)
        CUSTOM_COMPATIBILITY="anthropic-messages"
        ;;
      *)
        CUSTOM_COMPATIBILITY="openai-completions"
        ;;
    esac
    ask CUSTOM_BASE_URL "Custom provider base URL (e.g. http://127.0.0.1:4000/v1)" "" true
    ask CUSTOM_MODEL_ID "Custom model ID (without provider prefix)" "" true
    ask CUSTOM_API_KEY "Custom provider API key (optional)"
    MAIN_MODEL="${CUSTOM_PROVIDER_ID}/${CUSTOM_MODEL_ID}"
    AGENT_MODEL="${MAIN_MODEL}"
    echo -e "  ${GREEN}✓${NC} Custom provider configured as ${MAIN_MODEL}"
    ;;
  7)
    LLM_PROVIDER="custom"
    ask MAIN_MODEL "Main model (provider/model format)" "anthropic/claude-opus-4-5" true
    AGENT_MODEL="$MAIN_MODEL"
    ;;
esac

echo ""
echo "  Embedding model for vector memory (semantic search)."
echo "  Options:"
echo "    - OpenAI text-embedding-3-small (recommended, needs OpenAI key)"
echo "    - Skip (memory search will use BM25 only, no vectors)"
echo ""

if [ "$LLM_PROVIDER" = "openai" ] && [ -n "${OPENAI_API_KEY:-}" ]; then
  EMBEDDING_PROVIDER="openai"
  EMBEDDING_MODEL="text-embedding-3-small"
  echo -e "  ${GREEN}✓${NC} Using OpenAI embeddings (same API key)"
else
  read -p "  OpenAI API key for embeddings (or 'skip'): " EMBED_KEY
  if [ "$EMBED_KEY" = "skip" ] || [ -z "$EMBED_KEY" ]; then
    EMBEDDING_PROVIDER="none"
    EMBEDDING_MODEL=""
    echo -e "  ${YELLOW}⚠${NC} Embeddings skipped - memory search will be keyword-only"
  else
    OPENAI_API_KEY="$EMBED_KEY"
    EMBEDDING_PROVIDER="openai"
    EMBEDDING_MODEL="text-embedding-3-small"
    echo -e "  ${GREEN}✓${NC} Embeddings configured"
  fi
fi

echo ""
echo -e "${YELLOW}── Telegram (recommended) ──${NC}"
echo -e "  ${CYAN}Agents send you status updates via Telegram.${NC}"
echo -e "  ${CYAN}Get your ID from @userinfobot on Telegram.${NC}"
ask OWNER_TELEGRAM_ID "Your Telegram user ID (digits)"
ask TELEGRAM_CHANNEL "Your Telegram channel name (without @)"
ask BOT_USERNAME "Main bot username (e.g. @MyBot_bot)"

agent_internal_name() {
  case "$1" in
    heisenberg) echo "main" ;;
    saul) echo "producer" ;;
    walter) echo "teamlead" ;;
    jesse) echo "marketing-funnel" ;;
    skyler) echo "skyler" ;;
    hank) echo "hank" ;;
    gus) echo "kaizen" ;;
    twins) echo "researcher" ;;
    *) return 1 ;;
  esac
}

agent_default_display_name() {
  case "$1" in
    heisenberg) echo "Heisenberg" ;;
    saul) echo "Saul" ;;
    walter) echo "Walter" ;;
    jesse) echo "Jesse" ;;
    skyler) echo "Skyler" ;;
    hank) echo "Hank" ;;
    gus) echo "Gus" ;;
    twins) echo "Twins" ;;
    *) return 1 ;;
  esac
}

IFS=',' read -r -a SELECTED_AGENT_LIST <<< "$SELECTED_AGENTS"
echo ""
echo -e "${YELLOW}── Per-agent setup ──${NC}"
for i in "${!SELECTED_AGENT_LIST[@]}"; do
  agent="$(printf '%s' "${SELECTED_AGENT_LIST[$i]}" | xargs)"
  [ -z "$agent" ] && continue
  if ! internal_name="$(agent_internal_name "$agent")"; then
    echo -e "  ${YELLOW}⚠${NC} Unknown built-in agent '$agent' - skipped in guided token setup"
    continue
  fi
  upper=$(printf '%s' "$agent" | tr '[:lower:]' '[:upper:]')
  default_name="$(agent_default_display_name "$agent")"
  ask "DISPLAY_NAME_${upper}" "Display name for $agent" "$default_name" true
  ask "TELEGRAM_BOT_TOKEN_${upper}" "Telegram bot token for $agent" ""
  ask "INTERNAL_NAME_${upper}" "Internal OpenClaw agent name for $agent" "$internal_name" true
done

echo ""
echo -e "${YELLOW}── Optional ──${NC}"
ask OWNER_SURNAME "Your last name"
ask COUNTRY "Your country"
ask CITY "Your city"
ask GITHUB_ORG "GitHub organization/username" "$OWNER_USERNAME"
ask WORKSPACE_PATH "Workspace path" "$TEAM_DIRECTORY/"

echo ""
# ─── Step 3: Replace placeholders ───
echo -e "${BOLD}Step 3/5: Applying configuration...${NC}"
echo ""

# Build replacement pairs
REPLACEMENTS_FILE="$(mktemp)"
trap 'rm -f "$REPLACEMENTS_FILE"' EXIT

add_replacement() {
  printf '%s\t%s\n' "$1" "$2" >> "$REPLACEMENTS_FILE"
}

add_replacement "{{OWNER_NAME}}" "${OWNER_NAME}"
add_replacement "{{TEAM_NAME}}" "${TEAM_DISPLAY_NAME}"
add_replacement "{{OWNER_USERNAME}}" "${OWNER_USERNAME}"
add_replacement "{{OWNER_TELEGRAM_ID}}" "${OWNER_TELEGRAM_ID:-YOUR_TELEGRAM_ID}"
add_replacement "{{TELEGRAM_CHANNEL}}" "${TELEGRAM_CHANNEL:-YOUR_CHANNEL}"
add_replacement "{{BOT_USERNAME}}" "${BOT_USERNAME:-@YourBot_bot}"
add_replacement "{{OWNER_SURNAME}}" "${OWNER_SURNAME:-Surname}"
add_replacement "{{COUNTRY}}" "${COUNTRY:-Country}"
add_replacement "{{CITY}}" "${CITY:-City}"
add_replacement "{{GITHUB_ORG}}" "${GITHUB_ORG:-$OWNER_USERNAME}"
add_replacement "{{WORKSPACE_PATH}}" "${WORKSPACE_PATH:-$TEAM_DIRECTORY/}"
add_replacement "{{PROJECTS_PATH}}" "${WORKSPACE_PATH:-$TEAM_DIRECTORY/}projects/"
add_replacement "{{MAIN_MODEL}}" "${MAIN_MODEL:-anthropic/claude-opus-4-5}"
add_replacement "{{AGENT_MODEL}}" "${AGENT_MODEL:-anthropic/claude-sonnet-4-5}"
add_replacement "{{EMBEDDING_PROVIDER}}" "${EMBEDDING_PROVIDER:-openai}"
add_replacement "{{EMBEDDING_MODEL}}" "${EMBEDDING_MODEL:-text-embedding-3-small}"
add_replacement "{{ANTHROPIC_API_KEY}}" "${ANTHROPIC_API_KEY:-your-anthropic-key}"
add_replacement "{{OPENAI_API_KEY}}" "${OPENAI_API_KEY:-your-openai-key}"
add_replacement "{{GOOGLE_API_KEY}}" "${GOOGLE_API_KEY:-your-google-key}"
add_replacement "{{DEEPSEEK_API_KEY}}" "${DEEPSEEK_API_KEY:-your-deepseek-key}"
add_replacement "{{CUSTOM_PROVIDER_ID}}" "${CUSTOM_PROVIDER_ID:-custom}"
add_replacement "{{CUSTOM_BASE_URL}}" "${CUSTOM_BASE_URL:-http://127.0.0.1:4000/v1}"
add_replacement "{{CUSTOM_MODEL_ID}}" "${CUSTOM_MODEL_ID:-model-name}"
add_replacement "{{CUSTOM_COMPATIBILITY}}" "${CUSTOM_COMPATIBILITY:-openai-completions}"
add_replacement "{{CUSTOM_API_KEY}}" "${CUSTOM_API_KEY:-}"

for agent in heisenberg saul walter jesse skyler hank gus twins; do
  upper=$(printf '%s' "$agent" | tr '[:lower:]' '[:upper:]')
  display_var="DISPLAY_NAME_${upper}"
  token_var="TELEGRAM_BOT_TOKEN_${upper}"
  internal_var="INTERNAL_NAME_${upper}"
  default_name="$(agent_default_display_name "$agent")"
  default_internal_name="$(agent_internal_name "$agent")"
  display_value="${!display_var:-$default_name}"
  token_value="${!token_var:-}"
  if [ -z "$token_value" ]; then
    token_value="{{TELEGRAM_BOT_TOKEN}}"
  fi
  internal_value="${!internal_var:-$default_internal_name}"
  add_replacement "{{DISPLAY_NAME_${upper}}}" "$display_value"
  add_replacement "{{TELEGRAM_BOT_TOKEN_${upper}}}" "$token_value"
  add_replacement "{{INTERNAL_NAME_${upper}}}" "$internal_value"
done

# Count files to process
FILE_COUNT=$(find "$REPO_DIR" -type f \( \
  -name "*.md" -o -name "*.sh" -o -name "*.txt" -o \
  -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o \
  -name "*.example" -o -name "*.py" -o -name "LICENSE" \
\) ! -path "*/setup-wizard.sh" ! -path "*/.git/*" | wc -l | tr -d ' ')

echo -e "  Processing $FILE_COUNT files..."
echo ""

REPLACED_TOTAL=0
REPLACEMENT_RESULTS_FILE="$(mktemp)"
trap 'rm -f "$REPLACEMENTS_FILE" "$REPLACEMENT_RESULTS_FILE"' EXIT

python3 - "$REPO_DIR" "$REPLACEMENTS_FILE" > "$REPLACEMENT_RESULTS_FILE" <<'PY'
import sys
from pathlib import Path

repo_dir = Path(sys.argv[1])
replacements_file = Path(sys.argv[2])
allowed_suffixes = {".md", ".sh", ".txt", ".yaml", ".yml", ".json", ".example", ".py"}
skip_names = {"setup-wizard.sh", "depersonalize.sh"}

replacements = []
with replacements_file.open("r", encoding="utf-8") as handle:
    for raw_line in handle:
        line = raw_line.rstrip("\n")
        if not line:
            continue
        placeholder, value = line.split("\t", 1)
        replacements.append((placeholder, value))

files = []
for path in repo_dir.rglob("*"):
    if not path.is_file():
        continue
    if ".git" in path.parts:
        continue
    if path.name in skip_names:
        continue
    if path.name == "LICENSE" or path.suffix in allowed_suffixes:
        files.append(path)

for placeholder, value in replacements:
    touched = 0
    for path in files:
        text = path.read_text(encoding="utf-8", errors="ignore")
        if placeholder not in text:
            continue
        path.write_text(text.replace(placeholder, value), encoding="utf-8")
        touched += 1
    if touched:
        print(f"{placeholder}\t{value}\t{touched}")
PY

while IFS=$'\t' read -r placeholder value count; do
  [ -n "${placeholder:-}" ] || continue
  echo -e "  ${GREEN}✓${NC} $placeholder → $value ($count files)"
  REPLACED_TOTAL=$((REPLACED_TOTAL + count))
done < "$REPLACEMENT_RESULTS_FILE"

echo ""
echo -e "  Replaced in $REPLACED_TOTAL file locations."
echo ""

# ─── Step 4: Install agents and skills ───
echo -e "${BOLD}Step 4/5: Installing agents and skills...${NC}"
echo ""

OPENCLAW_DIR="$HOME/.openclaw/agents"
TEAM_ROOT_EXPANDED="${TEAM_DIRECTORY/#\~/$HOME}"
mkdir -p "$REPO_DIR/configs/generated" "$TEAM_ROOT_EXPANDED" "$TEAM_ROOT_EXPANDED/projects"

INSTALLED=0
for char_name in "${SELECTED_AGENT_LIST[@]}"; do
  char_name="$(printf "%s" "$char_name" | xargs)"
  [ -z "$char_name" ] && continue
  upper=$(printf '%s' "$char_name" | tr '[:lower:]' '[:upper:]')
  internal_var="INTERNAL_NAME_${upper}"
  agent_name="${!internal_var:-${AGENT_MAP[$char_name]}}"
  src="$REPO_DIR/agents/$char_name"
  dest="$OPENCLAW_DIR/$agent_name/agent"

  if [ -d "$src" ]; then
    mkdir -p "$dest" "$TEAM_ROOT_EXPANDED/$char_name"
    cp "$src"/*.md "$dest/"
    cp "$src"/*.md "$TEAM_ROOT_EXPANDED/$char_name/" 2>/dev/null || true
    if [ -f "$REPO_DIR/configs/$char_name.openclaw.json.example" ]; then
      generated_path="$REPO_DIR/configs/generated/$char_name.openclaw.json"
      cp "$REPO_DIR/configs/$char_name.openclaw.json.example" "$generated_path"
      if [ "$LLM_PROVIDER" = "custom" ] && [ -n "${CUSTOM_PROVIDER_ID:-}" ] && [ -n "${CUSTOM_BASE_URL:-}" ] && [ -n "${CUSTOM_MODEL_ID:-}" ]; then
        python3 - "$generated_path" "$CUSTOM_PROVIDER_ID" "$CUSTOM_BASE_URL" "$CUSTOM_COMPATIBILITY" "$CUSTOM_API_KEY" "$CUSTOM_MODEL_ID" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
provider_id = sys.argv[2]
base_url = sys.argv[3]
compatibility = sys.argv[4]
api_key = sys.argv[5]
model_id = sys.argv[6]

data = json.loads(config_path.read_text(encoding="utf-8"))
models = data.setdefault("models", {})
providers = models.setdefault("providers", {})
entry = {
    "baseUrl": base_url,
    "api": compatibility,
    "models": [
        {
            "id": model_id,
            "name": model_id,
        }
    ],
}
if api_key:
    entry["apiKey"] = api_key
providers[provider_id] = entry
config_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
      fi
    fi
    echo -e "  ${GREEN}✓${NC} $char_name → $agent_name"
    INSTALLED=$((INSTALLED + 1))
  else
    echo -e "  ${YELLOW}⚠${NC} $char_name not found, skipping"
  fi
done

echo ""

# Skills
SKILLS_DEST="$OPENCLAW_DIR/producer/agent/skills"
if [ -d "$REPO_DIR/skills" ]; then
  mkdir -p "$SKILLS_DEST"
  SKILL_ERRORS=0
  SKILL_OK=0
  for skill_dir in "$REPO_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    if cp -r "$skill_dir" "$SKILLS_DEST/" 2>/dev/null; then
      SKILL_OK=$((SKILL_OK + 1))
    else
      echo -e "  ${YELLOW}⚠${NC} Failed to copy skill: $skill_name"
      SKILL_ERRORS=$((SKILL_ERRORS + 1))
    fi
  done
  echo -e "  ${GREEN}✓${NC} $SKILL_OK skills installed"
  if [ "$SKILL_ERRORS" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠${NC} $SKILL_ERRORS skills failed to copy"
  fi
else
  echo -e "  ${RED}✗${NC} Skills directory not found!"
fi

echo ""

# ─── Step 5: Verification ───
echo -e "${BOLD}Step 5/5: Verification...${NC}"
echo ""

# Check remaining placeholders
REMAINING=$(python3 - "$REPO_DIR" <<'PY'
import re
import sys
from pathlib import Path

repo_dir = Path(sys.argv[1])
pattern = re.compile(r"\{\{[A-Z_]*\}\}")
allowed_suffixes = {".md", ".sh", ".py"}
skip_names = {"setup-wizard.sh", "depersonalize.sh", ".env.example"}
skip_fragments = {"quality-check/SKILL.md"}
count = 0

for path in repo_dir.rglob("*"):
    if not path.is_file():
        continue
    if ".git" in path.parts:
        continue
    if path.name in skip_names:
        continue
    rel = path.relative_to(repo_dir).as_posix()
    if any(fragment in rel for fragment in skip_fragments):
        continue
    if path.suffix not in allowed_suffixes:
        continue
    text = path.read_text(encoding="utf-8", errors="ignore")
    count += len(pattern.findall(text))

print(count)
PY
)

if [ "$REMAINING" -gt 0 ]; then
  echo -e "  ${YELLOW}⚠${NC} $REMAINING placeholder(s) still unfilled."
  echo -e "  ${CYAN}  These are optional fields. You can fill them later by editing the files directly.${NC}"
  echo -e "  ${CYAN}  Run: grep -rn '{{[A-Z_]*}}' . --include='*.md' | grep -v setup-wizard | head -20${NC}"
else
  echo -e "  ${GREEN}✓${NC} All placeholders replaced"
fi

# Check agents installed
AGENT_COUNT=$(ls "$OPENCLAW_DIR" 2>/dev/null | wc -l | tr -d ' ')
echo -e "  ${GREEN}✓${NC} $AGENT_COUNT agents installed in ~/.openclaw/agents/"
echo -e "  ${GREEN}✓${NC} Team directory prepared at $TEAM_ROOT_EXPANDED"

# Check skills
SKILL_COUNT=$(ls "$SKILLS_DEST" 2>/dev/null | wc -l | tr -d ' ')
echo -e "  ${GREEN}✓${NC} $SKILL_COUNT skills installed"

echo ""
echo "========================================"
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Confirm the CLI is available:         ${BOLD}openclaw --version${NC}"
echo -e "  2. Review generated configs:             ${BOLD}configs/generated/*.openclaw.json${NC}"
echo -e "     These configs already use your custom internal agent names and rewired session keys.${NC}"
if [ "$LLM_PROVIDER" = "custom" ]; then
  echo -e "     Custom provider injected:            ${BOLD}${CUSTOM_PROVIDER_ID}/${CUSTOM_MODEL_ID}${NC} -> ${CUSTOM_BASE_URL}"
fi
echo -e "  3. Start the system:                      ${BOLD}openclaw gateway start${NC}"
echo -e "  4. Check status:                          ${BOLD}openclaw status${NC}"
echo -e "  5. Send a message to your bot to test!"
echo ""
echo -e "Guides:"
echo -e "  First task:    ${BLUE}docs/first-task.md${NC}"
echo -e "  Architecture:  ${BLUE}docs/architecture.md${NC}"
echo -e "  FAQ:           ${BLUE}docs/faq.md${NC}"
echo ""
echo -e "🧪 ${BOLD}Say my name.${NC}"
