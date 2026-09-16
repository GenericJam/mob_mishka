defmodule MobMishka.GenTest do
  use ExUnit.Case, async: true

  alias MobMishka.Gen

  doctest MobMishka.Gen

  describe "normalize_name/1" do
    test "supplies the mishka_ prefix when omitted" do
      assert Gen.normalize_name("dialog") == :mishka_dialog
    end

    test "leaves the mishka_ prefix alone when present" do
      assert Gen.normalize_name("mishka_dialog") == :mishka_dialog
    end
  end

  describe "app_namespace/1" do
    test "converts a snake_case app atom to its PascalCase module namespace" do
      # `Module.concat/1` is what gives the proper `Elixir.MyApp` form —
      # `String.to_atom("MyApp")` would produce a different atom.
      assert Gen.app_namespace(:my_app) == MyApp
      assert Gen.app_namespace(:sloppy_joe) == SloppyJoe
    end
  end

  describe "override_module/2" do
    test "constructs the app's Components module under the plugin's short name" do
      assert Gen.override_module(MobMishka.Components.MishkaDialog, :my_app) ==
               MyApp.Components.MishkaDialog

      assert Gen.override_module(MobMishka.Components.MishkaCloseButton, :sloppy_joe) ==
               SloppyJoe.Components.MishkaCloseButton
    end
  end

  describe "destination_path/2" do
    test "writes to lib/<app>/components/<snake>.ex relative to the given root" do
      path =
        Gen.destination_path(
          MobMishka.Components.MishkaCloseButton,
          app: :my_app,
          root: "/tmp/fake_project"
        )

      assert path == "/tmp/fake_project/lib/my_app/components/mishka_close_button.ex"
    end

    test "defaults to a cwd-relative root when :root is omitted" do
      # `.` is Path.join/1's default root — normalize both sides so the
      # assertion doesn't hinge on whether the prefix is written explicitly.
      path = Gen.destination_path(MobMishka.Components.MishkaDialog, app: :my_app)
      assert Path.expand(path) == Path.expand("lib/my_app/components/mishka_dialog.ex")
    end
  end

  describe "rewrite_module/3" do
    test "rewrites only the top-level defmodule; sibling aliases stay pointed at the plugin" do
      # Sibling aliases refer to composites the user did NOT eject; those still
      # live in the plugin. Rewriting them would break references to modules
      # that don't exist under the app's namespace.
      source = """
      defmodule MobMishka.Components.MishkaCloseButton do
        alias MobMishka.Components.MishkaActionIcon

        def expand(props, children, _ctx), do: MishkaActionIcon.action_icon(props, children)
      end
      """

      out =
        Gen.rewrite_module(
          source,
          MobMishka.Components.MishkaCloseButton,
          MyApp.Components.MishkaCloseButton
        )

      assert out =~ "defmodule MyApp.Components.MishkaCloseButton do"
      refute out =~ "defmodule MobMishka.Components.MishkaCloseButton do"
      # Sibling alias untouched.
      assert out =~ "alias MobMishka.Components.MishkaActionIcon"
    end
  end

  describe "lookup/1" do
    test "resolves a normalized name to a real composite entry" do
      # Uses the actual composites/0 list — proves the lookup wires against
      # what MobMishka registers, not a stub.
      assert Gen.lookup("visually_hidden") ==
               {:mishka_visually_hidden, MobMishka.Components.MishkaVisuallyHidden}

      assert Gen.lookup("mishka_visually_hidden") ==
               {:mishka_visually_hidden, MobMishka.Components.MishkaVisuallyHidden}
    end

    test "returns nil for an unknown name" do
      assert Gen.lookup("does_not_exist") == nil
    end
  end

  describe "source_path/1" do
    test "points at a real file that exists on disk for a ported composite" do
      # If this fails, the plugin was fetched from Hex without its lib/, or the
      # module's short name doesn't match its filename. Either is a real bug.
      path = Gen.source_path(MobMishka.Components.MishkaVisuallyHidden)
      assert File.exists?(path)
      assert path =~ "mishka_visually_hidden.ex"
    end
  end

  describe "end-to-end eject through the pure helpers" do
    setup do
      tmp =
        Path.join(System.tmp_dir!(), "mob_mishka_gen_test_#{System.unique_integer([:positive])}")

      File.mkdir_p!(tmp)
      on_exit(fn -> File.rm_rf(tmp) end)
      {:ok, tmp: tmp}
    end

    test "eject writes the rewritten source to the app-relative path", %{tmp: tmp} do
      plugin_module = MobMishka.Components.MishkaVisuallyHidden

      source = File.read!(Gen.source_path(plugin_module))
      target_module = Gen.override_module(plugin_module, :my_app)
      dest_path = Gen.destination_path(plugin_module, app: :my_app, root: tmp)
      rewritten = Gen.rewrite_module(source, plugin_module, target_module)

      File.mkdir_p!(Path.dirname(dest_path))
      File.write!(dest_path, rewritten)

      assert File.exists?(dest_path)
      contents = File.read!(dest_path)
      assert contents =~ "defmodule MyApp.Components.MishkaVisuallyHidden do"
      refute contents =~ "defmodule MobMishka.Components.MishkaVisuallyHidden do"
    end
  end
end
