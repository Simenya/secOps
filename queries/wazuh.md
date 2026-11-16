# Wazuh Manager query pack (https://172.29.111.20, class login from the assignment brief)

Confirm field names on one alert first. Time range = Red Team window (UTC).

- **W1** agent: Agents list → find `apkit-secops`; record agent id, IP, OS, version, last keep-alive (screenshot).
- **W2** all alerts for the agent (Threat Hunting / Discover): `agent.name: apkit-secops`
  → table of `rule.id`, `rule.level`, `rule.description`, count. Export CSV.
- **W3** high severity: `agent.name: apkit-secops and rule.level >= 7`
- **W4** SSH / sudo: `agent.name: apkit-secops and rule.groups: (sshd or sudo or authentication_success or authentication_failed)`
- **W5** web attack rules: `agent.name: apkit-secops and rule.groups: (web or attack or accesslog)`
- **W6** from our IP: `agent.name: apkit-secops and data.srcip: "<ATTACKER_IP>"`
- **W7** MITRE view: MITRE ATT&CK module filtered to the agent → `rule.mitre.id` counts.
- **W8** posture already known to the defender: SCA (CIS benchmark score + failed checks),
  Vulnerability Detection, and FIM events for the agent. Export — these feed the
  hardening-script recommendations directly.
- **W9** docker: `agent.name: apkit-secops and rule.groups: docker` (shows whether the docker listener wodle is enabled; no hits during our `docker exec` = detection gap).
