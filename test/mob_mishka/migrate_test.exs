defmodule MobMishka.MigrateTest do
  # async: false — writes files under tmp dirs and reads real plugin
  # composite source from the running mob_mishka checkout.
  use ExUnit.Case, async: false

  alias MobMishka.Migrate

  setup do
    tmp =
      Path.join(
        System.tmp_dir!(),
        "mob_mishka_migrate_test_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)
    on_exit(fn -> File.rm_rf!(tmp) end)
    {:ok, tmp: tmp}
  end

  describe "plugin_lookup/0" do
    test "maps every ported composite by its filename basename" do
      lookup = Migrate.plugin_lookup()

      # MOB-249 ports 73 composites. Every one must have a lookup entry so
      # `plan/2` can align a vendored copy back to its plugin counterpart.
      assert map_size(lookup) == length(MobMishka.composites())

      # Spot-check the exact key shape a vendored copy on disk would carry.
      assert lookup["mishka_visually_hidden"] ==
               {:mishka_visually_hidden, MobMishka.Components.MishkaVisuallyHidden}

      assert lookup["mishka_dialog"] ==
               {:mishka_dialog, MobMishka.Components.MishkaDialog}
    end
  end

  describe "plan/2 composite classification" do
    test "returns [] for a project with no components/ dir", %{tmp: tmp} do
      assert Migrate.plan(tmp, app: :fake_app) == []
    end

    test "marks a byte-identical vendored copy for removal", %{tmp: tmp} do
      # Copy the plugin's own MishkaVisuallyHidden into a fake app tree with
      # the namespace substitution mob_new would perform on generation.
      plugin_src = File.read!(plugin_composite_path(MobMishka.Components.MishkaVisuallyHidden))
      vendored = namespace_swap(plugin_src, "FakeApp")

      user_path = write_vendored(tmp, :fake_app, "mishka_visually_hidden.ex", vendored)

      plan = Migrate.plan(tmp, app: :fake_app)

      assert plan == [
               {:remove_vendored_composite, user_path,
                {:mishka_visually_hidden, MobMishka.Components.MishkaVisuallyHidden}}
             ]
    end

    test "keeps a user-edited copy alone", %{tmp: tmp} do
      # Same source but with a real change — extra function the plugin does
      # not have. `normalise/1`'s namespace-only substitution must not paper
      # over this.
      plugin_src = File.read!(plugin_composite_path(MobMishka.Components.MishkaVisuallyHidden))

      edited =
        plugin_src
        |> namespace_swap("FakeApp")
        |> String.replace("def announce?, do: false", """
        def announce?, do: false

        # User addition: a helper the plugin doesn't ship.
        def user_helper, do: :extra
        """)

      user_path = write_vendored(tmp, :fake_app, "mishka_visually_hidden.ex", edited)

      plan = Migrate.plan(tmp, app: :fake_app)

      assert plan == [
               {:keep_user_edited_composite, user_path,
                {:mishka_visually_hidden, MobMishka.Components.MishkaVisuallyHidden}}
             ]
    end

    test "flags a mishka_*.ex file that doesn't match any plugin composite", %{tmp: tmp} do
      # A user's hand-written mob composite that happens to be namespaced
      # under mishka_ — plan/2 leaves it alone rather than assume it's ours.
      user_path =
        write_vendored(
          tmp,
          :fake_app,
          "mishka_custom.ex",
          "defmodule FakeApp.Components.MishkaCustom do\ndef expand(_,_,_), do: nil\nend\n"
        )

      plan = Migrate.plan(tmp, app: :fake_app)
      assert plan == [{:unrecognized_composite, user_path}]
    end
  end

  describe "plan/2 config.exs classification" do
    test "detects the extra_tags compat bridge", %{tmp: tmp} do
      config_path = write_config_with_bridge(tmp)
      plan = Migrate.plan(tmp, app: :fake_app)
      assert {:remove_extra_tags_block, ^config_path} = List.last(plan)
    end

    test "leaves a clean config.exs alone", %{tmp: tmp} do
      write_clean_config(tmp)
      # No components/, no bridge — plan is empty.
      assert Migrate.plan(tmp, app: :fake_app) == []
    end
  end

  describe "apply/2 composite deletion" do
    test "deletes files marked for removal", %{tmp: tmp} do
      plugin_src = File.read!(plugin_composite_path(MobMishka.Components.MishkaVisuallyHidden))

      user_path =
        write_vendored(
          tmp,
          :fake_app,
          "mishka_visually_hidden.ex",
          namespace_swap(plugin_src, "FakeApp")
        )

      actions = Migrate.plan(tmp, app: :fake_app)
      Migrate.apply(actions)

      refute File.exists?(user_path)
    end

    test "keeps user-edited files on disk", %{tmp: tmp} do
      plugin_src = File.read!(plugin_composite_path(MobMishka.Components.MishkaVisuallyHidden))

      edited =
        plugin_src
        |> namespace_swap("FakeApp")
        |> Kernel.<>("\ndefmodule Sentinel, do: :marker\n")

      user_path = write_vendored(tmp, :fake_app, "mishka_visually_hidden.ex", edited)

      Migrate.plan(tmp, app: :fake_app) |> Migrate.apply()

      assert File.exists?(user_path)
      assert File.read!(user_path) =~ "Sentinel"
    end
  end

  describe "apply/2 extra_tags stripping" do
    test "leaves the bridge in place by default", %{tmp: tmp} do
      config_path = write_config_with_bridge(tmp)
      Migrate.plan(tmp, app: :fake_app) |> Migrate.apply()

      # The compat bridge stays until the caller explicitly opts in.
      assert File.read!(config_path) =~ "config :mob, :extra_tags"
    end

    test "strips the bridge when remove_extra_tags: true", %{tmp: tmp} do
      config_path = write_config_with_bridge(tmp)

      Migrate.plan(tmp, app: :fake_app)
      |> Migrate.apply(remove_extra_tags: true)

      content = File.read!(config_path)
      refute content =~ "config :mob, :extra_tags"
      # Every OTHER line in config.exs stays.
      assert content =~ "config :mob, :repo"
    end

    test "strip is idempotent on a clean config", %{tmp: tmp} do
      write_clean_config(tmp)

      Migrate.plan(tmp, app: :fake_app)
      |> Migrate.apply(remove_extra_tags: true)

      # Second run on a clean config is a no-op.
      assert Migrate.plan(tmp, app: :fake_app) == []
    end
  end

  # ── helpers ─────────────────────────────────────────────────────────

  defp plugin_composite_path(module) do
    MobMishka.Gen.source_path(module)
  end

  defp namespace_swap(source, app_namespace) do
    String.replace(
      source,
      ~r/(defmodule|alias) MobMishka\.Components\.(Mishka[A-Za-z0-9_]+)/,
      "\\1 #{app_namespace}.Components.\\2"
    )
  end

  defp write_vendored(tmp, app, filename, content) do
    dir = Path.join([tmp, "lib", Atom.to_string(app), "components"])
    File.mkdir_p!(dir)
    path = Path.join(dir, filename)
    File.write!(path, content)
    path
  end

  # Mirrors the exact block mob_new emits when generating an app.
  # Include the sentinel comment that classify_extra_tags_block/1
  # scans for.
  defp write_config_with_bridge(tmp) do
    config_dir = Path.join(tmp, "config")
    File.mkdir_p!(config_dir)
    path = Path.join(config_dir, "config.exs")

    File.write!(path, """
    import Config

    config :fake_app, ecto_repos: [FakeApp.Repo]
    config :mob, :repo, FakeApp.Repo

    # `mob_mishka` supplies the `<Mishka…>` composite tags. The ~MOB sigil in
    # mob-that-ships-MOB-247 reads the plugin's manifest and whitelists them
    # automatically; on older mob it does not, so the block below is kept as a
    # compatibility bridge.
    config :mob, :extra_tags, ~w(
      MishkaAccordion
      MishkaChip
      MishkaVisuallyHidden
    )
    """)

    path
  end

  defp write_clean_config(tmp) do
    config_dir = Path.join(tmp, "config")
    File.mkdir_p!(config_dir)
    path = Path.join(config_dir, "config.exs")

    File.write!(path, """
    import Config

    config :fake_app, ecto_repos: [FakeApp.Repo]
    config :mob, :repo, FakeApp.Repo
    """)

    path
  end
end
