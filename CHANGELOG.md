# Changelog

All notable changes to `mob_mishka` are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- Package scaffold (MOB-248): `mix.exs`, `lib/mob_mishka.ex`, `priv/mob_plugin.exs`, test skeleton, credo config, pre-push hook.
- `MobMishka.register_all/0` stub wired into the plugin manifest's `:lifecycle.on_start`.
- `priv/mob_plugin.exs` declares an empty `:tags` field — placeholder for MOB-249's composite port. The mechanism that consumes it (plugin-manifest tag discovery in the `~MOB` sigil whitelist) ships in mob via MOB-247.

## [0.0.1] - unreleased

Initial spike. No composites ported yet — those land in MOB-249.
