%{
  name: :mob_mishka,
  mob_version: "~> 0.8",
  plugin_spec_version: 1,
  description: "Mishka Chelekom composites for Mob apps — plugin-shipped",

  # PascalCase tags this plugin contributes to the `~MOB` sigil whitelist.
  # Grows in MOB-249 as composites port from
  # `mishka_chelekom/development/mob/lib/*/components/*.ex`. Every tag here
  # matches a `{tag_atom, module}` entry in `MobMishka.composites/0`. See
  # MOB-247 in mob for how the sigil reads this list at compile time.
  #
  # Also accepts a per-platform map:
  #
  #     tags: %{ios: ~w(FooIOS), android: ~w(FooAndroid), both: ~w(FooShared)}
  tags: ~w(
    MishkaAccordion
    MishkaActionIcon
    MishkaAlertDialog
    MishkaAlphaSlider
    MishkaAnchor
    MishkaAngleSlider
    MishkaAutocomplete
    MishkaAvatar
    MishkaBurger
    MishkaCheckbox
    MishkaCheckboxGroup
    MishkaChip
    MishkaCloseButton
    MishkaCode
    MishkaCollapsible
    MishkaColorInput
    MishkaColorPicker
    MishkaColorSwatch
    MishkaCombobox
    MishkaContextMenu
    MishkaDialog
    MishkaDrawer
    MishkaEmptyState
    MishkaField
    MishkaFieldset
    MishkaFloatingIndicator
    MishkaFloatingWindow
    MishkaHighlight
    MishkaHueSlider
    MishkaJsonInput
    MishkaLoadingOverlay
    MishkaMark
    MishkaMarquee
    MishkaMaskInput
    MishkaMenu
    MishkaMenubar
    MishkaMeter
    MishkaNavLink
    MishkaNavigationMenu
    MishkaNumberField
    MishkaNumberFormatter
    MishkaOtpField
    MishkaOverflowList
    MishkaPill
    MishkaPillsInput
    MishkaPopover
    MishkaPreviewCard
    MishkaProgress
    MishkaRadio
    MishkaRadioGroup
    MishkaRollingNumber
    MishkaScrollArea
    MishkaScroller
    MishkaSegmentedControl
    MishkaSelect
    MishkaSemiCircleProgress
    MishkaSeparator
    MishkaSkeleton
    MishkaSlider
    MishkaSplitter
    MishkaSpoiler
    MishkaSwitch
    MishkaTabs
    MishkaTagsInput
    MishkaThemeIcon
    MishkaToast
    MishkaToggle
    MishkaToggleGroup
    MishkaToolbar
    MishkaTooltip
    MishkaTree
    MishkaTreeSelect
    MishkaVisuallyHidden
  ),

  # Runs at host app boot (called by `Mob.Plugins.Lifecycle` after the
  # plugin's application has started). Registers every composite listed in
  # `MobMishka.composites/0` into the host's `Mob.Composite` table so
  # `<MishkaTabs />` in `~MOB` resolves to `{MobMishka.Components.MishkaTabs,
  # :expand}` at render time.
  lifecycle: %{
    on_start: {MobMishka, :register_all, []}
  }
}
