defmodule Mix.Tasks.MobMishka.Gen do
  @moduledoc """
  Eject a plugin-shipped Mishka composite into your app's `lib/` so you can
  edit its source.

      mix mob_mishka.gen dialog
      mix mob_mishka.gen mishka_dialog
      mix mob_mishka.gen --all

  Both `dialog` and `mishka_dialog` are accepted — the `mishka_` prefix is
  supplied automatically. Copies the composite into
  `lib/<app>/components/<name>.ex` under `<AppNamespace>.Components.<Name>`.

  After ejecting one or more composites, activate them by adding this line to
  `config/config.exs`:

      config :mob_mishka, :override_namespace, <YourApp>.Components

  With that in place, `MobMishka.register_all/0` (called from the plugin
  manifest's `on_start`) registers your ejected module for the tag instead of
  the plugin's default. Editing your copy takes effect on the next compile;
  no re-registration needed.

  ## Undoing

  Just delete the file. `Code.ensure_loaded?/1` on the (now-missing) module
  falls back to the plugin's default on the next boot.

  ## Options

    * `--all` — eject every composite the plugin ships. Recreates roughly
      what `mob_new`'s vendoring produces today, for users who want that
      shape.
    * `--force` — overwrite an existing target file. Without this, `gen`
      refuses to clobber an ejected file that has drifted from the plugin.
  """
  @shortdoc "Eject a Mishka composite into your lib/ for editing"

  use Mix.Task

  alias MobMishka.Gen

  @impl Mix.Task
  def run(argv) do
    {opts, positional} =
      OptionParser.parse!(argv, switches: [all: :boolean, force: :boolean])

    # Validate the argv shape BEFORE the project-guard so a bare
    # `mix mob_mishka.gen` reports the expected "Usage:" hint regardless of
    # where it was invoked. Otherwise a user typing it in the wrong project
    # gets the project-guard error and no idea what they actually meant.
    if !opts[:all] and length(positional) != 1 do
      Mix.raise("Usage: mix mob_mishka.gen <name> | --all")
    end

    app = Mix.Project.config()[:app]

    if not is_atom(app) or app == :mob_mishka do
      Mix.raise(
        "mob_mishka.gen must be run from inside a Mix project that depends on :mob_mishka. " <>
          "Detected app: #{inspect(app)}"
      )
    end

    task_opts = [app: app, root: ".", force: opts[:force] || false]

    if opts[:all] do
      Enum.each(MobMishka.composites(), fn {_tag, module} -> eject(module, task_opts) end)
    else
      [name] = positional

      case Gen.lookup(name) do
        {_tag, module} -> eject(module, task_opts)
        nil -> Mix.raise("Unknown composite #{inspect(name)} — see `mix mob_mishka.list`.")
      end
    end
  end

  defp eject(plugin_module, opts) do
    src_path = Gen.source_path(plugin_module)

    unless File.exists?(src_path) do
      Mix.raise(
        "Source file for #{inspect(plugin_module)} not found at #{src_path}. " <>
          "This usually means the plugin's dep is fetched from Hex without priv/, " <>
          "or the module was renamed since composites/0 was regenerated."
      )
    end

    dest_path = Gen.destination_path(plugin_module, opts)

    if File.exists?(dest_path) and not opts[:force] do
      Mix.raise(
        "Refusing to overwrite existing #{dest_path}. Pass --force to overwrite " <>
          "any local edits, or delete the file first."
      )
    end

    target_module = Gen.override_module(plugin_module, opts[:app])
    File.mkdir_p!(Path.dirname(dest_path))
    File.write!(dest_path, Gen.rewrite_module(File.read!(src_path), plugin_module, target_module))

    Mix.shell().info("* creating #{dest_path}")
    print_activation_hint(plugin_module, opts[:app])
  end

  defp print_activation_hint(plugin_module, app) do
    ns = Gen.app_namespace(app)

    Mix.shell().info("""

      Activate ejected composites by adding this to config/config.exs (once):

          config :mob_mishka, :override_namespace, #{inspect(ns)}.Components

      Then any composite you eject via `mix mob_mishka.gen <name>` supersedes
      the plugin's default for its tag on the next boot.

      Ejected: #{inspect(plugin_module)}
    """)
  end
end
