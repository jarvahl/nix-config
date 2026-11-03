```mermaid
flowchart LR
    T[telegram-for-gaia.service]
    G[gaia.service]

    T -->|messages and replies| G
    G -->|proactive notifications| T
```
