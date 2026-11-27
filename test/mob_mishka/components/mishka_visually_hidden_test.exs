defmodule MobMishka.Components.MishkaVisuallyHiddenTest do
  use ExUnit.Case, async: true

  alias MobMishka.Components.MishkaVisuallyHidden

  doctest MishkaVisuallyHidden

  describe "visually_hidden/2" do
    test "returns no node at all, regardless of props or children" do
      # Any props / children are dropped. The children carry the caller's
      # intent (which becomes correct for free the day Mob grows an
      # accessibility label prop), so accepting them without erroring is
      # deliberate. It is `[]`, not a `size: 0` Spacer: iOS and mob_new's
      # current Android bridge read a Spacer of size <= 0 as flexible, so the
      # old "nothing" took a share of its parent Row or Column.
      assert MishkaVisuallyHidden.visually_hidden(%{label: "skip"}, [%{type: :text}]) == []
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
