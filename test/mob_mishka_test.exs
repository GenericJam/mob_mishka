defmodule MobMishkaTest do
  use ExUnit.Case, async: true

  doctest MobMishka

  describe "MobMishka scaffold" do
    test "composites/0 is empty at scaffold time" do
      # MOB-249 populates as composites port. Update this assertion in that
      # ticket rather than weakening it — the count is documentation of what
      # this scaffold does and does not ship.
      assert MobMishka.composites() == []
    end

    test "register_all/0 returns :ok with no composites to register" do
      # The registration path must be safe to call at boot even when the
      # composite list is empty — a host adopting the plugin before any
      # composite has ported still needs a clean boot.
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

    test "declares a :tags field (mechanism from MOB-247 in mob)", %{manifest: m} do
      # The value can be empty today; the presence of the key is what proves
      # the manifest is shaped for plugin-manifest tag discovery.
      assert Map.has_key?(m, :tags)
      assert is_list(m.tags) or is_map(m.tags)
    end

    test "wires register_all/0 into :lifecycle.on_start", %{manifest: m} do
      assert %{lifecycle: %{on_start: {MobMishka, :register_all, []}}} = m
    end
  end
end
