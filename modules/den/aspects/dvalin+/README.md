```mermaid
flowchart LR
    G[gaia.service]
    P[pi-telegram extension]
    T[Telegram Bot API]

    G --> P
    P <-->|polling and replies| T
```
