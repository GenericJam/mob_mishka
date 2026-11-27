# MishkaTooltip is not modal by default; tap-outside-to-close is opt-in
- Date: 2026-11-27
- Status: accepted

## Context
MishkaTooltip always handed its `:anchored` node an `on_dismiss` (as `on_tap`)
whenever `on_open_change` was set. On both platforms an open anchored node with
a dismiss handler covers the page to catch outside taps: iOS lays a full-screen
clear layer with `onTapGesture` (`MobAnchored.swift:99-106`), Android opens the
Popup focusable with `dismissOnClickOutside` (`MobBridge.kt` anchored case). The
tap that lands there is consumed to report the dismissal.

So every open tooltip was modal: the next tap anywhere closed the hint and
reached nothing else. With two open, the topmost layer belonged to whichever was
drawn last, so a tap meant for one tooltip's trigger toggled another tooltip
(found on the iOS check, MOB-561 finding E2; MOB-571).

## Decision
Non-modal by default. The tooltip wires no `on_dismiss`; an open bubble closes
from a tap on itself (`close_on_tap`, default true), a second hold on its
trigger, or the screen changing `open`. A new prop, `close_on_outside_tap`
(default `false`), restores tap-anywhere-to-close for a screen that wants it,
documented as consuming the closing tap. The handler is only put on an OPEN
anchored node; a closed tooltip never carries one.

## Consequences
- A tooltip is a hint, and a hint must not block the page; this matches the web,
  where pointer-leave closes a tooltip without eating the next click.
- Screens that relied on an outside tap closing a tooltip must pass
  `close_on_outside_tap={true}`. The CHANGELOG says so.
- MishkaPopover, MishkaPreviewCard and MishkaMenu dropdowns keep their own
  `on_dismiss` props: a panel is legitimately modal, a hint is not.
