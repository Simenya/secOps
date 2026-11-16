# secOps — Blue Team assessment of the Upanzi ApKit (Team 2)

Start with [PLAN.md](PLAN.md).

| Path | What |
|------|------|
| `PLAN.md` | Phases, agent task allocation, open items |
| `agents/` | OpenClaw setup (`setup-openclaw.sh`, `windows-ollama.ps1`) and agent briefs |
| `queries/` | Kibana KQL and Wazuh query packs |
| `evidence/` | Raw exports, screenshots, agent run logs |
| `hardening/` | Detection rules and hardening-script changes |
| `report/` | Report sources and the built `.docx` |
| `inputs/` | Canvas template, hardening scripts, Red Team report (provided files) |

## Quick start (Kali VM, on CMU VPN)
1. Windows host: run `agents/windows-ollama.ps1` as Administrator.
2. `./agents/setup-openclaw.sh` — enter the CMU AI Gateway key when prompted.
3. Run the probes in `agents/briefs/00-probes.md`.
4. Follow PLAN.md from Phase 1.
