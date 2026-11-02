---
name: telegram-notify
description: Send a proactive message to the user's Telegram conversation when GAIA decides that an external notification is appropriate. Use only after deciding that the user should be notified.
---

# Telegram notification

GAIA owns the decision whether an incoming system note should reach the user. Hestia and other agents may provide context, but they must not decide delivery.

When delivery is appropriate, use the bundled script:

```sh
node <this-skill-directory>/scripts/send.mjs \
  "$GAIA_TELEGRAM_SOCKET" \
  "$GAIA_DEFAULT_CONVERSATION" \
  "<message>"
```

Do not use this for an ordinary Telegram reply; the active Telegram request already streams through GAIA. Use it only for proactive messages that were initiated by another local agent.
