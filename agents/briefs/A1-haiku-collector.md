# A1 haiku-collector — brief template (one T-row per dispatch)

> Execute now, do not narrate a plan. You are collecting log evidence only; do not
> interpret it.
> Task {T-id}: {one-line action}. Time window (UTC): {from} to {to}.
> Target: {host.name / IP}. Source: {attacker IP}.
> 1. Run exactly this query/command: {query from queries/}.
> 2. Save the raw result to `evidence/{dir}/{T-id}-{name}.ndjson`.
> 3. Write `evidence/{dir}/{T-id}-{name}.md` containing: the query verbatim, the
>    time range, total hit count, first and last @timestamp, and the top 5 values of
>    {fields}. No conclusions.
> Stop after step 3.

Read-only: the agent must not change anything in Kibana or Wazuh (no rule edits,
no deletes, no saved-object changes).
