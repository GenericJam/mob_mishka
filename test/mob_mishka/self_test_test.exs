defmodule MobMishka.SelfTestTest do
  # async: false — run/1 reads the global Mob.Composite table and the app env
  # that MobMishka.RegisterAllOverrideTest mutates.
  use ExUnit.Case, async: false
  # The crashing-expander case logs Mob.Composite's error on purpose.
  @moduletag :capture_log

  alias Mob.Plugin.SelfTest, as: Contract
  alias MobDev.Plugin.{Manifest, Validator}
  alias MobMishka.SelfTest

  @plugin_dir Path.expand("../..", __DIR__)

  setup do
    Application.delete_env(:mob_mishka, :override_namespace)
    Mob.Composite.reset()
    MobMishka.register_all()
    :ok
  end

  test "the manifest declares the self-test, and the validator accepts it" do
    {:ok, m} = Manifest.load(@plugin_dir)
    assert m.selftest == MobMishka.SelfTest
    assert %{errors: [], warnings: warnings} = Validator.validate_plugin(m, @plugin_dir)
    refute Enum.any?(warnings, &(&1 =~ "selftest"))
  end

  test "passes once register_all/0 ran: the tree expands into toggle, text and progress" do
    result = SelfTest.run(%{platform: :android, device: :emulator})
    assert result == :pass
    assert Contract.result?(result)
  end

  test "fails when the lifecycle hook never registered the composites" do
    Mob.Composite.reset()
    result = SelfTest.run(%{platform: :ios, device: :simulator})
    assert {:fail, reason} = result
    assert reason =~ "#{length(MobMishka.composites())} of #{length(MobMishka.composites())}"
    assert reason =~ "register_all/0 did not run"
    assert Contract.result?(result)
  end

  test "one composite missing is named" do
    expanders = Map.delete(Mob.Composite.expanders(), :mishka_switch)
    result = SelfTest.check_registered(expanders)
    assert {:fail, "1 of " <> rest} = result
    assert rest =~ ":mishka_switch"
  end

  test "an ejected override registered under the configured namespace counts as registered" do
    Application.put_env(:mob_mishka, :override_namespace, MyApp.Components)

    expanders =
      Map.put(Mob.Composite.expanders(), :mishka_switch, {MyApp.Components.MishkaSwitch, :expand})

    assert SelfTest.check_registered(expanders) == :ok

    expanders = Map.put(expanders, :mishka_switch, {Elsewhere.MishkaSwitch, :expand})
    assert {:fail, _} = SelfTest.check_registered(expanders)
  end

  # A replaced expander also fails the registration check, so these drive the
  # expansion half directly, through the same Mob.Composite.expand/2 pass.
  defp expand_and_check,
    do: SelfTest.check_tree(Mob.Composite.expand(SelfTest.tree(), self()), self())

  test "a crashing expander (rendered as an empty column) fails the tree check" do
    Mob.Composite.register(:mishka_switch, {__MODULE__.Broken, :expand})
    result = expand_and_check()
    assert {:fail, "MishkaSwitch did not expand to a :toggle" <> _} = result
    assert Contract.result?(result)
  end

  test "an expander that drops the label or mis-scales the progress fails" do
    Mob.Composite.register(:mishka_switch, {__MODULE__.Unlabelled, :expand})
    assert {:fail, "MishkaSwitch did not render its label" <> _} = expand_and_check()

    MobMishka.register_all()
    Mob.Composite.register(:mishka_progress, {__MODULE__.Unscaled, :expand})
    assert {:fail, "MishkaProgress value 40" <> _} = expand_and_check()
  end

  test "an unexpanded mishka node fails" do
    tree = %{type: :column, props: %{}, children: [%{type: :mishka_tabs, props: %{}}]}
    assert {:fail, reason} = SelfTest.check_tree(tree, self())
    assert reason =~ "[:mishka_tabs] unexpanded"
  end

  test "a host's ejected, edited MishkaSwitch does not decide the plugin's result" do
    Application.put_env(:mob_mishka, :override_namespace, __MODULE__.Host)
    Mob.Composite.register(:mishka_switch, {__MODULE__.Host.MishkaSwitch, :expand})

    # Through the global table the host's copy renders no label row...
    assert {:fail, _} = expand_and_check()
    # ...but the self-test expands the plugin's own module and passes.
    assert SelfTest.run(%{platform: :android, device: :emulator}) == :pass
  end

  test "composites registered while the test waits (boot race) still pass" do
    Mob.Composite.reset()
    parent = self()

    spawn(fn ->
      Process.sleep(300)
      MobMishka.register_all()
      send(parent, :registered)
    end)

    assert SelfTest.run(%{platform: :ios, device: :simulator}) == :pass
    assert_received :registered
  end

  defmodule Broken do
    @moduledoc false
    def expand(_props, _children, _ctx), do: raise("boom")
  end

  defmodule Unlabelled do
    @moduledoc false
    def expand(props, _children, _ctx),
      do: %{type: :toggle, props: %{value: true, on_change: props.on_change}, children: []}
  end

  defmodule Unscaled do
    @moduledoc false
    def expand(props, _children, _ctx),
      do: %{type: :progress, props: %{value: props.value}, children: []}
  end

  defmodule Host.MishkaSwitch do
    @moduledoc false
    # A host's edited copy: no label row.
    def expand(props, _children, _ctx),
      do: %{type: :toggle, props: %{value: true, on_change: props.on_change}, children: []}
  end
end
