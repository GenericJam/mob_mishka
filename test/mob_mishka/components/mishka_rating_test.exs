defmodule MobMishka.Components.MishkaRatingTest do
  # async: false — Mob.ScreenCase starts the globally-named `Mob.State`.
  use Mob.ScreenCase, async: false

  alias MobMishka.Components.MishkaRating, as: Rating

  defp texts(tree), do: tree |> find_all(:text) |> Enum.map(& &1.props[:text])
  defp count(tree, glyph), do: Enum.count(texts(tree), &(&1 == glyph))
  # The row's children alternate cell, gap, cell, …
  defp cells(tree), do: Enum.take_every(tree.children, 2)

  describe "the value" do
    test "whole stars split into full and empty" do
      tree = Rating.rating(value: 3)

      assert count(tree, "★") == 3
      assert count(tree, "☆") == 2
    end

    test "0 is five empty cells, not an empty row" do
      tree = Rating.rating(value: 0)

      assert count(tree, "★") == 0
      assert count(tree, "☆") == 5
    end

    test "a fraction below a half draws no half" do
      tree = Rating.rating(value: 3.4)

      assert count(tree, "★") == 3
      assert count(tree, "☆") == 2
      assert find(tree, :box, clip_width: 0.5) == nil
    end

    test "half: false keeps the row whole" do
      tree = Rating.rating(value: 3.5, half: false)

      assert count(tree, "★") == 3
      assert find(tree, :box, clip_width: 0.5) == nil
    end
  end

  describe "the half star" do
    test "is the empty glyph with a filled one clipped over it" do
      tree = Rating.rating(value: 3.5)
      clip = find(tree, :box, clip_width: 0.5)

      assert %{type: :box} = clip
      assert [full] = find_all(clip, :text)
      assert full.props.text == "★"

      half = Enum.at(cells(tree), 3)
      assert [%{type: :text, props: %{text: "☆"}}, ^clip] = half.children
    end

    test "the filled glyph is centred in a size-wide clip box, so the cut lands on its centre" do
      # Start-aligned, the glyph hugs the box's left edge and 50% of `size`
      # cuts beside the star's centre, because a glyph's advance isn't `size`.
      clip = find(Rating.rating(value: 3.5, size: 22), :box, clip_width: 0.5)

      assert clip.props.width == 22
      assert clip.props.align == "center"
    end

    test "carries the cell's width and NO height, so it sits on the star line" do
      # A fixed height makes this cell shorter than the other stars' text boxes:
      # the row centres a shorter box and the half's baseline drops.
      tree = Rating.rating(value: 3.5, size: 22)
      clip = find(tree, :box, clip_width: 0.5)

      refute Map.has_key?(clip.props, :height)
      refute Map.has_key?(Enum.at(cells(tree), 3).props, :height)
    end
  end

  describe "cells" do
    test "full, half and empty cells are the same centred size-wide box with no height" do
      # The same box for every cell is what lines the five stars up.
      for cell <- cells(Rating.rating(value: 2.5, size: 22)) do
        assert cell.type == :box
        assert Map.delete(cell.props, :clip_width) == %{width: 22, align: "center"}
      end
    end

    test "a list-of-nodes icon stays inside its one cell" do
      empty = [
        %{type: :text, props: %{text: "O"}, children: []},
        %{type: :text, props: %{text: "o"}, children: []}
      ]

      tree = Rating.rating(value: 0, empty_icon: empty, gap: 4)

      assert [_, _, _, _, _] = cells = cells(tree)
      assert Enum.all?(cells, &(&1.children == empty))
    end
  end

  describe "geometry" do
    test "count sets how many cells" do
      assert count(Rating.rating(value: 7, count: 10), "★") == 7
    end

    test "gap is a declared spacer between cells" do
      tree = Rating.rating(value: 2, gap: 4)

      assert tree |> find_all(:box) |> Enum.count(&(&1.props[:width] == 4)) == 4
    end

    test "a string icon is drawn at size" do
      tree = Rating.rating(value: 1, size: 30)

      assert [full | _rest] = find_all(tree, :text)
      assert full.props.text_size == 30
    end
  end

  describe "icons" do
    test "a node replaces the string glyph" do
      icon = %{type: :text, props: %{text: "X"}, children: []}
      empty = %{type: :text, props: %{text: "O"}, children: []}

      tree = Rating.rating(value: 1, icon: icon, empty_icon: empty)

      assert texts(tree) == ["X", "O", "O", "O", "O"]
    end

    test "a list of nodes is used as given" do
      empty = [%{type: :text, props: %{text: "O"}, children: []}]

      tree = Rating.rating(value: 0, empty_icon: empty)

      assert count(tree, "O") == 5
    end
  end

  test "id is a testTag on the row" do
    assert Rating.rating(value: 3, id: "rating").props.id == "rating"
  end

  test "renders" do
    assert_renderable(Rating.rating(value: 3.5))
  end
end
