# Changelog

All notable changes to `mob_mishka` are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

Composite fixes from the iOS check (MOB-571). Everything below changes Android rendering too unless marked iOS. **Contains a breaking change (`MishkaTooltip`), so the next cut should be 0.2.0.**

### Breaking
- `MishkaTooltip` is no longer modal: **a tap outside an open tooltip no longer closes it.** Opt back in with `close_on_outside_tap={true}`. It used to pass `on_dismiss` to its anchored node whenever `on_open_change` was set, which on both platforms covers the page with a layer that swallows the next tap anywhere; so any open hint ate the next tap, and with two open a tap could toggle the other one. Without a handler the Android popup is also no longer focusable, and a closed tooltip no longer carries `on_tap` on its anchored node (`decisions/2026-11-27-tooltip-not-modal-by-default.md`).

### Added
- `MishkaTooltip`: `close_on_outside_tap` (default `false`) — opt in to "a tap anywhere outside the open bubble closes it". See Breaking.
- `MishkaMenu`: `item_icon_width` (default `24`); `MishkaNavLink`: `icon_width` (default `24`).

### Changed
- `MishkaVisuallyHidden` returns `[]` (no node) instead of a `size: 0` Spacer.
- `MishkaMenu` and `MishkaNavLink`: a glyph-string icon sits centred in a fixed-width slot, so labels line up. Emoji keep their own colours (documented); only symbol glyphs take the ink. `MishkaSelect` and `MishkaCombobox` rows are menu rows, so they change too: a ✓ mark now takes the 24-wide slot and pushes the label about 14 dp right.
- `MishkaPopover`: a markup arrow (`<MishkaPopoverArrow>` with nodes) now sits at the panel's leading edge instead of centred — there is no invisible copy to centre markup against. Give the popover a `width` and size the markup to it to centre it.
- `MishkaCalendar`: the default `time_width` is 52 (was 44). It is now a real fixed width (see Fixed), and 44 cut a 12-hour `"11:30 PM"` at the default 11sp to `"11:30 P…"` on both platforms — a regression on Android, where the cell used to grow. 52 fits it (≈45pt in SF Pro, 46–48dp in Roboto, measured from the font files); `time_width` stays overridable.

