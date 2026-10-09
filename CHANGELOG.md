# Changelog

All notable changes to `mob_mishka` are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **On-device self-test** (MOB-418). `MobMishka.SelfTest` implements `Mob.Plugin.SelfTest` and is declared in the manifest as `selftest:`. It checks that the lifecycle hook registered every composite with `Mob.Composite` (or the host's ejected override), then expands a `MishkaSwitch` + `MishkaProgress` tree through `Mob.Composite.expand/2` and asserts the native shape: no `:mishka_*` left, a `:toggle` with `value: true` and `on_change: {screen, tag}`, the label as a `:text`, and a `:progress` at `0.4`. Run it with `mix mob.selftest` from a host app (mob_dev 0.7.17). Requires mob 0.9.15; `mob_version` in the manifest is now `~> 0.9`.

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

