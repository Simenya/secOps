# Probes — run once per model after setup, save output to evidence/00-setup/

Check `evidence/00-setup/openclaw-help.txt` for the exact agent-run syntax of the
installed version; the prompts below are what matters.

**Text probe (all three models):**
> Reply with the word OK only.

**Tool probe (haiku-collector; also sonnet-analyst to re-confirm it still fails):**
> Execute now, do not narrate a plan. Run `date -u` and `hostname`, then reply with
> exactly the two output lines and nothing else.

Record per model: pass/fail, stop reason, seconds. If Sonnet now passes the tool
probe, it may take over part of Phase 2; otherwise routing in PLAN.md stands.