### Fixed
- `MishkaTree` / `MishkaTreeSelect`: indentation was inverted at depth 0 — the row's `size: 0` indent Spacer is flexible on iOS and on mob_new's current Android bridge, so it pushed root labels to mid-row. No zero-size Spacer is emitted any more (also `MishkaSplitter`'s blank pane and `MishkaVisuallyHidden`).
- `MishkaDock`: the bar's documented default `background` (`:surface_raised`) is applied.
- `MishkaListItem`: `align: :leading` / `:top` map to the Row's `top` (and `:trailing` / `:bottom` to `bottom`); neither renderer knows `leading`, so it fell back to centre. The doc lists the real values.
- `MishkaCard`: a string `title` gets `text_color: :on_surface`; with no ink it drew black on the dark theme on iOS.
- `MishkaColorPicker` value bands and `MishkaAlphaSlider` fade bands are drawn exactly one band wide; the `+1` overlap painted translucent edges twice and showed as dark seams.
- `MishkaSplitter` stacked (`orientation: :vertical`): the grip is centred across the divider instead of sitting at the left edge.
- `MishkaCalendar`: the agenda/day time cell uses `width`, not `min_width` (which no renderer reads), so rows line up.
- `MishkaPopover` and `MishkaPreviewCard` with an arrow above or below the panel: the arrow wrapper (a `fill_width` Box / Row) no longer forces the panel to the window cap. A glyph arrow is now placed by a hugging Box with a clear twin reserving its room (`decisions/2026-11-27-arrow-centred-by-clear-twin.md`). Parts that fill still widen the panel on Android: `MishkaPreviewCard`'s header, description and footer, and `MishkaPopover`'s `close` footer row. On iOS the panel stays cap-wide until mob's Column stops filling (MOB-564).
- Docs: a hold arrives as `{:long_press, …}`, not `{:tap, …}` (`MishkaTooltip`, `MishkaPopover`, `MishkaPreviewCard`, `MishkaToolbar`, `MishkaThemeIcon`, `MishkaContextMenu`); iOS has had `:anchored` since mob 0.8.3; iOS reads `weight` as fill-the-rest, not proportionally; `MishkaCode` no longer promises SF Mono (iOS falls back to the system font until mob resolves `"monospace"`, MOB-566); notes on former IOS_TODO items 1, 2, 6, 8 and 9 (fixed in mob 0.9.32) are updated.

## [0.1.6] - 2026-11-21

Catches up with mishka_chelekom `776c535b` (range `c3235534..776c535b`).

### Added
- **Seven composites** (upstream 7c170c7, 504eb0f), registered in `MobMishka.composites/0` and the plugin manifest (80 composites now):
  - `MishkaCalendar`: month grid, week lanes, day timeline and agenda views, all headless.
  - `MishkaCard`: figure, title, content and actions, with the slot tags `<MishkaCardFigure>`, `<MishkaCardTitle>` and `<MishkaCardActions>` (whitelisted, 39 slot tags now); `weight` and `height` on the root.
  - `MishkaDock` and `MishkaDockItem`: a floating bar of icon items with an action node beside it.
  - `MishkaListItem`: the leading / body / trailing row.
  - `MishkaRating`: stars, with a half star drawn as the empty glyph under a filled one cut at 50% by `clip_width`. Every cell hugs its glyph (no fixed width, so a star isn't cut at a large font scale), and the half cell centres both glyphs with the clip on an overlay that hugs the filled one, so the cut lands on the star's centre (MOB-536). The cut needs mob 0.9.32 and, on Android, a `MobBridge.kt` from mob_new 0.6.21; on an older renderer a half star draws as a full one. The default ink is `:amber_500`: upstream's `:warning` is no mob colour token, so default stars drew invisible on iOS and in the text colour on Android.
  - `MishkaTextInput`: a plain text field with the form events and leading/trailing nodes. Upstream's prop names are translated to the ones mob's text field reads (MOB-536): `keyboard_type` is sent as `keyboard` (a string), `font_family` as `font`, and `multiline: true` as `lines: 3` (an explicit `lines` wins); mob's `keyboard` and `font` are accepted as well. There is no `value_epoch`: to replace the text, assign a new `value`, which mob's renderers adopt.
- `MishkaActionIcon`: `size: :hug` (a bare, tappable glyph), `corner_radius`, and `overlay` (a corner badge over the glyph).
- `MishkaMenu`: `dropdown/4` keeps the trigger in flow and draws the panel in its own window; row height, padding, icon gap, text and separator props.
- `MishkaPopover`: `shadow` and per-edge `padding_*` on the panel. Like every `shadow` prop here, it reaches the node but mob's renderers don't draw it yet.
- `MishkaEmptyState`: `align: :left`, `title_size` / `title_weight` / `title_line_height`, per-edge padding.
- `MishkaPill`: `weight`.
- **Native test tags** (upstream c1aa001): an `id` on `MishkaAccordion`, `MishkaChip`, `MishkaCollapsible`, `MishkaCombobox`, `MishkaEmptyState`, `MishkaHighlight`, `MishkaLoadingOverlay`, `MishkaMark`, `MishkaMenu`, `MishkaPill`, `MishkaRollingNumber`, `MishkaSelect`, `MishkaSpoiler`, `MishkaSwitch`, `MishkaTagsInput` and `MishkaToast` tags the component and its parts (`<id>-trigger`, `<id>-panel`, `<id>-label`, …) for device tests. An unset `id` leaves the nodes untagged.
- Each composite's moduledoc links to its page on mishka.tools.
- `backdrop` prop on `MishkaAnchor` and `MishkaTabs`: the colour the label is painted in so the underline (now padding showing through, as wide as the text) reads on any surface. Defaults to `:surface`.
- `MishkaTabs`: the active label is set semibold as well as tinted.

### Changed
- Requires mob >= 0.9.32 (was >= 0.9.15), the first that draws `clip_width` (MOB-536). Android apps also need the `MobBridge.kt` from mob_new 0.6.21 for it.
- CI runs `mix test --warnings-as-errors`, so a `~MOB` "not in the Mob tag whitelist" warning fails the build (MOB-536).
- The `sync-upstream` workflow applies only upstream's change since `.upstream-sync-sha` (`git apply -3` of the diff between the two rewritten upstream trees), so blocks mob_mishka cut stay cut; a clashing file is committed with conflict markers and listed in the PR under "Conflicts to resolve". It leaves the sync branch alone while its open PR carries a review commit, and dispatches `tests` on the branch so the PR gets a result (MOB-536).

### Fixed
- Found reviewing the 0.1.6 release (upstream code): `MishkaCalendar` and `MishkaDockItem` put their `*font_family` props on Text nodes as `font_family`, which mob's Text never reads; they now emit `font`, so the fonts apply. `MishkaCalendar`'s day view draws `empty` for an empty `clusters` list, as for empty `rows`. `MishkaMenu.dropdown/4` routes an atom `on_dismiss` through `Event.handler/1`, so an outside tap closes the menu on Android.
- Rows whose first item filled the parent and left the rest zero wide: `MishkaMenubar` and `MishkaNavigationMenu` triggers hug their labels; `MishkaFloatingIndicator` targets share the row by `weight`; `MishkaToolbar` links draw their rule as padding instead of a filling Box.
- `MishkaTabs` underline was zero wide inside the scrolling strip; a tab with no panel no longer crashes when the strip is tagged.
- `MishkaDrawer.trigger/2` with a string builds a Box and Text, not a `:button` whose Material padding left no room for the label.
- `MishkaNumberField` sizes the value slot for the placeholder too, so an empty field stays one line and the strip keeps its width as the first digit goes in.
- `MishkaOverflowList`: the `+N` counter follows the last item, and items sit in a horizontal Scroll so the one at the edge is clipped rather than squeezed.
- Vertical `MishkaSlider` sends `width: length` so the Android bridge does not clip the track to a 48dp stub.
- Docs: sizing guidance for `MishkaFloatingWindow`, `MishkaPill` rows and `MishkaTooltip` spacing.

## [0.1.5] - 2026-10-12

Catches up with mishka_chelekom `c3235534`. The 0.1.0 port had been copied from
upstream `e7938f4` (Aug 5) while `.upstream-sync-sha` recorded Sep 15, so the
three Aug 20 commits below never reached mob_mishka.

### Added
- **Callers can supply the look these components hardcoded** (upstream 032cc52). All optional; the defaults draw exactly what 0.1.4 drew.
  - `MishkaChip`: `height`, `width`, `padding_x`/`padding_y`, `corner_radius`, `text_size`, `font_weight`, `max_lines`, a `trailing` slot, and colours for the unchecked and disabled states.
  - `MishkaPill`, `MishkaSegmentedControl`, `MishkaToggle`: height, horizontal padding, radius, text size and weight.
  - `MishkaActionIcon`, `MishkaThemeIcon`: `border_color`, `border_width`, and `shadow`.
  - **`shadow` doesn't draw yet**, on any component that takes it (action icon, theme icon, pill, segmented control, toggle, and the drawn switch's `thumb_shadow`): the prop reaches the node, but mob's renderers (iOS, and the Android bridge mob_new generates) don't read `shadow`. It's kept for parity with upstream and starts working once mob draws shadows.
  - `MishkaSeparator`: `render: :box` for a filled rule (`:divider` stays the default).
- **Drawn modes** (upstream ce3e26b): `render: :box` on `MishkaSwitch` (any track/thumb size, with `thumb_offset/4`), `MishkaProgress` and `MishkaMeter` (a declared-width, trackless bar; 0% and 100% both draw). The native primitive stays the default. `MishkaPill` gains `content_align`, `content_fill_width` and a `leading` slot.
- `MobMishka.slot_tags/0`: the 36 sub-component tags (`<MishkaTab>`, `<MishkaMenuItem>`, `<MishkaPopoverTrigger>`, `<MishkaSelectOption>`, …).
- `MobMishka.Components.Event.drag/1` reads a drag payload (atom or string keys) for drawer, floating window and splitter (upstream 1aa186e).

### Fixed
- **An explicit `nil` prop reached the device as the string `"nil"`** (upstream fae9393): a colour prop looked up a token named "nil", a Text drew the word, an `id` became a test tag every untagged sibling answered to. Props now read as `Map.get(props, :k) || default` (and default-true booleans as `!= false`), so `nil` means absent. One behaviour change: `number_formatter`'s `thousand_separator: nil` now groups; `false` and `""` still disable grouping.
- Sub-component tags warned "not in the Mob tag whitelist" in apps' `~MOB` sigils, because the manifest listed only the 73 composites. It now lists the slot tags too.
- Docs that pointed at upstream's `MishkaMob.App.on_start/0` or `mix mishka.ui.gen.mob` now name the plugin manifest and `MobMishka.register_all/0`.

### Changed
- Component tests track upstream's, with the gallery-page tests left out (mob_mishka doesn't ship the gallery). The `sync-upstream` workflow now syncs `test/mob_mishka/components/` along with the components, lists files that still name upstream-only modules, and its review notes no longer call `Map.get(props, :k) || default` an idiom to revert.

