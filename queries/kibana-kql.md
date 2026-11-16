# Kibana query pack (KQL)

Field names assume ECS (Elastic Agent / Packetbeat). **Step S0: open one document
in Discover and confirm the actual field names** in each data view; adjust and note
any differences here so the queries stay reproducible. Replace `<TARGET_IP>`,
`<ATTACKER_IP>` after scoping. Set the time picker to the Red Team window (UTC).

## Scoping
- **S1** target by name: `host.name : "apkit-secops" or agent.name : "apkit-secops" or host.hostname : "apkit-secops"`
- **S2** is it our old target? `host.ip : "172.29.108.118" or destination.ip : "172.29.108.118"` — compare `host.name` with S1
- **S3** list the host's IPs/OS: S1, then visualize/inspect `host.ip`, `host.os.full`, `agent.id`
- **S4** find our source IP: `destination.ip : "<TARGET_IP>" and url.path : ("/openapi.json" or "/redoc" or "/docs")` → top values of `source.ip`

## Network Packet Capture dashboard / network data view
- **N1** port scan: `source.ip : "<ATTACKER_IP>" and destination.ip : "<TARGET_IP>"` → unique count of `destination.port` per minute (Lens); a spike = nmap
- **N2** JS bundle fetches: `... and url.path : (*.js or /_next/*)`
- **N3** API docs: `... and url.path : ("/openapi.json" or "/redoc" or "/docs")`
- **N4** admin API: `... and url.path : /api/admin/*` ; split by `http.request.method`, `http.response.status_code` (look for the 201 then 200 of the prompt override create/revert)
- **N5** enumeration: `... and http.response.status_code : 404` → count over time
- **N6** uploads: `... and http.request.method : "POST" and url.path : *upload*`
- **N7** chat/prompt injection: `... and url.path : *chat*`
- **N8** Qdrant: `... and destination.port : 6333` ; check `url.path : /collections/*` and `destination.bytes` / `network.bytes`
- **N9** anything else from us: `source.ip : "<ATTACKER_IP>" and destination.ip : "<TARGET_IP>" and not destination.port : (80 or 3001 or 8001 or 6333 or 22)`

## Discover — host logs for the target
Base filter: `host.name : "apkit-secops"`
- **H1** SSH logins: `... and (event.category : "authentication" or process.name : "sshd" or message : *sshd*)` ; `event.outcome`, `source.ip`, `user.name`
- **H2** sudo: `... and (process.name : "sudo" or message : *sudo*)`
- **H3** docker / redis commands: `... and process.name : ("docker" or "redis-cli" or "curl" or "nmap")` → `process.command_line`, `user.name`
- **H4** process events during our SSH sessions: `... and event.category : "process" and user.name : "<SSH_USER>"`

## Alerts
- **A1** Elastic detections: Security → Alerts, filter `host.name : "apkit-secops"`; or `kibana.alert.rule.name : * and host.name : "apkit-secops"`
- **A2** everything from us that alerted: `source.ip : "<ATTACKER_IP>" and (event.kind : "alert" or event.kind : "signal")`

For every query save: screenshot (query bar + time range visible), CSV/NDJSON export
(Discover → Share → CSV, or Inspect → Response), and a `.md` note with hit count.
