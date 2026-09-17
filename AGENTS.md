# AGENTS.md — orientation for AI agents working on mob_mishka

You're in the **mob_mishka** repo, the plugin that ships Mishka Chelekom composites for Mob apps.

**Also read [`~/code/mob/AGENTS.md`](../mob/AGENTS.md)** for the system view: the mob three-repo topology, the render pipeline, `Mob.Composite` / `Mob.Sigil` / `~MOB`, how to drive a running app from your session, and the cross-cutting pre-empt-failure rules. This file is mob_mishka-specific.

> **Keep this file current.** When you change composite anatomy conventions, add a new pattern for cross-mob-version compat, or hit a gotcha that would trip the next agent, fix it here in the same commit — not in a follow-up.

## What mob_mishka is, in one paragraph

A Hex plugin that ships 73 Mob composites (`<MishkaDialog>`, `<MishkaTabs>`, `<MishkaHueSlider>`, `<MishkaSemiCircleProgress>`, `<MishkaAngleSlider>`, …) plus three support modules (`Anchored`, `Color`, `Event`). Instead of `mob_new` copying 75+ `.ex` files into every generated app at generation time — which is what happened before this plugin — the app depends on `{:mob_mishka, "~> 0.1"}` and every composite is available immediately, versioned like any other dep, upgradable in place. `mix mob_mishka.gen <name>` ejects one composite into `lib/<app>/components/` for editing, and `config :mob_mishka, :override_namespace, <App>.Components` makes the ejected copy supersede the plugin's default.

