defmodule MobMishka do
  @moduledoc """
  Mishka Chelekom composites for Mob apps.

  This package is the plugin-shipped replacement for the "vendor 75 composite
  files into every generated app" pattern that `mob_new` uses today. Add it
  to your `mix.exs`:

      {:mob,         "~> 0.9.0"},
      {:mob_mishka,  "~> 0.1"}

  and every `<Mishka…>` composite works in your `~MOB` sigils — no
  `Components.register_all/0` in your `on_start/0`, no `config :mob,
  :extra_tags` block, no editing `deps/mob/priv/tags/*.txt`. The plugin
  registers its composites at boot via its own lifecycle hook, and the sigil's
  compile-time whitelist reads plugin manifests for tag membership (mob 0.9.0
  MOB-247).

  If you want to edit the source of a specific composite, run
  `mix mob_mishka.gen <name>` (MOB-251) to eject a copy into your
  `lib/<app>/components/<name>.ex`, where it supersedes the plugin's version.
  For the default experience keep the plugin dep and touch nothing.

  See the [`mob_mishka` extraction epic (MOB-246)][epic] for the full arc.

  [epic]: https://linear.app/mobframework/issue/MOB-246
  """

  @doc """
  Registers every composite this plugin ships with `Mob.Composite`.

  Called from the plugin's manifest `:lifecycle.on_start` at boot; you should
  not need to call it yourself.

  ## Override precedence (opt-in vendoring — MOB-251)

  If the host app has ejected a composite into its own `lib/` (via `mix
  mob_mishka.gen <name>`), the user-owned module supersedes the plugin's
  default for that tag. Enable via `config/config.exs`:

      config :mob_mishka, :override_namespace, MyApp.Components

  On boot, for each `{tag, PluginModule}` in `composites/0`, `register_all/0`
  looks up `Module.concat(<override_namespace>, short_name(PluginModule))` and
  registers it if that module is loaded; otherwise it falls back to the
  plugin's own. So editing a copy in your `lib/` takes effect automatically
  without touching the plugin.
  """
  @spec register_all() :: :ok
  def register_all do
    namespace = Application.get_env(:mob_mishka, :override_namespace)

    Enum.each(composites(), fn {tag, plugin_module} ->
      module = pick_module(plugin_module, namespace)
      Mob.Composite.register(tag, {module, :expand})
    end)
  end

  # No override configured — always use the plugin-shipped composite.
  defp pick_module(plugin_module, nil), do: plugin_module

  defp pick_module(plugin_module, namespace) do
    short = plugin_module |> Module.split() |> List.last()
    override = Module.concat(namespace, short)

    # `ensure_loaded?/1` triggers a lazy load if the module compiled but hasn't
    # been referenced yet — the composite might live in a file the compiler
    # hasn't touched at boot time. Fall back to the plugin if the user's
    # module doesn't exist.
    if Code.ensure_loaded?(override), do: override, else: plugin_module
  end

  @doc """
  Enumerates every `{tag_atom, module}` this plugin registers.

  Grows in MOB-249 as composites port from
  `mishka_chelekom/development/mob/lib/mishka_mob/components/`. Kept as a
  data list so tests and the eventual `mix mob_mishka.gen` task can
  introspect the set without invoking `register_all/0`.

  Registration order is stable (alphabetical by tag atom) so a rebuild
  after adding one composite doesn't reshuffle the registry.
  """
  @spec composites() :: [{atom(), module()}]
  def composites do
    [
      {:mishka_accordion, MobMishka.Components.MishkaAccordion},
      {:mishka_action_icon, MobMishka.Components.MishkaActionIcon},
      {:mishka_alert_dialog, MobMishka.Components.MishkaAlertDialog},
      {:mishka_alpha_slider, MobMishka.Components.MishkaAlphaSlider},
      {:mishka_anchor, MobMishka.Components.MishkaAnchor},
      {:mishka_angle_slider, MobMishka.Components.MishkaAngleSlider},
      {:mishka_autocomplete, MobMishka.Components.MishkaAutocomplete},
      {:mishka_avatar, MobMishka.Components.MishkaAvatar},
      {:mishka_burger, MobMishka.Components.MishkaBurger},
      {:mishka_checkbox, MobMishka.Components.MishkaCheckbox},
      {:mishka_checkbox_group, MobMishka.Components.MishkaCheckboxGroup},
      {:mishka_chip, MobMishka.Components.MishkaChip},
      {:mishka_close_button, MobMishka.Components.MishkaCloseButton},
      {:mishka_code, MobMishka.Components.MishkaCode},
      {:mishka_collapsible, MobMishka.Components.MishkaCollapsible},
      {:mishka_color_input, MobMishka.Components.MishkaColorInput},
      {:mishka_color_picker, MobMishka.Components.MishkaColorPicker},
      {:mishka_color_swatch, MobMishka.Components.MishkaColorSwatch},
      {:mishka_combobox, MobMishka.Components.MishkaCombobox},
      {:mishka_context_menu, MobMishka.Components.MishkaContextMenu},
      {:mishka_dialog, MobMishka.Components.MishkaDialog},
      {:mishka_drawer, MobMishka.Components.MishkaDrawer},
      {:mishka_empty_state, MobMishka.Components.MishkaEmptyState},
      {:mishka_field, MobMishka.Components.MishkaField},
      {:mishka_fieldset, MobMishka.Components.MishkaFieldset},
      {:mishka_floating_indicator, MobMishka.Components.MishkaFloatingIndicator},
      {:mishka_floating_window, MobMishka.Components.MishkaFloatingWindow},
      {:mishka_highlight, MobMishka.Components.MishkaHighlight},
      {:mishka_hue_slider, MobMishka.Components.MishkaHueSlider},
      {:mishka_json_input, MobMishka.Components.MishkaJsonInput},
      {:mishka_loading_overlay, MobMishka.Components.MishkaLoadingOverlay},
      {:mishka_mark, MobMishka.Components.MishkaMark},
      {:mishka_marquee, MobMishka.Components.MishkaMarquee},
      {:mishka_mask_input, MobMishka.Components.MishkaMaskInput},
      {:mishka_menu, MobMishka.Components.MishkaMenu},
      {:mishka_menubar, MobMishka.Components.MishkaMenubar},
      {:mishka_meter, MobMishka.Components.MishkaMeter},
      {:mishka_nav_link, MobMishka.Components.MishkaNavLink},
      {:mishka_navigation_menu, MobMishka.Components.MishkaNavigationMenu},
      {:mishka_number_field, MobMishka.Components.MishkaNumberField},
      {:mishka_number_formatter, MobMishka.Components.MishkaNumberFormatter},
      {:mishka_otp_field, MobMishka.Components.MishkaOtpField},
      {:mishka_overflow_list, MobMishka.Components.MishkaOverflowList},
      {:mishka_pill, MobMishka.Components.MishkaPill},
      {:mishka_pills_input, MobMishka.Components.MishkaPillsInput},
      {:mishka_popover, MobMishka.Components.MishkaPopover},
      {:mishka_preview_card, MobMishka.Components.MishkaPreviewCard},
      {:mishka_progress, MobMishka.Components.MishkaProgress},
      {:mishka_radio, MobMishka.Components.MishkaRadio},
      {:mishka_radio_group, MobMishka.Components.MishkaRadioGroup},
      {:mishka_rolling_number, MobMishka.Components.MishkaRollingNumber},
      {:mishka_scroll_area, MobMishka.Components.MishkaScrollArea},
      {:mishka_scroller, MobMishka.Components.MishkaScroller},
      {:mishka_segmented_control, MobMishka.Components.MishkaSegmentedControl},
      {:mishka_select, MobMishka.Components.MishkaSelect},
      {:mishka_semi_circle_progress, MobMishka.Components.MishkaSemiCircleProgress},
      {:mishka_separator, MobMishka.Components.MishkaSeparator},
      {:mishka_skeleton, MobMishka.Components.MishkaSkeleton},
      {:mishka_slider, MobMishka.Components.MishkaSlider},
      {:mishka_splitter, MobMishka.Components.MishkaSplitter},
      {:mishka_spoiler, MobMishka.Components.MishkaSpoiler},
      {:mishka_switch, MobMishka.Components.MishkaSwitch},
      {:mishka_tabs, MobMishka.Components.MishkaTabs},
      {:mishka_tags_input, MobMishka.Components.MishkaTagsInput},
      {:mishka_theme_icon, MobMishka.Components.MishkaThemeIcon},
      {:mishka_toast, MobMishka.Components.MishkaToast},
      {:mishka_toggle, MobMishka.Components.MishkaToggle},
      {:mishka_toggle_group, MobMishka.Components.MishkaToggleGroup},
      {:mishka_toolbar, MobMishka.Components.MishkaToolbar},
      {:mishka_tooltip, MobMishka.Components.MishkaTooltip},
      {:mishka_tree, MobMishka.Components.MishkaTree},
      {:mishka_tree_select, MobMishka.Components.MishkaTreeSelect},
      {:mishka_visually_hidden, MobMishka.Components.MishkaVisuallyHidden}
    ]
  end
end
