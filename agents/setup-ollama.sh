#!/usr/bin/env bash
# Local model for agent A3 on the Kali machine itself (no VM). Ollama stays on
# 127.0.0.1 (its default), so nothing is exposed to the campus network.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"; EV="$REPO/evidence/00-setup"; mkdir -p "$EV"
MODEL="${MODEL:-qwen3:1.7b}"
{
  date -u
  command -v ollama >/dev/null || { echo "Installing Ollama"; curl -fsSL https://ollama.com/install.sh | sh; }
  ollama --version
  (systemctl is-active ollama || sudo systemctl enable --now ollama) 2>/dev/null || (nohup ollama serve >/dev/null 2>&1 &) ; sleep 3
  ollama pull "$MODEL"
  ollama list
  ss -ltnp 2>/dev/null | grep 11434 || true      # evidence: bound to 127.0.0.1 only
  nvidia-smi --query-gpu=name,memory.total --format=csv 2>/dev/null || echo "no NVIDIA GPU detected (CPU inference)"
} 2>&1 | tee "$EV/ollama-setup-$(date -u +%Y%m%dT%H%M%SZ).log"
echo "Model id for OpenClaw: run setup-openclaw.sh with QWEN_ID=$MODEL"