The extraction epic is [MOB-246](https://linear.app/mobframework/issue/MOB-246) — seven-child arc: plugin-manifest tag discovery (MOB-247 in mob), this package scaffold (MOB-248), composite port (MOB-249), mix-task move (MOB-250), opt-in vendoring (MOB-251), mob_new template surgery (MOB-252), migration guide (MOB-253).

## Relationship to mishka_chelekom (Phoenix upstream)

**Mishka Chelekom is the design system.** Its Phoenix/LiveView side lives at [mishka-group/mishka_chelekom](https://github.com/mishka-group/mishka_chelekom) and is the source of truth for the visual language, colour theory, component variants, and copy. `mob_mishka` is the **mob-side surface**: the same design intent expressed as `Mob.Composite` modules with `Mob.Canvas` / `Mob.UI` primitives instead of Phoenix HTML/CSS.

Practical consequences:

- **Visual & prop parity is a goal**, but code parity is not. A prop name that reads well in a Phoenix component (`class="rounded-lg shadow-md"`) may not exist at all in the mob composite (rounded corners are a `radius` number; shadows are a `Mob.Canvas` op). Match the *intent*; do not port the surface verbatim.
- **The Phoenix repo owns the design tokens.** Colour palettes, spacing constants, variant enums — if you're changing one, change it upstream first and mirror here, not the other way.
- **The mob composites are portable within mob, not to Phoenix.** A composite here calls `Mob.Composite.register/2`, expands via `expand/3` returning a `%{type: …}` node tree, and is drawn by SwiftUI (iOS) or Compose (Android). None of that has a browser analogue.
- **Old `mishka_chelekom` mob mix tasks** (`mix mishka.mob.*`) get one deprecation cycle that redirects users to `mob_mishka`. If you touch either side of that bridge, keep both messages in sync.

Anyone joining from the Phoenix side: skim `~/code/mob/AGENTS.md` end-to-end before your first composite change here. `~MOB` sigils, the composite expander contract, and `Mob.Canvas` are not obvious from the outside.

## Repo topology

mob_mishka is one leaf on the mob tree. Cross-repo work is normal.

| Repo | Path | What lives here | Edit when |
|---|---|---|---|
| **mob** | `~/code/mob` | Runtime library. `Mob.Sigil` reads plugin manifests to whitelist `<Mishka…>` tags (MOB-247, mob 0.9.0). `Mob.Composite` is the registry composites register into at boot. `Mob.Canvas` / `Mob.UI` are the primitives composites draw with. | Runtime plumbing that composites depend on. Bug in `Mob.Canvas.arc/6` → fix in mob, not here. |
| **mob_new** | `~/code/mob_new` | Project generator. Since MOB-252, no longer vendors composites; instead the template pins `{:mob_mishka, "~> 0.1"}`. Also holds the migration entry point (`mix mob_mishka.migrate` is a task shipped from here that scans a generated app and updates it). | Generator template touching the mob_mishka dep pin, or the migration task's app-side detection. |
| **mob_mishka** | `~/code/mob_mishka` (here) | The 73 composites + 3 support modules. Plugin manifest at `priv/mob_plugin.exs`. Mix tasks (`mob_mishka.gen`, `mob_mishka.migrate`) for opt-in ejection and migration. | New composites, composite behaviour changes, plugin-side surface. |
| **mishka_chelekom** | not in this workspace by default | Phoenix upstream. Owns the design tokens and Phoenix components. | Design decisions, upstream visual changes, cross-side prop harmonisation. |

Composites that need a new `Mob.Canvas` op, a new `Mob.UI` node type, or a `Mob.Sigil` change → land the mob-side change first, cut a mob release, then bump this plugin's `mob` floor and ship the composite. Do NOT ship a composite here that assumes an unreleased mob feature. See "Release flow" below.

## Anatomy of a Mob composite

Each composite is a module under `lib/mob_mishka/components/` following one shape:

```elixir
defmodule MobMishka.Components.MishkaAngleSlider do
  use Mob.Composite                      # gives you Mob.Composite behaviour

  alias MobMishka.Components.Color
  alias MobMishka.Components.Event

  # 1. Expander — what <MishkaAngleSlider .../> becomes in the sigil.
  #    Called at compile time by ~MOB. Return a node tree using
  #    Mob.UI / Mob.Canvas primitives.
  @doc "Composite expander (`<MishkaAngleSlider />`). Delegates to `angle_slider/1`."
  @impl Mob.Composite
  def expand(props, _children, _ctx), do: angle_slider(props)

  # 2. Public constructor — same shape as expand/3 result, callable
  #    directly (props as map or keyword). Used by other composites
  #    that compose you.
  def angle_slider(props \\ %{}) do
    props = Map.new(props)
    angle = normalize_angle(Map.get(props, :value, 0))
    size = Map.get(props, :size, @size)

    dial = canvas_node(size, dial(size, angle, props), Event.handler(Map.get(props, :on_change)), Map.get(props, :id))
    ~MOB"""
    <Column fill_width={true} align={:center}>{header(...)}{dial}</Column>
    """
  end

  # 3. Pure helpers — everything else. Doctest-eligible; drawing math
  #    lives here so it can be exercised without mounting a screen.
  def dial(size, angle, props) do
    center = size / 2
    radius = center - @ring
    [Mob.Canvas.circle(center, center, radius, color: @track, width: @ring)] ++
      arc(center, radius, angle, Map.get(props, :color, @accent))
  end
end
```

Then it gets registered:

- The plugin manifest at `priv/mob_plugin.exs` declares `:tags` (all `<MishkaXxx>` tags this plugin ships) and `:lifecycle.on_start` = `MobMishka.register_all/0`.
- `MobMishka.composites/0` lists `{tag, module}` pairs.
- `MobMishka.register_all/0` iterates that list at boot and calls `Mob.Composite.register/2`, preferring `<override_namespace>.<Short>` if that module is loaded (opt-in vendoring — see MOB-251).

Conventions that matter:

- **Every composite has a public constructor** (`angle_slider/1`, `semi_circle_progress/1`, …). `expand/3` delegates to it. This lets one composite call another without re-parsing sigil syntax, and it's the shape the doctest examples use.
- **Drawing math is a pure function**, testable without a screen. `dial(size, angle, props)` returns a `%{type: :canvas, draw: [ops]}` node. `Mob.Canvas.arc/6` produces the arc op with `start_deg` and `end_deg` in degrees (0° right, sweeping CW — see mob's `Mob.Canvas` @moduledoc).
- **Event handlers go through `Event.handler/1`**, which normalises the `:on_change` prop into the `on_tap` / `on_drag` map shape mob expects. Do not hand-roll `{self(), tag}` tuples in a composite — go through the helper so all composites route through the same registered path.
- **Ports of upstream tests live at `test/mob_mishka/components/`** as `<name>_test.exs`, mirroring the module layout under `lib/`. Doctests inside the composite module cover the pure helpers; the test file covers `expand/3` + registration + integration with `Mob.Composite`.

## Adding or editing a composite

1. **Check upstream first.** If mishka_chelekom already has this composite for Phoenix, mirror the prop names and defaults where the mob primitives allow. Diverge with intent and a comment naming *why*.
2. **Write the module** under `lib/mob_mishka/components/`. Use an existing composite of similar shape as a template — `MishkaSemiCircleProgress` for canvas-only, `MishkaAccordion` for stateful open/close, `MishkaAngleSlider` for touch-driven canvas.
3. **Add doctests** on the pure helpers where the doctest reads naturally (numeric functions, math). Doctest is worth more here than an inflated unit test — it doubles as a call-site example.
4. **Write a test file** at `test/mob_mishka/components/<name>_test.exs` covering `expand/3` returns the expected tree shape, `register_all/0` registers the tag, and any override-precedence behaviour if the composite has state.
5. **Register the tag.** Add `{:mishka_your_composite, MishkaYourComposite}` to `MobMishka.composites/0`. Add `:mishka_your_composite` to the `:tags` list in `priv/mob_plugin.exs`. The two lists must agree — a mismatch would mean the sigil recognises the tag at compile time but the runtime never registers a handler, so the composite silently no-ops.
6. **Physical-device verify** for anything canvas-drawn or gesture-driven. Compose and SwiftUI have platform-runtime deltas iOS's default behaviour absorbs and Android leaves to the caller (see the [MOB-256 arc ADR](../mob_new/decisions/2026-09-17-android-arc-angle-dp-scaling.md) in mob_new — a plausible-looking canvas op rendered wildly different across platforms because `canvasFloat` was applied to angles). Screenshot both platforms; do not trust "looks right on iOS" alone.
7. **Adversarial review** the diff before you commit — see the section below.

## Ejecting a composite (`mix mob_mishka.gen`)

`mix mob_mishka.gen dialog` (or `mishka_dialog` — the `mishka_` prefix is optional) copies `MobMishka.Components.MishkaDialog` into `lib/<app>/components/mishka_dialog.ex` as `<YourApp>.Components.MishkaDialog`. The namespace substitution is the only textual change.

Activation is host-app opt-in via `config/config.exs`:

```elixir
config :mob_mishka, :override_namespace, YourApp.Components
```

`MobMishka.register_all/0` looks at the override namespace at boot: for each `{tag, PluginModule}` in `composites/0`, it prefers `Module.concat(override, short_name(PluginModule))` if that module is `Code.ensure_loaded?/1` — otherwise it falls back to the plugin default. Delete an ejected file to fall back to the plugin.

Two agent-relevant gotchas:

- **`mix mob_mishka.gen` does not chase aliases.** If `MishkaCloseButton` internally calls `MishkaActionIcon` and you eject only the close button, the ejected copy still calls the plugin's `MishkaActionIcon`. Ejecting the sibling too is manual — this is intentional (partial ejection is a common shape). Say so if a user asks.
- **The ejected file is a snapshot.** If you upgrade `mob_mishka` and the plugin's default changed, the ejected copy stays where it was until the user re-runs `mix mob_mishka.gen --force <name>` or manually merges. The migration task (`mix mob_mishka.migrate`) is what tells the user about this drift.

## Testing

Run the suite:

```bash
mix deps.get
MIX_ENV=test mix test
```

At release-cut time the pre-push hook adds format + credo --strict:

```bash
mix format --check-formatted
mix credo --strict          # whole tree, includes ExSlop AI-pattern checks
```

The full pre-commit checklist mirrors mob's (see mob/CLAUDE.md § "Pre-commit checklist"). Same discipline:

- Every behaviour change ships with a test. The bar is "would this test fail if the fix were reverted?"
- Doctests count for pure helpers — including a doctest that demonstrates the intended call site is often more valuable than a test that asserts a shape.
- `~MOB` sigil tests belong in `test/mob_mishka/components/` and exercise the actual sigil compile, not just the pure helper.

Composite-specific patterns:

- Composite tests use `use Mob.Test.ScreenCase` (from mob) to mount a screen and drive `expand/3` end-to-end, then assert on the returned tree shape.
- For canvas-drawing composites, assert on the emitted `Mob.Canvas` ops list — the primitives are pure so the assertion is exact and fast.
- For gesture composites, use `Mob.Test.tap/2` to drive tags and `Mob.Test.assigns/1` to read state.

## Worktrees

**Default assumption: work happens in a git worktree.** The user (Kevin) runs multiple agents in parallel; each task in its own worktree prevents conflicts and keeps `master` clean while work is in flight.

If a task is assigned to you and worktree usage isn't mentioned, ask:

> "Should I use a worktree for this?"

Yes for anything non-trivial or that touches templates. In-place is fine for a single-file doc edit, one-line config change, or a version bump.

```bash
cd ~/code/mob_mishka
git worktree add ../mob_mishka-worktrees/<slug> -b <branch>
cd ../mob_mishka-worktrees/<slug>
```

The git stash stack is shared across worktrees. Never use bare `git stash` / `git stash pop` — you could pop another session's changes. Prefer a temporary WIP commit; if you must stash, use `git stash push -u -m "<unique-tag>"`, capture the entry's SHA via `git stash list --format='%H %gs'`, restore with `git stash apply <sha>`, and drop the entry after.

## Adversarial review — before every commit

**Non-trivial work gets an adversarial review before it is committed.** Spawn a subagent, point it at the diff, and tell it to find defects rather than to approve. Act on what it finds, then commit.

It must be a **separate agent**, not a re-read of your own work. The wrong version of an idea usually survives self-review because self-review carries the author's mental model.

Give the reviewer:

- The diff to read (`git diff <base>..HEAD`, and the base explicitly).
- What the change claims to do.
- The specific things you are least sure about.
- Rank findings blocking / should-fix / nitpick.
- Cite `file:line` for every finding.
- Separate what it verified in source from what it is reasoning about platform semantics.

Skip it only for: formatting, a typo, a version bump, a changelog edit, moving a file. Reach for it when the change has behaviour, touches a canvas op, or spans a platform boundary.

The recent [MOB-256 arc bug](https://github.com/GenericJam/mob_new/pull/75) — an Android canvas rendering bug this plugin's `MishkaSemiCircleProgress` and `MishkaAngleSlider` surfaced — went through three wrong "fixes" (clip-only, sweep-negate, start/end-swap) before an adversarial review of the wrong-answer diffs redirected to the actual root cause (dp→px scaling of angle values in the generated Android bridge). Each of those wrong fixes would have shipped without the review.

## Decision log

Non-obvious decisions — tradeoffs, workarounds, conventions, "why we chose X over Y" — go in `decisions/`, one file per decision:

```
decisions/YYYY-MM-DD-short-slug.md
```

Each file is a lightweight ADR:

```markdown
# <Title>
- Date: YYYY-MM-DD
- Status: accepted | superseded by <file> | proposed
## Context      — what prompted this
## Decision     — what we chose
## Consequences — tradeoffs, follow-ups
```

**Append new files; never edit existing ones.** If a decision changes, add a new file and mark the old one `Status: superseded by <new-file>`. The date-sorted directory listing is the index. Record the decision the moment you make it, not later.

Grep `decisions/` before you commit anything non-obvious — both directions. **Does this need a new record?** and **does this invalidate an existing record?** The half that gets missed is the second one, and it's more dangerous: a record asserting a property the code no longer has is worse than no record.

## Release flow

Canonical release process lives at [`~/code/mob/RELEASE.md`](../mob/RELEASE.md). The mob_mishka specifics:

- `mix.exs` is the source of truth. Bump `@version "X.Y.Z"`, commit, push — `.github/workflows/release.yml` detects the mix.exs change and tags / GH-releases / hex-publishes. Each step is idempotent.
- **The `mob` floor pin in this repo is load-bearing.** Every plugin release must state the mob version it needs and pin its `mob` dep accordingly. When you rely on a new `Mob.Canvas` op or a new `Mob.Composite` feature, land it in mob, wait for its release, then bump this pin — do not ship a plugin release that depends on an unreleased mob feature.
- **Lockstep with mob for user-visible feature releases.** If a new composite here requires a new `~MOB` tag semantics feature in mob, publish mob first, then this plugin against the released mob, then bump `mob_new`'s pins so a `mix mob.new` today produces an app pinned to the versions that actually work together.
- Ships as a real Hex package (`mix hex.publish`, run by CI when `HEX_API_KEY` secret is set). Docs are shipped in the same `mix hex.publish` call — the `docs:` config in `mix.exs` groups modules by kind (Composites / Support / Mix Tasks) and includes README + MIGRATIONS + CHANGELOG as extras. Keep the docs configuration current when you add module groups.
- **Review gate is on by default** (see mob/RELEASE.md § "Review gate"). Everything that landed since the last published version gets a code review before you publish, scoped at `v<last-published>..HEAD`, plus the version-sanity checks (is this version already published? did anything merge after the bump commit?). Skip only if the user says so.

Pre-push hook (`.githooks/pre-push`) runs format check + `mix test --exclude macos_only --exclude requires_zig` on every push (fast). Activate once per clone or worktree with:

```bash
git config core.hooksPath .githooks
```

## Issue tracking

Status lives in **Linear** (team `MOB`), the single board across mob, mob_dev, mob_new, and mob_mishka. See mob/CLAUDE.md § "Issue tracking" for the full split. Short version:

- **Linear (`MOB`)** — live status, one issue per thread.
- **`decisions/`** — durable rationale. Link from the issue; don't copy.
- **PRs / git** — the code. Reference the issue id in branch, PR title, commits.

`LINEAR_API_KEY` lives in `~/code/mob/.env`. Sibling repos `source ~/code/mob/.env`. Team `MOB` uuid = `07dd0939-c66d-44f2-8da5-e3a4a243e953`. No Linear MCP is wired in; use the raw GraphQL endpoint.

## Physical-device verification is not optional for canvas work

Every composite that draws via `Mob.Canvas` renders through SwiftUI on iOS and Compose on Android. The two runtimes have subtle deltas iOS's defaults absorb and Compose leaves to the caller. Simulators do not always reproduce physical-device behaviour, especially around density scaling, clipping, and touch coordinates.

Before shipping a canvas-drawn composite change:

- Screenshot both iOS **and** Android on a physical device. Compare side-by-side.
- If the composite is gesture-driven, drag it on both platforms and inspect the `Mob.Test.assigns/1` state — visual alone isn't enough.
- Read [MOB-256](https://linear.app/mobframework/issue/MOB-256) if you're touching arc / sweep / degrees at all. That bug survived three plausible-looking fixes because the root cause was upstream (dp→px scaling of angle values in the generated Android bridge), not in the composite math.

The `mishka_verify` app under `/private/tmp/…/scratchpad/mob-mishka-verify/mishka_verify` was created for exactly this purpose during the MOB-246 verification round. Similar throwaway apps should be spun up per major cross-platform composite change.

## Connecting to a running Mob app

Full guide at `~/code/mob/CLAUDE.md` § "Connecting an IEx session to a running mob app". The short version:

```bash
cd /path/to/your_mob_app
mix mob.connect            # starts IEx connected to all devices
```

Then from any IEx / one-shot script on the Mac:

```elixir
node = :"your_app_android_<suffix>@127.0.0.1"
Node.connect(node)
:rpc.call(node, GenServer, :call, [:mob_screen, :get_current_module])
:rpc.call(node, :mob_nif, :screenshot, [:png, 90, 1.0])
```

For composite verification, `Mob.Test.tap/2` (by tag) is faster than gesture-driven interaction. Set the `id` prop on the composite in the test screen so you can address it directly from the test.

## Common composite anti-patterns

- **Emitting `Mob.Canvas` ops with device-dependent units.** Arc angles are degrees; positions are dp. Do not multiply either by density. Read the `Mob.Canvas.arc/6` @doc before you write one.
- **Registering a tag but not adding it to `priv/mob_plugin.exs`.** The sigil compile-time whitelist and the runtime registry are separate — mismatch means silent no-op at render time.
- **Composing another composite by calling its module directly instead of via `~MOB` sigil.** Both are legal, but the sigil path exercises the `Mob.Composite` registry and matches how the app actually uses your composite. Prefer sigil-form in tests.
- **Assuming iOS SwiftUI convention matches Compose numeric convention.** They can differ (see MOB-256). Verify on device, not on paper.
- **A composite that assumes `:on_change` is set.** Screens legitimately render composites in a "read only" state with no handler. Every event prop must degrade to a no-op if the handler is nil — `Event.handler/1` returns `nil` in that case and the drawn node's `on_tap` / `on_drag` must handle that.

---

Anything that would trip the next agent, add here — same commit, not a follow-up.
