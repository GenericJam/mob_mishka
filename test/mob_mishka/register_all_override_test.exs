defmodule MobMishka.RegisterAllOverrideTest do
  # async: false — mutates the app env and the global Mob.Composite table.
  use ExUnit.Case, async: false

  setup do
    original = Application.get_env(:mob_mishka, :override_namespace)

    on_exit(fn ->
      if original do
        Application.put_env(:mob_mishka, :override_namespace, original)
      else
        Application.delete_env(:mob_mishka, :override_namespace)
      end
    end)
  end

  describe "MobMishka.register_all/0 override precedence" do
    test "with no override_namespace configured, plugin defaults win" do
      Application.delete_env(:mob_mishka, :override_namespace)
      Mob.Composite.reset()

      MobMishka.register_all()

      # Spot-check one composite: the plugin's own module handles :mishka_visually_hidden.
      assert Map.get(Mob.Composite.expanders(), :mishka_visually_hidden) ==
               {MobMishka.Components.MishkaVisuallyHidden, :expand}
    end

    test "with override_namespace set but no override module loaded, plugin defaults win" do
      Application.put_env(:mob_mishka, :override_namespace, MobMishkaTest.NoSuchNamespace)
      Mob.Composite.reset()

      MobMishka.register_all()

      # Namespace configured but MobMishkaTest.NoSuchNamespace.MishkaVisuallyHidden doesn't
      # exist — fall back to plugin. Guards against a config edit that names an
      # unpopulated namespace silently dropping every composite.
      assert Map.get(Mob.Composite.expanders(), :mishka_visually_hidden) ==
               {MobMishka.Components.MishkaVisuallyHidden, :expand}
    end

    test "with an override module present under the namespace, override wins" do
      Application.put_env(
        :mob_mishka,
        :override_namespace,
        MobMishka.RegisterAllOverrideTest.Overrides
      )

      Mob.Composite.reset()

      MobMishka.register_all()

      # The override module below is defined in this file (same compile unit),
      # so Code.ensure_loaded?/1 in pick_module/2 returns true and this test's
      # module supersedes the plugin's for its tag.
      assert Map.get(Mob.Composite.expanders(), :mishka_visually_hidden) ==
               {MobMishka.RegisterAllOverrideTest.Overrides.MishkaVisuallyHidden, :expand}
    end
  end

  # An override module that mirrors the plugin's shape. Presence here proves
  # the override lookup lands on a real module, not a phantom atom.
  defmodule Overrides.MishkaVisuallyHidden do
    @spec expand(map(), [map()], map()) :: map()
    def expand(_props, _children, _ctx),
      do: %{type: :spacer, props: %{size: 0}, children: []}
  end
end
