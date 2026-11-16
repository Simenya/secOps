#!/usr/bin/env bash
# Sets up the three OpenClaw model backends for the Blue Team assignment and
# records evidence of the setup. Run on the Kali VM, connected to CMU VPN.
#   ./agents/setup-openclaw.sh
# Keys are read with hidden input and stored only in ~/.config/secops/agents.env (0600).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
EV="$REPO/evidence/00-setup"; mkdir -p "$EV"
ENVF="$HOME/.config/secops/agents.env"; mkdir -p "$(dirname "$ENVF")"
LOG="$EV/setup-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee "$LOG") 2>&1

GATEWAY_URL="${GATEWAY_URL:-https://ai-gateway.andrew.cmu.edu/v1}"
OLLAMA_URL="${OLLAMA_URL:-http://172.21.48.1:11434/v1}"
HAIKU_ID="${HAIKU_ID:-claude-haiku-4-5}"      # adjust to the id shown by the gateway model list below
SONNET_ID="${SONNET_ID:-claude-sonnet-5}"
QWEN_ID="${QWEN_ID:-qwen1.7b-8k:latest}"

echo "== versions =="; date -u; uname -a
command -v openclaw >/dev/null || { echo "openclaw not installed"; exit 1; }
openclaw --version || true

echo "== API key (input hidden, not logged) =="
if [[ -f "$ENVF" ]] && grep -q CMU_GATEWAY_API_KEY "$ENVF"; then
  echo "Using existing key in $ENVF (delete the file to re-enter)."
else
  read -rsp "CMU AI Gateway API key: " K; echo
  [[ -n "$K" ]] || { echo "empty key"; exit 1; }
  umask 077
  printf 'export CMU_GATEWAY_API_KEY=%q\nexport OLLAMA_API_KEY=ollama-local\n' "$K" > "$ENVF"
  unset K
fi
# shellcheck disable=SC1090
source "$ENVF"

echo "== reachability =="
curl -sS -m 15 -o "$EV/gateway-models.json" -w 'gateway /models -> HTTP %{http_code}\n' \
  -H "Authorization: Bearer $CMU_GATEWAY_API_KEY" "$GATEWAY_URL/models" || true
curl -sS -m 15 -o "$EV/ollama-models.json" -w 'ollama /models  -> HTTP %{http_code}\n' "$OLLAMA_URL/models" || true
echo "Gateway model ids:"; grep -o '"id" *: *"[^"]*"' "$EV/gateway-models.json" | sort -u || true

echo "== provider registration =="
openclaw config set models.providers.ollama.baseUrl "\"$OLLAMA_URL\""
openclaw config set models.providers.ollama.models \
  "[{\"id\":\"$QWEN_ID\",\"name\":\"qwen3 1.7B (local)\",\"api\":\"openai-completions\",\"maxTokens\":4096}]"
openclaw config set models.providers.cmu-gateway.baseUrl "\"$GATEWAY_URL\""
openclaw config set models.providers.cmu-gateway.models \
  "[{\"id\":\"$HAIKU_ID\",\"name\":\"haiku-collector\",\"api\":\"openai-completions\",\"maxTokens\":8192},
    {\"id\":\"$SONNET_ID\",\"name\":\"sonnet-analyst\",\"api\":\"openai-completions\",\"maxTokens\":8192}]"

echo "== direct API probes (independent of OpenClaw) =="
probe() { # name url key model
  local out="$EV/probe-$1.json"
  curl -sS -m 60 -o "$out" -w "$1 -> HTTP %{http_code}\n" "$2/chat/completions" \
    -H "Authorization: Bearer $3" -H 'Content-Type: application/json' \
    -d "{\"model\":\"$4\",\"max_tokens\":20,\"messages\":[{\"role\":\"user\",\"content\":\"Reply with the word OK only.\"}]}" || true
  head -c 400 "$out"; echo
}
probe haiku  "$GATEWAY_URL" "$CMU_GATEWAY_API_KEY" "$HAIKU_ID"
probe sonnet "$GATEWAY_URL" "$CMU_GATEWAY_API_KEY" "$SONNET_ID"
probe qwen   "$OLLAMA_URL"  "$OLLAMA_API_KEY"      "$QWEN_ID"

echo "== OpenClaw CLI reference for this version (for the reproduction appendix) =="
openclaw --help > "$EV/openclaw-help.txt" 2>&1 || true
openclaw config get models.providers 2>/dev/null | sed -E 's/("apiKey" *: *")[^"]*/\1REDACTED/' > "$EV/openclaw-providers.json" || true

echo
echo "Done. Log: $LOG"
echo "Before each agent session:  source $ENVF"
echo "Next: run the tool-use probe in agents/briefs/00-probes.md and save output to evidence/00-setup/."
