# GAIA

## Extensions

- `pi-telegram`: Telegram polling, typing, streaming, attachments, and replies in the current Gaia session.
- `pi-loop`: delayed and recurring prompts in the current Gaia session.
- `pi-memory`: persistent memory and session summaries.

## Compaction memory

In compaction summaries, keep recurring durable facts under `Memory candidates` as `- [count=2] ...`. Carry a candidate unchanged when there is no new evidence; merge or redact it and increment the count when a similar or confirming fact appears; decrement it when neither appears; remove it at zero. At `count=3`, save the fact with the `pi-memory` `memory_write` tool using `target: "long_term"`, then remove the candidate. Keep candidates internal and never send them to the user or Telegram. Explicit memory requests are saved immediately; use `scratchpad` only for active follow-ups and constraints.
