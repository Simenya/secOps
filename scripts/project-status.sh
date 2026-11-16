#!/usr/bin/env bash
# project-status.sh — summarize what has been done in this secOps project and
# what must run next. Read-only: it changes nothing. Works in any clone of the repo.
#   ./scripts/project-status.sh            # full report
#   ./scripts/project-status.sh --short    # only the next steps
set -uo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)" || exit 1
SHORT=${1:-}

ok()   { printf '  [x] %s\n' "$*"; }
todo() { printf '  [ ] %s\n' "$*"; }
hdr()  { [[ -z "$SHORT" ]] && printf '\n== %s ==\n' "$*"; }
has()  { compgen -G "$1" >/dev/null 2>&1; }          # files matching a glob exist
nonempty_dir() { find "$1" -type f ! -name .gitkeep 2>/dev/null | grep -q .; }

NEXT=()
next() { NEXT+=("$*"); }

# ---- git state -------------------------------------------------------------
hdr "Repository"
if git rev-parse --git-dir >/dev/null 2>&1; then
  br=$(git branch --show-current)
  head=$(git log -1 --format='%h %s' 2>/dev/null)
  [[ -z "$SHORT" ]] && echo "  branch: $br"
  [[ -z "$SHORT" ]] && echo "  head:   $head"
  dirty=$(git status --short | wc -l)
  if (( dirty > 0 )); then next "Commit or stash $dirty uncommitted change(s): git status"; fi
  git fetch -q origin "$br" 2>/dev/null
  if git rev-parse "origin/$br" >/dev/null 2>&1; then
    ahead=$(git rev-list --count "origin/$br..HEAD"); behind=$(git rev-list --count "HEAD..origin/$br")
    [[ -z "$SHORT" ]] && echo "  vs origin: $ahead ahead, $behind behind"
    (( ahead > 0 )) && next "Push local commits: git push -u origin $br"
    (( behind > 0 )) && next "Pull remote commits: git pull --ff-only origin $br"
  fi
else
  echo "  not a git repository"; next "Clone the project: git clone -b claude/compassionate-mendel-jketql https://github.com/simenya/secops.git"
fi

# ---- planning / docs -------------------------------------------------------
hdr "Planning"
[[ -f PLAN.md ]] && ok "PLAN.md present" || { todo "PLAN.md missing"; next "Restore PLAN.md from the repo branch"; }
[[ -f report/outline.md ]] && ok "Report outline (report/outline.md)" || todo "Report outline"
[[ -f inputs/Reporting_Template.pdf || -f report/template-notes.md ]] && ok "Report template reviewed" || true

# ---- phase 0: setup --------------------------------------------------------
hdr "Phase 0 — Setup"
[[ -f agents/setup-ollama.sh ]] && ok "Ollama setup script (agents/setup-ollama.sh)" || todo "Ollama setup script"
[[ -f agents/setup-openclaw.sh ]] && ok "OpenClaw setup script (agents/setup-openclaw.sh)" || todo "OpenClaw setup script"
if has "evidence/00-setup/*.log"; then ok "Setup log(s) recorded in evidence/00-setup/"; else
  todo "Setup NOT run yet (no log in evidence/00-setup/)"
  next "On Kali (on CMU VPN): ./agents/setup-ollama.sh then ./agents/setup-openclaw.sh"
fi
if has "evidence/00-setup/probe-*.json"; then ok "Agent probes saved"; else
  todo "Agent probes not run"; next "Run the probes in agents/briefs/00-probes.md, save to evidence/00-setup/"
fi
command -v ollama >/dev/null && ok "ollama installed" || todo "ollama not installed on this machine"
command -v openclaw >/dev/null && ok "openclaw installed" || todo "openclaw not installed on this machine"
[[ -f "$HOME/.config/secops/agents.env" ]] && ok "Gateway key stored (~/.config/secops/agents.env)" || todo "Gateway key not entered yet"

# ---- phase 1: scoping ------------------------------------------------------
hdr "Phase 1 — Scoping"
if has "evidence/01-scoping/*"; then ok "Scoping evidence present"; else
  todo "Target not resolved yet (apkit-secops vs 172.29.108.118)"
  next "Run scoping queries S1–S4 in queries/kibana-kql.md; save to evidence/01-scoping/"
fi
if [[ -f evidence/01-scoping/window.md ]]; then ok "Red Team time window recorded"; else
  todo "Red Team time window missing"; next "Provide exact Red Team dates/times (UTC) and write evidence/01-scoping/window.md"
fi

# ---- phase 2: collection ---------------------------------------------------
hdr "Phase 2 — Collection (T1–T9)"
for t in T1 T2 T3 T4 T5 T6 T7 T8 T9; do
  if has "evidence/*/${t}-*"; then ok "$t collected"; else todo "$t not collected"; fi
done
if ! has "evidence/*/T*-*"; then next "Collect telemetry per action: one agent dispatch per T-row (agents/briefs/A1-haiku-collector.md)"; fi

# ---- phase 3–5: analysis, hardening ----------------------------------------
hdr "Phases 3–5 — Analysis, response, hardening"
[[ -f evidence/timeline.csv ]] && ok "timeline.csv built" || { todo "timeline.csv not built"; next "Merge T-rows into evidence/timeline.csv"; }
nonempty_dir hardening && ok "Hardening notes exist" || todo "No detections / hardening changes yet"
if [[ -d inputs/hardening-scripts ]] && nonempty_dir inputs/hardening-scripts; then ok "Upanzi hardening scripts provided"; else
  todo "Upanzi Ubuntu hardening scripts missing"; next "Put Canvas hardening scripts in inputs/hardening-scripts/ (needed for Phase 5)"
fi

# ---- phase 6: report -------------------------------------------------------
hdr "Phase 6 — Report"
if has "report/*.docx"; then ok "Word report built"; else todo "Word report not built"; next "Build report/ from report/outline.md (Executive Summary, Technical Analysis, Impact, Response & Recovery)"; fi

# ---- inputs still needed from the user -------------------------------------
hdr "Needed from you"
[[ -f inputs/engagement-tree.txt ]] || { todo "Past engagement folder tree"; next "Save: tree -L 3 \"/mnt/EXT/backup/Fall 2026/CyberOps/SecOp_group_2/\" > inputs/engagement-tree.txt"; }

# ---- next steps ------------------------------------------------------------
echo
echo "== Next steps =="
if (( ${#NEXT[@]} == 0 )); then echo "  Nothing pending detected. Check the report phase manually."
else i=1; for s in "${NEXT[@]}"; do printf '  %d. %s\n' "$i" "$s"; ((i++)); done; fi
echo
