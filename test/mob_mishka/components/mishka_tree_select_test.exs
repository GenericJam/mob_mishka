defmodule MobMishka.Components.MishkaTreeSelectTest do
  # async: false — Mob.ScreenCase starts the globally-named `Mob.State`, and the
  # showcase registry it drives is a persistent_term.
  use Mob.ScreenCase, async: false

  alias MobMishka.Components.{MishkaTree, MishkaTreeSelect}

  doctest MobMishka.Components.MishkaTreeSelect

  @nodes [
    %{label: "lib", value: "lib", children: [%{label: "app.ex", value: "lib/app.ex"}]},
    %{label: "mix.exs", value: "mix.exs"}
  ]

  # Mob turns an :id into a native testTag, so this is the set of handles a
  # device test has on a rendered tree.
  defp tags(tree), do: tree |> flatten() |> Enum.map(& &1.props[:id]) |> Enum.reject(&is_nil/1)

  defp value_node(tree, id), do: find(tree, :text, id: id)

  describe "display/2" do
    test "an empty string is not a selection — it is what a cleared field hands back" do
      assert MishkaTreeSelect.display("", "Pick one") == "Pick one"
      assert MishkaTreeSelect.display(nil, "Pick one") == "Pick one"
      assert MishkaTreeSelect.display("mix.exs", "Pick one") == "mix.exs"
    end

    test "anything that is not a string falls back, rather than rendering inspect output" do
      assert MishkaTreeSelect.display(:mix_exs, "Pick one") == "Pick one"
    end

    test "the default placeholder is the web's" do
      assert MishkaTreeSelect.display(nil) == "Select…"
    end
  end

  describe "the trigger" do
    test "shows the placeholder until something is chosen" do
      assert text(MishkaTreeSelect.tree_select()) =~ "Select…"
      assert text(MishkaTreeSelect.tree_select(placeholder: "Pick one")) =~ "Pick one"
      assert text(MishkaTreeSelect.tree_select(label: "mix.exs")) =~ "mix.exs"
      assert text(MishkaTreeSelect.tree_select(label: "", placeholder: "Pick one")) =~ "Pick one"
    end

    test "a placeholder is muted; a real selection is not" do
      assert find(MishkaTreeSelect.tree_select(), :text).props.text_color == :muted

      assert find(MishkaTreeSelect.tree_select(label: "mix.exs"), :text).props.text_color ==
               :on_surface
    end

    test "the value is one ellipsised line inside a weighted box, and the caret is not" do
      # Both halves are load-bearing. Compose measures a Row's UNWEIGHTED
      # children first, so an unwrapped label ate the row and left the caret
      # nothing; and a Text squeezed narrower than its content wraps CHARACTER
      # BY CHARACTER, so a path arrived as a column of single letters.
      tree = MishkaTreeSelect.tree_select(label: String.duplicate("lib/", 20), id: "ts")
      row = find(tree, :row)
      [value_box, _spacer, caret] = row.children

      assert value_box.props[:weight] == 1
      assert find(value_box, :text).props.max_lines == 1
      refute Map.has_key?(caret.props, :weight)
    end

    test "the caret follows the panel, so open is visible without reading a colour" do
      assert text(MishkaTreeSelect.tree_select()) =~ "▾"
      assert text(MishkaTreeSelect.tree_select(open: true)) =~ "▴"
    end

    test "reports taps" do
      tree = MishkaTreeSelect.tree_select(on_toggle: :toggle)

      assert find(tree, :box).props.on_tap == {self(), :toggle}
    end

    test "an already-wired handler is left alone, which is how a composite arrives" do
      tree = MishkaTreeSelect.tree_select(on_toggle: {self(), :toggle})

      assert find(tree, :box).props.on_tap == {self(), :toggle}
    end

    test "disabled mutes it and drops the handler, though one was given" do
      tree = MishkaTreeSelect.tree_select(disabled: true, on_toggle: :toggle, label: "x")

      refute Map.has_key?(find(tree, :box).props, :on_tap)
      assert find(tree, :text).props.text_color == :muted
    end

    test "a disabled caret is muted too — it is a control, not decoration" do
      tree = MishkaTreeSelect.tree_select(disabled: true, id: "ts")

      assert find(tree, :text, id: "ts-caret").props.text_color == :muted

      assert find(MishkaTreeSelect.tree_select(id: "ts"), :text, id: "ts-caret").props.text_color ==
               :on_surface
    end
  end

  describe "test tags" do
    test "every part of the anatomy is addressable" do
      tree = MishkaTreeSelect.tree_select(%{id: "ts", label: "mix.exs", open: true}, [])

      assert tags(tree) == ["ts", "ts-trigger-open", "ts-value", "ts-caret", "ts-panel"]
    end

    test "the trigger carries open/closed, because a glyph and a colour are all it shows" do
      assert MishkaTreeSelect.tree_select(id: "ts") |> tags() |> Enum.member?("ts-trigger-closed")

      assert MishkaTreeSelect.tree_select(id: "ts", open: true)
             |> tags()
             |> Enum.member?("ts-trigger-open")
    end

    test "disabled replaces the open state, being otherwise nothing but a muted ink" do
      tags = tags(MishkaTreeSelect.tree_select(id: "ts", disabled: true))

      assert "ts-trigger-disabled" in tags
      refute "ts-trigger-closed" in tags
    end

    test "the panel's own tag still reports a disabled select that was left open" do
      tags = MishkaTreeSelect.tree_select(%{id: "ts", disabled: true, open: true}, []) |> tags()

      assert "ts-trigger-disabled" in tags
      assert "ts-panel" in tags
    end

    test "the value says whether it is a placeholder — the web's data-placeholder" do
      empty = MishkaTreeSelect.tree_select(id: "ts")
      chosen = MishkaTreeSelect.tree_select(id: "ts", label: "mix.exs")

      assert value_node(empty, "ts-placeholder").props.text == "Select…"
      assert value_node(chosen, "ts-value").props.text == "mix.exs"
      refute "ts-value" in tags(empty)
      refute "ts-placeholder" in tags(chosen)
    end

    test "the panel is tagged only while it exists" do
      refute "ts-panel" in tags(MishkaTreeSelect.tree_select(id: "ts"))
      assert "ts-panel" in tags(MishkaTreeSelect.tree_select(%{id: "ts", open: true}, []))
    end

    test "without an id nothing is tagged, rather than tagging with a nil" do
      tree = MishkaTreeSelect.tree_select(%{open: true, label: "x"}, [])

      assert tags(tree) == []
    end
  end

  describe "the panel" do
    test "holds the children, and only when open" do
      child = [%{type: :text, props: %{text: "the tree"}, children: []}]

      refute text(MishkaTreeSelect.tree_select(%{}, child)) =~ "the tree"
      assert text(MishkaTreeSelect.tree_select(%{open: true}, child)) =~ "the tree"
    end

    test "holds a real tree, not just text" do
      tree = MishkaTreeSelect.tree_select(%{open: true}, [MishkaTree.tree(nodes: @nodes)])

      assert text(tree) =~ "lib"
      assert text(tree) =~ "mix.exs"
    end

    test "expand/3 uses the tag's children" do
      child = [%{type: :text, props: %{text: "x"}, children: []}]

      assert MishkaTreeSelect.expand(%{open: true}, child, %{screen: self()}) ==
               MishkaTreeSelect.tree_select(%{open: true}, child)
    end

    test "every variant renders" do
      for props <- [
            %{},
            %{id: "ts", label: "mix.exs"},
            %{id: "ts", open: true},
            %{id: "ts", disabled: true, label: "mix.exs"}
          ] do
        assert_renderable(MishkaTreeSelect.tree_select(props, [MishkaTree.tree(nodes: @nodes)]))
      end
    end
  end
end
