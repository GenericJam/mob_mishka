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
       the host never ran it and every `<Mishka…>` renders as nothing. The
       runner can call the test right after a relaunch, once the plugin's OTP
       application is up but possibly before the lifecycle `on_start`s have
       returned, so the test first waits for `Mob.Plugins.Supervisor` to
       finish `init/1` (which runs them) and re-checks for up to 5 s before
       failing.
    2. **Expansion.** A column holding `<MishkaSwitch label="mob_mishka
       self-test" checked on_change={:mob_mishka_selftest} />` and
       `<MishkaProgress value={40} />` goes through `Mob.Composite.expand/2`,
       the renderer's pass, with the test process as the screen. The result
       must contain no `:mishka_*` node, a `:toggle` with `value: true` whose
       `on_change` is `{self(), :mob_mishka_selftest}` (the event-target
       widening a tag goes through), the label as a `:text`, and a
       `:progress` with `value: 0.4`. A crashing expander shows up here: the
       renderer replaces it with an empty column. When the host registered
       its own ejected copy for either tag, the test expands those nodes with
       the plugin's module instead (same event-target widening and context),
       so a host's edited copy cannot fail the plugin's test.
  """
  @behaviour Mob.Plugin.SelfTest

  alias MobMishka.Components.{MishkaProgress, MishkaSwitch}

  @tag :mob_mishka_selftest
  @label "mob_mishka self-test"
  @boot_wait 5_000
  @own %{mishka_switch: MishkaSwitch, mishka_progress: MishkaProgress}

  @impl true
  def run(_ctx) do
    with :ok <- await_registered(System.monotonic_time(:millisecond) + @boot_wait) do
      check_tree(expand(tree(), Mob.Composite.expanders(), self()), self())
    end
  end

  defp await_registered(deadline) do
    case check_registered(Mob.Composite.expanders()) do
      :ok ->
        :ok

      failure ->
        if System.monotonic_time(:millisecond) < deadline do
          lifecycle_barrier()
          Process.sleep(100)
          await_registered(deadline)
        else
          failure
        end
    end
  end

  # A call to the lifecycle supervisor is answered only after its init/1, i.e.
  # after every plugin's on_start, has returned.
  defp lifecycle_barrier do
    if Process.whereis(Mob.Plugins.Supervisor) do
      _ = Supervisor.count_children(Mob.Plugins.Supervisor)
    end

    :ok
  catch
    :exit, _ -> :ok
  end

  @doc false
  # Mob.Composite.expand/2 when both tags map to the plugin's own modules;
  # with a host override registered, the two nodes are expanded by the
  # plugin's modules the way Mob.Composite would (widened event targets,
  # %{screen: pid}), then the result goes through Mob.Composite.expand/2.
  @spec expand(map(), %{atom() => {module(), atom()}}, pid()) :: term()
  def expand(%{children: children} = tree, expanders, pid) do
    if Enum.all?(@own, fn {tag, module} -> expanders[tag] == {module, :expand} end) do
      Mob.Composite.expand(tree, pid)
    else
      own = Enum.map(children, &expand_own(&1, pid))
      Mob.Composite.expand(%{tree | children: own}, pid)
    end
  end

  defp expand_own(%{type: type, props: props, children: children}, pid) do
    module = Map.fetch!(@own, type)
    module.expand(Mob.Composite.inject_event_targets(props, pid), children, %{screen: pid})
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
