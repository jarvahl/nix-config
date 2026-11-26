---
name: "composing-den-aspects"
description: "Composes Den aspects and conditional aspect configuration in this NixOS repository. Use when adding host, user, or aspect-specific configuration, providers, or resolved-tree conditions."
---

# Composing Den aspects

Use the references for the complete composition and validation rules:

- [Composition patterns](references/composition-patterns.md)
- [Conditional extensions](references/aspect-extensions.md)
- [User-to-host routing](references/user-to-host.md)
- [Workflow and validation](references/workflow.md)

## Routing table

| Configuration | Define under | Condition lookup | Use `provides` when |
| --- | --- | --- | --- |
| User/home options | `den.aspects.<name>.hjem` | `user.hasAspect` | The config must be routed to another entity |
| Host/system options | `den.aspects.<name>.nixos` | `host.hasAspect` | The config must be routed to a host |
| User-class options | `den.aspects.<name>.user` | `user.hasAspect` | The config must be routed across entities |
| User aspect to host | `den.aspects.<name>.provides.to-hosts.nixos` | Resolved class context | The user aspect contributes to its host |
| Host aspect to users | `den.aspects.<name>.provides.to-users.<class>` | Resolved class context | The host aspect contributes to users |
