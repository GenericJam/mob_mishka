defmodule MobMishka.Components.MishkaVisuallyHiddenTest do
  use ExUnit.Case, async: true

  alias MobMishka.Components.MishkaVisuallyHidden

  doctest MishkaVisuallyHidden

  describe "visually_hidden/2" do
    test "returns a Spacer node with size 0 regardless of props or children" do
      # Documenting the honest behaviour: any props / children are dropped and
      # the render is an empty Spacer. The children carry the caller's intent
      # (which becomes correct for free the day Mob grows an accessibility
      # label prop), so accepting them without erroring is deliberate.
      node = MishkaVisuallyHidden.visually_hidden(%{label: "skip"}, [%{type: :text}])
      assert node == %{type: :spacer, props: %{size: 0}, children: []}
    end

    test "expand/3 delegates to visually_hidden/2" do
      # The composite entry point mob calls at render time; keeping expand/3
      # a thin wrapper means the function form and the tag form of the API
      # can never drift.
      assert MishkaVisuallyHidden.expand(%{}, [], %{}) ==
               MishkaVisuallyHidden.visually_hidden(%{}, [])
    end
  end
end
