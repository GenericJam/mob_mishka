defmodule MobMishka.Components.MishkaRating do
  @moduledoc """
  Native Mob port of Mishka Chelekom's **headless Rating** — a row of stars with
  a real half star.

  The web component is a radio group because it is selectable. This port draws
  the value it is given: the caller owns the rating, the store and the tap that
  writes it. A control is a separate concern, and Mob has no radio-group engine
  with half steps to borrow.

  ## Icons

  `icon` and `empty_icon` take a glyph string, a node, or a list of nodes. A
  string is drawn as a `Text` at `size` in `color` / `empty_color`; a node is
  used as given, so an app's own icon font or glyph node keeps its own type.
  Either way the glyph is centred in a `size`-wide cell, so a node should be no
  wider than `size`.

  The defaults are the text characters `"★"` and `"☆"`, so a rating renders
  without an icon set.

  ## Every cell is a centred `size`-wide box

  A glyph's advance width is not `size`: `★` at text size 22 is narrower or
  wider than 22 depending on the font. Each cell, full, empty or half, is a Box
  `size` wide with `align: "center"`, and the glyph sits in its middle. Compose
  stacks a Box's children top-start unless told otherwise, and so does SwiftUI's
  `ZStack` as mob builds it, so without the alignment a glyph hugs the cell's
  left edge, and the half star's 50% cut lands beside the star's centre rather
  than on it. Because every cell is the same centred box, all the stars line up
  whichever of them is the half.

  On Android `size` is the cell's width in dp but a string glyph's text size in
  sp, which grows with the system font scale. At a large font scale the glyph
  can be wider than its cell, and is then cut to the cell's width. A rating that
  must keep its shape at any font scale takes node icons drawn `size` wide (an
  image or a canvas), which don't scale with text.

  ## The half star is a clip, not a second glyph

  A half star is the empty glyph with the filled one stacked over it and cut at
  50% by `clip_width`. Clipping the draw leaves measurement alone, so the pair
  occupies one star's line box and the row does not grow. The filled glyph sits
  in its own centred `size`-wide Box, and that Box carries the clip, so the cut
  falls at the cell's centre, which is the star's centre. `clip_width` keeps the
  leading half: the left in a left-to-right layout, the right in a right-to-left
  one, where the row runs the other way too.

  The cut needs a mob that draws `clip_width` (mob 0.9.x with clip_width) and,
  on Android, the mob_new bridge that reads it. On an older renderer the prop
  is ignored and a half star draws as a full one.

  ## Width only

  The cells carry a **width and no height**. The width is what the centring and
  the 50% crop need; the height must hug the glyph's line box. A fixed
  `size × size` Box makes that cell shorter than a star's text box: the row
  centres a shorter box against the others and the star's baseline drops below
  the line. Width only keeps every cell in the same line box, exactly as a bare
  star is.

  ## Props

  | Prop | Values | Default | Meaning |
  |------|--------|---------|---------|
  | `value` | number | `0` | The rating, in stars — `3.5` is three and a half. |
  | `count` | integer | `5` | How many cells. |
  | `size` | number | `22` | One cell's edge, and a string glyph's text size. |
  | `gap` | number | `2` | Space between cells. |
  | `icon` | string, node, or list of nodes | `"★"` | A full cell. |
  | `empty_icon` | string, node, or list of nodes | `"☆"` | An empty cell, and the outline under a half. |
  | `color` | color token / ARGB int | `:warning` | A string `icon`'s ink. |
  | `empty_color` | color token / ARGB int | `color` | A string `empty_icon`'s ink. |
  | `half` | boolean | `true` | Draw the half step when the value has one. |
  | `id` | string | unset | Native testTag on the row. |

  Children are ignored; the row is data.

  **Documentation:** https://mishka.tools/chelekom/docs/mob/rating
  """

  import Mob.Sigil

  @doc """
  Composite expander (`<MishkaRating />`). Delegates to `rating/1`.
  """
  @spec expand(map(), [map()], map()) :: map()
  def expand(props, _children, _ctx), do: rating(props)

  @doc """
  The rating node.

      rating(value: 3.5, size: 22, gap: 2)
  """
  @spec rating(map() | keyword()) :: map()
  def rating(props \\ %{}) do
    props = Map.new(props)

    ~MOB"""
    <Row align="center">
      {cells(props)}
    </Row>
    """
    |> put(:id, Map.get(props, :id))
  end

  defp cells(props) do
    size = setting(props, :size, 22)
    color = setting(props, :color, :warning)
    empty_color = setting(props, :empty_color, color)
    gap = setting(props, :gap, 2)
    count = setting(props, :count, 5)
    value = setting(props, :value, 0)
    full = trunc(value)
    half? = truthy?(Map.get(props, :half, true)) and value - full >= 0.5

    if count > 0 do
      1..count
      |> Enum.map(&star(cell(&1, full, half?), props, size, color, empty_color))
      |> Enum.intersperse(gap_node(gap))
    else
      []
    end
  end

  defp setting(props, key, default), do: Map.get(props, key) || default

  defp cell(index, full, _half?) when index <= full, do: :full
  defp cell(index, full, true) when index == full + 1, do: :half
  defp cell(_index, _full, _half?), do: :empty

  defp star(:full, props, size, color, _empty_color) do
    cell_box(size, %{}, glyph(Map.get(props, :icon) || "★", size, color))
  end

  defp star(:empty, props, size, _color, empty_color) do
    cell_box(size, %{}, glyph(Map.get(props, :empty_icon) || "☆", size, empty_color))
  end

  defp star(:half, props, size, color, empty_color) do
    empty = glyph(Map.get(props, :empty_icon) || "☆", size, empty_color)
    filled = cell_box(size, %{clip_width: 0.5}, glyph(Map.get(props, :icon) || "★", size, color))

    cell_box(size, %{}, List.wrap(empty) ++ [filled])
  end

  # A `size`-wide box with its content centred, and no height. See "Every cell
  # is a centred `size`-wide box" and "Width only".
  defp cell_box(size, extra, children) do
    %{
      type: :box,
      props: Map.merge(%{width: size, align: "center"}, extra),
      children: List.wrap(children)
    }
  end

  defp glyph(icon, size, color) when is_binary(icon) do
    ~MOB(<Text text={icon} text_size={size} text_color={color} />)
  end

  defp glyph(nodes, _size, _color), do: nodes

  defp gap_node(gap), do: %{type: :box, props: %{width: gap, height: 1}, children: []}

  defp truthy?(nil), do: false
  defp truthy?(false), do: false
  defp truthy?(_value), do: true

  defp put(node, _key, nil), do: node
  defp put(node, key, value), do: %{node | props: Map.put(node.props, key, value)}
end
