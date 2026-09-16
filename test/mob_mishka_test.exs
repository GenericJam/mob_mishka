defmodule MobMishkaTest do
  use ExUnit.Case, async: true

  doctest MobMishka

  describe "MobMishka scaffold" do
    test "composites/0 returns the expected shape and includes ported composites" do
      composites = MobMishka.composites()

      # The count is documentation of what this port ships. Bump when
      # MOB-249's follow-up commits add or remove a composite (or when a
      # sibling ticket adds one). The invariant test below guards the more
      # important property — that :tags stays in lockstep.
      assert length(composites) == 73

      # Spot-check a few representative composites — the port is bulk-derived,
      # so this catches a wholesale regression (empty list, wrong namespace,
      # missing atomization) more usefully than exhaustive enumeration.
      assert {:mishka_visually_hidden, MobMishka.Components.MishkaVisuallyHidden} in composites
      assert {:mishka_tabs, MobMishka.Components.MishkaTabs} in composites
      assert {:mishka_action_icon, MobMishka.Components.MishkaActionIcon} in composites
    end

    test "every listed composite exists and implements expand/3" do
      # Guard against a stale entry: composites/0 naming a module that has
      # been renamed or deleted would boot cleanly but `Mob.Composite`
      # would fail at first render.
      for {_tag, module} <- MobMishka.composites() do
        assert Code.ensure_loaded?(module), "missing composite module: #{inspect(module)}"

        assert function_exported?(module, :expand, 3),
               "#{inspect(module)} does not implement expand/3"
      end
    end

    test "register_all/0 returns :ok" do
      # Registration must be safe to call at boot regardless of composite
      # count. Also implicitly verifies `Mob.Composite.register/2` accepts
      # every `{tag, {module, :expand}}` shape composites/0 hands it.
      assert MobMishka.register_all() == :ok
    end
  end

  describe "priv/mob_plugin.exs manifest" do
    setup do
      path = Application.app_dir(:mob_mishka, "priv/mob_plugin.exs")
      {manifest, _} = Code.eval_file(path)
      {:ok, manifest: manifest}
    end

    test "declares the plugin name matching mix.exs", %{manifest: m} do
      assert m.name == :mob_mishka
    end

    test ":tags mirrors composites/0 (every registered composite is whitelisted)", %{manifest: m} do
      # The two lists must stay in lockstep — a composite registered without
      # a `:tags` entry warns as pass-through; a `:tags` entry without a
      # composite whitelists a tag that nothing renders. Compare as sets so
      # ordering / whitespace inside the ~w() doesn't matter.
      manifest_tags = MapSet.new(m.tags, &Macro.underscore/1)
      composite_tags = MapSet.new(MobMishka.composites(), fn {tag, _} -> Atom.to_string(tag) end)
      assert manifest_tags == composite_tags
    end

    test "wires register_all/0 into :lifecycle.on_start", %{manifest: m} do
      assert %{lifecycle: %{on_start: {MobMishka, :register_all, []}}} = m
    end
  end
end
