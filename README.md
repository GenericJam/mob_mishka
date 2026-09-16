# mob_mishka

Mishka Chelekom composites for [Mob](https://github.com/GenericJam/mob) apps, shipped as a proper plugin instead of vendored into every generated app.

**Status:** early spike. The scaffold is in place; composites port in [MOB-249](https://linear.app/mobframework/issue/MOB-249). Repository is private during the spike and opens once the core surface stabilises.

## Why this exists

Today `mob_new` bakes 75+ Mishka composite files into every generated app's `lib/<app>/components/` at generation time. Regenerating an app pulls a fresh snapshot; any user edits to a composite diverge from upstream forever. There is a bespoke `mix mob_new.sync_mishka` task coupling the mob_new archive to Mishka's source, and a `mishka_chelekom` mix task that used to write into `deps/mob/priv/tags/*.txt` to silence sigil warnings.

This plugin replaces all three:

- **Composites ship as a Hex dep**, callable directly and expandable via `~MOB` sigil tags. No files copied into your project by default.
- **Sigil whitelist membership rides the plugin manifest** — see MOB-247 in mob. No `config :mob, :extra_tags` block needed for tags this plugin ships.
- **`mix mob_mishka.gen <name>`** (MOB-251, planned) opts a specific composite into "copy source into my `lib/` so I can edit it," preserving Mishka's design-system value prop for users who want it — just no longer the default.

## Install

Add to your Mob app's `mix.exs`:

```elixir
def deps do
  [
    {:mob, "~> 0.8"},
    {:mob_mishka, "~> 0.0"}
  ]
end
```

Then in `mob.exs`, activate the plugin:

```elixir
config :mob, :plugins, [:mob_mishka]
```

That is the entire setup. No `Components.register_all/0` call in your `on_start/0`, no `extra_tags` config, no `deps/mob/priv/tags/*.txt` edits.

## Ejecting a composite for editing

```
mix mob_mishka.gen dialog          # or: mix mob_mishka.gen mishka_dialog
mix mob_mishka.gen --all           # eject every composite the plugin ships
```

Copies `MobMishka.Components.MishkaDialog` into `lib/<your_app>/components/mishka_dialog.ex` as `<YourApp>.Components.MishkaDialog`. Activate the ejected copies once (config/config.exs):

```elixir
config :mob_mishka, :override_namespace, YourApp.Components
```

`MobMishka.register_all/0` sees the app-local module at boot and prefers it over the plugin's default, so editing your copy takes effect on the next compile with no re-registration. Delete the file to fall back to the plugin's version.

Sibling aliases inside the ejected file still point at the plugin (e.g. `MishkaCloseButton` ejected on its own still calls the plugin's `MishkaActionIcon`). If you also want to edit a sibling, eject it too and fix up the alias by hand.

## Epic + arc

Full context in [MOB-246 Extract Mishka into a mob plugin (mob_mishka)](https://linear.app/mobframework/issue/MOB-246). Seven-child epic covering plugin-manifest tag discovery, this package scaffold, composite port, mix-task move, opt-in vendoring, mob_new template surgery, and migration guide.

## License

MIT.
