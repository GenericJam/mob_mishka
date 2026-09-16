defmodule MobMishka do
  @moduledoc """
  Mishka Chelekom composites for Mob apps.

  This package is the plugin-shipped replacement for the "vendor 75 composite
  files into every generated app" pattern that `mob_new` uses today. Add it
  to your `mix.exs`:

      {:mob_mishka, "~> 0.0"}

  and every `<Mishka…>` composite works in your `~MOB` sigils — no
  `Components.register_all/0` in your `on_start/0`, no `config :mob,
  :extra_tags` block, no editing `deps/mob/priv/tags/*.txt`. The plugin
  registers its composites at boot via its own lifecycle hook, and the sigil's
  compile-time whitelist reads plugin manifests for tag membership (see
  MOB-247 in mob).

  If you want to edit the source of a specific composite, run
  `mix mob_mishka.gen <name>` (MOB-251) to eject a copy into your
  `lib/<app>/components/<name>.ex`, where it supersedes the plugin's version.
  For the default experience keep the plugin dep and touch nothing.

  See the [`mob_mishka` extraction epic (MOB-246)][epic] for the full arc.

  [epic]: https://linear.app/mobframework/issue/MOB-246
  """

  @doc """
  Registers every composite this plugin ships with `Mob.Composite`.

  Called from the plugin's manifest `:lifecycle.on_start` at boot; you should
  not need to call it yourself. Idempotent — a second registration for the
  same tag is a no-op.

  Currently a stub: no composites are ported yet (MOB-249 will fill this in
  as the port arc lands). Ships as `:ok` so a host adopting the plugin early
  can still boot cleanly.
  """
  @spec register_all() :: :ok
  def register_all do
    Enum.each(composites(), fn {tag, module} ->
      Mob.Composite.register(tag, {module, :expand})
    end)
  end

  @doc """
  Enumerates every `{tag_atom, module}` this plugin registers.

  Grows in MOB-249 as composites port from
  `mishka_chelekom/development/mob/lib/mishka_mob/components/`. Kept as a
  data list so tests and the eventual `mix mob_mishka.gen` task can
  introspect the set without invoking `register_all/0`.

  Registration order is stable (alphabetical by tag atom) so a rebuild
  after adding one composite doesn't reshuffle the registry.
  """
  @spec composites() :: [{atom(), module()}]
  def composites do
    [
      {:mishka_visually_hidden, MobMishka.Components.MishkaVisuallyHidden}
    ]
  end
end
