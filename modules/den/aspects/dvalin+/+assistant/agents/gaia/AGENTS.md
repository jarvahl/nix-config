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

At each compaction:

1. Compare every candidate with the current conversation.
2. Increment `count` when the conversation contains a similar fact, a repetition, or another fact that confirms it.
3. Decrement `count` only when the conversation contains neither a similar fact nor a confirming fact.
4. Remove a candidate when its count reaches zero.
5. When a candidate reaches `count="3"`, save it with the `pi-memory` `memory_write` tool using `target: "long_term"`, then remove it from this temporary section.

Explicit requests to remember something bypass the counter and should be saved immediately with `memory_write`. Do not include temporary task state, guesses, tool output, or obsolete facts.
