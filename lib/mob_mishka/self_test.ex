defmodule MobMishka.SelfTest do
  @moduledoc """
  The plugin's on-device proof (`Mob.Plugin.SelfTest`), run by
  `mix mob.selftest` and mob_ci for every activated plugin.

  mob_mishka is pure Elixir: its whole job is that `<Mishka…>` tags in a
  screen's tree expand into native widgets. The test checks both halves on
  the device:

    1. **Registration.** Every `{tag, module}` in `MobMishka.composites/0`
       must be in `Mob.Composite.expanders/0` as `{module, :expand}` (or the
       host's ejected override of it, see `MobMishka.register_all/0`). The
       plugin's `lifecycle.on_start` does that at boot; a missing tag means
       the host never ran it and every `<Mishka…>` renders as nothing.
    2. **Expansion.** A column holding `<MishkaSwitch label="mob_mishka
       self-test" checked on_change={:mob_mishka_selftest} />` and
       `<MishkaProgress value={40} />` goes through `Mob.Composite.expand/2`,
       the renderer's pass, with the test process as the screen. The result
       must contain no `:mishka_*` node, a `:toggle` with `value: true` whose
       `on_change` is `{self(), :mob_mishka_selftest}` (the event-target
       widening a tag goes through), the label as a `:text`, and a
       `:progress` with `value: 0.4`. A crashing expander shows up here: the
       renderer replaces it with an empty column.
  """
  @behaviour Mob.Plugin.SelfTest

  @tag :mob_mishka_selftest
  @label "mob_mishka self-test"

  @impl true
  def run(_ctx) do
    with :ok <- check_registered(Mob.Composite.expanders()) do
      check_tree(Mob.Composite.expand(tree(), self()), self())
    end
  end

  @doc false
  # The composite tree the test expands: what `~MOB` produces for the two tags.
  @spec tree() :: map()
  def tree do
    %{
      type: :column,
      props: %{},
      children: [
        %{
          type: :mishka_switch,
          props: %{label: @label, checked: true, on_change: @tag},
          children: []
        },
        %{type: :mishka_progress, props: %{value: 40}, children: []}
      ]
    }
  end

  @doc false
  @spec check_registered(%{atom() => {module(), atom()}}) :: :ok | Mob.Plugin.SelfTest.result()
  def check_registered(expanders) do
    namespace = Application.get_env(:mob_mishka, :override_namespace)

    missing =
      for {tag, module} <- MobMishka.composites(),
          not registered?(Map.get(expanders, tag), module, namespace),
          do: tag

    case missing do
      [] ->
        :ok

      [_ | _] ->
        {shown, rest} = Enum.split(missing, 3)
        more = if rest == [], do: "", else: ", ..."

        {:fail,
         "#{length(missing)} of #{length(MobMishka.composites())} composites are not registered " <>
           "with Mob.Composite (#{Enum.map_join(shown, ", ", &inspect/1)}#{more}): the plugin's " <>
           "lifecycle.on_start MobMishka.register_all/0 did not run"}
    end
  end

  defp registered?({module, :expand}, module, _namespace), do: true

  defp registered?({override, :expand}, module, namespace) when not is_nil(namespace),
    do: override == Module.concat(namespace, module |> Module.split() |> List.last())

  defp registered?(_entry, _module, _namespace), do: false

  @doc false
  @spec check_tree(term(), pid()) :: Mob.Plugin.SelfTest.result()
  def check_tree(expanded, screen) do
    nodes = flatten(expanded)
    types = Enum.map(nodes, & &1.type)
    leftover = Enum.filter(types, &mishka?/1)

    cond do
      leftover != [] ->
        {:fail, "Mob.Composite.expand/2 left #{inspect(Enum.uniq(leftover))} unexpanded"}

      not Enum.any?(nodes, &toggle?(&1, screen)) ->
        {:fail,
         "MishkaSwitch did not expand to a :toggle with value: true and on_change: " <>
           "{screen, #{inspect(@tag)}} (got #{inspect(types)})"}

      not Enum.any?(nodes, &(&1.type == :text and &1.props[:text] == @label)) ->
        {:fail, "MishkaSwitch did not render its label as a :text (got #{inspect(types)})"}

      not Enum.any?(nodes, &(&1.type == :progress and &1.props[:value] == 0.4)) ->
        {:fail, "MishkaProgress value 40 did not expand to a :progress with value: 0.4"}

      true ->
        :pass
    end
  end

  defp toggle?(%{type: :toggle, props: props}, screen),
    do: props[:value] == true and props[:on_change] == {screen, @tag}

  defp toggle?(_node, _screen), do: false

  defp mishka?(type) when is_atom(type), do: String.starts_with?(Atom.to_string(type), "mishka_")
  defp mishka?(_type), do: false

  defp flatten(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &flatten/1)

  defp flatten(%{type: _} = node) do
    node = Map.put_new(node, :props, %{})
    [node | node |> Map.get(:children, []) |> flatten()]
  end

  defp flatten(_other), do: []
end
