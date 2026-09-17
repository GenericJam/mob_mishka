# Changelog

All notable changes to `mob_mishka` are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0] - 2026-09-17

Initial Hex release. Plugin-manifest tag discovery landed in mob 0.9.0 (MOB-247), and this ships against it.

### Added

- Package scaffold (MOB-248): `mix.exs`, `lib/mob_mishka.ex`, `priv/mob_plugin.exs`, test skeleton, credo config, pre-push hook.
- `MobMishka.register_all/0` wired into the plugin manifest's `:lifecycle.on_start`.
- 73 composites + 3 support modules ported from `mishka_chelekom/development/mob` (MOB-249), plus 59 upstream test files with showcase-only blocks stripped. `MobMishka.composites/0` returns the full `{tag, module}` list; `priv/mob_plugin.exs` `:tags` mirrors it. 1912 tests passing.
- `mix mob_mishka.gen <name>` and `mix mob_mishka.gen --all` (MOB-251): eject a plugin composite into `lib/<app>/components/<name>.ex` for editing.
- `config :mob_mishka, :override_namespace, MyApp.Components` (MOB-251): when set, `MobMishka.register_all/0` prefers `<override_namespace>.<Short>` over the plugin default per composite. Missing override modules fall back cleanly. Delete an ejected file to revert its tag to the plugin's default on the next boot.
- `mix mob_mishka.migrate` (MOB-253): analyse an existing Mob app that carries pre-plugin vendored composites and produce a plan of removals + preservations. Byte-identical copies (after namespace normalisation) are safe to delete; user-edited copies are kept as overrides. Dry run by default; `--apply` writes; `--remove-extra-tags` also strips the compat bridge once your mob dep supports plugin-manifest tag discovery (MOB-247). See [MIGRATIONS.md](MIGRATIONS.md).

