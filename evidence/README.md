# Evidence layout
- `00-setup/`      agent setup logs, model lists, probe results, OpenClaw CLI help
- `01-scoping/`    target resolution (S1–S4), attacker IP, `window.md`
- `02-network-pcap/` N-queries (Network Packet Capture dashboard)
- `03-discover/`   H-queries (host logs)
- `04-wazuh-alerts/` W-queries, Elastic alerts
- `05-agent-runs/` one file per agent dispatch: prompt, model, timestamp, raw output
- `screenshots/`   PNGs, named `<query-id>-<what>.png`
- `timeline.csv`   merged event timeline (built in Phase 3)

Each export has a sibling `.md` note: query verbatim, time range (UTC), hit count,
alert fired (y/n, rule id). Redact credentials and API keys before committing.
