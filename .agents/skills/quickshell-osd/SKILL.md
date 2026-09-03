---
name: quickshell-osd
description: Maintain the Hyprland Quickshell OSD in this repository. Use when changing its layout, visual styling, volume or brightness modes, transitions, slider animations, hide timeouts, or event handling.
---

# Quickshell OSD

Keep the OSD visually and behaviorally inspired by the iPhone Dynamic Island.

## Visual design

- Use a near-black pill with fully rounded ends and a subtle translucent edge highlight.
- Keep the surface clean; do not add a drop shadow unless explicitly requested.
- Use a restrained cool-neutral palette for icons, clock text, slider tracks, and slider fills.
- Avoid bright accent colors and flat medium-gray surfaces unless explicitly requested.
- Clip all content to the pill radius so fills and loaders cannot draw rectangular artifacts outside the island.

## Modes and transitions

- Treat `idle`, `volume`, and `brightness` as distinct modes.
- For `idle -> active`, fade out idle content, expand the pill, then fade in the active component.
- For `active -> idle`, fade out the active component, shrink the pill, then fade in idle content.
- For `volume <-> brightness`, preserve the pill size and use a short content crossfade; do not pass through idle.
- Stop or supersede in-progress transitions when a new mode event arrives. Rapid media-key input must not queue overlapping animations.

## Events and animation

- Repeated events for the current active mode restart its hide timeout.
- For repeated events, animate only the changing slider value; do not replay the whole mode transition.
- Animate slider fills smoothly.
- Keep timeout and transition state authoritative so stale callbacks cannot restore an older mode or layout.

## Change checklist

- Verify idle/active transitions in both directions.
- Verify volume/brightness swaps preserve the pill size.
- Verify repeated events update the value and timeout without replaying the full transition.
- Verify rapid events supersede stale transitions and no content escapes the pill radius.
