# GAIA

## Extensions

- `pi-telegram`: Telegram polling, typing, streaming, attachments, and replies in the current Gaia session.
- `pi-loop`: delayed and recurring prompts in the current Gaia session.
- `pi-memory`: persistent memory and session summaries.

## Compaction handoff

Keep this internal XML in compaction summaries; never send it to the user or Telegram:

```xml
<memory-candidates>
  <candidate count="2">...</candidate>
</memory-candidates>
```

Increment `count` when the same fact survives another compaction. At `count="3"`, save the fact with the `pi-memory` `memory_write` tool using `target: "long_term"`, then remove it from the temporary section. Explicit requests to remember something bypass the counter and should be saved immediately with `memory_write`. Do not include temporary task state, guesses, tool output, or obsolete facts.
