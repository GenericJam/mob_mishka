# Popover and preview-card arrows are placed by a hugging Box and a clear twin
- Date: 2026-11-27
- Status: accepted

## Context
A panel's arrow above or below it has to sit centred (or inset at start/end)
on the panel's edge. A Column has no horizontal alignment on either platform,
so MishkaPopover wrapped the beak in a `fill_width` Box and MishkaPreviewCard
put it in a `fill_width` Row of flexible spacers. A filling child makes a
wrapping Column as wide as its widest constraint; inside the anchored popup
window that is the window cap. So every popover or preview card with an arrow
was screen-wide on Android as well as iOS (MOB-563 / MOB-571).

The panel's width is decided by its content, so nothing can size the arrow's
lane to it without measuring, and mob has no node opacity.

## Decision
The panel and arrow become a hugging Box (a z-stack, sized by its widest child)
holding a Column of [panel, reserve] (or [reserve, panel]) and the arrow, with
the Box aligned to the arrow's edge (`top_center`, `bottom_trailing`, ...;
start/end insets are padding on a hugging wrapper). The reserve is the arrow's
own glyph Text with `text_color` 0x00000000 and no tag, so it takes exactly the
glyph's room on each platform without any measured or guessed height.

Markup arrows (`<MishkaPopoverArrow>` with nodes) have no invisible twin, so
they sit in the Column as given, at the panel's leading edge; the doc says to
give the popover a `width` and size the markup to it to centre it.

## Consequences
- The arrow wrapper no longer forces a panel to full width. It does NOT make
  every arrowed panel hug: a part that fills still widens it on Android —
  MishkaPreviewCard's header, description and footer, and MishkaPopover's
  `close` footer (`<Row fill_width={true}>` in `footer_row/1`). Measured on
  Android: such a panel is 362.9 dp of a 411 dp window. Those inner fills are
  left for a separate change. On iOS a Column still fills (MOB-564), so
  arrowed panels stay cap-wide there until that lands.
  *Update (MOB-561 docs pass):* MOB-564 has landed on mob master (next
  release). On that mob an iOS Column hugs unless it sets `fill_width`, and
  widens only when a child fills it, so arrowed panels hug on iOS as they do
  on Android, with the same inner fills above. On mob 0.9.33 and earlier the
  sentence before this one still holds.
- Markup arrows are no longer centred automatically (they were, at the cost of
  a screen-wide panel).
- The same idea fits any "centre X on a content-sized sibling" layout while
  mob lacks a horizontally aligned Column.
