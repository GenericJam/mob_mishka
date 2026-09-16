defmodule MobMishka.Gen do
  @moduledoc """
  Pure implementation behind `mix mob_mishka.gen`.

  Everything the mix task does — resolve the composite name, locate the
  plugin source, compute the destination path, rewrite the module line — is
  parameterised here so tests can drive it against a fake app root without
  standing up a full Mix project.
  """

  @type opts :: [app: atom(), root: Path.t(), force: boolean()]

  @doc """
  Normalise a user-supplied composite name to the plugin's tag atom.

  Both `dialog` and `mishka_dialog` map to `:mishka_dialog` — supplying the
  prefix is optional at the CLI so users don't have to remember it.
  """
  @spec normalize_name(String.t()) :: atom()
  def normalize_name(name) when is_binary(name) do
    canonical = if String.starts_with?(name, "mishka_"), do: name, else: "mishka_" <> name
    String.to_atom(canonical)
  end

  @doc """
  Convert a Mix app atom (`:my_app`) into its conventional Elixir module
  namespace (`MyApp`). `Module.concat/1` on a single-element list produces
  the proper `:"Elixir.MyApp"` form; naive `String.to_atom("MyApp")` would
  give `:MyApp`, which is a different atom.
  """
  @spec app_namespace(atom()) :: module()
  def app_namespace(app) when is_atom(app) do
    Module.concat([Macro.camelize(Atom.to_string(app))])
  end

  @doc """
  Compute the destination path for an ejected composite, under
  `<root>/lib/<app>/components/<short>.ex`.
  """
  @spec destination_path(module(), opts()) :: Path.t()
  def destination_path(plugin_module, opts) do
    app = Keyword.fetch!(opts, :app)
    root = Keyword.get(opts, :root, ".")
    filename = short_snake(plugin_module) <> ".ex"
    Path.join([root, "lib", Atom.to_string(app), "components", filename])
  end

  @doc """
  The module atom the ejected copy declares:
  `<AppNs>.Components.<Short>`.
  """
  @spec override_module(module(), atom()) :: module()
  def override_module(plugin_module, app) when is_atom(app) do
    short = plugin_module |> Module.split() |> List.last() |> String.to_atom()
    Module.concat([app_namespace(app), Components, short])
  end

  @doc """
  Rewrite the plugin's source so its top-level `defmodule` names the app's
  namespace instead of the plugin's. Only the top-line module is rewritten;
  aliases to unejected siblings still point at the plugin, which is correct
  (an unejected sibling still lives there).
  """
  @spec rewrite_module(String.t(), module(), module()) :: String.t()
  def rewrite_module(source, plugin_module, target_module) do
    src = strip_elixir_prefix(plugin_module)
    dst = strip_elixir_prefix(target_module)
    String.replace(source, "defmodule #{src} do", "defmodule #{dst} do", global: false)
  end

  # Anchored at THIS file's directory at compile time — `Application.app_dir/2`
  # would resolve to `_build/dev/lib/mob_mishka/` in dev/test, which does not
  # contain the composite `lib/` source. `__DIR__` is `<root>/lib/mob_mishka`
  # both in mob_mishka's own repo and as a Hex dep under
  # `<consumer>/deps/mob_mishka/lib/mob_mishka`, so this works in both.
  @source_dir Path.expand(Path.join(__DIR__, "components"))

  @doc """
  Path to a plugin composite's source, absolute for use with `File.read!/1`.
  """
  @spec source_path(module()) :: Path.t()
  def source_path(plugin_module) do
    filename = short_snake(plugin_module) <> ".ex"
    Path.join(@source_dir, filename)
  end

  @doc """
  Look up the `{tag, module}` entry a user-supplied name maps to. Returns
  `nil` if no composite by that name is registered.
  """
  @spec lookup(String.t()) :: {atom(), module()} | nil
  def lookup(name) when is_binary(name) do
    tag = normalize_name(name)
    Enum.find(MobMishka.composites(), fn {t, _} -> t == tag end)
  end

  # ── private helpers ──────────────────────────────────────────────────────

  defp short_snake(module) do
    module |> Module.split() |> List.last() |> Macro.underscore()
  end

  defp strip_elixir_prefix(module) do
    module |> Atom.to_string() |> String.trim_leading("Elixir.")
  end
end