## [0.1.4] - 2026-10-09

### Added
- **On-device self-test** (MOB-418). `MobMishka.SelfTest` implements `Mob.Plugin.SelfTest` and is declared in the manifest as `selftest:`. It checks that the lifecycle hook registered every composite with `Mob.Composite` (or the host's ejected override), waiting for `Mob.Plugins.Supervisor` to finish running the `on_start`s and re-checking for up to 5 s so a run right after a relaunch is not a false failure. It then expands a `MishkaSwitch` + `MishkaProgress` tree through `Mob.Composite.expand/2` and asserts the native shape: no `:mishka_*` left, a `:toggle` with `value: true` and `on_change: {screen, tag}`, the label as a `:text`, and a `:progress` at `0.4`. When the host registered its own ejected copy of either tag, those nodes are expanded with the plugin's module, so a host's edits never fail the plugin's test. Run it with `mix mob.selftest` from a host app (mob_dev 0.7.17).

### Changed
- Requires mob >= 0.9.15 (was `~> 0.9`), for `Mob.Plugin.SelfTest`; `mob_version` in the manifest is now `~> 0.9` (was `~> 0.8`).

## [0.1.3] - 2026-10-01

### Fixed
- 0.1.2's signature used the legacy v1 envelope (written by mob_dev 0.7.0), which current `mob_dev` refuses with `envelope_v1_unsupported`, so hosts still couldn't activate the plugin. The release workflow now signs with mob_dev 0.7.2+, which writes the v2 envelope.

## [0.1.2] - 2026-10-01

### Changed
- Releases are signed with the mob first-party key. `priv/mob_plugin.pub` (the shared first-party public key, fingerprint `ed25519:nc56w+1Kx0gIt/4EkHxnMZCKHMzp4+S5kS/HoSzEZkg=`) is now committed, and the release workflow regenerates `priv/mob_plugin.sig` from the current manifest before every Hex publish, so `mob_dev` hosts verify the package instead of reporting it unsigned.

## [0.1.1] - 2026-09-17

### Docs
- README rewritten for the shipped state: install snippet uses the actual pins (`{:mob, "~> 0.9.0"}`, `{:mob_mishka, "~> 0.1"}`), stale "spike" and "planned" callouts replaced with what actually shipped, added a short "what's in it" table with the ten most-used composites and a call-site example.
- `mix.exs` docs config: MIGRATIONS.md added to `extras`, composite modules grouped under "Composites" via `groups_for_modules`, support modules under "Support", mix tasks under "Mix Tasks", nested by `MobMishka.Components` prefix so the hexdocs sidebar reads at scale.
- `@moduledoc` on `MobMishka` names the actual mob floor (`~> 0.9.0`) and pin (`~> 0.1`).
- `AGENTS.md` + `CLAUDE.md` added for AI-agent onboarding. Cover composite anatomy, the `mishka_chelekom` upstream relationship, cross-repo work with mob, worktree discipline, adversarial review, release flow, and physical-device verification for canvas-drawn composites.

## [0.1.0] - 2026-09-17

Initial Hex release. Plugin-manifest tag discovery landed in mob 0.9.0 (MOB-247), and this ships against it.

### Added

- Package scaffold (MOB-248): `mix.exs`, `lib/mob_mishka.ex`, `priv/mob_plugin.exs`, test skeleton, credo config, pre-push hook.
- `MobMishka.register_all/0` wired into the plugin manifest's `:lifecycle.on_start`.
- 73 composites + 3 support modules ported from `mishka_chelekom/development/mob` (MOB-249), plus 59 upstream test files with showcase-only blocks stripped. `MobMishka.composites/0` returns the full `{tag, module}` list; `priv/mob_plugin.exs` `:tags` mirrors it. 1912 tests passing.
- `mix mob_mishka.gen <name>` and `mix mob_mishka.gen --all` (MOB-251): eject a plugin composite into `lib/<app>/components/<name>.ex` for editing.
- `config :mob_mishka, :override_namespace, MyApp.Components` (MOB-251): when set, `MobMishka.register_all/0` prefers `<override_namespace>.<Short>` over the plugin default per composite. Missing override modules fall back cleanly. Delete an ejected file to revert its tag to the plugin's default on the next boot.
- `mix mob_mishka.migrate` (MOB-253): analyse an existing Mob app that carries pre-plugin vendored composites and produce a plan of removals + preservations. Byte-identical copies (after namespace normalisation) are safe to delete; user-edited copies are kept as overrides. Dry run by default; `--apply` writes; `--remove-extra-tags` also strips the compat bridge once your mob dep supports plugin-manifest tag discovery (MOB-247). See [MIGRATIONS.md](MIGRATIONS.md).

