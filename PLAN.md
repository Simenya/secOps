# Blue Team Assessment Plan — Team 2, 04722-A Cybersecurity Operations

Goal: review our own Red Team activity against the Upanzi ApKit host from the
defender's side (Upanzi SIEM / Kibana + Wazuh Manager), and deliver a Word report
with Executive Summary, Technical Analysis, Impact Analysis, and Response and
Recovery Analysis, including concrete changes to the Upanzi Ubuntu hardening scripts.

Everything is laid out so a third party can recreate it: every step names the
command or query, the file the output is saved to, and who (which agent) ran it.

## Open items (blockers are marked)

| # | Item | Status |
|---|------|--------|
| 1 | Does `apkit-secops` = `pdp-analyzer-02` / 172.29.108.118? | Unknown — resolved by step 1.1 |
| 2 | Red Team time window (exact dates/times, timezone) | Needed — report only says "October 2026" |
| 3 | Attacker source IP as seen by the target (the Red Team ran from a Hyper-V Kali VM behind NAT, so the SIEM shows that Windows host's VPN address, not 172.21.59.44) | Needed — step 1.2 derives it |
| 4 | Reporting Template | Received (PDF); outline in `report/outline.md` |
| 5 | Upanzi Ubuntu hardening scripts from Canvas | **Blocker for Phase 5** — put in `inputs/hardening-scripts/` |
| 6 | Past engagement folder structure (`/mnt/EXT/backup/Fall 2026/CyberOps/engagement/`) | Not readable from cloud; run `tree -L 3` there and save to `inputs/engagement-tree.txt` |
| 7 | Exact OpenClaw CLI flags on the installed version | Verified by `agents/setup-openclaw.sh` (prints `openclaw --version` and help) |

## Agents and what each one does

Routing follows what was measured in the Red Team engagement (report §7): Haiku is
reliable with tools, Sonnet is reliable on plain text only, local Qwen only on
small single-fact tasks. Rule kept from last time: **delegate execution, never
delegate interpretation** — every agent conclusion is checked against its raw evidence.

| Agent | Backend | Role in this assignment | Never used for |
|-------|---------|-------------------------|----------------|
| A1 `haiku-collector` | Claude Haiku 4.5, CMU AI Gateway (cloud) | Tool-driven collection: run the saved queries, export results, build the per-finding log extracts and the event timeline CSV | Deciding what an event means |
| A2 `sonnet-analyst` | Claude Sonnet 5, CMU AI Gateway (cloud) | Text-only synthesis, **no tools**: given extracts pasted in the prompt, draft detection-gap analysis, ATT&CK mapping, impact narrative | Anything needing a tool call (fails on this gateway) |
| A3 `qwen-checker` | Qwen3 1.7B, Ollama (local) | Small consistency checks: do timestamps/IPs/counts in a draft section match the timeline CSV; flag contradictions | Long documents, synthesis |
| Commander | Claude Code + human | Scoping, safety decisions, task decomposition, verification of every claim against raw evidence, final report | — |

Dispatch rules: one small task per dispatch; each brief says "execute now, do not
narrate a plan"; retry once on HTTP 500 / connection reset before calling it a failure;
every run is logged to `evidence/05-agent-runs/` (prompt, model, output, timestamp).

## Phases

### Phase 0 — Setup (human + Commander)
- 0.1 Connect to CMU VPN; confirm reachability of SIEM (172.29.108.82:5601), Wazuh (172.29.111.20), AI gateway.
- 0.2 `agents/setup-ollama.sh` (installs/starts Ollama on the Kali machine, bound to 127.0.0.1, pulls Qwen3 1.7B).
- 0.3 `agents/setup-openclaw.sh` — prompts for the gateway API key (hidden input, stored in `~/.config/secops/agents.env`, mode 600, never in the repo), registers the three providers/models, runs a text probe and a tool probe per model, writes `evidence/00-setup/`.
- Exit criteria: three probes pass (or the failure is recorded and routing adjusted).

### Phase 1 — Scoping (Commander; A1 for exports)
- 1.1 Resolve the target: queries S1–S3 in `queries/kibana-kql.md` → host name, IPs, agent id. Save to `evidence/01-scoping/`.
- 1.2 Identify our attacker source IP(s): query S4 (who ran the nmap scan / fetched `/openapi.json`).
- 1.3 Fix the time window from Red Team evidence file timestamps + S4 first/last seen. Record in `evidence/01-scoping/window.md`.

### Phase 2 — Collection (A1 `haiku-collector`, one dispatch per row)
For each Red Team action, pull the matching logs from **Network Packet Capture**,
**Discover**, and **Wazuh alerts**, and save raw export + screenshot.

| ID | Red Team action (report ref) | Expected telemetry | Query |
|----|------------------------------|--------------------|-------|
| T1 | Nmap port/service scan (SEC-01) | Flow/packet records: many dst ports from one src | N1 |
| T2 | Client-side JS key extraction (SEC-02) | Ordinary HTTP GETs of JS bundles — likely no alert | N2 |
| T3 | `/openapi.json`, `/redoc`, `/docs` unauthenticated (SEC-03) | HTTP requests on 80/8001 | N3 |
| T4 | Admin API with leaked key; prompt override create (201) + revert (WB-01/BB-05) | HTTP to `/api/admin/*`, POST/PUT/DELETE | N4 |
| T5 | Session enumeration, fabricated UUIDs → 404s (BB-06) | Burst of 404s | N5 |
| T6 | Upload tests, arbitrary file types (BB-07, BB-09) | multipart POSTs, 4xx/5xx | N6 |
| T7 | Prompt-injection chat traffic (BB-08) | POSTs to chat endpoint, SSE | N7 |
| T8 | Qdrant 6333 unauthenticated dump (SEC-05) | Traffic to :6333, large responses | N8 |
| T9 | SSH login, sudo, `docker inspect/exec/top`, `redis-cli` (WB-01..06, SEC-06, SEC-08) | auth.log / auditd / Wazuh sshd + sudo rules, Elastic Agent process events | H1–H4 |

Each row produces `evidence/0X-*/T<n>-*.{ndjson|csv,png,md}`; the `.md` records the
exact query, time range, hit count, and whether a security alert fired.

### Phase 3 — Analysis (A2 drafts from extracts; Commander verifies)
- 3.1 Timeline: merge all T-rows into `evidence/timeline.csv` (UTC time, source, dst, action, log source, alert y/n).
- 3.2 Detection coverage matrix: per action → logged? alerted? rule id/level? MITRE ATT&CK technique.
- 3.3 Gap analysis: what generated no alert and why (e.g. HTTP body/headers not captured, no rule for admin-key reuse).
- 3.4 Impact analysis: confidentiality/integrity/availability per finding, using Red Team evidence of what was actually reached.

### Phase 4 — QA (A3 + Commander)
- A3 checks each draft section against `timeline.csv` for mismatched times, IPs, counts.
- Commander re-opens the raw export behind every number quoted in the report.

### Phase 5 — Response, recovery, hardening (Commander; A2 for wording)
- Containment/eradication/recovery steps per finding (rotate leaked keys, bind Qdrant/Redis to localhost, etc.).
- New detections: Wazuh custom rules + Kibana detection rules for each gap (`hardening/detections.md`).
- Diffs against the Upanzi Ubuntu hardening scripts (`hardening/script-changes.md`) — **needs item 5**.

### Phase 6 — Report (Commander)
- Fill `report/` sections following the Canvas Reporting Template; build `.docx` using the template as the style reference; embed screenshots; add the agent-methodology and reproduction appendix (this plan + `evidence/` index).

## Reproducibility conventions
- All times UTC; state the Kibana time picker range in every evidence note.
- Every screenshot shows the query bar and time range.
- File naming: `<T-id>-<short-name>.<ext>`; one `.md` note per export.
- No credentials in the repo. The class SIEM/Wazuh login stays in the assignment brief only.
